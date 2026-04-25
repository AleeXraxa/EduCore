import 'dart:math';
import 'package:educore/src/core/responsive/breakpoints.dart';
import 'package:educore/src/core/ui/widgets/app_card.dart';
import 'package:educore/src/features/dashboard/institute_dashboard_controller.dart';
import 'package:flutter/material.dart';
import 'package:educore/src/core/ui/widgets/app_dropdown.dart';

class InstituteChartsSection extends StatefulWidget {
  const InstituteChartsSection({super.key, required this.controller});

  final InstituteDashboardController controller;

  @override
  State<InstituteChartsSection> createState() => _InstituteChartsSectionState();
}

class _InstituteChartsSectionState extends State<InstituteChartsSection> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _revealAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _revealAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutQuart,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final present = widget.controller.todaysAttendance.toDouble();
    final absent = max(0, widget.controller.totalStudents - widget.controller.todaysAttendance).toDouble();
    
    final pending = widget.controller.pendingFeesCount.toDouble();
    final paid = widget.controller.paidFeesCount.toDouble();

    final growthSeries = widget.controller.studentGrowth;
    final growthLabels = widget.controller.studentGrowthLabels;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = screenSizeForWidth(constraints.maxWidth);
        final vertical = size == ScreenSize.compact;

        return FadeTransition(
          opacity: _revealAnimation,
          child: SlideTransition(
            position: _revealAnimation.drive(
              Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'ANALYTICS ENGINE',
                   style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                      ),
                ),
                const SizedBox(height: 16),
                _PremiumChartCard(
                  child: _ChartBox(
                    title: 'Student Growth',
                    subtitle: 'Enrollment performance over last 6 months',
                    child: _PremiumLineChart(values: growthSeries, labels: growthLabels, animation: _revealAnimation),
                  ),
                ),
                const SizedBox(height: 20),
                Flex(
                  direction: vertical ? Axis.vertical : Axis.horizontal,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 1,
                      child: _PremiumChartCard(
                        child: _ChartBox(
                            title: 'Fees Overview',
                            subtitle: 'Payment status distribution',
                            child: _PremiumBarChart(
                              labels: const ['Paid', 'Pending'],
                              values: [paid, pending],
                              colors: const [Color(0xFF10B981), Color(0xFFF59E0B)],
                              animation: _revealAnimation,
                            ),
                          ),
                      ),
                    ),
                    SizedBox(width: vertical ? 0 : 20, height: vertical ? 20 : 0),
                    Expanded(
                      flex: 1,
                      child: _PremiumChartCard(
                        child: _ChartBox(
                          title: 'Live Attendance',
                          subtitle: 'Today\'s check-in metrics',
                          child: _PremiumDonutChart(
                            values: [present, absent],
                            labels: const ['Present', 'Absent'],
                            colors: const [Color(0xFF6366F1), Color(0xFFF43F5E)],
                            animation: _revealAnimation,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                 const SizedBox(height: 20),
                _PremiumChartCard(
                  child: _ChartBox(
                    title: 'Revenue Streams',
                    subtitle: 'Fund distribution analytics',
                    child: _PremiumBarChart(
                      labels: const ['Admission', 'Monthly', 'Package', 'Misc'],
                      values: [
                        widget.controller.admissionCollected,
                        widget.controller.monthlyCollected,
                        widget.controller.packageCollected,
                        widget.controller.miscCollected,
                      ],
                      colors: const [
                        Color(0xFF8B5CF6), 
                        Color(0xFF0D9488), 
                        Color(0xFFF97316),
                        Color(0xFFF43F5E),
                      ],
                      isCurrency: true,
                      animation: _revealAnimation,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PremiumChartCard extends StatelessWidget {
  const _PremiumChartCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(24),
      child: child,
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
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today, size: 14, color: cs.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Last 30 Days',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        SizedBox(height: 180, child: child),
      ],
    );
  }
}

// ==========================================
// PREMIUM CHART WIDGETS
// ==========================================

class _PremiumLineChart extends StatelessWidget {
  const _PremiumLineChart({required this.values, required this.labels, required this.animation});
  final List<double> values;
  final List<String> labels;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return CustomPaint(
          painter: _LinePainter(
            values: values,
            labels: labels,
            primary: cs.primary,
            gridColor: cs.outlineVariant.withValues(alpha: 0.3),
            labelStyle: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
            progress: animation.value,
          ),
          child: const SizedBox.expand(),
        );
      },
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
    required this.progress,
  });

  final List<double> values;
  final List<String> labels;
  final Color primary;
  final Color gridColor;
  final TextStyle labelStyle;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final double bottomPadding = 30.0;
    final double drawHeight = size.height - bottomPadding;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    // Draw horizontal grid lines
    for (var i = 0; i <= 4; i++) {
      final y = drawHeight * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final minV = 0.0; // Assume 0 for better baseline
    final maxV = max(1.0, values.reduce(max) * 1.2); // Add some headroom
    final span = maxV - minV;

    final dx = size.width / (values.length - 1);
    final points = <Offset>[
      for (var i = 0; i < values.length; i++)
        Offset(i * dx, drawHeight - ((values[i] - minV) / span) * drawHeight * progress),
    ];

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final cur = points[i];
      final cp1 = Offset(prev.dx + dx * 0.5, prev.dy);
      final cp2 = Offset(cur.dx - dx * 0.5, cur.dy);
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, cur.dx, cur.dy);
    }

    // Fill under path
    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, drawHeight)
      ..lineTo(points.first.dx, drawHeight)
      ..close();

    final fillGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [primary.withValues(alpha: 0.3 * progress), primary.withValues(alpha: 0.0)],
    );

    canvas.drawPath(fillPath, Paint()..shader = fillGradient.createShader(Offset(0, 0) & Size(size.width, drawHeight)));

    // Draw smooth line
    final linePaint = Paint()
      ..color = primary.withValues(alpha: progress)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);

    // Draw interactive-style dots
    final dotPaint = Paint()..color = Colors.white;
    final dotStroke = Paint()..color = primary..style = PaintingStyle.stroke..strokeWidth = 2.5;

    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      if (progress > (i / points.length)) {
         canvas.drawCircle(p, 5, dotPaint);
         canvas.drawCircle(p, 5, dotStroke);
      }

      // Draw label
      if (i < labels.length && progress > 0.8) {
        final tp = TextPainter(
          text: TextSpan(text: labels[i], style: labelStyle),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(canvas, Offset(p.dx - tp.width / 2, size.height - bottomPadding + 10));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) => old.progress != progress;
}

class _PremiumBarChart extends StatelessWidget {
  const _PremiumBarChart({
    required this.labels,
    required this.values,
    required this.colors,
    required this.animation,
    this.isCurrency = false,
  });

  final List<String> labels;
  final List<double> values;
  final List<Color> colors;
  final Animation<double> animation;
  final bool isCurrency;

  @override
  Widget build(BuildContext context) {
    if (values.every((v) => v == 0)) {
      return Center(child: Text('Insufficient data for period', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)));
    }

    final maxVal = max(1.0, values.reduce(max));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (var i = 0; i < values.length; i++)
          _PremiumBar(
            label: labels[i],
            value: values[i],
            maxVal: maxVal,
            color: colors[i],
            isCurrency: isCurrency,
            animation: animation,
            index: i,
            total: values.length,
          ),
      ],
    );
  }
}

class _PremiumBar extends StatelessWidget {
  const _PremiumBar({
    required this.label,
    required this.value,
    required this.maxVal,
    required this.color,
    required this.animation,
    required this.index,
    required this.total,
    this.isCurrency = false,
  });
  final String label;
  final double value;
  final double maxVal;
  final Color color;
  final Animation<double> animation;
  final int index;
  final int total;
  final bool isCurrency;

  String _format(double v) {
    if (!isCurrency) return v.toInt().toString();
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toInt().toString();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final localProgress = (animation.value * total - index).clamp(0.0, 1.0);
        final pct = maxVal == 0 ? 0.0 : (value / maxVal) * localProgress;
        
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Opacity(
                  opacity: localProgress,
                  child: Text(
                    _format(value),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: FractionallySizedBox(
                    heightFactor: pct.clamp(0.01, 1.0),
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            color,
                            color.withValues(alpha: 0.6),
                          ],
                        ),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PremiumDonutChart extends StatelessWidget {
  const _PremiumDonutChart({
    required this.values,
    required this.labels,
    required this.colors,
    required this.animation,
  });

  final List<double> values;
  final List<String> labels;
  final List<Color> colors;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final total = values.fold<double>(0, (a, b) => a + b);
    final presentPct = total == 0 ? 0 : (values[0] / total * 100).round();

    return Row(
      children: [
        Expanded(
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, _) {
              return CustomPaint(
                painter: _DonutPainter(values: values, colors: colors, progress: animation.value),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(presentPct * animation.value).round()}%',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: -1),
                      ),
                      Text(
                        'PRESENT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 24),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < labels.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colors[i],
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                           BoxShadow(color: colors[i].withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(labels[i], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                        Text(
                          '${values[i].toInt()} students',
                          style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
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
  const _DonutPainter({required this.values, required this.colors, required this.progress});

  final List<double> values;
  final List<Color> colors;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = min(size.width, size.height) * 0.45;
    final strokeWidth = radius * 0.28;

    final trackPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    final total = values.fold<double>(0, (a, b) => a + b);
    if (total == 0) return;

    var start = -pi / 2;
    for (var i = 0; i < values.length; i++) {
        if (values[i] == 0) continue;
      final sweep = (values[i] / total) * (pi * 2) * progress;
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      // Add a subtle outer glow to the arc
      final shadowPaint = Paint()
        ..color = colors[i].withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 4
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start, max(0.01, sweep - 0.05), false, shadowPaint);
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start, max(0.01, sweep - 0.05), false, paint);
      start += (values[i] / total) * (pi * 2);
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => old.progress != progress;
}
