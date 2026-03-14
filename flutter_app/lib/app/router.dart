import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/pages/auth_page.dart';
import '../features/baby/presentation/pages/baby_setup_page.dart';
import '../features/calendar/presentation/pages/calendar_page.dart';
import '../features/daily_moments/presentation/pages/daily_moments_page.dart';
import '../features/diaper/presentation/pages/diaper_page.dart';
import '../features/feeding/presentation/pages/add_feeding_page.dart';
import '../features/growth/presentation/pages/growth_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/knowledge/presentation/pages/knowledge_article_page.dart';
import '../features/knowledge/presentation/pages/knowledge_page.dart';
import '../features/profile/presentation/pages/about_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../features/reminders/presentation/pages/reminders_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import '../features/session/application/session_providers.dart';
import '../features/session/presentation/pages/splash_page.dart';
import '../features/shared/presentation/main_shell.dart';
import '../features/sleep/presentation/pages/sleep_page.dart';
import '../features/stats/presentation/pages/stats_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(sessionControllerProvider);
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isSplash = state.matchedLocation == '/splash';
      final isAuth = state.matchedLocation == '/auth';
      final isBabySetup = state.matchedLocation == '/baby/setup';

      if (session.isLoading) {
        return isSplash ? null : '/splash';
      }

      final data = session.valueOrNull;
      if (data == null || !data.isAuthenticated) {
        return isAuth ? null : '/auth';
      }

      if (!data.hasBaby) {
        return isBabySetup ? null : '/baby/setup';
      }

      if (isSplash || isAuth || isBabySetup) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
      GoRoute(path: '/auth', builder: (context, state) => const AuthPage()),
      GoRoute(
        path: '/baby/setup',
        builder: (context, state) => const BabySetupPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                  path: '/home', builder: (context, state) => const HomePage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/calendar',
                builder: (context, state) => const CalendarPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/moments',
                builder: (context, state) => const DailyMomentsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                  path: '/stats',
                  builder: (context, state) => const StatsPage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/feeding/add',
        builder: (context, state) => const AddFeedingPage(),
      ),
      GoRoute(path: '/sleep', builder: (context, state) => const SleepPage()),
      GoRoute(path: '/diaper', builder: (context, state) => const DiaperPage()),
      GoRoute(path: '/growth', builder: (context, state) => const GrowthPage()),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/knowledge',
        builder: (context, state) => const KnowledgePage(),
      ),
      GoRoute(
        path: '/knowledge/:id',
        builder: (context, state) => KnowledgeArticlePage(
          articleId: state.pathParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: '/reminders',
        builder: (context, state) => const RemindersPage(),
      ),
      GoRoute(path: '/about', builder: (context, state) => const AboutPage()),
    ],
  );
});
