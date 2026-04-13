import 'package:flutter/material.dart';
import 'package:educore/src/core/ui/widgets/app_scaffold.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Dashboard',
      body: Center(child: Text('Dashboard placeholder')),
    );
  }
}
