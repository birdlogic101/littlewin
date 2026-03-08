import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/bet_entity.dart';
import '../../domain/entities/stake_entity.dart';
import '../models/bet_model.dart';
import '../../domain/entities/bet_resolution_entity.dart';

import 'package:injectable/injectable.dart';

/// Remote data source for bet and stake Supabase operations.
///
/// Throws [PostgrestException] on server errors — callers are responsible
/// for catching and converting to domain failures.
@lazySingleton
class BetRemoteDataSource {
  final SupabaseClient _client;

  BetRemoteDataSource(this._client);

  // ── Reads ──────────────────────────────────────────────────────────────────

  /// Fetches all available stakes ordered by category then title.
  Future<List<StakeEntity>> fetchStakes() async {
    final rows = await _client
        .from('stakes')
        .select('id, title, category, emoji')
        .order('category')
        .order('title');

    return rows.map<StakeEntity>(BetModel.stakeFromJson).toList();
  }

  /// Fetches all pending bets on [runId], joined with bettor username and
  /// stake title for display.
  Future<List<BetEntity>> fetchBetsForRun(String runId) async {
    final rows = await _client
        .from('bets')
        .select('''
          id,
          run_id,
          bettor_id,
          target_streak,
          stake_id,
          status,
          is_self_bet,
          created_at,
          custom_stake_title,
          users!bettor_id(username),
          stakes(title)
        ''')
        .eq('run_id', runId)
        .order('created_at', ascending: false);

    return rows.map<BetEntity>(BetModel.fromJson).toList();
  }

  // ── Writes ─────────────────────────────────────────────────────────────────

  /// Calls the `place_bet` server-side RPC.
  ///
  /// Server validates all business rules (streak window, run status, limits).
  /// Throws a [PostgrestException] whose `message` is the error code string
  /// (e.g. `STREAK_TOO_LOW`) on validation failure.
  Future<BetEntity> placeBet({
    required String runId,
    required int targetStreak,
    String? stakeId,
    String? customStakeTitle,
    required bool isSelfBet,
  }) async {
    final result = await _client.rpc('place_bet', params: {
      'p_run_id': runId,
      'p_target_streak': targetStreak,
      if (stakeId != null) 'p_stake_id': stakeId,
      'p_is_self_bet': isSelfBet,
      if (customStakeTitle != null) 'p_custom_stake_title': customStakeTitle,
    });

    // RPC returns a single row as a Map
    final row = result as Map<String, dynamic>;
    return BetModel.fromJson(row);
  }

  /// Inserts a new custom stake for the current user (category = 'custom' via RPC).
  ///
  /// Returns the newly created [StakeEntity].
  Future<StakeEntity> createStake({required String title}) async {
    final result = await _client.rpc('create_custom_stake', params: {
      'p_title': title.trim(),
    });

    return BetModel.stakeFromJson(result as Map<String, dynamic>);
  }

  /// Fetches bets won by the current user that haven't been celebrated in-app yet.
  Future<List<BetResolutionEntity>> fetchUnseenWonBets() async {
    final result = await _client.rpc('get_unseen_won_bets');
    if (result == null) return [];

    final list = result as List<dynamic>;
    // Group by run_id to avoid multiple modals for the same run
    final Map<String, List<WonBetEntry>> grouped = {};
    final Map<String, String> challengeTitles = {};
    final Map<String, int> targetStreaks = {};

    for (final b in list) {
      final runId = b['run_id'] as String;
      challengeTitles[runId] = b['challenge_title'] as String;
      targetStreaks[runId] = b['target_streak'] as int;

      final catStr = b['stake_category'] as String? ?? 'plan';
      final category = switch (catStr) {
        'gift' => StakeCategory.gift,
        'custom' => StakeCategory.custom,
        _ => StakeCategory.plan,
      };

      grouped.putIfAbsent(runId, () => []).add(WonBetEntry(
            betId: b['bet_id'] as String,
            bettorId: _client.auth.currentUser!.id,
            bettorUsername: b['runner_username'] as String?,
            bettorAvatarId: b['runner_avatar_id'] as int?,
            stakeTitle: b['stake_title'] as String?,
            stakeCategory: category,
            isSelfBet: false,
          ));
    }

    return grouped.entries.map((e) {
      return BetResolutionEntity(
        runId: e.key,
        challengeTitle: challengeTitles[e.key]!,
        newStreak: targetStreaks[e.key]!,
        wonBets: e.value,
      );
    }).toList();
  }

  /// Marks a list of bets as "notified in app" so they don't celebrate again.
  Future<void> acknowledgeWonBets(List<String> ids) async {
    await _client.rpc('acknowledge_won_bets', params: {'p_bet_ids': ids});
  }
}
