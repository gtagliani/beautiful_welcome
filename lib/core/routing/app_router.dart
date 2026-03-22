import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:beautiful_welcome/features/routines/presentation/screens/routines_dashboard_screen.dart';
import 'package:beautiful_welcome/features/routines/presentation/screens/create_routine_screen.dart';
import 'package:beautiful_welcome/features/tracking/presentation/screens/track_workout_screen.dart';
import 'package:beautiful_welcome/features/profile/presentation/screens/profile_screen.dart';

import 'package:beautiful_welcome/features/health/presentation/screens/health_dashboard_screen.dart';
import 'package:beautiful_welcome/core/routing/main_scaffold.dart';

final appRouter = GoRouter(
  initialLocation: '/workout',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainScaffold(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/workout',
              builder: (context, state) => const RoutinesDashboardScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/health',
              builder: (context, state) => const HealthDashboardScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/create-routine',
      pageBuilder: (context, state) {
        return CustomTransitionPage(
          child: const CreateRoutineScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      },
    ),
    GoRoute(
      path: '/track-workout/:routineId',
      pageBuilder: (context, state) {
        final routineId = state.pathParameters['routineId']!;
        return CustomTransitionPage(
          child: TrackWorkoutScreen(routineId: routineId),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        );
      },
    ),
  ],
);
