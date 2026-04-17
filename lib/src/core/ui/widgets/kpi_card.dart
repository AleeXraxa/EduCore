import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:flutter/material.dart';

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

class _KpiCardState extends State<KpiCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final trendText = widget.data.trendText;
    final trendUp = widget.data.trendUp;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: Matrix4.identity()..translate(0.0, _isHovered ? -4.0 : 0.0),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: AppRadii.r20,
          border: Border.all(
            color: _isHovered ? cs.primary.withValues(alpha: 0.3) : cs.outlineVariant.withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _isHovered ? 0.06 : 0.02),
              blurRadius: _isHovered ? 32 : 24,
              offset: Offset(0, _isHovered ? 12 : 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: AppRadii.r16,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: widget.data.gradient,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.data.gradient.first.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(widget.data.icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.data.label.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(
                        child: Text(
                          widget.data.value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1.0,
                              ),
                        ),
                      ),
                      if (trendText != null && trendUp != null) ...[
                        const SizedBox(width: 12),
                        _TrendPill(text: trendText, up: trendUp),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendPill extends StatelessWidget {
  const _TrendPill({required this.text, required this.up});

  final String text;
  final bool up;

  @override
  Widget build(BuildContext context) {
    final fg = up ? const Color(0xFF16A34A) : const Color(0xFFE11D48);
    final bg = fg.withValues(alpha: 0.08);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            up ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            size: 14,
            color: fg,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w900,
              fontSize: 10,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
