import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/records/records_bloc.dart';
import '../../bloc/records/records_event.dart';
import '../../bloc/records/records_state.dart';
import '../../widgets/run_record_card.dart';
import '../../../core/theme/design_system.dart';
import '../../../domain/entities/challenge_record.dart';

/// The Records tab — shows the user's completed runs, grouped by challenge.
class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

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

    return BlocBuilder<RecordsBloc, RecordsState>(
      builder: (context, state) {
        return ColoredBox(
          color: lw.backgroundApp,
          child: switch (state) {
            RecordsInitial() || RecordsLoading() => const _LoadingView(),
            RecordsFailure(:final message) => _ErrorView(message: message),
            RecordsLoaded(:final runs) => () {
                // Group flat completed list by challenge for the card display.
                final groups = ChallengeRecord.fromRuns(runs);

                if (groups.isEmpty) return const _EmptyView();

                return CustomScrollView(
                  slivers: [
                    // ── Header ─────────────────────────────────────────────
                    SliverToBoxAdapter(
                      child: _RecordsHeader(totalGroups: groups.length),
                    ),

                    // ── Challenge group cards ───────────────────────────────
                    SliverList.builder(
                      itemCount: groups.length,
                      itemBuilder: (context, index) {
                        final g = groups[index];
                        return RunRecordCard(
                          key: ValueKey(g.challengeId),
                          record: g,
                          onShare: () {
                            // TODO: share sheet
                          },
                          onRetry: () {
                            // TODO: navigate to Explore / join flow for this challenge
                          },
                        );
                      },
                    ),
                    const SliverToBoxAdapter(
                        child: SizedBox(height: LWSpacing.xxl)),
                  ],
                );
              }(),
          },
        );
      },
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _RecordsHeader extends StatelessWidget {
  final int totalGroups;
  const _RecordsHeader({required this.totalGroups});

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LWSpacing.xl,
        LWSpacing.xxl,
        LWSpacing.xl,
        LWSpacing.sm,
      ),
      child: Row(
        children: [
          // ── Title ──────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Records',
                  style:
                      LWTypography.title4.copyWith(color: lw.contentPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  '$totalGroups challenge${totalGroups == 1 ? '' : 's'} completed',
                  style: LWTypography.smallNormalRegular
                      .copyWith(color: lw.contentSecondary),
                ),
              ],
            ),
          ),

          // ── "All" filter chip (visual only for now) ─────────────────
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: LWSpacing.md,
              vertical: LWSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: lw.backgroundCard,
              borderRadius: BorderRadius.circular(LWRadius.pill),
              border: Border.all(color: lw.borderSubtle),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.filter_alt_rounded,
                    size: 14, color: lw.contentSecondary),
                const SizedBox(width: 4),
                Text(
                  'All',
                  style: LWTypography.smallNormalRegular
                      .copyWith(color: lw.contentPrimary),
                ),
                const SizedBox(width: 4),
                Icon(Icons.expand_more_rounded,
                    size: 14, color: lw.contentSecondary),
              ],
            ),
          ),
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

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(LWSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events_outlined,
                size: 64, color: lw.contentSecondary),
            const SizedBox(height: LWSpacing.lg),
            Text(
              'No records yet',
              style: LWTypography.title4.copyWith(color: lw.contentPrimary),
            ),
            const SizedBox(height: LWSpacing.sm),
            Text(
              'Complete a run to see your scores here.',
              style: LWTypography.regularNormalRegular
                  .copyWith(color: lw.contentSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

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
