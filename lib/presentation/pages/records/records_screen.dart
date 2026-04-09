import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/records/records_bloc.dart';
import '../../bloc/records/records_event.dart';
import '../../bloc/records/records_state.dart';
import '../../widgets/run_record_card.dart';
import '../../widgets/challenge_history_sheet.dart';
import '../../../core/theme/design_system.dart';
import '../../../domain/entities/challenge_record.dart';
import '../../../data/repositories/bet_repository.dart';
import '../../widgets/lw_empty_state.dart';
import '../../widgets/create_challenge_sheet.dart';

/// The Records tab — shows the user's completed runs, grouped by challenge.
class RecordsScreen extends StatefulWidget {
  final BetRepository betRepository;
  final VoidCallback? onChallengeRestarted;
  const RecordsScreen({
    super.key,
    required this.betRepository,
    this.onChallengeRestarted,
  });

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<RecordsBloc>().add(const RecordsFetchRequested());
  }

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);

    return BlocConsumer<RecordsBloc, RecordsState>(
      listener: (context, state) {
        if (state is RecordsRestartSuccess) {
          widget.onChallengeRestarted?.call();
        } else if (state is RecordsRestartAlreadyActive) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You already have an ongoing run for this challenge!'),
              duration: Duration(seconds: 2),
            ),
          );
          // Still navigate back to check-in if that was the intended flow
          widget.onChallengeRestarted?.call();
        }
      },
      builder: (context, state) {
        return ColoredBox(
          color: lw.backgroundApp,
          child: switch (state) {
            RecordsInitial() ||
            RecordsLoading() ||
            RecordsRestartSuccess() ||
            RecordsRestartAlreadyActive() =>
              const _LoadingView(),
            RecordsFailure(:final message) => _ErrorView(message: message),
            RecordsLoaded(:final runs) => ColoredBox(
                color: LWColors.skyLighter,
                child: () {
                  // Group flat completed list by challenge for the card display.
                  final groups = ChallengeRecord.fromRuns(runs);

                return CustomScrollView(
                  slivers: [
                    // ── Filter chip row (White header area, fixed height to match tabs)
                    SliverToBoxAdapter(
                      child: Container(
                        height: 48,
                        color: lw.backgroundApp, // white
                        padding: const EdgeInsets.fromLTRB(LWSpacing.lg, 0, LWSpacing.lg, 4),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: _FilterChip(),
                        ),
                      ),
                    ),

                    if (groups.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: LWEmptyState(
                          title: 'No records yet 🏆',
                          subtitle: 'Your best streaks belong here.',
                          actions: [
                            LWEmptyStateAction(
                              label: 'Create challenge',
                              isPrimary: true,
                              isPremium: true,
                              onPressed: () => CreateChallengeSheet.show(
                                context,
                                betRepository: widget.betRepository,
                              ),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      // ── Gap at the top (Align with Check-in list padding)
                      const SliverToBoxAdapter(
                        child: SizedBox(height: LWSpacing.sm),
                      ),
                      // ── Challenge group cards
                      SliverList.builder(
                      itemCount: groups.length,
                      itemBuilder: (context, index) {
                        final g = groups[index];
                        return RunRecordCard(
                          key: ValueKey(g.challengeId),
                          record: g,
                          onShare: () {},
                          onRetry: () {
                            // Find any run in the group to get the metadata
                            final first = g.runs.first;
                            context.read<RecordsBloc>().add(
                                  RecordsRestartChallengeRequested(
                                    challengeId: g.challengeId,
                                    challengeTitle: g.challengeTitle,
                                    challengeSlug: g.challengeSlug,
                                    imageAsset: first.imageAsset,
                                    imageUrl: first.imageUrl,
                                  ),
                                );
                          },
                          onViewHistory: () => ChallengeHistorySheet.show(
                            context,
                            record: g,
                          ),
                        );
                      },
                    ),
                    const SliverToBoxAdapter(
                        child: SizedBox(height: LWSpacing.xxl)),
                    ],
                  ],
                );
                }(),
              ),
          },
        );
      },
    );
  }
}

// ── Filter chip ──────────────────────────────────────────────────────────────



class _FilterChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LWSpacing.md,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: lw.backgroundSurface,
        borderRadius: BorderRadius.circular(LWRadius.md),
        border: Border.all(color: lw.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.filter_list_rounded,
              size: 16, color: lw.contentSecondary),
          const SizedBox(width: 8),
          Text(
            'All',
            style: LWTypography.smallNormalRegular
                .copyWith(color: lw.contentPrimary),
          ),
          const SizedBox(width: 4),
          Icon(Icons.expand_more_rounded,
              size: 18, color: lw.contentSecondary),
        ],
      ),
    );
  }
}

// ── Supporting views ──────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);
    return Center(
      child:
          CircularProgressIndicator(color: lw.brandPrimary, strokeWidth: 2.5),
    );
  }
}

// _EmptyView was removed and replaced by LWEmptyState inline above.

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(LWSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 48, color: lw.contentSecondary),
            const SizedBox(height: LWSpacing.lg),
            Text('Could not load records.',
                style: LWTypography.regularNormalBold
                    .copyWith(color: lw.contentPrimary)),
            const SizedBox(height: LWSpacing.sm),
            Text(message,
                style: LWTypography.smallNormalRegular
                    .copyWith(color: lw.contentSecondary),
                textAlign: TextAlign.center,
                maxLines: 3),
            const SizedBox(height: LWSpacing.xl),
            ElevatedButton(
              onPressed: () => context
                  .read<RecordsBloc>()
                  .add(const RecordsFetchRequested()),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
