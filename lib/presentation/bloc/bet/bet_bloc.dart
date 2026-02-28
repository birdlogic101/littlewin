import 'package:flutter_bloc/flutter_bloc.dart';
import 'bet_event.dart';
import 'bet_state.dart';
import '../../../data/repositories/bet_repository.dart';

/// Scoped BLoC for the RunBetsSheet + PlaceBetModal flow.
///
/// Created inside the bottom sheet widget tree — no global lifetime needed.
class BetBloc extends Bloc<BetEvent, BetState> {
  final BetRepository _repository;

  BetBloc({required BetRepository repository})
      : _repository = repository,
        super(const BetInitial()) {
    on<BetSheetOpened>(_onSheetOpened);
    on<BetTargetChanged>(_onTargetChanged);
    on<BetStakeSelected>(_onStakeSelected);
    on<BetPlaceRequested>(_onPlaceRequested);
    on<BetCustomStakeCreated>(_onCustomStakeCreated);
  }

  // ── Handlers ───────────────────────────────────────────────────────────────

  Future<void> _onSheetOpened(
    BetSheetOpened event,
    Emitter<BetState> emit,
  ) async {
    emit(const BetLoading());
    try {
      // Load stakes and existing bets in parallel.
      final results = await Future.wait([
        _repository.getStakes(),
        _repository.getBetsForRun(event.runId),
      ]);

      final stakes = results[0] as List;
      final bets = results[1] as List;

      emit(BetReady(
        existingBets: List.unmodifiable(bets),
        stakes: List.unmodifiable(stakes),
        targetStreak: event.currentStreak + 7,
        currentStreak: event.currentStreak,
        isSelfBet: event.isSelfBet,
        runId: event.runId,
      ));
    } catch (e) {
      // Rare: if both fetch calls fail we still show an error.
      emit(BetReady(
        existingBets: const [],
        stakes: const [],
        targetStreak: event.currentStreak + 7,
        currentStreak: event.currentStreak,
        isSelfBet: event.isSelfBet,
        runId: event.runId,
        submitStatus: BetSubmitStatus.error,
        errorMessage: 'Could not load bets. Please check your connection.',
      ));
    }
  }

  void _onTargetChanged(
    BetTargetChanged event,
    Emitter<BetState> emit,
  ) {
    final current = state;
    if (current is! BetReady) return;

    final newTarget = (current.targetStreak + event.delta)
        .clamp(current.currentStreak + 1, current.maxStreak);

    emit(current.copyWith(
      targetStreak: newTarget,
      submitStatus: BetSubmitStatus.idle,
      errorMessage: null,
    ));
  }

  void _onStakeSelected(
    BetStakeSelected event,
    Emitter<BetState> emit,
  ) {
    final current = state;
    if (current is! BetReady) return;

    // Tapping the already-selected stake deselects it.
    final newId = event.stakeId == current.selectedStakeId
        ? null
        : event.stakeId;

    emit(current.copyWith(
      selectedStakeId: newId,
      submitStatus: BetSubmitStatus.idle,
      errorMessage: null,
    ));
  }

  Future<void> _onPlaceRequested(
    BetPlaceRequested event,
    Emitter<BetState> emit,
  ) async {
    final current = state;
    if (current is! BetReady || !current.canPlace) return;

    emit(current.copyWith(submitStatus: BetSubmitStatus.submitting));
    try {
      final newBet = await _repository.placeBet(
        runId: current.runId,
        targetStreak: current.targetStreak,
        stakeId: current.selectedStakeId,
        isSelfBet: current.isSelfBet,
      );

      // Optimistically prepend the new bet to the existing list.
      final updatedBets = [newBet, ...current.existingBets];
      emit(current.copyWith(
        existingBets: updatedBets,
        submitStatus: BetSubmitStatus.success,
        errorMessage: null,
      ));
    } on BetValidationException catch (e) {
      emit(current.copyWith(
        submitStatus: BetSubmitStatus.error,
        errorMessage: e.userMessage,
      ));
    } catch (e) {
      emit(current.copyWith(
        submitStatus: BetSubmitStatus.error,
        errorMessage: 'Could not place bet. Please try again.',
      ));
    }
  }

  Future<void> _onCustomStakeCreated(
    BetCustomStakeCreated event,
    Emitter<BetState> emit,
  ) async {
    final current = state;
    if (current is! BetReady) return;

    // ── Deduplication: check in-memory cache first (zero Supabase calls)
    final normalised = event.title.trim().toLowerCase();
    final existing = current.stakes
        .where((s) => s.title.toLowerCase() == normalised)
        .firstOrNull;

    if (existing != null) {
      // Already exists — just select it, no network call needed.
      emit(current.copyWith(
        selectedStakeId: existing.id,
        submitStatus: BetSubmitStatus.idle,
        errorMessage: null,
      ));
      return;
    }

    // ── New stake: persist to Supabase
    try {
      final stake = await _repository.createCustomStake(title: event.title);
      final updatedStakes = [...current.stakes, stake];
      emit(current.copyWith(
        stakes: updatedStakes,
        selectedStakeId: stake.id, // auto-select the new stake
        submitStatus: BetSubmitStatus.idle,
        errorMessage: null,
      ));
    } catch (e) {
      emit(current.copyWith(
        submitStatus: BetSubmitStatus.error,
        errorMessage: 'Could not create stake. Please try again.',
      ));
    }
  }
}
