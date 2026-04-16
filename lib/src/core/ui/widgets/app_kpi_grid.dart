import 'package:educore/src/core/ui/widgets/kpi_card.dart';
import 'package:flutter/material.dart';

/// A responsive grid for displaying KPI cards with consistent spacing.
class AppKpiGrid extends StatelessWidget {
  const AppKpiGrid({
    super.key,
    required this.columns,
    required this.items,
    this.gap = 12.0,
  });

  final int columns;
  final List<KpiCardData> items;
  final double gap;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalGap = gap * (columns - 1);
        final cardWidth = (constraints.maxWidth - totalGap) / columns;
        
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final item in items)
              SizedBox(
                width: cardWidth,
                child: KpiCard(data: item),
              ),
          ],
        );
      },
    );
  }
}
