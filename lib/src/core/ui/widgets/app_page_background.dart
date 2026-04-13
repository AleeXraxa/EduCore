import 'package:flutter/material.dart';
import 'package:educore/src/app/theme/app_tokens.dart';

class AppPageBackground extends StatelessWidget {
  const AppPageBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.background,
                  cs.primary.withValues(alpha: 0.06),
                  cs.secondary.withValues(alpha: 0.05),
                  AppColors.background,
                ],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
