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
            child: Stack(
              children: [
              Scaffold(
                backgroundColor: lw.backgroundApp,
                body: SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: LWSpacing.xl),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: LWSpacing.xxl),
                          // Logo / Icon
                          Center(
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: lw.brandPrimary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: LwIcon(
                                  'nav_home',
                                  size: 40,
                                  color: lw.brandPrimary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: LWSpacing.xl),
                          Text(
                            _isLogin ? 'Welcome Back' : 'Join Littlewin',
                            style: LWTypography.title2.copyWith(color: lw.contentPrimary),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: LWSpacing.xs),
                          Text(
                            _isLogin 
                              ? 'Sign in to continue your streaks' 
                              : 'Start your journey to better habits',
                            style: LWTypography.regularNormalRegular.copyWith(color: lw.contentSecondary),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: LWSpacing.xxl),

                          // Email Field
                          _buildLabel('Email Address'),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            enabled: !isLoading,
                            decoration: _buildInputDecoration('name@example.com'),
                            validator: (v) => (v?.contains('@') ?? false) ? null : 'Enter a valid email',
                          ),
                          const SizedBox(height: LWSpacing.lg),

                          // Username Field (Sign Up only)
                          if (!_isLogin) ...[
                            _buildLabel('Username'),
                            TextFormField(
                              controller: _usernameController,
                              enabled: !isLoading,
                              decoration: _buildInputDecoration('shady_cookie_42'),
                              validator: (v) => (v?.length ?? 0) >= 3 ? null : 'Too short',
                            ),
                            const SizedBox(height: LWSpacing.lg),
                          ],

                          // Password Field
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
                          ),
                          const SizedBox(height: LWSpacing.xl),

                          // Submit Button
                          LwButton.primary(
                            label: _isLogin ? 'Sign In' : 'Create Account',
                            onPressed: _submit,
                            isLoading: isLoading,
                            size: LWButtonSize.large,
                          ),
                          const SizedBox(height: LWSpacing.xl),

                          // Divider
                          Row(
                            children: [
                              Expanded(child: Divider(color: lw.borderSubtle)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: LWSpacing.md),
                                child: Text('OR', style: LWTypography.smallNormalMedium.copyWith(color: lw.contentSecondary)),
                              ),
                              Expanded(child: Divider(color: lw.borderSubtle)),
                            ],
                          ),
                          const SizedBox(height: LWSpacing.xl),

                          // Google Button
                          LwButton(
                            label: 'Continue with Google',
                            variant: LWButtonVariant.secondary,
                            size: LWButtonSize.large,
                            onPressed: () => context.read<AuthBloc>().add(AuthGoogleSignInRequested()),
                            isLoading: isLoading,
                            icon: Image.network(
                              'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_\"G\"_logo.svg',
                              width: 20,
                              errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, size: 24),
                            ),
                          ),
                          const SizedBox(height: LWSpacing.lg),

                          // Guest Button
                          LwButton.ghost(
                            label: 'Continue as Guest',
                            onPressed: () => context.read<AuthBloc>().add(AuthAnonymousLoginRequested()),
                            isLoading: isLoading,
                            size: LWButtonSize.medium,
                          ),
                          
                          const SizedBox(height: LWSpacing.xl),

                          // Toggle Login/Register
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _isLogin ? "Don't have an account? " : "Already have an account? ",
                                style: LWTypography.smallNormalRegular.copyWith(color: lw.contentSecondary),
                              ),
                              GestureDetector(
                                onTap: isLoading ? null : _toggleMode,
                                child: Text(
                                  _isLogin ? 'Sign Up' : 'Sign In',
                                  style: LWTypography.smallNormalBold.copyWith(
                                    color: isLoading ? lw.contentDisabled : lw.brandPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: bottomPadding + LWSpacing.xl),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (isLoading)
                Positioned.fill(
                  child: Container(
                    color: Colors.black26,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(LWSpacing.xl),
                        decoration: BoxDecoration(
                          color: lw.backgroundSheet,
                          borderRadius: BorderRadius.circular(LWRadius.lg),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
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
      hintStyle: LWTypography.regularNormalRegular.copyWith(color: lw.contentSecondary.withOpacity(0.5)),
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
