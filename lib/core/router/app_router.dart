import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../presentation/pages/home_page.dart';
import '../../presentation/pages/onboarding/auth_screen.dart';
import '../../presentation/pages/onboarding/onboarding_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>();

final GoRouter router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  redirect: (context, state) {
    final settings = Hive.box('settings');
    final completed = settings.get('onboarding_completed', defaultValue: false);

    // First launch: show onboarding (anonymous session is created in the background)
    if (!completed && state.matchedLocation != '/onboarding') {
      return '/onboarding';
    }

    // If onboarding is done and somehow still on /onboarding, go home
    if (completed && state.matchedLocation == '/onboarding') {
      return '/';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const AppShell(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthScreen(),
    ),
  ],
);
