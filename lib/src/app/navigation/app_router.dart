import 'package:educore/src/app/navigation/app_routes.dart';
import 'package:educore/src/features/dashboard/dashboard_view.dart';
import 'package:educore/src/features/startup/startup_view.dart';
import 'package:flutter/material.dart';

abstract final class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.startup:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const StartupView(),
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
    return const Scaffold(
      body: Center(child: Text('Page not found')),
    );
  }
}
