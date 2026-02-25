import 'dart:async';
import '../../domain/entities/completed_run_entity.dart';
import '../datasources/run_remote_datasource.dart';

/// Shared in-memory store for the user's completed runs.
///
/// Seeded with historical mock records on first run. On startup, call
/// [initialize] to replace/add real records from Supabase.
/// [RunsRepository.processCompletions] feeds new completions into it
/// as the user misses check-in deadlines.
class CompletedRunsRepository {
  CompletedRunsRepository({
    List<CompletedRunEntity>? initial,
    RunRemoteDataSource? datasource,
  })  : _runs = List<CompletedRunEntity>.from(initial ?? _defaultRuns()),
        _datasource = datasource;

  final List<CompletedRunEntity> _runs;
  final RunRemoteDataSource? _datasource;
  final _controller =
      StreamController<List<CompletedRunEntity>>.broadcast();

  /// Immutable snapshot of all completed runs, newest first.
  List<CompletedRunEntity> get allRuns => List.unmodifiable(_runs);

  /// Emits a new snapshot whenever a run is added.
  Stream<List<CompletedRunEntity>> get stream => _controller.stream;

  // ── Initialization ─────────────────────────────────────────────────────────

  /// Loads the current user's completed runs from Supabase.
  /// Deduplicates against any records already added by [processCompletions].
  Future<void> initialize() async {
    if (_datasource == null) return;
    try {
      final remoteRuns = await _datasource.fetchMyCompletedRuns();
      for (final run in remoteRuns) {
        addRun(run); // deduplicates by runId
      }
    } catch (e) {
      // ignore: avoid_print
      print('[CompletedRunsRepository] initialize error (non-fatal): $e');
    }
  }

  // ── Mutations ──────────────────────────────────────────────────────────────

  /// Add a newly completed run (deduplicates by [runId]).
  void addRun(CompletedRunEntity run) {
    if (_runs.any((r) => r.runId == run.runId)) return;
    _runs.insert(0, run);
    _controller.add(List.unmodifiable(_runs));
  }

  void dispose() => _controller.close();

  // ── Seed / mock historical records ─────────────────────────────────────────

  static List<CompletedRunEntity> _defaultRuns() => [
        const CompletedRunEntity(
          runId: 'rec-1',
          challengeId: 'ch-04',
          challengeTitle: '10-Minute Workout',
          challengeSlug: '10-minute-workout',
          finalScore: 66,
          startDate: '2025-11-01',
          endDate: '2026-01-05',
          imageAsset: 'assets/pictures/challenge_10-minute-workout.jpg',
        ),
        const CompletedRunEntity(
          runId: 'rec-2',
          challengeId: 'ch-04',
          challengeTitle: '10-Minute Workout',
          challengeSlug: '10-minute-workout',
          finalScore: 12,
          startDate: '2025-08-10',
          endDate: '2025-08-22',
          imageAsset: 'assets/pictures/challenge_10-minute-workout.jpg',
        ),
        const CompletedRunEntity(
          runId: 'rec-3',
          challengeId: 'ch-08',
          challengeTitle: 'No Added Sugar',
          challengeSlug: 'no-added-sugar',
          finalScore: 7,
          startDate: '2025-10-01',
          endDate: '2025-10-08',
        ),
        const CompletedRunEntity(
          runId: 'rec-4',
          challengeId: 'ch-02',
          challengeTitle: '16-Hour Fasting',
          challengeSlug: '16-hour-fasting',
          finalScore: 21,
          startDate: '2025-06-01',
          endDate: '2025-06-22',
          imageAsset: 'assets/pictures/challenge_16-hour-fasting.jpg',
        ),
      ];
}
