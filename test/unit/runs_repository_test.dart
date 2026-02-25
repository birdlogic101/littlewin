import 'package:flutter_test/flutter_test.dart';
import 'package:littlewin/data/repositories/completed_runs_repository.dart';
import 'package:littlewin/data/repositories/runs_repository.dart';
import 'package:littlewin/domain/entities/active_run_entity.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Returns a UTC date string [n] days before [dateUtc] (yyyy-MM-dd).
String daysAgo(String todayUtc, int n) {
  final d = DateTime.parse('${todayUtc}T00:00:00Z').subtract(Duration(days: n));
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// Returns a UTC date string [n] days after [dateUtc] (yyyy-MM-dd).
String daysAhead(String todayUtc, int n) {
  final d = DateTime.parse('${todayUtc}T00:00:00Z').add(Duration(days: n));
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// Creates a minimal [ActiveRunEntity] for testing.
ActiveRunEntity makeRun({
  required String runId,
  required String startDate,
  String? lastCheckinDay,
  int currentStreak = 0,
  bool hasCheckedInToday = false,
}) {
  return ActiveRunEntity(
    runId: runId,
    challengeId: 'ch-test',
    challengeTitle: 'Test Challenge',
    challengeSlug: 'test-challenge',
    currentStreak: currentStreak,
    startDate: startDate,
    hasCheckedInToday: hasCheckedInToday,
    lastCheckinDay: lastCheckinDay,
  );
}

void main() {
  // Fixed UTC reference date used throughout the tests.
  const today = '2026-03-01';

  group('RunsRepository.dayBefore', () {
    test('returns the previous UTC day', () {
      expect(RunsRepository.dayBefore('2026-03-01'), '2026-02-28');
    });

    test('handles month boundary', () {
      expect(RunsRepository.dayBefore('2026-03-01'), '2026-02-28');
    });

    test('handles leap year', () {
      expect(RunsRepository.dayBefore('2024-03-01'), '2024-02-29');
    });
  });

  // ── processCompletions ─────────────────────────────────────────────────────

  group('RunsRepository.processCompletions', () {
    late CompletedRunsRepository completedRepo;

    setUp(() {
      completedRepo = CompletedRunsRepository(initial: []);
    });

    // ── Day-1 rule ─────────────────────────────────────────────────────────

    test('Day-1 rule: run started today with no check-in survives', () {
      final repo = RunsRepository(initial: [
        makeRun(runId: 'r1', startDate: today, lastCheckinDay: null),
      ]);

      repo.processCompletions(today, completedRepo);

      expect(repo.activeRuns.length, 1,
          reason: 'Run started today must never be missed on day 1');
      expect(completedRepo.allRuns, isEmpty);
    });

    test('Day-1 rule: hasCheckedInToday is reset to false', () {
      final repo = RunsRepository(initial: [
        makeRun(
          runId: 'r1',
          startDate: today,
          lastCheckinDay: today,
          hasCheckedInToday: true,
          currentStreak: 1,
        ),
      ]);

      repo.processCompletions(today, completedRepo);

      expect(repo.activeRuns.first.hasCheckedInToday, isFalse);
    });

    // ── Survival rule ──────────────────────────────────────────────────────

    test('Survival: run with lastCheckinDay == yesterday survives', () {
      final yesterday = daysAgo(today, 1);
      final repo = RunsRepository(initial: [
        makeRun(
          runId: 'r1',
          startDate: daysAgo(today, 5),
          lastCheckinDay: yesterday,
          currentStreak: 5,
        ),
      ]);

      repo.processCompletions(today, completedRepo);

      expect(repo.activeRuns.length, 1,
          reason: 'Run with yesterday check-in must survive');
      expect(completedRepo.allRuns, isEmpty);
    });

    test('Survival: hasCheckedInToday is reset to false for surviving run', () {
      final yesterday = daysAgo(today, 1);
      final repo = RunsRepository(initial: [
        makeRun(
          runId: 'r1',
          startDate: daysAgo(today, 5),
          lastCheckinDay: yesterday,
          hasCheckedInToday: true,
          currentStreak: 5,
        ),
      ]);

      repo.processCompletions(today, completedRepo);

      expect(repo.activeRuns.first.hasCheckedInToday, isFalse);
    });

    // ── Missed: never checked in ───────────────────────────────────────────

    test(
        'Missed: run started yesterday with no check-in → completed with score 0',
        () {
      final yesterday = daysAgo(today, 1);
      final repo = RunsRepository(initial: [
        makeRun(
          runId: 'r1',
          startDate: yesterday,
          lastCheckinDay: null, // never checked in
          currentStreak: 0,
        ),
      ]);

      repo.processCompletions(today, completedRepo);

      expect(repo.activeRuns, isEmpty,
          reason: 'Missed run must be removed from active list');
      expect(completedRepo.allRuns.length, 1);
      expect(completedRepo.allRuns.first.finalScore, 0,
          reason: 'Score must be 0 for a never-checked-in run');
      expect(completedRepo.allRuns.first.endDate, yesterday);
    });

    // ── Missed: multi-day gap ──────────────────────────────────────────────

    test('Missed: lastCheckinDay 2 days ago → completed (multi-day gap)', () {
      final twoDaysAgo = daysAgo(today, 2);
      final yesterday = daysAgo(today, 1);
      final repo = RunsRepository(initial: [
        makeRun(
          runId: 'r1',
          startDate: daysAgo(today, 10),
          lastCheckinDay: twoDaysAgo,
          currentStreak: 7,
        ),
      ]);

      repo.processCompletions(today, completedRepo);

      expect(repo.activeRuns, isEmpty);
      expect(completedRepo.allRuns.first.finalScore, 7);
      expect(completedRepo.allRuns.first.endDate, yesterday,
          reason: 'endDate should be the last day that should have had a check-in');
    });

    // ── Timezone travel: checked in yesterday in a different timezone ───────

    test(
        'Timezone travel: user checked in yesterday (UTC) regardless of local TZ → survives',
        () {
      // Simulates a user who was in UTC+9 (Tokyo) yesterday but is now in
      // UTC-5 (NYC). The canonical check-in day is always UTC, so as long as
      // lastCheckinDay == yesterday UTC, the run survives.
      final yesterday = daysAgo(today, 1);
      final repo = RunsRepository(initial: [
        makeRun(
          runId: 'r1',
          startDate: daysAgo(today, 30),
          lastCheckinDay: yesterday, // checked in on UTC yesterday
          currentStreak: 30,
        ),
      ]);

      repo.processCompletions(today, completedRepo);

      expect(repo.activeRuns.length, 1,
          reason: 'Timezone travel must not break the streak');
      expect(completedRepo.allRuns, isEmpty);
    });

    // ── Idempotency ────────────────────────────────────────────────────────

    test('Idempotency: calling processCompletions twice has the same result', () {
      final yesterday = daysAgo(today, 1);
      final repo = RunsRepository(initial: [
        // Run that will be completed (never checked in)
        makeRun(runId: 'r1', startDate: yesterday, lastCheckinDay: null),
        // Run that will survive
        makeRun(runId: 'r2', startDate: daysAgo(today, 5), lastCheckinDay: yesterday),
      ]);

      repo.processCompletions(today, completedRepo);
      // Call again — should be a no-op (r1 is already gone, r2 still alive)
      repo.processCompletions(today, completedRepo);

      expect(repo.activeRuns.length, 1);
      expect(repo.activeRuns.first.runId, 'r2');
      // CompletedRunsRepository deduplicates by runId, so still only 1
      expect(completedRepo.allRuns.length, 1);
    });

    // ── Multiple runs in one pass ─────────────────────────────────────────

    test('Multiple runs: correctly partitions survivors and completed', () {
      final yesterday = daysAgo(today, 1);
      final repo = RunsRepository(initial: [
        makeRun(
            runId: 'alive-1',
            startDate: daysAgo(today, 3),
            lastCheckinDay: yesterday,
            currentStreak: 3),
        makeRun(
            runId: 'alive-2',
            startDate: today), // day-1 rule
        makeRun(
            runId: 'dead-1',
            startDate: daysAgo(today, 1),
            lastCheckinDay: null), // never checked in
        makeRun(
            runId: 'dead-2',
            startDate: daysAgo(today, 5),
            lastCheckinDay: daysAgo(today, 3),
            currentStreak: 2), // 2-day gap
      ]);

      repo.processCompletions(today, completedRepo);

      final activeIds = repo.activeRuns.map((r) => r.runId).toSet();
      final completedIds = completedRepo.allRuns.map((r) => r.runId).toSet();

      expect(activeIds, {'alive-1', 'alive-2'},
          reason: 'Only yesterday-checked and day-1 runs should survive');
      expect(completedIds, containsAll(['completed-dead-1-$yesterday', 'completed-dead-2-$yesterday']),
          reason: 'Both missed runs must be completed');
    });
  });

  // ── clearStaleCheckinFlags ─────────────────────────────────────────────────

  group('RunsRepository.clearStaleCheckinFlags', () {
    test('resets hasCheckedInToday when lastCheckinDay != today', () {
      final yesterday = daysAgo(today, 1);
      final repo = RunsRepository(initial: [
        makeRun(
          runId: 'r1',
          startDate: daysAgo(today, 5),
          lastCheckinDay: yesterday, // checked in yesterday
          hasCheckedInToday: true, // stale flag from yesterday
          currentStreak: 5,
        ),
      ]);

      repo.clearStaleCheckinFlags(today);

      expect(repo.activeRuns.first.hasCheckedInToday, isFalse,
          reason: 'Stale check-in flag must be cleared for new UTC day');
    });

    test('does not reset hasCheckedInToday when lastCheckinDay == today', () {
      final repo = RunsRepository(initial: [
        makeRun(
          runId: 'r1',
          startDate: daysAgo(today, 5),
          lastCheckinDay: today,
          hasCheckedInToday: true,
          currentStreak: 5,
        ),
      ]);

      repo.clearStaleCheckinFlags(today);

      expect(repo.activeRuns.first.hasCheckedInToday, isTrue,
          reason: 'Today\'s check-in flag must not be cleared');
    });
  });
}
