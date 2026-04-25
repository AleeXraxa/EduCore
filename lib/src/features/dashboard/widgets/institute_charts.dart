import 'dart:math';
import 'package:educore/src/core/responsive/breakpoints.dart';
import 'package:educore/src/core/ui/widgets/app_card.dart';
import 'package:educore/src/features/dashboard/institute_dashboard_controller.dart';
import 'package:flutter/material.dart';
import 'package:educore/src/core/ui/widgets/app_dropdown.dart';

class InstituteChartsSection extends StatelessWidget {
  const InstituteChartsSection({super.key, required this.controller});

  final InstituteDashboardController controller;

  @override
  Widget build(BuildContext context) {
    final present = controller.todaysAttendance.toDouble();
    final absent = max(0, controller.totalStudents - controller.todaysAttendance).toDouble();
    
    final pending = controller.pendingFeesCount.toDouble();
    final paid = controller.paidFeesCount.toDouble();

    final growthSeries = controller.studentGrowth;
    final growthLabels = controller.studentGrowthLabels;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = screenSizeForWidth(constraints.maxWidth);
        final vertical = size == ScreenSize.compact;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'ANALYTICS OVERVIEW',
               style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
            ),
            const SizedBox(height: 16),
            AppCard(
              padding: const EdgeInsets.all(20),
              child: _ChartBox(
                title: 'Student Growth',
                subtitle: 'Enrollment over last 6 months',
                child: _SimpleLineChart(values: growthSeries, labels: growthLabels),
              ),
            ),
            const SizedBox(height: 20),
            Flex(
              direction: vertical ? Axis.vertical : Axis.horizontal,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: AppCard(
                    padding: const EdgeInsets.all(20),
                    child: _ChartBox(
                        title: 'Fees Overview',
                        subtitle: 'Paid vs Pending this month',
                        child: _SimpleBarChart(
                          labels: const ['Paid', 'Pending'],
                          values: [paid, pending],
                          colors: const [Color(0xFF10B981), Color(0xFFF59E0B)],
                        ),
                      ),
                  ),
                ),
                SizedBox(width: vertical ? 0 : 20, height: vertical ? 20 : 0),
                Expanded(
                  flex: 1,
                  child: AppCard(
                    padding: const EdgeInsets.all(20),
                    child: _ChartBox(
                      title: 'Attendance',
                      subtitle: 'Present vs Absent today',
                      child: _SimpleDonutChart(
                        values: [present, absent],
                        labels: const ['Present', 'Absent'],
                        colors: const [Color(0xFF2563EB), Color(0xFFEF4444)],
                      ),
                    ),
                  ),
                ),
              ],
            ),
             const SizedBox(height: 20),
            AppCard(
              padding: const EdgeInsets.all(20),
              child: _ChartBox(
                title: 'Revenue Streams',
                subtitle: 'Breakdown of collected funds',
                child: _SimpleBarChart(
                  labels: const ['Admission', 'Monthly', 'Package', 'Misc'],
                  values: [
                    controller.admissionCollected,
                    controller.monthlyCollected,
                    controller.packageCollected,
                    controller.miscCollected,
                  ],
                  colors: [
                    const Color(0xFF8B5CF6), // Purple for admission
                    const Color(0xFF0D9488), // Teal for monthly
                    Theme.of(context).colorScheme.secondary, // Secondary for package
                    const Color(0xFFF43F5E), // Rose for misc
                  ],
                  isCurrency: true,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ChartBox extends StatelessWidget {
  const _ChartBox({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
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
            SizedBox(
              width: 130,
              child: AppDropdown<String>(
                label: 'Filter',
                showLabel: false,
                compact: true,
                items: const ['Today', '7d', '30d'],
                value: 'Today',
                itemLabel: (s) => s,
                onChanged: (_) {}, // To be wired up to controller later
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(height: 160, child: child),
      ],
    );
  }
}

// ==========================================
// Chart Painters
// ==========================================

class _SimpleLineChart extends StatelessWidget {
  const _SimpleLineChart({required this.values, required this.labels});
  final List<double> values;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return CustomPaint(
      painter: _LinePainter(
        values: values,
        labels: labels,
        primary: cs.primary,
        gridColor: cs.outlineVariant.withOpacity(0.5),
        labelStyle: TextStyle(
          color: cs.onSurfaceVariant,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _LinePainter extends CustomPainter {
  const _LinePainter({
    required this.values,
    required this.labels,
    required this.primary,
    required this.gridColor,
    required this.labelStyle,
  });

  final List<double> values;
  final List<String> labels;
  final Color primary;
  final Color gridColor;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final double bottomPadding = 24.0;
    final double drawHeight = size.height - bottomPadding;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    for (var i = 1; i <= 3; i++) {
      final y = drawHeight * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final minV = values.reduce(min);
    final maxV = values.reduce(max);
    final span = (maxV - minV).abs() < 0.001 ? 1.0 : (maxV - minV);

    final dx = size.width / (values.length - 1);
    final points = <Offset>[
      for (var i = 0; i < values.length; i++)
        Offset(i * dx, drawHeight - ((values[i] - minV) / span) * (drawHeight * 0.8) - (drawHeight * 0.1)),
    ];

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final cur = points[i];
      final cp1 = Offset(prev.dx + dx * 0.4, prev.dy);
      final cp2 = Offset(cur.dx - dx * 0.4, cur.dy);
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, cur.dx, cur.dy);
    }

    final linePaint = Paint()
      ..color = primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPath = Path.from(path)
      ..lineTo(size.width, drawHeight)
      ..lineTo(0, drawHeight)
      ..close();

    final fillGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [primary.withOpacity(0.2), primary.withOpacity(0.0)],
    );

    canvas.drawPath(
        fillPath, Paint()..shader = fillGradient.createShader(Offset(0, 0) & Size(size.width, drawHeight)));
    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = Colors.white;
    final dotStroke = Paint()..color = primary..style = PaintingStyle.stroke..strokeWidth = 2;

    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      canvas.drawCircle(p, 4, dotPaint);
      canvas.drawCircle(p, 4, dotStroke);

      // Draw label
      if (i < labels.length) {
        final tp = TextPainter(
          text: TextSpan(text: labels[i], style: labelStyle),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(canvas, Offset(p.dx - tp.width / 2, size.height - bottomPadding + 6));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LinePainter oldDelegate) => oldDelegate.values != values || oldDelegate.primary != primary || oldDelegate.labels != labels;
}

class _SimpleBarChart extends StatelessWidget {
  const _SimpleBarChart({
    required this.labels,
    required this.values,
    required this.colors,
    this.isCurrency = false,
  });

  final List<String> labels;
  final List<double> values;
  final List<Color> colors;
  final bool isCurrency;

  @override
  Widget build(BuildContext context) {
    if (values.every((v) => v == 0)) {
      return Center(
        child: Text(
          'No data',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (var i = 0; i < values.length; i++)
          _Bar(
            label: labels[i],
            value: values[i],
            maxVal: values.reduce(max),
            color: colors[i],
            isCurrency: isCurrency,
          ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.label, required this.value, required this.maxVal, required this.color, this.isCurrency = false});
  final String label;
  final double value;
  final double maxVal;
  final Color color;
  final bool isCurrency;

  String _format(double v) {
    if (!isCurrency) return v.toInt().toString();
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toInt().toString();
  }

  @override
  Widget build(BuildContext context) {
    final pct = maxVal == 0 ? 0.0 : value / maxVal;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(_format(value), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
        const SizedBox(height: 4),
        Expanded(
          child: FractionallySizedBox(
            heightFactor: pct,
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 32,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _SimpleDonutChart extends StatelessWidget {
  const _SimpleDonutChart({
    required this.values,
    required this.labels,
    required this.colors,
  });

  final List<double> values;
  final List<String> labels;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    if (values.every((v) => v == 0)) {
      return Center(
        child: Text(
          'No data',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }

    final total = values.fold<double>(0, (a, b) => a + b);
    final presentPct = total == 0 ? 0 : (values[0] / total * 100).round();

    return Row(
      children: [
        Expanded(
          child: CustomPaint(
            painter: _DonutPainter(values: values, colors: colors),
            child: Center(
              child: Text(
                '$presentPct%',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < labels.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: colors[i], shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(labels[i], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
          ],
        )
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.values, required this.colors});

  final List<double> values;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = min(size.width, size.height) * 0.45;
    final trackPaint = Paint()
      ..color = Colors.grey.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.3;

    canvas.drawCircle(center, radius, trackPaint);

    final total = values.fold<double>(0, (a, b) => a + b);
    if (total == 0) return;

    var start = -pi / 2;
    for (var i = 0; i < values.length; i++) {
        if (values[i] == 0) continue;
      final sweep = (values[i] / total) * (pi * 2);
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.3
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start, max(0.01, sweep - 0.05), false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => old.values != values || old.colors != colors;
}
