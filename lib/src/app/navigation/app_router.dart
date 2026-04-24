import 'package:educore/src/app/navigation/app_routes.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/features/dashboard/super_admin_dashboard_view.dart';
import 'package:educore/src/features/dashboard/institute_dashboard_view.dart';
import 'package:educore/src/features/dashboard/staff_dashboard_view.dart';
import 'package:educore/src/features/dashboard/teacher_dashboard_view.dart';
import 'package:educore/src/features/login/login_view.dart';
import 'package:educore/src/features/certificates/views/certificate_verification_view.dart';
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
      case AppRoutes.instituteDashboard:
        final authService = AppServices.instance.authService;
        final isSignedIn = authService?.currentUser != null;
        final isInstituteAdmin = authService?.session?.isInstituteAdmin ?? false;
        
        if (!isSignedIn || !isInstituteAdmin) {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const LoginView(),
          );
        }
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const InstituteDashboardView(),
        );
      case AppRoutes.staffDashboard:
        final authService = AppServices.instance.authService;
        final isSignedIn = authService?.currentUser != null;
        final isStaff = authService?.session?.isStaff ?? false;
        
        if (!isSignedIn || !isStaff) {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const LoginView(),
          );
        }
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const StaffDashboardView(),
        );
      case AppRoutes.teacherDashboard:
        final authService = AppServices.instance.authService;
        final isSignedIn = authService?.currentUser != null;
        final isTeacher = authService?.session?.isTeacher ?? false;
        
        if (!isSignedIn || !isTeacher) {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const LoginView(),
          );
        }
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const TeacherDashboardView(),
        );
      case AppRoutes.verifyCertificate:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const CertificateVerificationView(),
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
