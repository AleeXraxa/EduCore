import 'package:flutter/material.dart';

class AppCenteredCard extends StatelessWidget {
  const AppCenteredCard({
    super.key,
    required this.child,
    this.maxWidth = 980,
    this.outerPadding = const EdgeInsets.all(24),
    this.innerPadding = const EdgeInsets.all(24),
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsets outerPadding;
  final EdgeInsets innerPadding;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: outerPadding,
          child: Card(
            elevation: 0,
            color: colorScheme.surfaceContainerLowest,
            child: Padding(
              padding: innerPadding,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
