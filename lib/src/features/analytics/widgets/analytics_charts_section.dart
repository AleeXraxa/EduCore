import 'dart:math';

import 'package:educore/src/core/responsive/breakpoints.dart';
import 'package:educore/src/core/ui/widgets/app_card.dart';
import 'package:educore/src/features/analytics/analytics_controller.dart';
import 'package:flutter/material.dart';

class AnalyticsChartsSection extends StatelessWidget {
  const AnalyticsChartsSection({super.key, required this.snapshot});

  final AnalyticsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: 'Trends',
          subtitle: 'Revenue and growth signals over time.',
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final size = screenSizeForWidth(constraints.maxWidth);
            final vertical = size == ScreenSize.compact;
            return Flex(
              direction: vertical ? Axis.vertical : Axis.horizontal,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: AppCard(
                    padding: const EdgeInsets.all(16),
                    child: _ChartCard(
                      title: 'Revenue over time',
                      subtitle: 'Monthly revenue trend',
                      child: _MockLineChart(values: snapshot.revenueSeries),
                    ),
                  ),
                ),
                SizedBox(width: vertical ? 0 : 12, height: vertical ? 12 : 0),
                Expanded(
                  flex: 2,
                  child: AppCard(
                    padding: const EdgeInsets.all(16),
                    child: _ChartCard(
                      title: 'Institute growth',
                      subtitle: 'New institutes per month',
                      child: _MockBarChart(values: snapshot.growthSeries),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final size = screenSizeForWidth(constraints.maxWidth);
            final vertical = size == ScreenSize.compact;
            return Flex(
              direction: vertical ? Axis.vertical : Axis.horizontal,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppCard(
                    padding: const EdgeInsets.all(16),
                    child: _ChartCard(
                      title: 'Plan distribution',
                      subtitle: snapshot.planDist.items.isEmpty
                          ? 'No active subscriptions'
                          : snapshot.planDist.items.take(3).map((e) => e.label).join(' • '),
                      trailing: _Legend(
                        items: snapshot.planDist.items.take(5).indexed.map((e) {
                          final (i, item) = e;
                          return _LegendItem(
                            color: _DonutChart.segmentColors[i % _DonutChart.segmentColors.length],
                            label: item.label,
                          );
                        }).toList(),
                      ),
                      child: _DonutChart(dist: snapshot.planDist),
                    ),
                  ),
                ),
                SizedBox(width: vertical ? 0 : 12, height: vertical ? 12 : 0),
                Expanded(
                  child: AppCard(
                    padding: const EdgeInsets.all(16),
                    child: _ChartCard(
                      title: 'Payments',
                      subtitle: 'Approved • Pending • Rejected',
                      child: _PaymentBreakdownBars(
                        breakdown: snapshot.paymentBreakdown,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final trailing = this.trailing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 240,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.24),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.9)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: child,
          ),
        ),
      ],
    );
  }
}

class _MockLineChart extends StatelessWidget {
  const _MockLineChart({required this.values});

  final List<double> values;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return CustomPaint(
      painter: _LineChartPainter(
        values: values,
        lineGradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [cs.primary, cs.secondary, cs.tertiary],
        ),
        gridColor: cs.outlineVariant.withValues(alpha: 0.75),
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _MockBarChart extends StatelessWidget {
  const _MockBarChart({required this.values});

  final List<double> values;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return CustomPaint(
      painter: _BarChartPainter(
        values: values,
        barGradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [cs.secondary, cs.tertiary],
        ),
        gridColor: cs.outlineVariant.withValues(alpha: 0.75),
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  const _LineChartPainter({
    required this.values,
    required this.lineGradient,
    required this.gridColor,
  });

  final List<double> values;
  final Gradient lineGradient;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    for (var i = 1; i <= 4; i++) {
      final y = size.height * (i / 5);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final minV = values.reduce(min);
    final maxV = values.reduce(max);
    final span = (maxV - minV).abs() < 0.001 ? 1.0 : (maxV - minV);

    final dx = size.width / (values.length - 1);
    final points = <Offset>[
      for (var i = 0; i < values.length; i++)
        Offset(
          i * dx,
          size.height - ((values[i] - minV) / span) * size.height,
        ),
    ];

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final cur = points[i];
      final cp1 = Offset(prev.dx + dx * 0.55, prev.dy);
      final cp2 = Offset(cur.dx - dx * 0.55, cur.dy);
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, cur.dx, cur.dy);
    }

    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF2563EB).withValues(alpha: 0.18),
            const Color(0xFF2563EB).withValues(alpha: 0.02),
          ],
        ).createShader(bounds),
    );

    final linePaint = Paint()
      ..shader = lineGradient.createShader(bounds)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = Colors.white;
    final dotStroke = Paint()
      ..shader = lineGradient.createShader(bounds)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    for (final p in points) {
      canvas.drawCircle(p, 4.2, dotPaint);
      canvas.drawCircle(p, 4.2, dotStroke);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.lineGradient != lineGradient ||
        oldDelegate.gridColor != gridColor;
  }
}

class _BarChartPainter extends CustomPainter {
  const _BarChartPainter({
    required this.values,
    required this.barGradient,
    required this.gridColor,
  });

  final List<double> values;
  final Gradient barGradient;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 1; i <= 4; i++) {
      final y = size.height * (i / 5);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final maxV = values.reduce(max);
    final span = maxV <= 0 ? 1.0 : maxV;

    final gap = 10.0;
    final barW = (size.width - gap * (values.length - 1)) / values.length;

    for (var i = 0; i < values.length; i++) {
      final h = (values[i] / span) * size.height;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          i * (barW + gap),
          size.height - h,
          barW,
          h,
        ),
        const Radius.circular(999),
      );

      canvas.drawRRect(rect, Paint()..shader = barGradient.createShader(bounds));
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.barGradient != barGradient ||
        oldDelegate.gridColor != gridColor;
  }
}

class _DonutChart extends StatelessWidget {
  const _DonutChart({required this.dist});

  final PlanDistribution dist;

  static const segmentColors = [
    Color(0xFF2563EB), // Blue
    Color(0xFF8B5CF6), // Purple
    Color(0xFF6366F1), // Indigo
    Color(0xFFEC4899), // Pink
    Color(0xFFF59E0B), // Amber
    Color(0xFF10B981), // Emerald
    Color(0xFF06B6D4), // Cyan
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    // Find dominant plan to show in center
    String dominantLabel = 'No data';
    int dominantPct = 0;
    
    if (dist.items.isNotEmpty) {
      final dominant = dist.items.first;
      dominantLabel = dominant.label;
      dominantPct = dominant.percentage.round();
    }

    return CustomPaint(
      painter: _DonutPainter(
        segments: dist.items,
        colors: segmentColors,
        track: cs.outlineVariant.withValues(alpha: 0.65),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$dominantPct%',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                dominantLabel,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({
    required this.segments,
    required this.colors,
    required this.track,
  });

  final List<PlanDistributionItem> segments;
  final List<Color> colors;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = min(size.width, size.height) * 0.36;
    final thickness = radius * 0.36;

    final rect = Rect.fromCircle(center: center, radius: radius);
    final trackPaint = Paint()
      ..color = track.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -pi / 2, pi * 2, false, trackPaint);

    if (segments.isEmpty) return;

    final total = segments.fold<double>(0, (sum, e) => sum + e.percentage);
    if (total <= 0) return;

    var start = -pi / 2;
    for (var i = 0; i < segments.length; i++) {
      final sweep = (segments[i].percentage / total) * (pi * 2);
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, start, max(0.01, sweep - 0.04), false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.segments != segments ||
        oldDelegate.colors != colors ||
        oldDelegate.track != track;
  }
}

class _PaymentBreakdownBars extends StatelessWidget {
  const _PaymentBreakdownBars({required this.breakdown});

  final PaymentBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final total = max(1, breakdown.total);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BarRow(
          label: 'Approved',
          value: breakdown.approved,
          total: total,
          color: const Color(0xFF16A34A),
        ),
        const SizedBox(height: 12),
        _BarRow(
          label: 'Pending',
          value: breakdown.pending,
          total: total,
          color: const Color(0xFFF59E0B),
        ),
        const SizedBox(height: 12),
        _BarRow(
          label: 'Rejected',
          value: breakdown.rejected,
          total: total,
          color: const Color(0xFFEF4444),
        ),
        const Spacer(),
        Text(
          'Total: $total payments',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _BarRow extends StatelessWidget {
  const _BarRow({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });

  final String label;
  final int value;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pct = (value / total).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const Spacer(),
            Text(
              '$value',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 10,
            child: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.7),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: pct,
                  alignment: Alignment.centerLeft,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color.withValues(alpha: 0.95),
                          color.withValues(alpha: 0.60),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendItem {
  const _LegendItem({required this.color, required this.label});
  final Color color;
  final String label;
}

class _Legend extends StatelessWidget {
  const _Legend({required this.items});
  final List<_LegendItem> items;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        for (final it in items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: it.color,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: cs.outlineVariant),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                it.label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
      ],
    );
  }
}

