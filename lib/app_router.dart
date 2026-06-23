import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/home_screen.dart';
import '../screens/terminal_screen.dart';
import '../screens/profile_editor_screen.dart';
import '../screens/key_management_screen.dart';
import '../screens/quick_commands_screen.dart';

/// Top-level route paths.
final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// GoRouter configuration for OPA.
final goRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/terminal/:profileId',
      builder: (context, state) {
        final profileId = state.pathParameters['profileId']!;
        return TerminalScreen(profileId: profileId);
      },
    ),
    GoRoute(
      path: '/profile/new',
      builder: (context, state) => const ProfileEditorScreen(),
    ),
    GoRoute(
      path: '/profile/:profileId',
      builder: (context, state) {
        final profileId = state.pathParameters['profileId']!;
        return ProfileEditorScreen(profileId: profileId);
      },
    ),
    GoRoute(
      path: '/keys',
      builder: (context, state) => const KeyManagementScreen(),
    ),
    GoRoute(
      path: '/commands',
      builder: (context, state) => const QuickCommandsScreen(),
    ),
  ],
);

/// Provider for the router.
final appRouterProvider = Provider<GoRouter>((ref) => goRouter);
