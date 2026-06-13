import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/authentication/presentation/login_screen.dart';
import '../features/authentication/presentation/register_screen.dart';
import '../features/authentication/providers/auth_notifier.dart';
import '../features/authentication/providers/auth_state.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/projects/presentation/projects_shell.dart';
import '../features/rooms/presentation/rooms_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/tasks/tasks_screen.dart';
import 'shell/app_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      final isLoggedIn = authState.status == AuthStatus.authenticated;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      final isSplashRoute = state.matchedLocation == '/splash';

      if (isSplashRoute) return null;
      if (isLoggedIn && isAuthRoute) return '/dashboard';
      if (!isLoggedIn && !isAuthRoute) return '/login';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const DashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/projects',
            name: 'projects',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const ProjectsShell(),
            ),
          ),
          GoRoute(
            path: '/rooms',
            name: 'rooms',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const RoomsScreen(),
            ),
          ),
          GoRoute(
            path: '/tasks',
            name: 'tasks',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const TasksScreen(),
            ),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const SettingsScreen(),
            ),
          ),
        ],
      ),
    ],
  );

  // Listen for auth state changes to navigate away from splash
  ref.listen(authNotifierProvider, (previous, next) {
    if (next.status == AuthStatus.authenticated) {
      router.go('/dashboard');
    } else if (next.status == AuthStatus.unauthenticated) {
      router.go('/login');
    }
  });

  return router;
});
