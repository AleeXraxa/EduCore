import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppAttendanceHeatmap extends StatelessWidget {
  const AppAttendanceHeatmap({
    super.key,
    required this.data, // Map<DateTime, int> where int is the attendance count or intensity
  });

  final Map<DateTime, int> data;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final sixMonthsAgo = DateTime(now.year, now.month - 5, 1);
    
    // Generate all days for the last 6 months
    final allDays = <DateTime>[];
    var current = sixMonthsAgo;
    while (current.isBefore(now) || DateUtils.isSameDay(current, now)) {
      allDays.add(DateTime(current.year, current.month, current.day));
      current = current.add(const Duration(days: 1));
    }

    // Group days by week for the grid
    final weeks = <List<DateTime>>[];
    List<DateTime> currentWeek = [];
    
    // Pad first week if needed
    for (int i = 0; i < allDays.first.weekday % 7; i++) {
      currentWeek.add(DateTime(2000)); // Placeholder
    }

    for (var day in allDays) {
      currentWeek.add(day);
      if (currentWeek.length == 7) {
        weeks.add(currentWeek);
        currentWeek = [];
      }
    }
    if (currentWeek.isNotEmpty) {
      while (currentWeek.length < 7) {
        currentWeek.add(DateTime(2000)); // Placeholder
      }
      weeks.add(currentWeek);
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, cs),
          const SizedBox(height: 24),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWeekdayLabels(cs),
                const SizedBox(width: 8),
                ...weeks.map((week) => _buildWeekColumn(context, week, cs)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildLegend(cs),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme cs) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ATTENDANCE CONSISTENCY',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Activity density over last 6 months',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
            ),
          ],
        ),
        Icon(Icons.grid_view_rounded, color: cs.primary.withValues(alpha: 0.5)),
      ],
    );
  }

  Widget _buildWeekdayLabels(ColorScheme cs) {
    const labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return Column(
      children: labels.map((l) => Container(
        height: 14,
        width: 14,
        margin: const EdgeInsets.symmetric(vertical: 2),
        alignment: Alignment.center,
        child: Text(l, style: TextStyle(fontSize: 8, color: cs.onSurfaceVariant, fontWeight: FontWeight.bold)),
      )).toList(),
    );
  }

  Widget _buildWeekColumn(BuildContext context, List<DateTime> week, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        children: week.map((day) => _buildDaySquare(context, day, cs)).toList(),
      ),
    );
  }

  Widget _buildDaySquare(BuildContext context, DateTime day, ColorScheme cs) {
    if (day.year == 2000) {
      return Container(
        height: 14,
        width: 14,
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(3),
        ),
      );
    }

    final count = data[DateTime(day.year, day.month, day.day)] ?? 0;
    
    // Intensity mapping
    Color color;
    if (count == 0) {
      color = cs.surfaceContainerHighest.withValues(alpha: 0.3);
    } else if (count < 10) {
      color = cs.primary.withValues(alpha: 0.2);
    } else if (count < 30) {
      color = cs.primary.withValues(alpha: 0.4);
    } else if (count < 50) {
      color = cs.primary.withValues(alpha: 0.7);
    } else {
      color = cs.primary;
    }

    return Tooltip(
      message: '${DateFormat('MMM d, yyyy').format(day)}: $count present',
      child: Container(
        height: 14,
        width: 14,
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }

  Widget _buildLegend(ColorScheme cs) {
    return Row(
      children: [
        Text('Less', style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
        const SizedBox(width: 8),
        _legendSquare(cs.surfaceContainerHighest.withValues(alpha: 0.3)),
        _legendSquare(cs.primary.withValues(alpha: 0.2)),
        _legendSquare(cs.primary.withValues(alpha: 0.4)),
        _legendSquare(cs.primary.withValues(alpha: 0.7)),
        _legendSquare(cs.primary),
        const SizedBox(width: 8),
        Text('More', style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
      ],
    );
  }

  Widget _legendSquare(Color color) {
    return Container(
      height: 10,
      width: 10,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
