import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/design_system.dart';
import '../widgets/lw_button.dart';
import '../bloc/bet/bet_bloc.dart';
import '../bloc/bet/bet_event.dart';
import '../bloc/bet/bet_state.dart';

/// A compact bottom sheet that lets a premium user create a custom reward stake.
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

    return Material(
      color: lw.backgroundApp,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(LWRadius.lg)),
      clipBehavior: Clip.hardEdge,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: LWSpacing.md),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: LWColors.skyBase,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ── Header row: title + info icon + close
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    LWSpacing.xl, LWSpacing.lg, LWSpacing.sm, LWSpacing.md),
                child: Row(
                  children: [
                    // "Custom reward" title
                    Text(
                      'Custom reward',
                      style: LWTypography.largeNoneBold.copyWith(
                        color: LWColors.inkBase,
                      ),
                    ),
                    const SizedBox(width: LWSpacing.xs),
                    // Info icon with tooltip
                    Tooltip(
                      message: 'Create a one-off reward unique to this bet.\n'
                          'Only you and the bettor will see it.',
                      triggerMode: TooltipTriggerMode.tap,
                      preferBelow: true,
                      showDuration: const Duration(seconds: 4),
                      child: const Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: LWColors.skyDark,
                      ),
                    ),
                    const Spacer(),
                    // Close icon: 24×24, skyDark
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Padding(
                        padding: const EdgeInsets.all(LWSpacing.sm),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 24,
                          color: LWColors.skyDark,
                          weight: 300,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // ── Body
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    LWSpacing.xl, LWSpacing.lg, LWSpacing.xl, LWSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // Field label
                    Text(
                      'Title',
                      style: LWTypography.smallNoneRegular.copyWith(
                        color: LWColors.inkLighter,
                      ),
                    ),
                    const SizedBox(height: LWSpacing.sm),

                    // Text input
                    TextFormField(
                      controller: _titleCtrl,
                      autofocus: true,
                      maxLength: 100,
                      textCapitalization: TextCapitalization.sentences,
                      style: LWTypography.regularNoneRegular.copyWith(
                        color: LWColors.inkBase,
                      ),
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        hintText: 'e.g. Your Favorite Cake',
                        hintStyle: LWTypography.regularNoneRegular.copyWith(
                          color: LWColors.skyDark,
                        ),
                        // Counter aligned right, small + lighter
                        counterStyle: LWTypography.smallNoneRegular.copyWith(
                          color: LWColors.inkLighter,
                        ),
                        filled: true,
                        fillColor: lw.backgroundCard,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: LWSpacing.md,
                          vertical: LWSpacing.md,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(LWRadius.md),
                          borderSide: BorderSide(
                              color: LWColors.skyBase, width: 1),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(LWRadius.md),
                          borderSide: BorderSide(
                              color: LWColors.skyBase, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(LWRadius.md),
                          borderSide: BorderSide(
                              color: LWColors.primaryBase, width: 1.5),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(LWRadius.md),
                          borderSide: BorderSide(
                              color: lw.feedbackNegative, width: 1.5),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(LWRadius.md),
                          borderSide: BorderSide(
                              color: lw.feedbackNegative, width: 2),
                        ),
                      ),
                      validator: (v) {
                        final s = v?.trim() ?? '';
                        if (s.length < 3) return 'At least 3 characters required';
                        return null;
                      },
                    ),

                    if (errorMessage != null) ...[
                      const SizedBox(height: LWSpacing.sm),
                      Text(
                        errorMessage,
                        style: LWTypography.smallNormalRegular.copyWith(
                          color: lw.feedbackNegative,
                        ),
                      ),
                    ],

                    const SizedBox(height: LWSpacing.xl),

                    // Place bet CTA
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
            ],
          ),
        ),
      ),
    );
  }
}
