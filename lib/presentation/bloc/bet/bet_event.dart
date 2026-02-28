import 'package:equatable/equatable.dart';

abstract class BetEvent extends Equatable {
  const BetEvent();

  @override
  List<Object?> get props => [];
}

/// Load stakes and bets for [runId].
class BetSheetOpened extends BetEvent {
  final String runId;
  final int currentStreak;
  final bool isSelfBet;

  const BetSheetOpened({
    required this.runId,
    required this.currentStreak,
    required this.isSelfBet,
  });

  @override
  List<Object?> get props => [runId, currentStreak, isSelfBet];
}

/// User adjusted the target streak value by [delta] (+1, -1, +10, -10).
class BetTargetChanged extends BetEvent {
  final int delta;
  const BetTargetChanged(this.delta);

  @override
  List<Object?> get props => [delta];
}

/// User selected (or deselected) a stake.
class BetStakeSelected extends BetEvent {
  /// null = deselect current stake.
  final String? stakeId;
  const BetStakeSelected(this.stakeId);

  @override
  List<Object?> get props => [stakeId];
}

/// User tapped "Place bet".
class BetPlaceRequested extends BetEvent {
  const BetPlaceRequested();
}

/// User created a custom stake (premium feature) from the + chip.
class BetCustomStakeCreated extends BetEvent {
  final String title;
  const BetCustomStakeCreated(this.title);

  @override
  List<Object?> get props => [title];
}
