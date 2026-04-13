import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/design_system.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';
import '../bloc/auth/auth_state.dart';
import 'lw_icon.dart';

class ProfileDrawer extends StatelessWidget {
  const ProfileDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);
    final topPadding = MediaQuery.of(context).padding.top;

    return Drawer(
      backgroundColor: lw.backgroundApp,
      child: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailureState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: lw.feedbackNegative,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is AuthLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AuthAuthenticated) {
            final user = state.user;
            return Column(
              children: [
                _Header(
                  username: user.username,
                  email: user.email,
                  isAnonymous: user.isAnonymous,
                  isPremium: user.isPremium,
                  topPadding: topPadding,
                ),
                const _SectionDivider(),
                _DrawerItem(
                  icon: 'misc_cog',
                  label: 'Edit Username',
                  onTap: () => _showEditUsernameSheet(context, user.username),
                ),
                if (!user.isPremium)
                  _DrawerItem(
                    icon: 'misc_streak',
                    label: user.isAnonymous ? 'Join to Go Premium' : 'Upgrade Account',
                    onTap: () {
                      Navigator.pop(context);
                      ProfileDrawer.showUpgradeDialog(context);
                    },
                  ),
                if (user.isAnonymous) ...[
                  _DrawerItem(
                    icon: 'misc_add_contact',
                    label: 'Link Google Account',
                    onTap: () {
                      context
                          .read<AuthBloc>()
                          .add(AuthGoogleSignInRequested());
                      Navigator.pop(context);
                    },
                  ),
                ],
                const Spacer(),
                const Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: LWSpacing.lg),
                  child: Divider(height: 1),
                ),
                const SizedBox(height: LWSpacing.sm),
                _DrawerItem(
                  icon: 'arrows_back',
                  label: 'Sign Out',
                  isDestructive: true,
                  onTap: () {
                    Navigator.pop(context);
                    context
                        .read<AuthBloc>()
                        .add(AuthSignOutRequested());
                  },
                ),
                SizedBox(
                    height: MediaQuery.of(context).padding.bottom +
                        LWSpacing.lg),
              ],
            );
          }

          // Unauthenticated / initial fallback
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const LwIcon('misc_incognito', size: 64),
              const SizedBox(height: LWSpacing.lg),
              const Text('Welcome to Littlewin!'),
              const SizedBox(height: LWSpacing.xl),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: LWSpacing.xl),
                child: FilledButton(
                    onPressed: () {
                      Navigator.pop(context); // close drawer
                      context.go('/auth');
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: lw.brandPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(LWRadius.md),
                      ),
                    ),
                    child: const Text('Sign In / Sign Up'),
                ),
              ),
              const Spacer(),
            ],
          );
        },
      ),
    );
  }

  void _showEditUsernameSheet(BuildContext context, String currentUsername) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<AuthBloc>(),
        child: _EditUsernameSheet(currentUsername: currentUsername),
      ),
    );
  }

  /// Shows the premium upgrade confirmation dialog.
  /// Can be called from anywhere that has an AuthBloc ancestor.
  static void showUpgradeDialog(BuildContext context) {
    final lw = LWThemeExtension.of(context);
    final authBloc = context.read<AuthBloc>();
    final authState = authBloc.state;

    if (authState is! AuthAuthenticated) return;

    final user = authState.user;

    if (user.isAnonymous) {
      // ── Show Sign Up invitation for Anonymous users
      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: lw.backgroundSheet,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(LWRadius.lg),
          ),
          titlePadding: const EdgeInsets.fromLTRB(LWSpacing.xl, LWSpacing.xl, LWSpacing.xl, 0),
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: lw.brandPrimary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('✨', style: TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(height: LWSpacing.md),
              Text(
                'Join Littlewin',
                textAlign: TextAlign.center,
                style: LWTypography.largeNormalBold.copyWith(
                  color: lw.contentPrimary,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: Text(
            'Create an account to save your progress and access premium features like custom challenges.',
            textAlign: TextAlign.center,
            style: LWTypography.smallNormalRegular.copyWith(color: lw.contentSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Not Now',
                  style: LWTypography.regularNormalMedium.copyWith(color: lw.contentSecondary)),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // Navigate to auth screen
                context.push('/auth');
              },
              style: FilledButton.styleFrom(
                backgroundColor: lw.brandPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(LWRadius.md),
                ),
              ),
              child: Text('Sign Up',
                  style: LWTypography.regularNormalMedium.copyWith(color: Colors.white)),
            ),
          ],
        ),
      );
      return;
    }

    // ── Show Upgrade dialog for Authenticated (non-anonymous) users
    showDialog<void>(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: authBloc,
        child: BlocListener<AuthBloc, AuthState>(
          listener: (ctx, state) {
            if (state is AuthAuthenticated || state is AuthFailureState) {
              // Close dialog if upgrade succeeded or failed
              if (Navigator.of(dialogContext).canPop()) {
                Navigator.of(dialogContext).pop();
              }
              
              if (state is AuthAuthenticated && state.user.isPremium) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('🎉 Account upgraded to Premium!'),
                    backgroundColor: lw.feedbackPositive,
                    duration: const Duration(seconds: 3),
                  ),
                );
              } else if (state is AuthFailureState) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: lw.feedbackNegative,
                  ),
                );
              }
            }
          },
          child: AlertDialog(
            backgroundColor: lw.backgroundSheet,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(LWRadius.lg),
            ),
            titlePadding: const EdgeInsets.fromLTRB(LWSpacing.xl, LWSpacing.xl, LWSpacing.xl, 0),
            contentPadding: const EdgeInsets.fromLTRB(LWSpacing.xl, LWSpacing.md, LWSpacing.xl, 0),
            title: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: lw.brandPrimary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('⚡', style: TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(height: LWSpacing.md),
                Text(
                  'Upgrade to Premium',
                  textAlign: TextAlign.center,
                  style: LWTypography.largeNormalBold.copyWith(
                    color: lw.contentPrimary,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Get full access to all exclusive features.',
                  textAlign: TextAlign.center,
                  style: LWTypography.smallNormalRegular.copyWith(color: lw.contentSecondary),
                ),
                const SizedBox(height: LWSpacing.xl),
                const _PremiumFeature(
                  icon: 'misc_plus',
                  title: 'Create Own Challenges',
                  description: 'Host your own runs and invite friends.',
                ),
                const SizedBox(height: LWSpacing.md),
                const _PremiumFeature(
                  icon: 'misc_bet',
                  title: 'Custom Stakes',
                  description: 'Define your own rewards for any run.',
                ),
                const SizedBox(height: LWSpacing.xl),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text('Not Now',
                    style: LWTypography.regularNormalMedium.copyWith(color: lw.contentSecondary)),
              ),
              BlocBuilder<AuthBloc, AuthState>(
                builder: (ctx, state) {
                  final loading = state is AuthLoading;
                  return FilledButton(
                    onPressed: loading
                        ? null
                        : () => ctx.read<AuthBloc>().add(AuthUpgradeToPremiumRequested()),
                    style: FilledButton.styleFrom(
                      backgroundColor: lw.brandPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(LWRadius.md),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: LWSpacing.xl),
                    ),
                    child: loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text('Go Premium',
                            style: LWTypography.regularNormalMedium.copyWith(color: Colors.white)),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumFeature extends StatelessWidget {
  final String icon;
  final String title;
  final String description;

  const _PremiumFeature({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(LWSpacing.xs),
          decoration: BoxDecoration(
            color: lw.brandPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(LWRadius.sm),
          ),
          child: LwIcon(icon, size: 20, color: lw.brandPrimary),
        ),
        const SizedBox(width: LWSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: LWTypography.smallNormalBold.copyWith(color: lw.contentPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: LWTypography.tinyNormalRegular.copyWith(color: lw.contentSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String username;
  final String email;
  final bool isAnonymous;
  final bool isPremium;
  final double topPadding;

  const _Header({
    required this.username,
    required this.email,
    required this.isAnonymous,
    required this.isPremium,
    required this.topPadding,
  });

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);
    final initial =
        username.isNotEmpty ? username[0].toUpperCase() : '?';

    return Container(
      padding: EdgeInsets.fromLTRB(
        LWSpacing.lg,
        topPadding + LWSpacing.xl,
        LWSpacing.lg,
        LWSpacing.xl,
      ),
      width: double.infinity,
      color: lw.backgroundApp,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: lw.brandPrimary.withOpacity(0.12),
            child: Text(
              isAnonymous ? '👤' : initial,
              style: LWTypography.title2.copyWith(color: lw.brandPrimary),
            ),
          ),
          const SizedBox(height: LWSpacing.md),
          Row(
            children: [
              Flexible(
                child: Text(
                  username,
                  style: LWTypography.title4.copyWith(color: lw.contentPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isPremium) ...[
                const SizedBox(width: 6),
                const LwIcon(
                  'misc_crown',
                  size: 20,
                  color: Color(0xFFFFD700),
                ),
              ],
            ],
          ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              email,
              style: LWTypography.smallNormalRegular
                  .copyWith(color: lw.contentSecondary),
            ),
          ],
          if (isAnonymous) ...[
            const SizedBox(height: LWSpacing.sm),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: lw.accentDefault.withOpacity(0.18),
                borderRadius: BorderRadius.circular(LWRadius.sm),
              ),
              child: Text(
                'Guest Account',
                style: LWTypography.smallNormalBold.copyWith(
                  color: lw.accentDefault,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Drawer items ─────────────────────────────────────────────────────────────

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);
    return Divider(height: 1, color: lw.borderSubtle);
  }
}

class _DrawerItem extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);
    final color =
        isDestructive ? lw.feedbackNegative : lw.contentPrimary;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
          horizontal: LWSpacing.lg, vertical: 2),
      leading: LwIcon(icon, size: 22, color: color),
      title: Text(
        label,
        style: LWTypography.regularNormalMedium.copyWith(color: color),
      ),
      onTap: onTap,
    );
  }
}

// ── Edit Username bottom sheet ────────────────────────────────────────────────

class _EditUsernameSheet extends StatefulWidget {
  final String currentUsername;

  const _EditUsernameSheet({required this.currentUsername});

  @override
  State<_EditUsernameSheet> createState() => _EditUsernameSheetState();
}

class _EditUsernameSheetState extends State<_EditUsernameSheet> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentUsername);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final newName = _controller.text.trim();
    if (newName == widget.currentUsername) {
      Navigator.pop(context);
      return;
    }
    setState(() => _saving = true);
    context
        .read<AuthBloc>()
        .add(AuthUpdateUsernameRequested(newName));
  }

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated || state is AuthFailureState) {
          setState(() => _saving = false);
          if (state is AuthAuthenticated) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Username updated!'),
                backgroundColor: lw.feedbackPositive,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      },
      child: Material(
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

                // ── Header: title + close
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      LWSpacing.xl, LWSpacing.lg, LWSpacing.sm, LWSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Edit Username',
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
                      LWSpacing.xl, LWSpacing.lg, LWSpacing.xl, LWSpacing.xxl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'This is how other players see you.',
                        style: LWTypography.smallNoneRegular.copyWith(
                          color: LWColors.inkLighter,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      const SizedBox(height: LWSpacing.lg),
                      TextFormField(
                        controller: _controller,
                        autofocus: true,
                        maxLength: 30,
                        inputFormatters: [
                          FilteringTextInputFormatter.deny(RegExp(r'\s')),
                        ],
                        decoration: InputDecoration(
                          hintText: 'e.g. shady_cookie_400',
                          counterStyle: LWTypography.smallNormalRegular
                              .copyWith(color: lw.contentSecondary),
                          filled: true,
                          fillColor: lw.backgroundCard,
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
                        ),
                        validator: (value) {
                          final v = value?.trim() ?? '';
                          if (v.isEmpty) return 'Username cannot be empty';
                          if (v.length < 3) return 'Must be at least 3 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: LWSpacing.lg),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _saving ? null : _save,
                          style: FilledButton.styleFrom(
                            backgroundColor: lw.brandPrimary,
                            padding: const EdgeInsets.symmetric(vertical: LWSpacing.md),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(LWRadius.md),
                            ),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : Text(
                                  'Save',
                                  style: LWTypography.regularNormalMedium
                                      .copyWith(color: Colors.white),
                                ),
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
}
