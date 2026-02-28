import 'package:flutter_test/flutter_test.dart';
import 'package:littlewin/domain/entities/bet_entity.dart';
import 'package:littlewin/domain/entities/stake_entity.dart';
import 'package:littlewin/data/repositories/bet_repository.dart';
import 'package:littlewin/presentation/bloc/bet/bet_bloc.dart';
import 'package:littlewin/presentation/bloc/bet/bet_event.dart';
import 'package:littlewin/presentation/bloc/bet/bet_state.dart';

// ── Mock repository ────────────────────────────────────────────────────────────

class _MockBetRepository extends BetRepository {
  final List<StakeEntity> mockStakes;
  final List<BetEntity> mockBets;
  final BetEntity? mockPlacedBet;
  final Exception? placeBetError;

  _MockBetRepository({
    required this.mockStakes,
    required this.mockBets,
    this.mockPlacedBet,
    this.placeBetError,
  });

  @override
  Future<List<StakeEntity>> getStakes() async => mockStakes;

  @override
  Future<List<BetEntity>> getBetsForRun(String runId) async => mockBets;

  @override
  Future<BetEntity> placeBet({
    required String runId,
    required int targetStreak,
    String? stakeId,
    required bool isSelfBet,
  }) async {
    if (placeBetError != null) throw placeBetError!;
    return mockPlacedBet ?? _makeBet(targetStreak: targetStreak);
  }
}

// ── Fixtures ──────────────────────────────────────────────────────────────────

const _runId = 'run-1';
const _currentStreak = 15;

List<StakeEntity> _stakes() => [
      const StakeEntity(id: 's1', title: 'Coffee', category: StakeCategory.plan),
      const StakeEntity(id: 's2', title: 'Brunch', category: StakeCategory.plan),
    ];

BetEntity _makeBet({int targetStreak = 20}) => BetEntity(
      id: 'bet-1',
      runId: _runId,
      bettorId: 'u1',
      targetStreak: targetStreak,
      status: BetStatus.pending,
      isSelfBet: false,
      createdAt: DateTime(2026),
    );

_MockBetRepository _repo({
  List<StakeEntity>? stakes,
  List<BetEntity>? bets,
  BetEntity? placedBet,
  Exception? placeBetError,
}) =>
    _MockBetRepository(
      mockStakes: stakes ?? _stakes(),
      mockBets: bets ?? [],
      mockPlacedBet: placedBet,
      placeBetError: placeBetError,
    );

/// Opens the sheet and waits for the initial ready state.
Future<BetBloc> _openedBloc({_MockBetRepository? repository}) async {
  final bloc = BetBloc(repository: repository ?? _repo());
  bloc.add(const BetSheetOpened(
    runId: _runId,
    currentStreak: _currentStreak,
    isSelfBet: false,
  ));
  // Drain events
  await Future.delayed(Duration.zero);
  return bloc;
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('BetBloc — BetSheetOpened', () {
    test('emits BetLoading then BetReady with stakes + empty bets', () async {
      final bloc = BetBloc(repository: _repo());
      final states = <BetState>[];
      bloc.stream.listen(states.add);

      bloc.add(const BetSheetOpened(
        runId: _runId,
        currentStreak: _currentStreak,
        isSelfBet: false,
      ));
      await Future.delayed(Duration.zero);

      expect(states[0], isA<BetLoading>());
      final ready = states[1] as BetReady;
      expect(ready.stakes.length, 2);
      expect(ready.existingBets, isEmpty);
      expect(ready.targetStreak, _currentStreak + 1);
      expect(ready.maxStreak, _currentStreak + 90);
    });

    test('populates existingBets when run has bets', () async {
      final bloc = await _openedBloc(
        repository: _repo(bets: [_makeBet()]),
      );
      final ready = bloc.state as BetReady;
      expect(ready.existingBets.length, 1);
    });
  });

  group('BetBloc — BetTargetChanged', () {
    test('increments streak by 1', () async {
      final bloc = await _openedBloc();
      bloc.add(const BetTargetChanged(1));
      await Future.delayed(Duration.zero);
      expect((bloc.state as BetReady).targetStreak, _currentStreak + 2);
    });

    test('clamps to min (currentStreak + 1)', () async {
      final bloc = await _openedBloc();
      bloc.add(const BetTargetChanged(-1000));
      await Future.delayed(Duration.zero);
      expect((bloc.state as BetReady).targetStreak, _currentStreak + 1);
    });

    test('clamps to max (currentStreak + 90)', () async {
      final bloc = await _openedBloc();
      bloc.add(const BetTargetChanged(1000));
      await Future.delayed(Duration.zero);
      expect((bloc.state as BetReady).targetStreak, _currentStreak + 90);
    });

    test('decrements by 10 correctly', () async {
      final bloc = await _openedBloc();
      bloc.add(const BetTargetChanged(20)); // set to +21
      await Future.delayed(Duration.zero);
      bloc.add(const BetTargetChanged(-10));
      await Future.delayed(Duration.zero);
      expect((bloc.state as BetReady).targetStreak, _currentStreak + 11);
    });
  });

  group('BetBloc — BetStakeSelected', () {
    test('selects a stake', () async {
      final bloc = await _openedBloc();
      bloc.add(const BetStakeSelected('s1'));
      await Future.delayed(Duration.zero);
      expect((bloc.state as BetReady).selectedStakeId, 's1');
    });

    test('tapping same stake deselects it', () async {
      final bloc = await _openedBloc();
      bloc.add(const BetStakeSelected('s1'));
      await Future.delayed(Duration.zero);
      bloc.add(const BetStakeSelected('s1'));
      await Future.delayed(Duration.zero);
      expect((bloc.state as BetReady).selectedStakeId, isNull);
    });

    test('switches selection to a different stake', () async {
      final bloc = await _openedBloc();
      bloc.add(const BetStakeSelected('s1'));
      await Future.delayed(Duration.zero);
      bloc.add(const BetStakeSelected('s2'));
      await Future.delayed(Duration.zero);
      expect((bloc.state as BetReady).selectedStakeId, 's2');
    });
  });

  group('BetBloc — BetPlaceRequested', () {
    test('success: emits submitting then success with new bet prepended',
        () async {
      final placed = _makeBet(targetStreak: 16);
      final bloc = await _openedBloc(
          repository: _repo(bets: [], placedBet: placed));
      final states = <BetState>[];
      bloc.stream.listen(states.add);

      bloc.add(const BetPlaceRequested());
      await Future.delayed(Duration.zero);

      final submitting = states[0] as BetReady;
      expect(submitting.submitStatus, BetSubmitStatus.submitting);

      final success = states[1] as BetReady;
      expect(success.submitStatus, BetSubmitStatus.success);
      expect(success.existingBets.length, 1);
      expect(success.existingBets.first.id, 'bet-1');
    });

    test('validation error: emits error with user message', () async {
      final bloc = await _openedBloc(
        repository: _repo(
          placeBetError: const BetValidationException('STREAK_TOO_LOW'),
        ),
      );
      final states = <BetState>[];
      bloc.stream.listen(states.add);

      bloc.add(const BetPlaceRequested());
      await Future.delayed(Duration.zero);

      final error = states.last as BetReady;
      expect(error.submitStatus, BetSubmitStatus.error);
      expect(error.errorMessage, isNotNull);
      expect(error.errorMessage, contains('streak'));
    });

    test('canPlace is true at min valid streak', () async {
      final bloc = await _openedBloc();
      final ready = bloc.state as BetReady;
      // targetStreak starts at currentStreak + 1 → canPlace = true
      expect(ready.canPlace, isTrue);
      expect(ready.targetStreak, _currentStreak + 1);
    });
  });
}
