import 'package:educore/src/app/navigation/app_router.dart';
import 'package:educore/src/app/navigation/app_routes.dart';
import 'package:educore/src/app/theme/app_theme.dart';
import 'package:flutter/material.dart';

class EduCoreApp extends StatelessWidget {
  const EduCoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduCore',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      onGenerateRoute: AppRouter.onGenerateRoute,
      initialRoute: AppRoutes.splash,
    );
  }
}
