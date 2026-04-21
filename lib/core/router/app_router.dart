import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/transactions/presentation/transactions_screen.dart';
import '../../features/transactions/presentation/transaction_form.dart';
import '../../features/categories/presentation/categories_screen.dart';
import '../../features/reports/presentation/reports_screen.dart';
import '../../features/budget/presentation/budget_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/onboarding/presentation/splash_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/settings/data/settings_local_storage.dart';
import '../widgets/app_scaffold.dart';

part 'app_router.g.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

final onboardingCompletedProvider = FutureProvider.autoDispose<bool>((ref) async {
  final authState = ref.watch(authControllerProvider);
  final user = authState.valueOrNull;
  if (user == null) return false;

  return SettingsLocalStorage.getOnboardingCompleted(
    userId: user.id,
    email: user.email,
  );
});

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  final refreshListenable = ValueNotifier<int>(0);
  ref.onDispose(refreshListenable.dispose);

  ref.listen(authControllerProvider, (_, __) {
    refreshListenable.value++;
  });

  ref.listen(onboardingCompletedProvider, (_, __) {
    refreshListenable.value++;
  });

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final onboardingState = ref.read(onboardingCompletedProvider);
      final location = state.matchedLocation;
      final isPreviewOnboarding = state.uri.queryParameters['preview'] == '1';

      if (location == '/splash') {
        if (authState.isLoading || onboardingState.isLoading) return null;

        final bool isAuth = authState.valueOrNull != null;
        if (!isAuth) return '/auth';

        final bool onboardingCompleted = onboardingState.valueOrNull ?? false;
        return onboardingCompleted ? '/dashboard' : '/onboarding';
      }

      if (authState.isLoading || onboardingState.isLoading) return null;

      final bool isAuth = authState.valueOrNull != null;
      final bool isGoingToAuth = location == '/auth';
      final bool isGoingToOnboarding = location == '/onboarding';
      final bool onboardingCompleted = onboardingState.valueOrNull ?? false;

      if (!isAuth) {
        if (isGoingToAuth) return null;
        return '/auth';
      }

      if (!onboardingCompleted && !isGoingToOnboarding) {
        return '/onboarding';
      }

      if (onboardingCompleted && isGoingToOnboarding && !isPreviewOnboarding) {
        return '/dashboard';
      }

      if (isAuth && isGoingToAuth) return '/dashboard';

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/transaction-add',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const TransactionFormScreen(),
      ),
      GoRoute(
        path: '/categories',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CategoriesScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => AppScaffold(child: child),
        routes: [
           GoRoute(
             path: '/dashboard',
             pageBuilder: (context, state) => const NoTransitionPage(child: DashboardScreen()),
           ),
           GoRoute(
             path: '/transactions',
             pageBuilder: (context, state) => const NoTransitionPage(child: TransactionsScreen()),
           ),
           GoRoute(
             path: '/reports',
             pageBuilder: (context, state) => const NoTransitionPage(child: ReportsScreen()),
           ),
           GoRoute(
             path: '/budgets',
             pageBuilder: (context, state) => const NoTransitionPage(child: BudgetScreen()),
           ),
           GoRoute(
             path: '/settings',
             pageBuilder: (context, state) => const NoTransitionPage(child: SettingsScreen()),
           ),
        ]
      )
    ],
  );
}
