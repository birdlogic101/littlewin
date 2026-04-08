import 'dart:async';
import '../../domain/entities/completed_run_entity.dart';
import '../datasources/run_remote_datasource.dart';

import 'package:injectable/injectable.dart';

/// Shared in-memory store for the user's completed runs.
///
/// On startup, call [initialize] to load real records from Supabase.
/// [RunsRepository.processCompletions] feeds new completions into it
/// as the user misses check-in deadlines.
@lazySingleton
class CompletedRunsRepository {
  CompletedRunsRepository({
    RunRemoteDataSource? datasource,
  })  : _runs = <CompletedRunEntity>[],
        _datasource = datasource;

  /// Test constructor — seeds with [initial] runs, no datasource required.
  CompletedRunsRepository.seeded([List<CompletedRunEntity>? initial])
      : _runs = initial != null ? List.of(initial) : <CompletedRunEntity>[],
        _datasource = null;

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
      
      _runs.clear();
      for (final run in remoteRuns) {
        // We use the internal list directly here to avoid multiple stream
        // emissions in a loop. deduplication isn't strictly needed for a 
        // fresh clear() but kept for safety.
        if (!_runs.any((r) => r.runId == run.runId)) {
          _runs.add(run);
        }
      }
      
      // Sort newest first as per repository design (addRun uses insert(0))
      _runs.sort((a, b) => b.endDate.compareTo(a.endDate));
      
      _controller.add(List.unmodifiable(_runs));
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
}
