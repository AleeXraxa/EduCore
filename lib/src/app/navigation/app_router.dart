import 'package:educore/src/app/navigation/app_routes.dart';
import 'package:educore/src/features/dashboard/dashboard_view.dart';
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
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const DashboardView(),
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
