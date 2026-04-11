import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../../core/di/injection.dart';
import '../../core/theme/design_system.dart';
import '../../data/datasources/challenge_remote_datasource.dart';
import '../../data/repositories/challenge_repository_impl.dart';
import '../../data/repositories/runs_repository.dart';
import '../../data/repositories/bet_repository.dart';
import '../../domain/usecases/create_challenge.dart';
import '../bloc/create_challenge/create_challenge_bloc.dart';
import '../bloc/create_challenge/create_challenge_event.dart';
import '../bloc/create_challenge/create_challenge_state.dart';
import 'self_bet_invite_dialog.dart';

/// Full-screen bottom sheet for creating a new challenge (premium users only).
///
/// Usage:
/// ```dart
/// CreateChallengeSheet.show(context, betRepository: _betRepository);
/// ```
class CreateChallengeSheet extends StatelessWidget {
  final BetRepository betRepository;

  const CreateChallengeSheet._({required this.betRepository});

  /// Opens the sheet. Builds its own [CreateChallengeBloc] from Supabase.
  static Future<void> show(
    BuildContext context, {
    required BetRepository betRepository,
  }) {
    final bloc = CreateChallengeBloc(
      runsRepository: getIt<RunsRepository>(),
      createChallenge: CreateChallenge(
        ChallengeRepositoryImpl(
          ChallengeRemoteDataSource(Supabase.instance.client),
        ),
      ),
    );

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider<CreateChallengeBloc>.value(
        value: bloc,
        child: CreateChallengeSheet._(betRepository: betRepository),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);

    return BlocListener<CreateChallengeBloc, CreateChallengeState>(
      listener: (ctx, state) {
        if (state is CreateChallengeSuccess) {
          Navigator.pop(ctx);
          SelfBetInviteDialog.show(
            ctx,
            runId: state.result.runId,
            challengeTitle: state.result.challengeTitle,
            currentStreak: 0,
            betRepository: betRepository,
          );
        } else if (state is CreateChallengeFailure) {
          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: lw.feedbackNegative,
          ));
        }
      },
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
  final _descCtrl = TextEditingController();
  bool _isPublic = true;
  String? _selectedImageAsset = 'assets/pictures/challenge_default_1080.jpg';

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<CreateChallengeBloc>().add(CreateChallengeSubmitted(
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          visibility: _isPublic ? 'public' : 'private',
          imageAsset: _selectedImageAsset,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isLoading =
        context.watch<CreateChallengeBloc>().state is CreateChallengeLoading;

    return Material(
      color: lw.backgroundApp,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(LWRadius.lg)),
      clipBehavior: Clip.hardEdge,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
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

                // ── Header: title + close
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      LWSpacing.xl, LWSpacing.lg, LWSpacing.sm, LWSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Create a challenge',
                          style: LWTypography.largeNoneBold.copyWith(
                            color: LWColors.inkBase,
                          ),
                        ),
                      ),
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

              // Title field
              _FieldLabel(label: 'Title *', lw: lw),
              const SizedBox(height: LWSpacing.sm),
              TextFormField(
                controller: _titleCtrl,
                maxLength: 50,
                textCapitalization: TextCapitalization.sentences,
                decoration:
                    _inputDeco(lw, hint: 'e.g. 10-Minute Workout'),
                validator: (v) {
                  final s = v?.trim() ?? '';
                  if (s.length < 3) {
                    return 'At least 3 characters required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: LWSpacing.md),

              // Description field
              _FieldLabel(label: 'Description (optional)', lw: lw),
              const SizedBox(height: LWSpacing.sm),
              TextFormField(
                controller: _descCtrl,
                maxLength: 500,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: _inputDeco(lw,
                    hint: 'What is this challenge about?'),
              ),
              const SizedBox(height: LWSpacing.md),

              const SizedBox(height: LWSpacing.md),

              // Visibility toggle
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: LWSpacing.md, vertical: LWSpacing.sm),
                decoration: BoxDecoration(
                  color: lw.backgroundCard,
                  borderRadius: BorderRadius.circular(LWRadius.md),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isPublic ? 'Public' : 'Private',
                            style: LWTypography.regularNormalMedium
                                .copyWith(color: lw.contentPrimary),
                          ),
                          Text(
                            _isPublic
                                ? 'Anyone can see and join'
                                : 'Only you can see this challenge',
                            style: LWTypography.smallNormalRegular
                                .copyWith(color: lw.contentSecondary),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isPublic,
                      activeColor: lw.brandPrimary,
                      onChanged: (v) => setState(() => _isPublic = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: LWSpacing.xl),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: isLoading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: lw.brandPrimary,
                    padding: const EdgeInsets.symmetric(
                        vertical: LWSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(LWRadius.pill),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text('Create Challenge',
                          style: LWTypography.regularNormalMedium
                              .copyWith(color: Colors.white)),
                ),
              ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static InputDecoration _inputDeco(LWThemeExtension lw,
      {required String hint}) {
    return InputDecoration(
      hintText: hint,
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
        borderSide: BorderSide(color: lw.feedbackNegative, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(LWRadius.md),
        borderSide: BorderSide(color: lw.feedbackNegative, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
          horizontal: LWSpacing.md, vertical: LWSpacing.md),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  final LWThemeExtension lw;
  const _FieldLabel({required this.label, required this.lw});

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: LWTypography.smallNormalBold
            .copyWith(color: lw.contentSecondary),
      );
}
