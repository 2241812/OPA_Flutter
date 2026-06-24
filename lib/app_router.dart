import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../services/onboarding_service.dart';
import '../screens/home_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/terminal_screen.dart';
import '../screens/profile_editor_screen.dart';
import '../screens/key_management_screen.dart';
import '../screens/quick_commands_screen.dart';

/// Top-level route paths.
final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Custom page transition — slide from right with fade.
CustomTransitionPage<void> _buildTransitionPage({
  required Widget child,
  required GoRouterState state,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        ),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.06, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        ),
      );
    },
  );
}

/// GoRouter configuration for OPA.
final goRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  redirect: (context, state) {
    final onboardingService =
        ProviderScope.containerOf(context).read(onboardingServiceProvider);
    final isComplete = onboardingService.isOnboardingComplete();
    final isOnboardingRoute = state.matchedLocation == '/onboarding';

    if (!isComplete && !isOnboardingRoute) {
      return '/onboarding';
    }
    if (isComplete && isOnboardingRoute) {
      return '/';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/onboarding',
      pageBuilder: (context, state) => _buildTransitionPage(
        child: const OnboardingScreen(),
        state: state,
      ),
    ),
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => _buildTransitionPage(
        child: const HomeScreen(),
        state: state,
      ),
    ),
    GoRoute(
      path: '/terminal/:profileId',
      pageBuilder: (context, state) {
        final profileId = state.pathParameters['profileId']!;
        return _buildTransitionPage(
          child: TerminalScreen(profileId: profileId),
          state: state,
        );
      },
    ),
    GoRoute(
      path: '/profile/new',
      pageBuilder: (context, state) => _buildTransitionPage(
        child: const ProfileEditorScreen(),
        state: state,
      ),
    ),
    GoRoute(
      path: '/profile/:profileId',
      pageBuilder: (context, state) {
        final profileId = state.pathParameters['profileId']!;
        return _buildTransitionPage(
          child: ProfileEditorScreen(profileId: profileId),
          state: state,
        );
      },
    ),
    GoRoute(
      path: '/keys',
      pageBuilder: (context, state) => _buildTransitionPage(
        child: const KeyManagementScreen(),
        state: state,
      ),
    ),
    GoRoute(
      path: '/commands',
      pageBuilder: (context, state) => _buildTransitionPage(
        child: const QuickCommandsScreen(),
        state: state,
      ),
    ),
  ],
);

/// Provider for the router.
final appRouterProvider = Provider<GoRouter>((ref) => goRouter);
