import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'dart:math';

@immutable
class KpiCardData {
  const KpiCardData({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
    this.trendText,
    this.trendUp,
  });

  final String label;
  final String value;
  final IconData icon;
  final List<Color> gradient;
  final String? trendText;
  final bool? trendUp;
}

class KpiCard extends StatefulWidget {
  const KpiCard({super.key, required this.data});

  final KpiCardData data;

  @override
  State<KpiCard> createState() => _KpiCardState();
}

class _KpiCardState extends State<KpiCard> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  void _onHover(bool isHovering) {
    setState(() => _isHovered = isHovering);
    if (isHovering) {
      _hoverController.forward();
    } else {
      _hoverController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final trendText = widget.data.trendText;
    final trendUp = widget.data.trendUp;

    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: AnimatedBuilder(
        animation: _hoverController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(24),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: AppRadii.r24,
                border: Border.all(
                  color: _isHovered
                      ? cs.primary.withValues(alpha: 0.4)
                      : cs.outlineVariant.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: cs.shadow.withValues(
                      alpha: _isHovered ? 0.12 : 0.04,
                    ),
                    blurRadius: _isHovered ? 40 : 20,
                    offset: Offset(0, _isHovered ? 20 : 10),
                  ),
                ],
              ),
              constraints: const BoxConstraints(minHeight: 110),
              child: Stack(
                children: [
                  // --- Decorative Background Pattern ---
                  Positioned(
                    right: -20,
                    bottom: -20,
                    child: Opacity(
                      opacity: _isHovered ? 0.08 : 0.03,
                      child: Transform.rotate(
                        angle: -pi / 6,
                        child: Icon(
                          widget.data.icon,
                          size: 120,
                          color: widget.data.gradient.first,
                        ),
                      ),
                    ),
                  ),

                  // --- Content ---
                  Row(
                    children: [
                      // --- Icon Container ---
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              borderRadius: AppRadii.r20,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: widget.data.gradient,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: widget.data.gradient.first.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: _isHovered ? 20 : 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                          ),
                          Icon(widget.data.icon, color: Colors.white, size: 32),
                        ],
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.data.label.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: cs.onSurfaceVariant,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2.0,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Expanded(
                                  child: _AnimatedCountText(
                                    value: widget.data.value,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -1.5,
                                          color: cs.onSurface,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AnimatedCountText extends StatelessWidget {
  const _AnimatedCountText({required this.value, this.style});

  final String value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final match = RegExp(r'[0-9.,]+').firstMatch(value);

    if (match == null) {
      return Text(value, style: style);
    }

    final numericPart = match.group(0)!;
    final numericValue = double.tryParse(numericPart.replaceAll(',', ''));
    final prefix = value.substring(0, match.start);
    final suffix = value.substring(match.end);

    if (numericValue == null) {
      return Text(
        value,
        style: style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: numericValue),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.fastLinearToSlowEaseIn,
      builder: (context, val, child) {
        final formattedValue = val >= 1000
            ? '${(val / 1000).toStringAsFixed(1)}k'
            : val.toInt().toString();

        return Text(
          '$prefix$formattedValue$suffix',
          style: style,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}
