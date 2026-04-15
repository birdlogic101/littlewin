import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive/hive.dart';
import '../../domain/entities/explore_run_entity.dart';
import '../../domain/entities/active_run_entity.dart';
import '../../domain/entities/completed_run_entity.dart';
import '../../domain/entities/bet_resolution_entity.dart';
import '../../domain/entities/stake_entity.dart';

import 'package:injectable/injectable.dart';

/// Remote data source for all run-related Supabase operations.
@lazySingleton
class RunRemoteDataSource {
  final SupabaseClient _client;

  RunRemoteDataSource(this._client);

  // ── Reads ──────────────────────────────────────────────────────────────────

  /// Fetches the current user's ongoing runs joined with challenge metadata.
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
  ///
  /// If [userId] is not the current user, filters for public challenges only.
  Future<List<ActiveRunEntity>> fetchUserRuns(String userId) async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      final isOwner = currentUserId != null && currentUserId == userId;

      // ignore: avoid_print
      print('🚀 [RunRemoteDataSource] querying runs for user $userId (isOwner: $isOwner)...');

      var query = _client
          .from('runs')
          .select('''
            id,
            challenge_id,
            current_streak,
            start_date,
            challenges!inner(title, slug, image_asset, visibility, description),
            checkins(check_in_day_utc),
            bets(id)
          ''')
          .eq('user_id', userId)
          .eq('status', 'ongoing');

      // Privacy Filter: Only show public runs to other users
      if (!isOwner) {
        query = query.eq('challenges.visibility', 'public');
      }

      final rows = await query.order('created_at').timeout(const Duration(seconds: 15));
      final today = _todayUtc();

      final runs = <ActiveRunEntity>[];
      for (final row in rows) {
        try {
          runs.add(_mapActiveRun(row, today));
        } catch (e) {
          // ignore: avoid_print
          print('⚠️ [RunRemoteDataSource] row mapping error in fetchUserRuns: $e');
        }
      }
      return runs;
    } catch (e) {
      // ignore: avoid_print
      print('❌ [RunRemoteDataSource] fetchUserRuns fatal error: $e');
      rethrow;
    }
  }

  ActiveRunEntity _mapActiveRun(Map<String, dynamic> row, String today) {
    final rawStart = row['start_date']?.toString() ?? today;
    final startDate = rawStart.length >= 10 
        ? rawStart.substring(0, 10) 
        : rawStart;
    
    final challenge = row['challenges'] as Map<String, dynamic>? ?? {};
    final isPublic = challenge['visibility']?.toString() == 'public';

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

    final description = challenge['description'] as String?;
    if (description != null) {
      Hive.box('challenge_descriptions').put(row['challenge_id'], description);
    }

    return ActiveRunEntity(
      runId: row['id'] as String,
      challengeId: row['challenge_id'] as String? ?? '',
      challengeTitle: challenge['title']?.toString() ?? 'Unknown Challenge',
      challengeDescription: description,
      challengeSlug: challenge['slug']?.toString() ?? 'unknown-slug',
      currentStreak: row['current_streak'] as int? ?? 0,
      startDate: startDate,
      hasCheckedInToday: hasCheckedInToday,
      lastCheckinDay: lastCheckinDay,
      betCount: (row['bets'] as List<dynamic>? ?? []).length,
      isPublic: isPublic,
      imageAsset: challenge['image_asset'] as String? ?? 'assets/pictures/challenge_default_1080.jpg',
    );
  }

  /// Fetches the current user's completed runs.
  Future<List<CompletedRunEntity>> fetchMyCompletedRuns() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    return fetchUserCompletedRuns(userId);
  }

  /// Fetches completed runs for a specific user.
  ///
  /// If [userId] is not the current user, filters for public challenges only.
  Future<List<CompletedRunEntity>> fetchUserCompletedRuns(String userId) async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      final isOwner = currentUserId != null && currentUserId == userId;

      // ignore: avoid_print
      print('🚀 [RunRemoteDataSource] querying completed runs for user $userId (isOwner: $isOwner)...');

      var query = _client
          .from('runs')
          .select('''
            id,
            challenge_id,
            final_score,
            start_date,
            updated_at,
            challenges!inner(title, slug, image_asset, visibility, description)
          ''')
          .eq('user_id', userId)
          .eq('status', 'completed');

      if (!isOwner) {
        query = query.eq('challenges.visibility', 'public');
      }

      final rows = await query.order('updated_at', ascending: false);
      
      final runs = <CompletedRunEntity>[];
      for (final row in rows) {
        try {
          runs.add(_mapCompletedRun(row));
        } catch (e) {
          // ignore: avoid_print
          print('⚠️ [RunRemoteDataSource] row mapping error in fetchUserCompletedRuns: $e');
        }
      }
      return runs;
    } catch (e) {
      // ignore: avoid_print
      print('❌ [RunRemoteDataSource] fetchUserCompletedRuns error: $e');
      rethrow;
    }
  }

  CompletedRunEntity _mapCompletedRun(Map<String, dynamic> row) {
    final challenge = row['challenges'] as Map<String, dynamic>;
    final isPublic = challenge['visibility']?.toString() == 'public';
    
    final rawUpdate = row['updated_at']?.toString() ?? _todayUtc();
    final endDate = rawUpdate.length >= 10 ? rawUpdate.substring(0, 10) : rawUpdate;

    final rawStart = row['start_date']?.toString() ?? _todayUtc();
    final startDate = rawStart.length >= 10 ? rawStart.substring(0, 10) : rawStart;

    final description = challenge['description'] as String?;
    if (description != null) {
      Hive.box('challenge_descriptions').put(row['challenge_id'], description);
    }

    return CompletedRunEntity(
      runId: 'completed-${row['id']}',
      challengeId: row['challenge_id'] as String,
      challengeTitle: challenge['title'] as String,
      challengeDescription: description,
      challengeSlug: challenge['slug'] as String,
      finalScore: (row['final_score'] as int?) ?? 0,
      startDate: startDate,
      endDate: endDate,
      isPublic: isPublic,
      imageAsset: challenge['image_asset'] as String? ?? 'assets/pictures/challenge_default_1080.jpg',
    );
  }

  /// Fetches a batch of runs for the Explore screen.
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

      return rows.map<ExploreRunEntity>((r) => ExploreRunEntity(
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
          isPremium: r['is_premium'] as bool? ?? false,
        )).toList();
    } catch (e) {
      // ignore: avoid_print
      print('❌ [RunRemoteDataSource] fetchExploreFeed error: $e');
      rethrow;
    }
  }

  Future<void> dismissRun(String runId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    final expiresAt = DateTime.now().toUtc().add(const Duration(days: 14)).toIso8601String();
    await _client.from('dismissed_runs').upsert({
      'user_id': userId,
      'run_id': runId,
      'expires_at': expiresAt,
    }, onConflict: 'user_id, run_id');
  }

  Future<String> createRun({required String challengeId}) async {
    // ignore: avoid_print
    print('🚀 [RunRemoteDataSource] joinChallenge RPC for $challengeId...');
    final result = await _client.rpc('join_challenge', params: {
      'p_challenge_id': challengeId,
    });
    return result as String;
  }

  Future<BetResolutionEntity?> recordCheckin({
    required String runId,
    required String challengeTitle,
    required String todayUtc,
  }) async {
    // ignore: avoid_print
    print('🚀 [RunRemoteDataSource] recordCheckin RPC for $runId on $todayUtc...');
    final result = await _client.rpc('perform_checkin', params: {
      'p_run_id': runId,
      'p_day_utc': todayUtc,
    });
    final json = result as Map<String, dynamic>;
    final triggeredBets = (json['triggered_bets'] as List<dynamic>? ?? []);
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

  Future<void> settleRuns(String todayUtc) async {
    try {
      // ignore: avoid_print
      print('🚀 [RunRemoteDataSource] settle_runs RPC for $todayUtc...');
      await _client.rpc('settle_runs', params: {'today_utc': todayUtc});
    } catch (e) {
      // ignore: avoid_print
      print('⚠️ [RunRemoteDataSource] settle_runs error (non-fatal): $e');
    }
  }

  static String _todayUtc() {
    final now = DateTime.now().toUtc();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
