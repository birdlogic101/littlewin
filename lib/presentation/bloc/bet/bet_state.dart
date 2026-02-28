import 'package:equatable/equatable.dart';
import '../../../domain/entities/bet_entity.dart';
import '../../../domain/entities/stake_entity.dart';

/// Submission status sub-enum used inside [BetReady].
enum BetSubmitStatus { idle, submitting, success, error }

sealed class BetState extends Equatable {
  const BetState();

  @override
  List<Object?> get props => [];
}

/// Before any data has been loaded.
class BetInitial extends BetState {
  const BetInitial();
}

/// Loading stakes and existing bets for the run.
class BetLoading extends BetState {
  const BetLoading();
}

/// Data loaded; user is interacting with the sheet or modal.
class BetReady extends BetState {
  /// Existing bets on the run (populated when the sheet opens).
  final List<BetEntity> existingBets;

  /// All available stakes.
  final List<StakeEntity> stakes;

  /// Currently selected stake id; null means no stake.
  final String? selectedStakeId;

  /// The selected target streak value.
  final int targetStreak;

  /// The run's current streak (lower bound for target = currentStreak + 1).
  final int currentStreak;

  /// Upper bound for target streak — hard cap at 999.
  int get maxStreak => 999;

  final bool isSelfBet;
  final String runId;

  final BetSubmitStatus submitStatus;

  /// Set when [submitStatus] == [BetSubmitStatus.error].
  final String? errorMessage;

  const BetReady({
    required this.existingBets,
    required this.stakes,
    this.selectedStakeId,
    required this.targetStreak,
    required this.currentStreak,
    required this.isSelfBet,
    required this.runId,
    this.submitStatus = BetSubmitStatus.idle,
    this.errorMessage,
  });

  bool get canPlace =>
      targetStreak > currentStreak &&
      targetStreak <= maxStreak &&
      submitStatus != BetSubmitStatus.submitting;

  BetReady copyWith({
    List<BetEntity>? existingBets,
    List<StakeEntity>? stakes,
    Object? selectedStakeId = _sentinel,
    int? targetStreak,
    BetSubmitStatus? submitStatus,
    Object? errorMessage = _sentinel,
  }) {
    return BetReady(
      existingBets: existingBets ?? this.existingBets,
      stakes: stakes ?? this.stakes,
      selectedStakeId: identical(selectedStakeId, _sentinel)
          ? this.selectedStakeId
          : selectedStakeId as String?,
      targetStreak: targetStreak ?? this.targetStreak,
      currentStreak: currentStreak,
      isSelfBet: isSelfBet,
      runId: runId,
      submitStatus: submitStatus ?? this.submitStatus,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  static const Object _sentinel = Object();

  @override
  List<Object?> get props => [
        existingBets,
        stakes,
        selectedStakeId,
        targetStreak,
        currentStreak,
        isSelfBet,
        runId,
        submitStatus,
        errorMessage,
      ];
}
