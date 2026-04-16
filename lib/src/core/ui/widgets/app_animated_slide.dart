import 'package:flutter/material.dart';

/// A premium entrance animation that fades and slides a widget into position.
class AppAnimatedSlide extends StatelessWidget {
  const AppAnimatedSlide({
    super.key,
    required this.child,
    this.delayIndex = 0,
    this.offset = const Offset(0, 20),
    this.duration = const Duration(milliseconds: 400),
  });

  final Widget child;

  /// Used to stagger animations in a list or grid.
  final int delayIndex;

  /// The starting offset of the child.
  final Offset offset;

  /// The base duration of the animation.
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(
        milliseconds: duration.inMilliseconds + (delayIndex * 100),
      ),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: offset * (1 - value),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
