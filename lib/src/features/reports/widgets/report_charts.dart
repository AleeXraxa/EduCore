import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Revenue vs Expense bar chart for the Reports dashboard analytics section.
class RevenueExpenseChart extends StatelessWidget {
  const RevenueExpenseChart({
    super.key,
    required this.revenue,
    required this.expenses,
    required this.monthLabels,
  });

  final List<double> revenue;
  final List<double> expenses;
  final List<String> monthLabels;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fmt = NumberFormat.compact();
    final maxVal = [
      ...revenue,
      ...expenses,
      1.0,
    ].reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        maxY: maxVal * 1.25,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxVal / 4,
          getDrawingHorizontalLine: (value) => FlLine(
            color: cs.outlineVariant.withValues(alpha: 0.3),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 56,
              getTitlesWidget: (value, meta) => Text(
                fmt.format(value),
                style: TextStyle(
                  fontSize: 10,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= monthLabels.length) {
                  return const SizedBox.shrink();
                }
                final parts = monthLabels[idx].split('-');
                final label = parts.length == 2
                    ? _monthAbbr(int.tryParse(parts[1]) ?? 0)
                    : monthLabels[idx];
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: List.generate(monthLabels.length, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: revenue.length > i ? revenue[i] : 0,
                color: const Color(0xFF2563EB),
                width: 12,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
              BarChartRodData(
                toY: expenses.length > i ? expenses[i] : 0,
                color: const Color(0xFFE11D48),
                width: 12,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ],
          );
        }),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => cs.surface,
            tooltipBorder: BorderSide(color: cs.outlineVariant),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final label = rodIndex == 0 ? 'Revenue' : 'Expenses';
              return BarTooltipItem(
                '$label\nRs. ${NumberFormat('#,##0').format(rod.toY)}',
                TextStyle(
                  color: rod.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  String _monthAbbr(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return month >= 1 && month <= 12 ? months[month] : '';
  }
}

/// Donut chart for expense categories.
class ExpenseCategoryDonut extends StatefulWidget {
  const ExpenseCategoryDonut({
    super.key,
    required this.data,
  });

  final Map<String, double> data;

  @override
  State<ExpenseCategoryDonut> createState() => _ExpenseCategoryDonutState();
}

class _ExpenseCategoryDonutState extends State<ExpenseCategoryDonut> {
  int _touched = -1;

  static const _palette = [
    Color(0xFF2563EB),
    Color(0xFFE11D48),
    Color(0xFFF59E0B),
    Color(0xFF0D9488),
    Color(0xFF7C3AED),
    Color(0xFF0891B2),
    Color(0xFF16A34A),
    Color(0xFF64748B),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final entries = widget.data.entries.toList();
    final total = entries.fold(0.0, (s, e) => s + e.value);

    if (entries.isEmpty) {
      return Center(
        child: Text(
          'No expense data',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      _touched = -1;
                    } else {
                      _touched = pieTouchResponse
                          .touchedSection!.touchedSectionIndex;
                    }
                  });
                },
              ),
              sections: entries.asMap().entries.map((e) {
                final isTouched = e.key == _touched;
                final pct = total > 0 ? (e.value.value / total * 100) : 0.0;
                return PieChartSectionData(
                  color: _palette[e.key % _palette.length],
                  value: e.value.value,
                  title: '${pct.toStringAsFixed(1)}%',
                  radius: isTouched ? 60 : 50,
                  titleStyle: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Legend
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: entries.asMap().entries.map((e) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _palette[e.key % _palette.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    e.value.key,
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Rs. ${NumberFormat.compact().format(e.value.value)}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// P&L line chart.
class ProfitLossLineChart extends StatelessWidget {
  const ProfitLossLineChart({
    super.key,
    required this.plValues,
    required this.labels,
  });

  final List<double> plValues;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (plValues.isEmpty) return const SizedBox.shrink();

    final maxAbs = plValues.map((v) => v.abs()).reduce((a, b) => a > b ? a : b);
    final maxY = maxAbs * 1.3;

    return LineChart(
      LineChartData(
        minY: -maxY,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: cs.outlineVariant.withValues(alpha: 0.3),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (value, _) => Text(
                NumberFormat.compact().format(value),
                style: TextStyle(fontSize: 9, color: cs.onSurfaceVariant),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                final idx = value.toInt();
                if (idx < 0 || idx >= labels.length) {
                  return const SizedBox.shrink();
                }
                final parts = labels[idx].split('-');
                final lbl = parts.length == 2
                    ? '${_monthAbbr(int.tryParse(parts[1]) ?? 0)} ${parts[0].substring(2)}'
                    : labels[idx];
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    lbl,
                    style: TextStyle(
                        fontSize: 9,
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: plValues.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
            isCurved: true,
            color: const Color(0xFF10B981),
            barWidth: 2.5,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF10B981).withValues(alpha: 0.15),
                  const Color(0xFF10B981).withValues(alpha: 0.01),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: 0,
              color: cs.outlineVariant,
              strokeWidth: 1,
              dashArray: [4, 4],
            ),
          ],
        ),
      ),
    );
  }

  String _monthAbbr(int month) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return month >= 1 && month <= 12 ? months[month] : '';
  }
}
