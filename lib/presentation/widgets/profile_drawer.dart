import 'package:flutter/material.dart';
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
      child: BlocBuilder<AuthBloc, AuthState>(
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
                const Divider(),
                if (user.isAnonymous)
                  _DrawerItem(
                    icon: 'misc_add_contact',
                    label: 'Link Google Account',
                    onTap: () {
                      context.read<AuthBloc>().add(AuthGoogleSignInRequested());
                      Navigator.pop(context);
                    },
                  )
                else
                  _DrawerItem(
                    icon: 'misc_cog',
                    label: 'Settings',
                    onTap: () {
                      // Navigate to settings
                      Navigator.pop(context);
                    },
                  ),
                const Spacer(),
                _DrawerItem(
                  icon: 'arrows_back',
                  label: 'Sign Out',
                  onTap: () {
                    context.read<AuthBloc>().add(AuthSignOutRequested());
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: LWSpacing.xl),
              ],
            );
          }

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
                  context.read<AuthBloc>().add(AuthGoogleSignInRequested());
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
}

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
            backgroundColor: lw.brandPrimary.withOpacity(0.1),
            child: Text(
              isAnonymous ? '👤' : (username.isNotEmpty ? username[0].toUpperCase() : '?'),
              style: LWTypography.title2.copyWith(color: lw.brandPrimary),
            ),
          ),
          const SizedBox(height: LWSpacing.md),
          Text(
            username,
            style: LWTypography.title4.copyWith(color: lw.contentPrimary),
          ),
          if (email.isNotEmpty)
            Text(
              email,
              style: LWTypography.smallNormalRegular.copyWith(color: lw.contentSecondary),
            ),
          if (isAnonymous)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: lw.feedbackWarning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(LWRadius.sm),
                ),
                child: Text(
                  'Guest Account',
                  style: LWTypography.smallNormalBold.copyWith(
                    color: lw.feedbackWarning,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);
    return ListTile(
      leading: LwIcon(icon, size: 24, color: lw.contentPrimary),
      title: Text(
        label,
        style: LWTypography.regularNormalMedium.copyWith(color: lw.contentPrimary),
      ),
      onTap: onTap,
    );
  }
}
