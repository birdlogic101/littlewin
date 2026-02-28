import 'package:equatable/equatable.dart';
import 'stake_entity.dart';

/// Represents one won bet entry shown in the BetWonModal rewards list.
class WonBetEntry extends Equatable {
  final String betId;
  final String bettorId;

  /// Display name of the bettor. Falls back to 'Someone' if null.
  final String? bettorUsername;

  /// Remote avatar URL for the bettor. If null, show initials fallback.
  final String? bettorAvatarUrl;

  final String? stakeTitle;
  final StakeCategory? stakeCategory;
  final String? stakeEmoji;

  /// True when the bettor is the runner themselves (self-bet).
  final bool isSelfBet;

  const WonBetEntry({
    required this.betId,
    required this.bettorId,
    this.bettorUsername,
    this.bettorAvatarUrl,
    this.stakeTitle,
    this.stakeCategory,
    this.stakeEmoji,
    required this.isSelfBet,
  });

  @override
  List<Object?> get props => [
        betId,
        bettorId,
        bettorUsername,
        bettorAvatarUrl,
        stakeTitle,
        stakeCategory,
        stakeEmoji,
        isSelfBet,
      ];
}

/// Returned by [RunsRepository.checkin] when the new streak triggers one or
/// more bets. Used to drive the [BetWonModal].
class BetResolutionEntity extends Equatable {
  final String runId;
  final String challengeTitle;

  /// The streak value that was just reached.
  final int newStreak;

  /// All bets whose [WonBetEntry.targetStreak] == [newStreak].
  final List<WonBetEntry> wonBets;

  const BetResolutionEntity({
    required this.runId,
    required this.challengeTitle,
    required this.newStreak,
    required this.wonBets,
  });

  bool get hasRewards => wonBets.any((b) => b.stakeTitle != null);

  @override
  List<Object?> get props => [runId, challengeTitle, newStreak, wonBets];
}
