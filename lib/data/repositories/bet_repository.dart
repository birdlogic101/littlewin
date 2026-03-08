import '../../domain/entities/bet_entity.dart';
import '../../domain/entities/stake_entity.dart';
import '../../domain/entities/bet_resolution_entity.dart';
import '../datasources/bet_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:injectable/injectable.dart';

/// In-memory + remote repository for bet-related operations.
///
/// Stakes are cached after the first fetch to keep the modal snappy on
/// subsequent opens (they change rarely; TTL is managed externally or simply
/// re-fetched on each [StakesRequested] event for MLP simplicity).
///
/// Call [initialize] with a [BetRemoteDataSource] to enable persistence;
/// without it the repository uses only mock data (useful in tests).
@lazySingleton
class BetRepository {
  BetRepository({
    BetRemoteDataSource? datasource,
  })  : _datasource = datasource,
        _cachedStakes = null;

  final BetRemoteDataSource? _datasource;
  List<StakeEntity>? _cachedStakes;

  // ── Stakes ─────────────────────────────────────────────────────────────────

  /// Returns cached stakes if available, otherwise fetches from Supabase.
  /// Falls back to [_mockStakes] if the datasource is unavailable.
  Future<List<StakeEntity>> getStakes() async {
    if (_cachedStakes != null) return _cachedStakes!;
    if (_datasource != null) {
      try {
        _cachedStakes = await _datasource.fetchStakes();
        return _cachedStakes!;
      } catch (e) {
        // ignore: avoid_print
        print('[BetRepository] fetchStakes error (non-fatal): $e');
      }
    }
    // Fallback to mock when Supabase is unavailable
    _cachedStakes = _mockStakes();
    return _cachedStakes!;
  }

  // ── Bets per run ───────────────────────────────────────────────────────────

  /// Fetches all bets for [runId] from the server.
  /// Returns empty list if the datasource is unavailable.
  Future<List<BetEntity>> getBetsForRun(String runId) async {
    if (_datasource == null) return [];
    try {
      return await _datasource.fetchBetsForRun(runId);
    } catch (e) {
      // ignore: avoid_print
      print('[BetRepository] fetchBetsForRun error (non-fatal): $e');
      return [];
    }
  }

  // No longer needed as custom stakes are one-time and non-persistent.
  // Future<StakeEntity> createCustomStake({required String title}) async { ... }

  // ── Place bet ──────────────────────────────────────────────────────────────

  /// Places a bet via the server-side RPC.
  ///
  /// Throws a [BetValidationException] for known error codes so that callers
  /// can surface a clear message to the user.
  Future<BetEntity> placeBet({
    required String runId,
    required int targetStreak,
    String? stakeId,
    String? customStakeTitle,
    required bool isSelfBet,
  }) async {
    if (_datasource == null) {
      throw BetValidationException('BET_DATASOURCE_UNAVAILABLE');
    }
    try {
      return await _datasource.placeBet(
        runId: runId,
        targetStreak: targetStreak,
        stakeId: stakeId,
        customStakeTitle: customStakeTitle,
        isSelfBet: isSelfBet,
      );
    } on PostgrestException catch (e) {
      // The Supabase RPC raises exceptions whose message is the error code
      // string we defined (e.g. "STREAK_TOO_LOW"). Re-wrap for clarity.
      final code = _extractCode(e.message);
      if (code != 'UNKNOWN_ERROR') {
        throw BetValidationException(code);
      }
      rethrow;
    }
  }

  // ── Win celebrations ───────────────────────────────────────────────────────

  /// Fetches wins that haven't triggered a celebratory modal yet.
  Future<List<BetResolutionEntity>> getUnseenWonBets() async {
    if (_datasource == null) return [];
    try {
      return await _datasource.fetchUnseenWonBets();
    } catch (e) {
      // ignore: avoid_print
      print('[BetRepository] getUnseenWonBets error: $e');
      return [];
    }
  }

  /// Marks wins as celebrated.
  Future<void> acknowledgeWonBets(List<String> ids) async {
    if (_datasource == null) return;
    try {
      await _datasource.acknowledgeWonBets(ids);
    } catch (e) {
      // ignore: avoid_print
      print('[BetRepository] acknowledgeWonBets error: $e');
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static String _extractCode(String message) {
    const codes = [
      'STREAK_TOO_LOW',
      'STREAK_TOO_HIGH',
      'RUN_NOT_ACTIVE',
      'RUN_NOT_FOUND',
      'MAX_BETS_PER_RUN',
      'MAX_BETS_PER_DAY',
    ];
    for (final code in codes) {
      if (message.contains(code)) return code;
    }
    return 'UNKNOWN_ERROR';
  }

  // ── Mock data (used when Supabase is not wired) ────────────────────────────

  static List<StakeEntity> _mockStakes() => [
        // ── Plan stakes
        const StakeEntity(
          id: 'a0000000-0000-0000-0000-000000000001',
          title: 'Coffee Cup',
          category: StakeCategory.plan,
          imageAsset: 'assets/icons/stake-coffee_cup.png',
        ),
        const StakeEntity(
          id: 'a0000000-0000-0000-0000-000000000002',
          title: 'Brunch Invite',
          category: StakeCategory.plan,
          imageAsset: 'assets/icons/stake-brunch_invite.png',
        ),
        const StakeEntity(
          id: 'a0000000-0000-0000-0000-000000000003',
          title: 'Restaurant Dinner',
          category: StakeCategory.plan,
          imageAsset: 'assets/icons/stake-restaurant_dinner.png',
        ),
        const StakeEntity(
          id: 'a0000000-0000-0000-0000-000000000004',
          title: 'Drinks Round',
          category: StakeCategory.plan,
          imageAsset: 'assets/icons/stake-drinks_round.png',
        ),
        const StakeEntity(
          id: 'a0000000-0000-0000-0000-000000000005',
          title: 'Cinema Night',
          category: StakeCategory.plan,
          imageAsset: 'assets/icons/stake-cinema_night.png',
        ),
        // ── Gift stakes
        const StakeEntity(
          id: 'a0000000-0000-0000-0000-000000000006',
          title: 'Chocolate Box',
          category: StakeCategory.gift,
          imageAsset: 'assets/icons/stake-chocolate_box.png',
        ),
        const StakeEntity(
          id: 'a0000000-0000-0000-0000-000000000007',
          title: 'Wine Bottle',
          category: StakeCategory.gift,
          imageAsset: 'assets/icons/stake-wine_bottle.png',
        ),
        const StakeEntity(
          id: 'a0000000-0000-0000-0000-000000000008',
          title: 'Spa Access',
          category: StakeCategory.gift,
          imageAsset: 'assets/icons/stake-spa_access.png',
        ),
        const StakeEntity(
          id: 'a0000000-0000-0000-0000-000000000009',
          title: 'Massage Session',
          category: StakeCategory.gift,
          imageAsset: 'assets/icons/stake-massage_session.png',
        ),
        const StakeEntity(
          id: 'a0000000-0000-0000-0000-00000000000a',
          title: 'Surprise Box',
          category: StakeCategory.gift,
          imageAsset: 'assets/icons/stake-gift_box.png',
        ),
      ];
}

/// Thrown when the server rejects a bet placement with a known error code.
class BetValidationException implements Exception {
  final String code;
  const BetValidationException(this.code);

  String get userMessage => switch (code) {
        'STREAK_TOO_LOW' => 'Target streak must be higher than the current streak.',
        'STREAK_TOO_HIGH' => 'Target streak is too far ahead (max +90 days).',
        'RUN_NOT_ACTIVE' => 'This run is no longer active.',
        'RUN_NOT_FOUND' => 'Run not found.',
        'MAX_BETS_PER_RUN' => 'Maximum bets for this run reached.',
        'MAX_BETS_PER_DAY' => 'You have placed the maximum bets allowed today.',
        _ => 'Could not place bet. Please try again.',
      };
}
