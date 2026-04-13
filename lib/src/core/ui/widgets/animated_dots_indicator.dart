import 'package:flutter/material.dart';

class AnimatedDotsIndicator extends StatefulWidget {
  const AnimatedDotsIndicator({
    super.key,
    this.dotSize = 7,
    this.dotSpacing = 7,
    this.color,
  });

  final double dotSize;
  final double dotSpacing;
  final Color? color;

  @override
  State<AnimatedDotsIndicator> createState() => _AnimatedDotsIndicatorState();
}

class _AnimatedDotsIndicatorState extends State<AnimatedDotsIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.color ?? Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value; // 0..1
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List<Widget>.generate(3, (index) {
            final phase = (t + index * 0.2) % 1.0;
            final opacity = (0.35 + 0.65 * (1 - (phase - 0.5).abs() * 2))
                .clamp(0.15, 1.0);
            final scale =
                (0.85 + 0.25 * (1 - (phase - 0.5).abs() * 2)).clamp(0.85, 1.1);

            return Padding(
              padding: EdgeInsets.only(
                right: index == 2 ? 0 : widget.dotSpacing,
              ),
              child: Transform.scale(
                scale: scale,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: baseColor.withValues(alpha: opacity),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: SizedBox(
                    width: widget.dotSize,
                    height: widget.dotSize,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

