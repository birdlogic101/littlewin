import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
                    label: 'Upgrade Account',
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
            children: [
              SizedBox(height: topPadding + LWSpacing.xl),
              const LwIcon('misc_incognito', size: 64),
              const SizedBox(height: LWSpacing.lg),
              const Text('Welcome to Littlewin!'),
              const Spacer(),
              _DrawerItem(
                icon: 'misc_add_contact',
                label: 'Sign in with Google',
                onTap: () {
                  context
                      .read<AuthBloc>()
                      .add(AuthGoogleSignInRequested());
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: LWSpacing.xl),
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
    showDialog<void>(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<AuthBloc>(),
        child: BlocListener<AuthBloc, AuthState>(
          listener: (ctx, state) {
            if (state is AuthAuthenticated || state is AuthFailureState) {
              Navigator.of(dialogContext, rootNavigator: true).pop();
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
            title: Row(
              children: [
                const Text('⚡', style: TextStyle(fontSize: 22)),
                const SizedBox(width: LWSpacing.sm),
                Text(
                  'Upgrade to Premium',
                  style: LWTypography.title4
                      .copyWith(color: lw.contentPrimary),
                ),
              ],
            ),
            content: Text(
              'Get full access to all features, including creating your own challenges.',
              style: LWTypography.regularNormalRegular
                  .copyWith(color: lw.contentSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text('Cancel',
                    style: LWTypography.regularNormalMedium
                        .copyWith(color: lw.contentSecondary)),
              ),
              BlocBuilder<AuthBloc, AuthState>(
                builder: (ctx, state) {
                  final loading = state is AuthLoading;
                  return FilledButton(
                    onPressed: loading
                        ? null
                        : () => ctx
                            .read<AuthBloc>()
                            .add(AuthUpgradeToPremiumRequested()),
                    style: FilledButton.styleFrom(
                      backgroundColor: lw.brandPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(LWRadius.md),
                      ),
                    ),
                    child: loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text('Upgrade',
                            style: LWTypography.regularNormalMedium
                                .copyWith(color: Colors.white)),
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

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String username;
  final String email;
  final bool isAnonymous;
  final double topPadding;

  const _Header({
    required this.username,
    required this.email,
    required this.isAnonymous,
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
            backgroundColor: lw.brandPrimary.withValues(alpha: 0.12),
            child: Text(
              isAnonymous ? '👤' : initial,
              style: LWTypography.title2.copyWith(color: lw.brandPrimary),
            ),
          ),
          const SizedBox(height: LWSpacing.md),
          Text(
            username,
            style: LWTypography.title4.copyWith(color: lw.contentPrimary),
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
                color: lw.accentDefault.withValues(alpha: 0.18),
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
      child: Container(
        decoration: BoxDecoration(
          color: lw.backgroundApp,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.fromLTRB(
            LWSpacing.lg, LWSpacing.lg, LWSpacing.lg, bottomInset + LWSpacing.xl),
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
              Text(
                'Edit Username',
                style: LWTypography.title4
                    .copyWith(color: lw.contentPrimary),
              ),
              const SizedBox(height: LWSpacing.sm),
              Text(
                'This is how other players see you.',
                style: LWTypography.smallNormalRegular
                    .copyWith(color: lw.contentSecondary),
              ),
              const SizedBox(height: LWSpacing.lg),
              TextFormField(
                controller: _controller,
                autofocus: true,
                maxLength: 30,
                inputFormatters: [
                  // No spaces allowed
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
      ),
    );
  }
}
