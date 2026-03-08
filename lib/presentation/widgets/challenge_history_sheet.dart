import 'package:flutter/material.dart';
import '../../core/theme/design_system.dart';
import '../../domain/entities/challenge_record.dart';
import '../../domain/entities/completed_run_entity.dart';
import 'png_streak_ring.dart';

/// A bottom sheet that displays the full history of runs for a single challenge.
class ChallengeHistorySheet extends StatelessWidget {
  final ChallengeRecord record;

  const ChallengeHistorySheet({
    super.key,
    required this.record,
  });

  static Future<void> show(
    BuildContext context, {
    required ChallengeRecord record,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChallengeHistorySheet(record: record),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);
    final size = MediaQuery.of(context).size;

    return Container(
      height: size.height * 0.8,
      decoration: BoxDecoration(
        color: lw.backgroundApp,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(LWRadius.lg)),
      ),
      child: Column(
        children: [
          // ── Header Section ──────────────────────────────────────────────
          const SizedBox(height: LWSpacing.md),
          Center(
            child: Container(
              width: LWComponents.modal.dragHandleWidth,
              height: LWComponents.modal.dragHandleHeight,
              decoration: BoxDecoration(
                color: lw.borderSubtle,
                borderRadius: BorderRadius.circular(LWComponents.modal.dragHandleRadius),
              ),
            ),
          ),
          const SizedBox(height: LWSpacing.md),
          
          _Header(
            title: record.challengeTitle,
            onClose: () => Navigator.pop(context),
          ),
          
          const Divider(height: 1),

          // ── History List ────────────────────────────────────────────────
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(LWSpacing.lg),
              itemCount: record.runs.length,
              separatorBuilder: (_, __) => const SizedBox(height: LWSpacing.md),
              itemBuilder: (context, index) {
                final run = record.runs[index];
                return _HistoryRunCard(run: run);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final VoidCallback onClose;

  const _Header({
    required this.title,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: LWSpacing.lg, vertical: LWSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: LWTypography.regularNormalBold.copyWith(color: lw.contentPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Challenge History',
                  style: LWTypography.smallNormalRegular.copyWith(color: lw.contentSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
            color: lw.contentSecondary,
          ),
        ],
      ),
    );
  }
}

class _HistoryRunCard extends StatelessWidget {
  final CompletedRunEntity run;

  const _HistoryRunCard({required this.run});

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);

    return Container(
      padding: const EdgeInsets.all(LWSpacing.md),
      decoration: BoxDecoration(
        color: lw.backgroundCard,
        borderRadius: BorderRadius.circular(LWRadius.md),
        border: Border.all(color: lw.borderSubtle),
      ),
      child: Row(
        children: [
          PngStreakRing(
            streak: run.finalScore,
            size: 52,
            numberColor: lw.contentPrimary,
          ),
          const SizedBox(width: LWSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Final Score: ${run.finalScore} days',
                  style: LWTypography.regularNormalBold.copyWith(color: lw.contentPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  '${run.startDate} to ${run.endDate}',
                  style: LWTypography.smallNormalRegular.copyWith(color: lw.contentSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
