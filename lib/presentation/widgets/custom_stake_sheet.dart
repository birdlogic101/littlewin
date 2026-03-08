import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/design_system.dart';
import '../widgets/lw_button.dart';
import '../bloc/bet/bet_bloc.dart';
import '../bloc/bet/bet_event.dart';
import '../bloc/bet/bet_state.dart';

/// A compact bottom sheet that lets a premium user create a custom stake.
///
/// On success the new stake is appended to the [BetBloc] stakes list and
/// auto-selected, then the sheet closes automatically.
///
/// Usage:
/// ```dart
/// CustomStakeSheet.show(context);
/// ```
class CustomStakeSheet extends StatelessWidget {
  const CustomStakeSheet._();

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<BetBloc>(),
        child: const CustomStakeSheet._(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BetBloc, BetState>(
      listenWhen: (prev, curr) {
        if (curr is! BetReady) return false;
        // Close if the bet was placed successfully via this flow
        return curr.submitStatus == BetSubmitStatus.success;
      },
      listener: (ctx, _) => Navigator.pop(ctx),
      child: const _SheetBody(),
    );
  }
}

// ── Sheet body ────────────────────────────────────────────────────────────────

class _SheetBody extends StatefulWidget {
  const _SheetBody();

  @override
  State<_SheetBody> createState() => _SheetBodyState();
}

class _SheetBodyState extends State<_SheetBody> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context
        .read<BetBloc>()
        .add(BetPlaceWithCustomStakeRequested(_titleCtrl.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final state = context.watch<BetBloc>().state;
    final isLoading = state is BetReady &&
        state.submitStatus == BetSubmitStatus.submitting;
    final errorMessage = (state is BetReady) ? state.errorMessage : null;

    return Container(
      decoration: BoxDecoration(
        color: lw.backgroundApp,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        LWSpacing.lg,
        LWSpacing.lg,
        LWSpacing.lg,
        bottomInset + LWSpacing.xl,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: LWSpacing.lg),
                decoration: BoxDecoration(
                  color: lw.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Row(
              children: [
                const Text('🎁', style: TextStyle(fontSize: 22)),
                const SizedBox(width: LWSpacing.sm),
                Text('Custom Stake',
                    style: LWTypography.title4
                        .copyWith(color: lw.contentPrimary)),
              ],
            ),
            const SizedBox(height: LWSpacing.xs),
            Text(
              'Personalize this bet with a one-time reward.',
              style: LWTypography.smallNormalRegular
                  .copyWith(color: lw.contentSecondary),
            ),
            const SizedBox(height: LWSpacing.xl),

            // Title field
            Text('Stake title',
                style: LWTypography.smallNormalBold
                    .copyWith(color: lw.contentSecondary)),
            const SizedBox(height: LWSpacing.sm),
            TextFormField(
              controller: _titleCtrl,
              autofocus: true,
              maxLength: 100,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'e.g. Weekend Road Trip',
                hintStyle: LWTypography.regularNormalRegular
                    .copyWith(color: lw.contentDisabled),
                filled: true,
                fillColor: lw.backgroundCard,
                counterStyle: LWTypography.smallNormalRegular
                    .copyWith(color: lw.contentSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(LWRadius.md),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(LWRadius.md),
                  borderSide: BorderSide(color: lw.brandPrimary, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(LWRadius.md),
                  borderSide:
                      BorderSide(color: lw.feedbackNegative, width: 1.5),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(LWRadius.md),
                  borderSide:
                      BorderSide(color: lw.feedbackNegative, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: LWSpacing.md, vertical: LWSpacing.md),
              ),
              validator: (v) {
                final s = v?.trim() ?? '';
                if (s.length < 3) return 'At least 3 characters required';
                return null;
              },
              onFieldSubmitted: (_) => _submit(),
            ),

            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: LWSpacing.md),
                child: Text(
                  errorMessage,
                  style: LWTypography.smallNormalRegular
                      .copyWith(color: lw.feedbackNegative),
                ),
              ),

            const SizedBox(height: LWSpacing.xl),

            // Place bet button
            LwButton.primary(
              label: 'Place bet',
              onPressed: _submit,
              isLoading: isLoading,
              icon: const Icon(Icons.star_rounded, size: 18),
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }
}
