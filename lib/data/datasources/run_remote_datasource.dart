import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/active_run_entity.dart';
import '../../domain/entities/completed_run_entity.dart';

/// Remote data source for all run-related Supabase operations.
///
/// All methods throw a [PostgrestException] on server errors — callers are
/// responsible for catching and converting to domain failures.
class RunRemoteDataSource {
  final SupabaseClient _client;

  RunRemoteDataSource(this._client);

  // ── Reads ──────────────────────────────────────────────────────────────────

  /// Fetches the current user's ongoing runs joined with challenge metadata
  /// and the latest check-in date for each run.
  ///
  /// Returns a list of [ActiveRunEntity] ready to load into [RunsRepository].
  Future<List<ActiveRunEntity>> fetchMyRuns() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    // Fetch ongoing runs with challenge data joined.
    // last_checkin_day is derived from the max(check_in_day_utc) in checkins.
    final rows = await _client
        .from('runs')
        .select('''
          id,
          challenge_id,
          current_streak,
          start_date,
          challenges!inner(title, slug),
          checkins(check_in_day_utc)
        ''')
        .eq('user_id', userId)
        .eq('status', 'ongoing')
        .order('created_at');

    final today = _todayUtc();

    return rows.map<ActiveRunEntity>((row) {
      final runId = row['id'] as String;
      final startDate = (row['start_date'] as String).substring(0, 10);
      final challenge = row['challenges'] as Map<String, dynamic>;

      // Derive lastCheckinDay from all checkin rows for this run
      final checkins = (row['checkins'] as List<dynamic>? ?? []);
      final checkinDays = checkins
          .map((c) => (c['check_in_day_utc'] as String).substring(0, 10))
          .toList()
        ..sort();
      final lastCheckinDay = checkinDays.isNotEmpty ? checkinDays.last : null;

      // hasCheckedInToday: true if the last checkin was today's UTC date
      final hasCheckedInToday = lastCheckinDay == today;

      return ActiveRunEntity(
        runId: runId,
        challengeId: row['challenge_id'] as String,
        challengeTitle: challenge['title'] as String,
        challengeSlug: challenge['slug'] as String,
        currentStreak: row['current_streak'] as int,
        startDate: startDate,
        hasCheckedInToday: hasCheckedInToday,
        lastCheckinDay: lastCheckinDay,
      );
    }).toList();
  }

  /// Fetches the current user's completed runs.
  Future<List<CompletedRunEntity>> fetchMyCompletedRuns() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final rows = await _client
        .from('runs')
        .select('''
          id,
          challenge_id,
          final_score,
          start_date,
          updated_at,
          challenges!inner(title, slug)
        ''')
        .eq('user_id', userId)
        .eq('status', 'completed')
        .order('updated_at', ascending: false);

    return rows.map<CompletedRunEntity>((row) {
      final challenge = row['challenges'] as Map<String, dynamic>;
      // updated_at is set to now() when settled — use its date as endDate
      final endDate =
          (row['updated_at'] as String).substring(0, 10);

      return CompletedRunEntity(
        runId: 'completed-${row['id']}',
        challengeId: row['challenge_id'] as String,
        challengeTitle: challenge['title'] as String,
        challengeSlug: challenge['slug'] as String,
        finalScore: (row['final_score'] as int?) ?? 0,
        startDate: (row['start_date'] as String).substring(0, 10),
        endDate: endDate,
      );
    }).toList();
  }

  // ── Writes ─────────────────────────────────────────────────────────────────

  /// Creates a new ongoing run for the current user on [challengeId].
  ///
  /// Returns the newly created run's UUID so [RunsRepository] can use it.
  Future<String> createRun({required String challengeId}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final today = _todayUtc();

    final row = await _client
        .from('runs')
        .insert({
          'challenge_id': challengeId,
          'user_id': userId,
          'start_date': today,
          'current_streak': 0,
          'status': 'ongoing',
          'visibility': 'public',
        })
        .select('id')
        .single();

    // Increment challenge participant count
    await _client.rpc('increment_participant_count', params: {
      'cid': challengeId,
    });

    return row['id'] as String;
  }

  /// Records a check-in for today on [runId] and increments the streak.
  ///
  /// Idempotent: the `unique(run_id, check_in_day_utc)` constraint on the
  /// checkins table means a duplicate insert is silently ignored.
  Future<void> recordCheckin({
    required String runId,
    required int newStreak,
  }) async {
    final today = _todayUtc();

    // Insert (or ignore duplicate) check-in row
    await _client.from('checkins').upsert(
      {
        'run_id': runId,
        'check_in_day_utc': today,
      },
      onConflict: 'run_id,check_in_day_utc',
      ignoreDuplicates: true,
    );

    // Update the run's streak counter
    await _client.from('runs').update({
      'current_streak': newStreak,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', runId);
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  /// Calls the server-side [settle_runs] RPC for [todayUtc].
  ///
  /// This is fire-and-forget from the client perspective — any runs settled
  /// here are removed from the active list on the next [fetchMyRuns] call.
  ///
  /// Never throws: errors are swallowed and logged so they never block the UI.
  Future<void> settleRuns(String todayUtc) async {
    try {
      await _client.rpc('settle_runs', params: {'today_utc': todayUtc});
    } catch (e) {
      // Settlement failure is non-fatal — the nightly pg_cron job is the
      // safety net. Log only; never surface to the user.
      // ignore: avoid_print
      print('[RunRemoteDataSource] settle_runs error (non-fatal): $e');
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static String _todayUtc() {
    final now = DateTime.now().toUtc();
    return '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }
}
