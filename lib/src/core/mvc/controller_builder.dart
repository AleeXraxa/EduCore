import 'package:flutter/material.dart';

class ControllerBuilder<T extends Listenable> extends StatelessWidget {
  const ControllerBuilder({
    super.key,
    required this.controller,
    required this.builder,
    this.child,
  });

  final T controller;
  final Widget Function(BuildContext context, T controller, Widget? child)
      builder;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => builder(context, controller, child),
      child: child,
    );
  }
}
