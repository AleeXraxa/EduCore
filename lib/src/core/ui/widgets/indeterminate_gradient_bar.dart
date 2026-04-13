import 'package:flutter/material.dart';

class IndeterminateGradientBar extends StatefulWidget {
  const IndeterminateGradientBar({
    super.key,
    this.width = 320,
    this.height = 8,
    this.radius = 999,
  });

  final double width;
  final double height;
  final double radius;

  @override
  State<IndeterminateGradientBar> createState() =>
      _IndeterminateGradientBarState();
}

class _IndeterminateGradientBarState extends State<IndeterminateGradientBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final track = cs.surfaceContainerHighest;
    final bandGradient = LinearGradient(
      colors: [
        cs.primary.withValues(alpha: 0.0),
        cs.primary.withValues(alpha: 0.85),
        cs.secondary.withValues(alpha: 0.85),
        cs.tertiary.withValues(alpha: 0.75),
        cs.tertiary.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.25, 0.52, 0.78, 1.0],
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: DecoratedBox(
          decoration: BoxDecoration(color: track),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value; // 0..1
              final x = -1.6 + (t * 3.2);
              return Stack(
                fit: StackFit.expand,
                children: [
                  Align(
                    alignment: Alignment(x, 0),
                    child: FractionallySizedBox(
                      widthFactor: 0.55,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: bandGradient,
                        ),
                      ),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: cs.outlineVariant.withValues(alpha: 0.7),
                        width: 1,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

