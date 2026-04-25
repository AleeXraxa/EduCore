import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:educore/src/core/ui/widgets/app_button.dart';
import 'package:educore/src/core/ui/widgets/app_dropdown.dart';
import 'package:educore/src/features/reports/controllers/reports_controller.dart';
import 'package:educore/src/features/reports/models/report_config.dart';

/// Left-side filter panel shown beside the preview table.
class ReportFilterPanel extends StatelessWidget {
  const ReportFilterPanel({super.key, required this.controller});

  final ReportsController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final meta = controller.selectedReport;
    if (meta == null) return const SizedBox.shrink();

    final showClassFilter = _needsClass(meta.type);
    final showStudentFilter = _needsStudent(meta.type);
    final showStatusFilter = _needsStatus(meta.type);
    final showDateFilter = _needsDate(meta.type);
    final showYearFilter = _needsYear(meta.type);

    if (!showClassFilter && !showStudentFilter && !showStatusFilter && !showDateFilter && !showYearFilter) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.tune_rounded, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Text(
                'Filters',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const Spacer(),
              if (controller.filters.hasAnyFilter)
                TextButton(
                  onPressed: controller.clearFilters,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Clear',
                    style: TextStyle(fontSize: 11, color: cs.error),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              if (showClassFilter)
                SizedBox(
                  width: 220,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _label(context, 'CLASS'),
                      const SizedBox(height: 6),
                      AppDropdown<Map<String, String>?>(
                        label: 'Class',
                        showLabel: false,
                        compact: true,
                        value: controller.filters.classId == null
                            ? null
                            : controller.availableClasses
                                .where((c) =>
                                    c['id'] == controller.filters.classId)
                                .firstOrNull,
                        items: [null, ...controller.availableClasses],
                        itemLabel: (c) =>
                            c == null ? 'All Classes' : (c['name'] ?? ''),
                        onChanged: (val) => controller.updateClassFilter(
                          val?['id'],
                          val?['name'],
                        ),
                      ),
                    ],
                  ),
                ),
              if (showStudentFilter && controller.filters.classId != null)
                SizedBox(
                  width: 220,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _label(context, 'STUDENT'),
                      const SizedBox(height: 6),
                      AppDropdown<Map<String, String>?>(
                        label: 'Student',
                        showLabel: false,
                        compact: true,
                        searchable: true,
                        value: controller.filters.studentId == null
                            ? null
                            : controller.availableStudents
                                .where((s) =>
                                    s['id'] == controller.filters.studentId)
                                .firstOrNull,
                        items: [null, ...controller.availableStudents],
                        itemLabel: (s) =>
                            s == null ? 'All Students' : (s['name'] ?? ''),
                        onChanged: (val) => controller.updateStudentFilter(
                          val?['id'],
                          val?['name'],
                        ),
                      ),
                    ],
                  ),
                ),
              if (showStatusFilter)
                SizedBox(
                  width: 180,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _label(context, 'STATUS'),
                      const SizedBox(height: 6),
                      AppDropdown<String?>(
                        label: 'Status',
                        showLabel: false,
                        compact: true,
                        value: controller.filters.status,
                        items: const [
                          null,
                          'active',
                          'inactive',
                          'paid',
                          'pending',
                          'partial'
                        ],
                        itemLabel: (s) =>
                            s == null ? 'All Statuses' : _capitalize(s),
                        onChanged: controller.updateStatusFilter,
                      ),
                    ],
                  ),
                ),
              if (showYearFilter)
                SizedBox(
                  width: 140,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _label(context, 'YEAR'),
                      const SizedBox(height: 6),
                      AppDropdown<int?>(
                        label: 'Year',
                        showLabel: false,
                        compact: true,
                        value: controller.filters.year,
                        items: [
                          null,
                          ...List.generate(5, (i) => DateTime.now().year - i)
                        ],
                        itemLabel: (y) => y == null ? 'All Years' : y.toString(),
                        onChanged: controller.updateYearFilter,
                      ),
                    ],
                  ),
                ),
              if (showDateFilter)
                SizedBox(
                  width: 240,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _label(context, 'DATE RANGE'),
                      const SizedBox(height: 6),
                      _DateRangeButton(controller: controller),
                    ],
                  ),
                ),
              AppButton(
                label: 'Generate Report',
                icon: Icons.play_arrow_rounded,
                onPressed: controller.generateReport,
                busy: controller.isGenerating,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _label(BuildContext context, String text) => Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      );

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  bool _needsClass(ReportType t) => const {
        ReportType.classWiseStudents,
        ReportType.attendanceByClass,
        ReportType.attendanceByStudent,
        ReportType.examResults,
        ReportType.testResults,
        ReportType.paidFees,
        ReportType.pendingFees,
        ReportType.partialFees,
        ReportType.feeCollectionByDate,
        ReportType.studentFeeHistory,
        ReportType.monthlyFeeReport,
      }.contains(t);

  bool _needsStatus(ReportType t) => const {
        ReportType.studentList,
      }.contains(t);

  bool _needsDate(ReportType t) => const {
        ReportType.attendanceByStudent,
        ReportType.attendanceSummary,
        ReportType.feeCollectionByDate,
        ReportType.expenseList,
        ReportType.monthlyExpenseSummary,
      }.contains(t);

  bool _needsStudent(ReportType t) => const {
        ReportType.attendanceByStudent,
        ReportType.studentFeeHistory,
      }.contains(t);

  bool _needsYear(ReportType t) => const {
        ReportType.profitLossYearly,
        ReportType.profitLossMonthly,
      }.contains(t);
}

class _DateRangeButton extends StatelessWidget {
  const _DateRangeButton({required this.controller});
  final ReportsController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fmt = DateFormat('dd MMM yy');
    final start = controller.filters.startDate;
    final end = controller.filters.endDate;
    final label = start != null && end != null
        ? '${fmt.format(start)} – ${fmt.format(end)}'
        : 'Pick date range';

    return InkWell(
      onTap: () async {
        final range = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          initialDateRange: controller.selectedDateRange,
          builder: (ctx, child) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400, maxHeight: 520),
              child: Dialog(
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
                child: child,
              ),
            ),
          ),
        );
        if (range != null) {
          controller.updateDateRange(range.start, range.end);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, size: 16, color: cs.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: start != null ? cs.onSurface : cs.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (start != null)
              GestureDetector(
                onTap: () => controller.updateDateRange(null, null),
                child: Icon(Icons.close, size: 14, color: cs.onSurfaceVariant),
              ),
          ],
        ),
      ),
    );
  }
}
