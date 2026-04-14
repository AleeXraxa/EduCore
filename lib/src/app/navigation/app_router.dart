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
        final isSignedIn =
            AppServices.instance.authService?.currentUser != null;
        if (!isSignedIn) {
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
