import 'package:equatable/equatable.dart';

/// The status of a bet.
enum BetStatus { pending, won, lost }

/// A single bet placed on a run.
class BetEntity extends Equatable {
  final String id;
  final String runId;
  final String bettorId;

  /// Display name of the bettor (joined from `users.username`).
  final String? bettorUsername;

  /// Target streak the bettor is betting the run will reach.
  final int targetStreak;

  /// Optional stake; null means "no stake selected".
  final String? stakeId;

  /// Title of the stake (joined from `stakes.title`), if any.
  final String? stakeTitle;

  final BetStatus status;
  final bool isSelfBet;
  final DateTime createdAt;

  const BetEntity({
    required this.id,
    required this.runId,
    required this.bettorId,
    this.bettorUsername,
    required this.targetStreak,
    this.stakeId,
    this.stakeTitle,
    required this.status,
    required this.isSelfBet,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        runId,
        bettorId,
        bettorUsername,
        targetStreak,
        stakeId,
        stakeTitle,
        status,
        isSelfBet,
        createdAt,
      ];
}
