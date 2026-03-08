import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/explore_run_entity.dart';
import '../../domain/entities/active_run_entity.dart';
import '../../domain/entities/completed_run_entity.dart';
import '../../domain/entities/bet_resolution_entity.dart';
import '../../domain/entities/stake_entity.dart';

import 'package:injectable/injectable.dart';

/// Remote data source for all run-related Supabase operations.
///
/// All methods throw a [PostgrestException] on server errors — callers are
/// responsible for catching and converting to domain failures.
@lazySingleton
class RunRemoteDataSource {
  final SupabaseClient _client;

  RunRemoteDataSource(this._client);

  // ── Reads ──────────────────────────────────────────────────────────────────

  /// Fetches the current user's ongoing runs joined with challenge metadata
  /// and the latest check-in date for each run.
  ///
  /// Returns a list of [ActiveRunEntity] ready to load into [RunsRepository].
  Future<List<ActiveRunEntity>> fetchMyRuns() async {
    final user = _client.auth.currentUser;
    final userId = user?.id;
    // ignore: avoid_print
    print('🚀 [RunRemoteDataSource] fetchMyRuns started. Auth state: ${user != null ? 'Logged in ($userId)' : 'Not logged in'}');
    
    if (userId == null) {
      // ignore: avoid_print
      print('⚠️ [RunRemoteDataSource] No user ID, returning empty list');
      return [];
    }

    return fetchUserRuns(userId);
  }

  /// Fetches ongoing runs for a specific user.
  Future<List<ActiveRunEntity>> fetchUserRuns(String userId) async {
    try {
      // ignore: avoid_print
      print('🚀 [RunRemoteDataSource] querying runs for user $userId...');
      final rows = await _client
          .from('runs')
          .select('''
            id,
            challenge_id,
            current_streak,
            start_date,
            challenges!inner(title, slug),
            checkins(check_in_day_utc),
            bets(id)
          ''')
          .eq('user_id', userId)
          .eq('status', 'ongoing')
          .order('created_at')
          .timeout(const Duration(seconds: 15));

      final today = _todayUtc();

      final runs = <ActiveRunEntity>[];
      for (final row in rows) {
        try {
          runs.add(_mapActiveRun(row, today));
        } catch (e) {
          // ignore: avoid_print
          print('[RunRemoteDataSource] row mapping error: $e');
          // skip this single row if it's malformed
        }
      }
      return runs;
    } catch (e) {
      // ignore: avoid_print
      print('[RunRemoteDataSource] fetchUserRuns fatal error: $e');
      rethrow;
    }
  }

  ActiveRunEntity _mapActiveRun(Map<String, dynamic> row, String today) {
    final runId = row['id'] as String;
    // start_date is a date string 'yyyy-MM-dd' or ISO. 
    // Use safe substring or fallback.
    final rawStart = row['start_date']?.toString() ?? today;
    final startDate = rawStart.length >= 10 
        ? rawStart.substring(0, 10) 
        : rawStart;
    
    final challenge = row['challenges'] as Map<String, dynamic>? ?? {};
    final title = challenge['title']?.toString() ?? 'Unknown Challenge';
    final slug = challenge['slug']?.toString() ?? 'unknown-slug';

    // Derive lastCheckinDay from all checkin rows for this run
    final checkins = (row['checkins'] as List<dynamic>? ?? []);
    final checkinDays = checkins
        .map((c) {
          final day = c['check_in_day_utc']?.toString();
          return (day != null && day.length >= 10) 
              ? day.substring(0, 10) 
              : null;
        })
        .whereType<String>()
        .toList()
      ..sort();
    
    final lastCheckinDay = checkinDays.isNotEmpty ? checkinDays.last : null;
    final hasCheckedInToday = lastCheckinDay == today;

    // Count bets
    final bets = (row['bets'] as List<dynamic>? ?? []);
    final betCount = bets.length;

    return ActiveRunEntity(
      runId: runId,
      challengeId: row['challenge_id'] as String? ?? '',
      challengeTitle: title,
      challengeSlug: slug,
      currentStreak: row['current_streak'] as int? ?? 0,
      startDate: startDate,
      hasCheckedInToday: hasCheckedInToday,
      lastCheckinDay: lastCheckinDay,
      betCount: betCount,
    );
  }

  /// Fetches the current user's completed runs.
  Future<List<CompletedRunEntity>> fetchMyCompletedRuns() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    return fetchUserCompletedRuns(userId);
  }

  /// Fetches completed runs for a specific user.
  Future<List<CompletedRunEntity>> fetchUserCompletedRuns(String userId) async {
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

    return rows.map<CompletedRunEntity>((row) => _mapCompletedRun(row)).toList();
  }

  CompletedRunEntity _mapCompletedRun(Map<String, dynamic> row) {
    final challenge = row['challenges'] as Map<String, dynamic>;
    // updated_at is set to now() when settled — use its date as endDate
    final endDate = (row['updated_at'] as String).substring(0, 10);

    return CompletedRunEntity(
      runId: 'completed-${row['id']}',
      challengeId: row['challenge_id'] as String,
      challengeTitle: challenge['title'] as String,
      challengeSlug: challenge['slug'] as String,
      finalScore: (row['final_score'] as int?) ?? 0,
      startDate: (row['start_date'] as String).substring(0, 10),
      endDate: endDate,
    );
  }

  /// Fetches a batch of runs for the Explore screen using the priority-based RPC.
  Future<List<ExploreRunEntity>> fetchExploreFeed({
    required int limit,
    required int offset,
  }) async {
    final userId = _client.auth.currentUser?.id;
    try {
      final rows = await _client.rpc('get_explore_feed', params: {
        'p_user_id': userId,
        'p_limit': limit,
        'p_offset': offset,
      }) as List<dynamic>;

      return rows.map<ExploreRunEntity>((r) {
        // The SQL aliases `image_asset` as `image_url` — these are local
        // asset paths, so map to `imageAsset` for correct rendering.
        return ExploreRunEntity(
          runId: r['run_id'] as String,
          challengeId: r['challenge_id'] as String,
          challengeTitle: r['challenge_title'] as String,
          challengeSlug: r['challenge_slug'] as String,
          userId: r['user_id'] as String,
          username: r['username'] as String,
          avatarId: r['avatar_id'] as int?,
          currentStreak: r['current_streak'] as int,
          imageAsset: r['image_url'] as String?,
          challengeDescription: r['challenge_description'] as String?,
          recentBetCount: r['recent_bet_count'] as int? ?? 0,
          isCompleted: r['is_completed'] as bool? ?? false,
        );
      }).toList();
    } catch (e) {
      // ignore: avoid_print
      print('[RunRemoteDataSource] fetchExploreFeed error: $e');
      rethrow;
    }
  }

  /// Records a run dismissal to exclude it from the Explore feed for 14 days.
  Future<void> dismissRun(String runId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final expiresAt =
        DateTime.now().toUtc().add(const Duration(days: 14)).toIso8601String();

    await _client.from('dismissed_runs').upsert({
      'user_id': userId,
      'run_id': runId,
      'expires_at': expiresAt,
    }, onConflict: 'user_id, run_id');
  }

  // ── Writes ─────────────────────────────────────────────────────────────────

  /// Creates a new ongoing run for the current user on [challengeId] atomically.
  ///
  /// Calls the `join_challenge` RPC which handles the run insertion and
  /// challenge participant increment in a single transaction.
  ///
  /// Returns the newly created run's UUID.
  Future<String> createRun({required String challengeId}) async {
    final result = await _client.rpc('join_challenge', params: {
      'p_challenge_id': challengeId,
    });
    return result as String;
  }

  /// Records a check-in for today on [runId] via the server-side RPC.
  ///
  /// Returns a [BetResolutionEntity] if the new streak triggered any won bets,
  /// or `null` if no bets were triggered.
  ///
  /// The RPC handles streak increment, checkin insert, bet settlement, and
  /// notification creation atomically in a single round-trip.
  Future<BetResolutionEntity?> recordCheckin({
    required String runId,
    required String challengeTitle,
    required String todayUtc,
  }) async {
    final result = await _client.rpc('perform_checkin', params: {
      'p_run_id': runId,
      'p_day_utc': todayUtc,
    });

    // RPC returns: { new_streak: int, triggered_bets: [...] }
    final json = result as Map<String, dynamic>;
    final triggeredBets =
        (json['triggered_bets'] as List<dynamic>? ?? []);

    if (triggeredBets.isEmpty) return null;

    final wonBets = triggeredBets.map<WonBetEntry>((b) {
      final catStr = b['stake_category'] as String? ?? 'plan';
      final category = switch (catStr) {
        'gift' => StakeCategory.gift,
        'custom' => StakeCategory.custom,
        _ => StakeCategory.plan,
      };
      return WonBetEntry(
        betId: b['id'] as String,
        bettorId: b['bettor_id'] as String,
        bettorUsername: b['bettor_username'] as String?,
        bettorAvatarId: b['bettor_avatar_id'] as int?,
        stakeTitle: b['stake_title'] as String?,
        stakeId: b['stake_id'] as String?,
        stakeCategory: category,
        stakeEmoji: b['stake_emoji'] as String?,
        isSelfBet: b['is_self_bet'] as bool? ?? false,
      );
    }).toList();

    return BetResolutionEntity(
      runId: runId,
      challengeTitle: challengeTitle,
      newStreak: json['new_streak'] as int,
      wonBets: wonBets,
    );
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
