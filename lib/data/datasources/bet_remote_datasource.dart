import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/bet_entity.dart';
import '../../domain/entities/stake_entity.dart';
import '../models/bet_model.dart';

/// Remote data source for bet and stake Supabase operations.
///
/// Throws [PostgrestException] on server errors — callers are responsible
/// for catching and converting to domain failures.
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
    required bool isSelfBet,
  }) async {
    final result = await _client.rpc('place_bet', params: {
      'p_run_id': runId,
      'p_target_streak': targetStreak,
      if (stakeId != null) 'p_stake_id': stakeId,
      'p_is_self_bet': isSelfBet,
    });

    // RPC returns a single row as a Map
    final row = result as Map<String, dynamic>;
    return BetModel.fromJson(row);
  }

  /// Inserts a new custom stake for the current user (category = 'gift').
  ///
  /// Returns the newly created [StakeEntity].
  Future<StakeEntity> createStake({required String title}) async {
    final rows = await _client
        .from('stakes')
        .insert({
          'title': title.trim(),
          'category': 'gift',
          'created_by': _client.auth.currentUser?.id,
        })
        .select('id, title, category, emoji')
        .single();

    return BetModel.stakeFromJson(rows);
  }
}
