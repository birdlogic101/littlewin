import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/design_system.dart';
import '../../data/repositories/bet_repository.dart';
import '../bloc/checkin/checkin_bloc.dart';
import '../bloc/checkin/checkin_event.dart';
import 'run_bets_sheet.dart';

/// A lightweight dialog that appears after a user joins or creates a challenge,
/// inviting them to place a self-bet for extra motivation.
///
/// Tapping "Place a self-bet" navigates directly into the [RunBetsSheet]
/// in self-bet mode. Tapping "Maybe later" dismisses the dialog.
class SelfBetInviteDialog {
  SelfBetInviteDialog._();

  static Future<void> show(
    BuildContext context, {
    required String runId,
    required String challengeTitle,
    required int currentStreak,
    required BetRepository betRepository,
    String? username, // current user's own username; defaults to 'you'
  }) async {
    final lw = LWThemeExtension.of(context);

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: lw.backgroundSheet,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LWRadius.lg),
        ),
        // ── Icon + title
        title: Column(
          children: [
            Text('🌟', style: const TextStyle(fontSize: 32)),
            const SizedBox(height: LWSpacing.sm),
            Text(
              'You\'re in!',
              style:
                  LWTypography.title4.copyWith(color: lw.contentPrimary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        // ── Body
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '"$challengeTitle"',
              style: LWTypography.regularNormalBold
                  .copyWith(color: lw.brandPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: LWSpacing.md),
            Text(
              'Make sure failing is not an option: bet on yourself now!',
              style: LWTypography.regularNormalRegular
                  .copyWith(color: lw.contentSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        // ── Actions
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(
            LWSpacing.lg, 0, LWSpacing.lg, LWSpacing.lg),
        actions: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Primary CTA
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  RunBetsSheet.show(
                    context,
                    runId: runId,
                    currentStreak: currentStreak,
                    username: username ?? 'you',
                    isSelfBet: true,
                    startInPlaceMode: true,
                    betRepository: betRepository,
                    onBetPlaced: () {
                      try {
                        context.read<CheckinBloc>().add(
                            CheckinRunBetPlaced(runId: runId));
                      } catch (_) {
                        // context may have changed or bloc not present
                      }
                    },
                  );
                  // Full refresh when sheet/dialog closes
                  try {
                    context.read<CheckinBloc>().add(
                        const CheckinFetchRequested());
                  } catch (_) {}
                },
                style: FilledButton.styleFrom(
                  backgroundColor: lw.brandPrimary,
                  padding: const EdgeInsets.symmetric(
                      vertical: LWSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(LWRadius.pill),
                  ),
                ),
                icon: const Icon(Icons.star_rounded,
                    size: 18, color: Colors.white),
                label: Text(
                  'Place a self-bet',
                  style: LWTypography.regularNormalMedium
                      .copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(height: LWSpacing.sm),
              // Secondary dismiss
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(
                  'Maybe later',
                  style: LWTypography.regularNormalRegular
                      .copyWith(color: lw.contentSecondary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
