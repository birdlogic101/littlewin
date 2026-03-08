import 'package:flutter_bloc/flutter_bloc.dart';
import 'bet_event.dart';
import 'bet_state.dart';
import '../../../data/repositories/bet_repository.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/di/injection.dart';
import '../../../domain/entities/stake_entity.dart';
import '../../../domain/entities/bet_entity.dart';

/// Scoped BLoC for the unified RunBetsSheet flow.
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
    on<BetPlaceWithCustomStakeRequested>(_onPlaceWithCustomStakeRequested);
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

      final stakes = results[0] as List<StakeEntity>;
      final bets = results[1] as List<BetEntity>;

      // Dynamic preselection logic:
      // - Self-bet: Find "Spa Access" (Gift)
      // - Other: Find "Brunch Invite" (Plan)
      String? preselectedStakeId;
      try {
        final targetTitle = event.isSelfBet ? 'Spa Access' : 'Brunch Invite';
        final stake = stakes.firstWhere(
          (s) => s.title.toLowerCase() == targetTitle.toLowerCase(),
        );
        preselectedStakeId = stake.id;
      } catch (_) {
        // Fallback: no preselection if titles don't match
      }

      emit(BetReady(
        existingBets: List.unmodifiable(bets),
        stakes: List.unmodifiable(stakes),
        selectedStakeId: preselectedStakeId,
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
      customStakeTitle: null, // Selecting a predefined stake clears any custom title.
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
        customStakeTitle: current.customStakeTitle,
        isSelfBet: current.isSelfBet,
      );

      // Optimistically prepend the new bet to the existing list.
      final updatedBets = [newBet, ...current.existingBets];
      emit(current.copyWith(
        existingBets: updatedBets,
        submitStatus: BetSubmitStatus.success,
        errorMessage: null,
      ));

      // Contextual permission request: Ask if they want to be notified of the outcome!
      getIt<NotificationService>().requestPermissions();
    } on BetValidationException catch (e) {
      emit(current.copyWith(
        submitStatus: BetSubmitStatus.error,
        errorMessage: e.userMessage,
      ));
    } catch (e) {
      // ignore: avoid_print
      print('[BetBloc] placeBet error: $e');
      emit(current.copyWith(
        submitStatus: BetSubmitStatus.error,
        errorMessage: 'Could not place bet. Please try again.',
      ));
    }
  }

  Future<void> _onPlaceWithCustomStakeRequested(
    BetPlaceWithCustomStakeRequested event,
    Emitter<BetState> emit,
  ) async {
    final current = state;
    if (current is! BetReady) return;

    // 1. Update state with the title and set status to submitting.
    // Also clear selectedStakeId.
    emit(current.copyWith(
      customStakeTitle: event.title,
      selectedStakeId: null,
      submitStatus: BetSubmitStatus.submitting,
    ));

    // 2. Perform same logic as _onPlaceRequested.
    try {
      final newBet = await _repository.placeBet(
        runId: current.runId,
        targetStreak: current.targetStreak,
        stakeId: null, // Clear for custom
        customStakeTitle: event.title,
        isSelfBet: current.isSelfBet,
      );

      final updatedBets = [newBet, ...current.existingBets];
      emit(current.copyWith(
        existingBets: updatedBets,
        submitStatus: BetSubmitStatus.success,
        errorMessage: null,
      ));

      getIt<NotificationService>().requestPermissions();
    } on BetValidationException catch (e) {
      emit(current.copyWith(
        submitStatus: BetSubmitStatus.error,
        errorMessage: e.userMessage,
      ));
    } catch (e) {
      print('[BetBloc] placeWithCustomStake error: $e');
      emit(current.copyWith(
        submitStatus: BetSubmitStatus.error,
        errorMessage: 'Could not place bet. Please try again.',
      ));
    }
  }
}
