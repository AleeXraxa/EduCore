import 'package:flutter/material.dart';

class HoverScale extends StatefulWidget {
  const HoverScale({
    super.key,
    required this.child,
    this.enabled = true,
    this.scale = 1.02,
    this.duration = const Duration(milliseconds: 140),
    this.curve = Curves.easeOutCubic,
  });

  final Widget child;
  final bool enabled;
  final double scale;
  final Duration duration;
  final Curve curve;

  @override
  State<HoverScale> createState() => _HoverScaleState();
}

class _HoverScaleState extends State<HoverScale> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final target = (widget.enabled && _hovered) ? widget.scale : 1.0;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: target,
        duration: widget.duration,
        curve: widget.curve,
        child: widget.child,
      ),
    );
  }
}

