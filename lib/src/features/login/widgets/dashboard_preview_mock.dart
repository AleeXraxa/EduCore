import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:flutter/material.dart';

class DashboardPreviewMock extends StatelessWidget {
  const DashboardPreviewMock({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AspectRatio(
      aspectRatio: 16 / 10,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: AppRadii.r20,
          boxShadow: AppShadows.soft(Colors.black.withValues(alpha: 0.08)),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.65)),
        ),
        child: ClipRRect(
          borderRadius: AppRadii.r20,
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        cs.primary.withValues(alpha: 0.06),
                        cs.secondary.withValues(alpha: 0.04),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                top: 14,
                child: Row(
                  children: [
                    const _Dot(color: Color(0xFFEF4444)),
                    const SizedBox(width: 6),
                    const _Dot(color: Color(0xFFF59E0B)),
                    const SizedBox(width: 6),
                    const _Dot(color: Color(0xFF22C55E)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 28,
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: cs.primary.withValues(alpha: 0.12),
                      child: Text(
                        'E',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 14,
                top: 56,
                bottom: 14,
                child: Container(
                  width: 68,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
              Positioned(
                left: 94,
                right: 14,
                top: 56,
                bottom: 14,
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Expanded(child: _KpiChip(label: 'Students', value: '1,248')),
                        SizedBox(width: 10),
                        Expanded(child: _KpiChip(label: 'Revenue', value: 'PKR 420k')),
                        SizedBox(width: 10),
                        Expanded(child: _KpiChip(label: 'Attendance', value: '92%')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: CustomPaint(
                          painter: _MiniChartPainter(
                            stroke: cs.primary.withValues(alpha: 0.65),
                          ),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 18,
                bottom: 18,
                child: _FloatingCard(
                  title: 'Profit (MTD)',
                  value: 'PKR 155k',
                  tint: cs.tertiary,
                ),
              ),
              Positioned(
                left: 110,
                bottom: 22,
                child: _FloatingCard(
                  title: 'Fees Collected',
                  value: 'Today',
                  tint: cs.secondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _KpiChip extends StatelessWidget {
  const _KpiChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}

class _FloatingCard extends StatelessWidget {
  const _FloatingCard({
    required this.title,
    required this.value,
    required this.tint,
  });

  final String title;
  final String value;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.soft(Colors.black.withValues(alpha: 0.10)),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.auto_graph_rounded, color: tint, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniChartPainter extends CustomPainter {
  _MiniChartPainter({required this.stroke});
  final Color stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final h = size.height;
    final w = size.width;
    path.moveTo(w * 0.08, h * 0.70);
    path.cubicTo(w * 0.22, h * 0.55, w * 0.34, h * 0.85, w * 0.46, h * 0.60);
    path.cubicTo(w * 0.58, h * 0.35, w * 0.72, h * 0.72, w * 0.86, h * 0.40);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MiniChartPainter oldDelegate) =>
      oldDelegate.stroke != stroke;
}
