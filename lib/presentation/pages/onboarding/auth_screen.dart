import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/design_system.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../../widgets/lw_icon.dart';
import '../../widgets/lw_button.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _formKey.currentState?.reset();
    });
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final username = _usernameController.text.trim();

    if (_isLogin) {
      context.read<AuthBloc>().add(AuthSignInRequested(email: email, password: password));
    } else {
      context.read<AuthBloc>().add(AuthSignUpRequested(
            email: email,
            password: password,
            username: username,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthFailureState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: lw.feedbackNegative,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (state is AuthAuthenticated) {
          context.go('/');
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return PopScope(
            canPop: false,
            child: Scaffold(
              backgroundColor: lw.backgroundApp,
              body: Stack(
                children: [
                  // ── Hero Background (Gradient) ───────────────────────────────
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 220,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            lw.brandPrimary.withOpacity(0.15),
                            lw.backgroundApp,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── Main Content ─────────────────────────────────────────────
                  SafeArea(
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: LWSpacing.xl),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: LWSpacing.xl),
                            
                            // Logo
                            Center(
                              child: Hero(
                                tag: 'app_logo',
                                child: Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: lw.brandPrimary,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: lw.brandPrimary.withOpacity(0.3),
                                        blurRadius: 15,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: LwIcon(
                                      'nav_home',
                                      size: 32,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: LWSpacing.xl),
                            
                            // Copy
                            Text(
                              _isLogin ? 'Keep winning' : 'Join us',
                              style: LWTypography.title3.copyWith(color: lw.contentPrimary),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: LWSpacing.xs),
                            Text(
                              _isLogin 
                                ? 'Sign in to keep your streaks alive' 
                                : 'Start your journey to better habits',
                              style: LWTypography.smallNormalRegular.copyWith(color: lw.contentSecondary),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: LWSpacing.xxl),

                            // ── Mode Toggle ────────────────────────────────────────
                            Container(
                              height: 48,
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: lw.backgroundSurface,
                                borderRadius: BorderRadius.circular(LWRadius.pill),
                              ),
                              child: Row(
                                children: [
                                  _ToggleTab(
                                    label: 'Sign In',
                                    isActive: _isLogin,
                                    onTap: () { if (!_isLogin) _toggleMode(); },
                                  ),
                                  _ToggleTab(
                                    label: 'Sign Up',
                                    isActive: !_isLogin,
                                    onTap: () { if (_isLogin) _toggleMode(); },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: LWSpacing.xl),

                            // ── Input Fields ──────────────────────────────────────
                            _buildLabel('Email Address'),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              enabled: !isLoading,
                              decoration: _buildInputDecoration('name@example.com'),
                              validator: (v) => (v?.contains('@') ?? false) ? null : 'Enter a valid email',
                              style: LWTypography.regularNormalMedium.copyWith(color: lw.contentPrimary),
                            ),
                            const SizedBox(height: LWSpacing.lg),

                            if (!_isLogin) ...[
                              _buildLabel('Username'),
                              TextFormField(
                                controller: _usernameController,
                                enabled: !isLoading,
                                decoration: _buildInputDecoration('shady_cookie_42'),
                                validator: (v) => (v?.length ?? 0) >= 3 ? null : 'Too short',
                                style: LWTypography.regularNormalMedium.copyWith(color: lw.contentPrimary),
                              ),
                              const SizedBox(height: LWSpacing.lg),
                            ],

                            _buildLabel('Password'),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              enabled: !isLoading,
                              decoration: _buildInputDecoration('••••••••').copyWith(
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    color: lw.contentSecondary,
                                    size: 20,
                                  ),
                                  onPressed: isLoading ? null : () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                              validator: (v) => (v?.length ?? 0) >= 6 ? null : 'Min 6 characters',
                              style: LWTypography.regularNormalMedium.copyWith(color: lw.contentPrimary),
                            ),
                            const SizedBox(height: LWSpacing.xxl),

                            // Submit Button
                            LwButton.primary(
                              label: _isLogin ? 'Sign In' : 'Create Account',
                              onPressed: _submit,
                              isLoading: isLoading,
                              size: LWButtonSize.large,
                            ),
                            const SizedBox(height: LWSpacing.xxl),

                            // ── Social & Guest (Compact Bottom) ───────────────────
                            Row(
                              children: [
                                Expanded(child: Divider(color: lw.borderSubtle)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: LWSpacing.md),
                                  child: Text('OR', style: LWTypography.tinyNormalBold.copyWith(color: lw.contentSecondary)),
                                ),
                                Expanded(child: Divider(color: lw.borderSubtle)),
                              ],
                            ),
                            const SizedBox(height: LWSpacing.xl),

                            // Social Buttons Row
                            Row(
                              children: [
                                Expanded(
                                  child: _SocialButton(
                                    label: 'Google',
                                    iconPath: 'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_\"G\"_logo.svg',
                                    onPressed: () => context.read<AuthBloc>().add(AuthGoogleSignInRequested()),
                                    isLoading: isLoading,
                                  ),
                                ),
                                const SizedBox(width: LWSpacing.md),
                                Expanded(
                                  child: _SocialButton(
                                    label: 'Guest',
                                    icon: Icons.person_outline,
                                    onPressed: () => context.read<AuthBloc>().add(AuthAnonymousLoginRequested()),
                                    isLoading: isLoading,
                                  ),
                                ),
                              ],
                            ),
                            
                            SizedBox(height: bottomPadding + LWSpacing.xxl),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── Loading Overlay ──────────────────────────────────────────
                  if (isLoading)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black45,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(LWSpacing.xl),
                            decoration: BoxDecoration(
                              color: lw.backgroundSheet,
                              borderRadius: BorderRadius.circular(LWRadius.lg),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(color: lw.brandPrimary),
                                const SizedBox(height: LWSpacing.md),
                                Text(
                                  'Authenticating...',
                                  style: LWTypography.regularNormalMedium.copyWith(color: lw.contentPrimary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: LWSpacing.xs, left: 4),
      child: Text(
        text,
        style: LWTypography.smallNormalMedium.copyWith(color: LWThemeExtension.of(context).contentPrimary),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    final lw = LWThemeExtension.of(context);
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: lw.backgroundCard,
      hintStyle: LWTypography.regularNormalRegular.copyWith(color: lw.contentSecondary.withOpacity(0.3)),
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
        borderSide: BorderSide(color: lw.feedbackNegative, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: LWSpacing.md, vertical: LWSpacing.md),
    );
  }
}

class _ToggleTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ToggleTab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: LWDuration.standard,
          decoration: BoxDecoration(
            color: isActive ? lw.backgroundCard : Colors.transparent,
            borderRadius: BorderRadius.circular(LWRadius.pill),
            boxShadow: isActive ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
          child: Center(
            child: Text(
              label,
              style: (isActive ? LWTypography.smallNormalBold : LWTypography.smallNormalMedium).copyWith(
                color: isActive ? lw.contentPrimary : lw.contentSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final String? iconPath;
  final IconData? icon;
  final VoidCallback onPressed;
  final bool isLoading;

  const _SocialButton({
    required this.label,
    this.iconPath,
    this.icon,
    required this.onPressed,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: lw.borderSubtle),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(LWRadius.md)),
          foregroundColor: lw.contentPrimary,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (iconPath != null)
              Image.network(
                iconPath!,
                width: 18,
                errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, size: 24),
              )
            else if (icon != null)
              Icon(icon, size: 18, color: lw.contentSecondary),
            const SizedBox(width: 8),
            Text(label, style: LWTypography.smallNormalMedium),
          ],
        ),
      ),
    );
  }
}
