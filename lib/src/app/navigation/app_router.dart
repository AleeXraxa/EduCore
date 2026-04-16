import 'package:educore/src/app/navigation/app_routes.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/features/dashboard/super_admin_dashboard_view.dart';
import 'package:educore/src/features/login/login_view.dart';
import 'package:educore/src/features/splash/splash_view.dart';
import 'package:flutter/material.dart';

abstract final class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const SplashView(),
        );
      case AppRoutes.login:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const LoginView(),
        );
      case AppRoutes.dashboard:
        final authService = AppServices.instance.authService;
        final isSignedIn = authService?.currentUser != null;
        // Role guard: only Super Admins may access the admin shell.
        // A regular teacher/staff who is Firebase-authenticated must not
        // reach this view — they are redirected to login instead.
        final isSuperAdmin = authService?.session?.isSuperAdmin ?? false;

        if (!isSignedIn || !isSuperAdmin) {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const LoginView(),
          );
        }
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const SuperAdminDashboardView(),
        );
    }

    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => const _UnknownRouteView(),
    );
  }
}

class _UnknownRouteView extends StatelessWidget {
  const _UnknownRouteView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Page not found')));
  }
}
