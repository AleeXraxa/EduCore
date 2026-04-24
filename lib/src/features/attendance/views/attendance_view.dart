import 'package:educore/src/core/mvc/controller_builder.dart';
import 'package:educore/src/core/responsive/breakpoints.dart';
import 'package:educore/src/core/ui/widgets/app_dialogs.dart';
import 'package:educore/src/core/ui/widgets/kpi_card.dart';
import 'package:educore/src/features/attendance/controllers/attendance_controller.dart';
import 'package:educore/src/features/attendance/controllers/attendance_report_controller.dart';
import 'package:educore/src/features/attendance/models/attendance_record.dart';
import 'package:flutter/material.dart';
import 'package:educore/src/features/classes/models/institute_class.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:educore/src/core/ui/widgets/access_denied_view.dart';
import 'package:educore/src/core/services/app_services.dart';

class AttendanceView extends StatefulWidget {
  const AttendanceView({super.key});

  @override
  State<AttendanceView> createState() => _AttendanceViewState();
}

class _AttendanceViewState extends State<AttendanceView> {
  late final AttendanceController _controller;
  late final AttendanceReportController _reportController;
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _controller = AttendanceController();
    _reportController = AttendanceReportController();

    _controller.loadInitialData();
    _reportController.fetchReport();
    _searchController.addListener(() {
      _controller.setSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _reportController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _openMarkingPanel() {
    final width = MediaQuery.sizeOf(context).width;
    final size = screenSizeForWidth(width);

    if (size == ScreenSize.compact) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _AttendanceMarkingPanel(
          controller: _controller,
          searchController: _searchController,
          onSave: () => Navigator.pop(context),
        ),
      );
    } else {
      _scaffoldKey.currentState?.openEndDrawer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final featureSvc = AppServices.instance.featureAccessService;
    if (featureSvc == null || !featureSvc.canAccess('attendance_view')) {
      return const AccessDeniedView(featureName: 'Attendance Hub');
    }

    return ControllerBuilder<AttendanceController>(
      controller: _controller,
      builder: (context, controller, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final size = screenSizeForWidth(constraints.maxWidth);
            final isMobile = size == ScreenSize.compact;

            return DefaultTabController(
              length: 2,
              child: Scaffold(
                key: _scaffoldKey,
                backgroundColor: cs.surfaceContainerLowest.withValues(
                  alpha: 0.5,
                ),
                endDrawer: !isMobile
                    ? Drawer(
                        width: 500,
                        child: _AttendanceMarkingPanel(
                          controller: _controller,
                          searchController: _searchController,
                          onSave: () => Navigator.pop(context),
                        ),
                      )
                    : null,
                body: Column(
                  children: [
                    _AttendanceHeader(
                      controller: _controller,
                      onMarkPressed: _openMarkingPanel,
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _MarkingOverviewTab(
                            controller: _controller,
                            isMobile: isMobile,
                          ),
                          if (featureSvc.canAccess('attendance_reports'))
                            _ReportsTab(controller: _reportController)
                          else
                            const AccessDeniedView(featureName: 'Attendance Reports'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _AttendanceHeader extends StatelessWidget {
  const _AttendanceHeader({
    required this.controller,
    required this.onMarkPressed,
  });
  final AttendanceController controller;
  final VoidCallback onMarkPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDesktop =
        screenSizeForWidth(MediaQuery.sizeOf(context).width) !=
        ScreenSize.compact;

    return Container(
      color: cs.surface,
      padding: EdgeInsets.fromLTRB(
        isDesktop ? 32 : 16,
        24,
        isDesktop ? 32 : 16,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ATTENDANCE HUB',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEEE, MMM d, yyyy').format(DateTime.now()),
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                  ),
                ],
              ),
              const Spacer(),
              if (isDesktop && AppServices.instance.featureAccessService!.canAccess('attendance_mark'))
                FilledButton.icon(
                  onPressed: onMarkPressed,
                  icon: const Icon(Icons.edit_calendar_rounded, size: 18),
                  label: const Text('Mark Attendance'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'MARK ATTENDANCE'),
              Tab(text: 'ADVANCED REPORTS'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MarkingOverviewTab extends StatelessWidget {
  const _MarkingOverviewTab({required this.controller, required this.isMobile});
  final AttendanceController controller;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : 32,
        24,
        isMobile ? 16 : 32,
        80,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (controller.hasError) ...[
            _IndexErrorBanner(error: controller.error!),
            const SizedBox(height: 16),
          ],
          _AttendanceAnalytics(controller: controller),
          const SizedBox(height: 32),
          if (controller.attentionNeeded.isNotEmpty) ...[
            _AttentionNeededSection(controller: controller),
            const SizedBox(height: 32),
          ],
          Row(
            children: [
              Text(
                'CURRENT STATUS (OVERVIEW)',
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Divider(color: cs.outlineVariant.withValues(alpha: 0.5)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (controller.records.isEmpty)
            _EmptyAttendance()
          else
            _StatusOverviewGrid(controller: controller),
        ],
      ),
    );
  }
}

class _ReportsTab extends StatelessWidget {
  const _ReportsTab({required this.controller});
  final AttendanceReportController controller;

  @override
  Widget build(BuildContext context) {
    final isDesktop =
        screenSizeForWidth(MediaQuery.sizeOf(context).width) !=
        ScreenSize.compact;

    return ControllerBuilder<AttendanceReportController>(
      controller: controller,
      builder: (context, controller, _) {
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            isDesktop ? 32 : 16,
            24,
            isDesktop ? 32 : 16,
            80,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ReportFilters(controller: controller),
              const SizedBox(height: 24),
              _ReportSummaryCards(controller: controller),
              const SizedBox(height: 32),
              _ReportResultsTable(controller: controller),
            ],
          ),
        );
      },
    );
  }
}

class _ReportFilters extends StatelessWidget {
  const _ReportFilters({required this.controller});
  final AttendanceReportController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SegmentedButton<ReportType>(
          segments: const [
            ButtonSegment(
              value: ReportType.student,
              label: Text('Student'),
              icon: Icon(Icons.person_rounded, size: 16),
            ),
            ButtonSegment(
              value: ReportType.teacher,
              label: Text('Teacher'),
              icon: Icon(Icons.school_rounded, size: 16),
            ),
            ButtonSegment(
              value: ReportType.classroom,
              label: Text('Class'),
              icon: Icon(Icons.class_rounded, size: 16),
            ),
          ],
          selected: {controller.currentType},
          onSelectionChanged: (set) => controller.setReportType(set.first),
          showSelectedIcon: false,
          style: SegmentedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _FilterChip(
                label: 'Today',
                selected: controller.currentFilter == DateFilter.today,
                onTap: () => controller.setDateFilter(DateFilter.today),
              ),
              _FilterChip(
                label: '7D',
                selected: controller.currentFilter == DateFilter.last7,
                onTap: () => controller.setDateFilter(DateFilter.last7),
              ),
              _FilterChip(
                label: '30D',
                selected: controller.currentFilter == DateFilter.last30,
                onTap: () => controller.setDateFilter(DateFilter.last30),
              ),
              _FilterChip(
                label:
                    (controller.currentFilter == DateFilter.custom &&
                        controller.customRange != null)
                    ? '${DateFormat('MMM d').format(controller.customRange!.start)} - ${DateFormat('MMM d').format(controller.customRange!.end)}'
                    : 'Custom',
                selected: controller.currentFilter == DateFilter.custom,
                onTap: () async {
                  final range = await showDialog<DateTimeRange>(
                    context: context,
                    builder: (context) => _CustomRangeDialog(
                      initialRange: controller.customRange,
                    ),
                  );
                  if (range != null) {
                    controller.setCustomRange(range.start, range.end);
                  }
                },
              ),
            ],
          ),
        ),
        if (controller.busy)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? cs.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? cs.onPrimary : cs.onSurfaceVariant,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _ReportSummaryCards extends StatelessWidget {
  const _ReportSummaryCards({required this.controller});
  final AttendanceReportController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1200
            ? 4
            : (constraints.maxWidth > 600 ? 2 : 1);
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 2.5,
          children: [
            KpiCard(
              data: KpiCardData(
                label: 'Total Records',
                value: controller.totalRecords.toString(),
                icon: Icons.analytics_rounded,
                gradient: [Colors.blue, Colors.blue.shade700],
              ),
            ),
            KpiCard(
              data: KpiCardData(
                label: 'Avg. Attendance',
                value: '${controller.avgAttendance.toStringAsFixed(1)}%',
                icon: Icons.percent_rounded,
                gradient: [Colors.green, Colors.green.shade700],
              ),
            ),
            KpiCard(
              data: KpiCardData(
                label: 'Highest',
                value: controller.highestAttendance,
                icon: Icons.trending_up_rounded,
                gradient: [Colors.orange, Colors.orange.shade700],
                trendText: 'Attendance Streak',
                trendUp: true,
              ),
            ),
            KpiCard(
              data: KpiCardData(
                label: 'Lowest',
                value: controller.lowestAttendance,
                icon: Icons.trending_down_rounded,
                gradient: [Colors.red, Colors.red.shade700],
                trendText: 'Needs Attention',
                trendUp: false,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ReportResultsTable extends StatelessWidget {
  const _ReportResultsTable({required this.controller});
  final AttendanceReportController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            cs.surfaceContainerHighest.withValues(alpha: 0.3),
          ),
          columns: _buildColumns(),
          rows: controller.reportData
              .map((data) => _buildRow(data, cs))
              .toList(),
        ),
      ),
    );
  }

  List<DataColumn> _buildColumns() {
    final type = controller.currentType;
    if (type == ReportType.student) {
      return const [
        DataColumn(label: Text('STUDENT NAME')),
        DataColumn(label: Text('PRESENT')),
        DataColumn(label: Text('ABSENT')),
        DataColumn(label: Text('LEAVE')),
        DataColumn(label: Text('ATTENDANCE %')),
      ];
    } else if (type == ReportType.teacher) {
      return const [
        DataColumn(label: Text('TEACHER NAME')),
        DataColumn(label: Text('CLASSES')),
        DataColumn(label: Text('SESSIONS')),
        DataColumn(label: Text('AVG %')),
      ];
    } else {
      return const [
        DataColumn(label: Text('CLASS NAME')),
        DataColumn(label: Text('STUDENTS')),
        DataColumn(label: Text('SUMMARY')),
        DataColumn(label: Text('AVG %')),
      ];
    }
  }

  DataRow _buildRow(Map<String, dynamic> data, ColorScheme cs) {
    final type = controller.currentType;
    if (type == ReportType.student) {
      return DataRow(
        cells: [
          DataCell(
            Text(
              data['name'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataCell(Text((data['present'] ?? 0).toString())),
          DataCell(Text((data['absent'] ?? 0).toString())),
          DataCell(Text((data['leave'] ?? 0).toString())),
          DataCell(
            _buildPercentageCell((data['percentage'] ?? 0.0).toDouble()),
          ),
        ],
      );
    } else if (type == ReportType.teacher) {
      return DataRow(
        cells: [
          DataCell(
            Text(
              data['name'] ?? 'N/A',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataCell(Text(data['classes'] ?? '-')),
          DataCell(Text((data['sessions'] ?? 0).toString())),
          DataCell(
            _buildPercentageCell((data['percentage'] ?? 0.0).toDouble()),
          ),
        ],
      );
    } else {
      return DataRow(
        cells: [
          DataCell(
            Text(
              data['name'] ?? 'N/A',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataCell(Text((data['students'] ?? 0).toString())),
          DataCell(Text(data['summary'] ?? '-')),
          DataCell(
            _buildPercentageCell((data['percentage'] ?? 0.0).toDouble()),
          ),
        ],
      );
    }
  }

  Widget _buildPercentageCell(double pct) {
    final color = pct >= 90
        ? Colors.green
        : (pct >= 75 ? Colors.orange : Colors.red);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${pct.toStringAsFixed(1)}%',
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _DateNavigator extends StatelessWidget {
  const _DateNavigator({required this.currentDate, required this.onChanged});
  final DateTime currentDate;
  final Function(DateTime) onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dateStr = DateFormat('EEE, MMM d').format(currentDate);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () =>
                onChanged(currentDate.subtract(const Duration(days: 1))),
            icon: const Icon(Icons.chevron_left_rounded, size: 20),
            visualDensity: VisualDensity.compact,
          ),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: currentDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) onChanged(picked);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                dateStr,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () =>
                onChanged(currentDate.add(const Duration(days: 1))),
            icon: const Icon(Icons.chevron_right_rounded, size: 20),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _ClassSelector extends StatelessWidget {
  const _ClassSelector({this.selected, required this.onChanged, required this.classes});
  final InstituteClass? selected;
  final Function(InstituteClass?) onChanged;
  final List<InstituteClass> classes;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      height: 44,
      decoration: BoxDecoration(
        color: cs.secondaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<InstituteClass>(
          value: selected,
          hint: const Text('All Classes', style: TextStyle(fontSize: 13)),
          style: TextStyle(
            color: cs.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          items: classes
              .map((c) => DropdownMenuItem(value: c, child: Text(c.displayName)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _BulkActionButtons extends StatelessWidget {
  const _BulkActionButtons({required this.controller});
  final AttendanceController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: () => controller.markAll(AttendanceStatus.absent),
          icon: const Icon(Icons.close_rounded, size: 18),
          label: const Text('Mark Absent'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: () => controller.markAll(AttendanceStatus.leave),
          icon: const Icon(Icons.beach_access_rounded, size: 18),
          label: const Text('Mark Leave'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.orange,
            side: const BorderSide(color: Colors.orange),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilledButton.icon(
            onPressed: () => controller.markAll(AttendanceStatus.present),
            icon: const Icon(Icons.done_all_rounded, size: 18),
            label: const Text('Mark All Present'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}

class _AttendanceListItem extends StatelessWidget {
  const _AttendanceListItem({required this.record, required this.onChanged});
  final AttendanceRecord record;
  final Function(AttendanceStatus) onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: record.status == AttendanceStatus.present
              ? const Color(0xFF10B981).withValues(alpha: 0.3)
              : record.status == AttendanceStatus.absent
              ? Colors.red.withValues(alpha: 0.3)
              : record.status == AttendanceStatus.leave
              ? Colors.orange.withValues(alpha: 0.3)
              : cs.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          _Avatar(name: record.studentName),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.studentName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  '${record.className} • ${record.phone}',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                ),
              ],
            ),
          ),
          _PresenceToggle(status: record.status, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _PresenceToggle extends StatelessWidget {
  const _PresenceToggle({required this.status, required this.onChanged});
  final AttendanceStatus status;
  final Function(AttendanceStatus) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleButton(
            label: 'P',
            isActive: status == AttendanceStatus.present,
            activeColor: const Color(0xFF10B981),
            onTap: () => onChanged(AttendanceStatus.present),
          ),
          const SizedBox(width: 4),
          _ToggleButton(
            label: 'A',
            isActive: status == AttendanceStatus.absent,
            activeColor: const Color(0xFFEF4444),
            onTap: () => onChanged(AttendanceStatus.absent),
          ),
          const SizedBox(width: 4),
          _ToggleButton(
            label: 'L',
            isActive: status == AttendanceStatus.leave,
            activeColor: const Color(0xFFF59E0B),
            onTap: () => onChanged(AttendanceStatus.leave),
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        name[0].toUpperCase(),
        style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Search student...',
          hintStyle: TextStyle(
            fontSize: 14,
            color: cs.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          prefixIcon: Icon(Icons.search_rounded, color: cs.primary, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 11),
        ),
      ),
    );
  }
}

class _EmptyAttendance extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_note_rounded, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No students found',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            'Try changing the filters',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _AttendanceAnalytics extends StatelessWidget {
  const _AttendanceAnalytics({required this.controller});
  final AttendanceController controller;

  @override
  Widget build(BuildContext context) {
    final isDesktop =
        screenSizeForWidth(MediaQuery.sizeOf(context).width) !=
        ScreenSize.compact;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ANALYTICS & TRENDS',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 16),
        Flex(
          direction: isDesktop ? Axis.horizontal : Axis.vertical,
          children: [
            Expanded(
              flex: isDesktop ? 2 : 0,
              child: _AnalyticsBox(
                title: 'Weekly Percentage Trend',
                subtitle: 'Attendance rate over last 7 days',
                child: _LineChart(values: controller.weeklyTrend),
              ),
            ),
            SizedBox(width: isDesktop ? 20 : 0, height: isDesktop ? 0 : 20),
            Expanded(
              flex: 1,
              child: _AnalyticsBox(
                title: 'Today\'s Breakdown',
                subtitle: 'Present vs Absent ratio',
                child: _DonutChart(
                  present: controller.presentCount.toDouble(),
                  absent: controller.absentCount.toDouble(),
                  leave: controller.leaveCount.toDouble(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AttentionNeededSection extends StatelessWidget {
  const _AttentionNeededSection({required this.controller});
  final AttendanceController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'ATTENTION NEEDED',
              style: TextStyle(
                color: cs.error,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: cs.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${controller.attentionNeeded.length} Alerts',
                style: TextStyle(
                  color: cs.error,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: controller.attentionNeeded.map((alert) {
            final isCritical = alert['isCritical'] == true;
            return Container(
              width: 300,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (isCritical ? cs.error : Colors.orange).withValues(
                    alpha: 0.3,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: (isCritical ? cs.error : Colors.orange).withValues(
                        alpha: 0.1,
                      ),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      isCritical
                          ? Icons.emergency_rounded
                          : Icons.warning_amber_rounded,
                      color: isCritical ? cs.error : Colors.orange,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          alert['reason'],
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
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

class _AnalyticsBox extends StatelessWidget {
  const _AnalyticsBox({
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          Text(
            subtitle,
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
          ),
          const SizedBox(height: 24),
          SizedBox(height: 150, child: child),
        ],
      ),
    );
  }
}

class _LineChart extends StatelessWidget {
  const _LineChart({required this.values});
  final List<double> values;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return CustomPaint(
      painter: _LineChartPainter(values: values, color: cs.primary),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  const _LineChartPainter({required this.values, required this.color});
  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dx = size.width / (values.length - 1);
    const maxVal = 100.0;

    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final y = size.height - (values[i] / maxVal) * size.height;
      points.add(Offset(i * dx, y));
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final cur = points[i];
      path.cubicTo(
        prev.dx + dx * 0.5,
        prev.dy,
        cur.dx - dx * 0.5,
        cur.dy,
        cur.dx,
        cur.dy,
      );
    }

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.0)],
        ).createShader(Offset.zero & size),
    );

    canvas.drawPath(path, paint);

    for (final p in points) {
      canvas.drawCircle(p, 4, Paint()..color = Colors.white);
      canvas.drawCircle(p, 4, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter old) => old.values != values;
}

class _DonutChart extends StatelessWidget {
  const _DonutChart({
    required this.present,
    required this.absent,
    required this.leave,
  });
  final double present;
  final double absent;
  final double leave;

  @override
  Widget build(BuildContext context) {
    final total = present + absent + leave;
    final pct = total == 0 ? 0 : (present / total * 100).round();

    return Stack(
      children: [
        CustomPaint(
          size: Size.infinite,
          painter: _DonutChartPainter(
            values: [present, absent, leave],
            colors: [
              const Color(0xFF10B981),
              const Color(0xFFEF4444),
              const Color(0xFFF59E0B),
            ],
          ),
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$pct%',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              const Text(
                'Overall',
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  const _DonutChartPainter({required this.values, required this.colors});
  final List<double> values;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * 0.45;
    final total = values.fold(0.0, (a, b) => a + b);

    if (total == 0) return;

    final bgPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.3;

    canvas.drawCircle(center, radius, bgPaint);

    var start = -3.1415 / 2;
    for (var i = 0; i < values.length; i++) {
      final sweep = (values[i] / total) * 3.1415 * 2;
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.3
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start + 0.1,
        sweep - 0.2,
        false,
        paint,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter old) => old.values != values;
}

class _StatusOverviewGrid extends StatelessWidget {
  const _StatusOverviewGrid({required this.controller});
  final AttendanceController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        mainAxisExtent: 64,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: controller.records.length,
      itemBuilder: (context, index) {
        final r = controller.records[index];
        final isNone = r.status == AttendanceStatus.none;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              _Avatar(name: r.studentName),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.studentName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      r.className,
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isNone)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (r.status == AttendanceStatus.present
                                ? Colors.green
                                : r.status == AttendanceStatus.absent
                                ? Colors.red
                                : Colors.orange)
                            .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    r.status.name.toUpperCase(),
                    style: TextStyle(
                      color: r.status == AttendanceStatus.present
                          ? Colors.green
                          : r.status == AttendanceStatus.absent
                          ? Colors.red
                          : Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                )
              else
                Icon(
                  Icons.pending_actions_rounded,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                  size: 18,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _AttendanceMarkingPanel extends StatelessWidget {
  const _AttendanceMarkingPanel({
    required this.controller,
    required this.searchController,
    required this.onSave,
  });

  final AttendanceController controller;
  final TextEditingController searchController;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mq = MediaQuery.of(context);
    final isMobile = screenSizeForWidth(mq.size.width) == ScreenSize.compact;

    return Container(
      height: isMobile ? mq.size.height * 0.9 : double.infinity,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: isMobile
            ? const BorderRadius.vertical(top: Radius.circular(32))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 40,
            offset: const Offset(-10, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              children: [
                if (isMobile)
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: cs.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mark Attendance',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                          ),
                        ),
                        Text(
                          DateFormat(
                            'EEEE, MMM d',
                          ).format(controller.selectedDate),
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    _DateNavigator(
                      currentDate: controller.selectedDate,
                      onChanged: controller.setDate,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ClassSelector(
                        selected: controller.selectedClass,
                        onChanged: controller.setClass,
                        classes: controller.classes,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _SearchBar(controller: searchController),
                const SizedBox(height: 12),
                _BulkActionButtons(controller: controller),
              ],
            ),
          ),
          const Divider(height: 1),
          // List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: controller.records.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final r = controller.records[index];
                return _AttendanceListItem(
                  record: r,
                  onChanged: (status) =>
                      controller.updateStatus(r.studentId, status),
                );
              },
            ),
          ),
          // Footer
          Container(
            padding: EdgeInsets.fromLTRB(24, 16, 24, mq.padding.bottom + 16),
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(
                top: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      AppDialogs.showLoading(context, message: 'Saving records...');

                      try {
                        await controller.saveAttendance();
                        if (context.mounted) {
                          AppDialogs.hideLoading(context);
                          Navigator.pop(context);
                          AppDialogs.showSuccess(
                            context,
                            title: 'Attendance Saved',
                            message: 'Daily attendance records have been synchronized successfully.',
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          AppDialogs.hideLoading(context);
                          AppDialogs.showError(
                            context,
                            title: 'Submission Failed',
                            message: 'An error occurred while saving attendance records.',
                          );
                        }
                      }
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Save Attendance'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomRangeDialog extends StatefulWidget {
  const _CustomRangeDialog({this.initialRange});
  final DateTimeRange? initialRange;

  @override
  State<_CustomRangeDialog> createState() => _CustomRangeDialogState();
}

class _CustomRangeDialogState extends State<_CustomRangeDialog> {
  late DateTime _start;
  late DateTime _end;

  @override
  void initState() {
    super.initState();
    _start =
        widget.initialRange?.start ??
        DateTime.now().subtract(const Duration(days: 7));
    _end = widget.initialRange?.end ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        width: 440,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.date_range_rounded, color: cs.primary),
                ),
                const SizedBox(width: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Custom Range',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Choose start and end dates',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: _DateField(
                    label: 'Start Date',
                    value: _start,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _start,
                        firstDate: DateTime(2020),
                        lastDate: _end,
                      );
                      if (picked != null) setState(() => _start = picked);
                    },
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _DateField(
                    label: 'End Date',
                    value: _end,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _end,
                        firstDate: _start,
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setState(() => _end = picked);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: () => Navigator.pop(
                  context,
                  DateTimeRange(start: _start, end: _end),
                ),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Apply Selection',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });
  final String label;
  final DateTime value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: cs.onSurfaceVariant,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    DateFormat('MMM d, yyyy').format(value),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                Icon(Icons.calendar_today_rounded, size: 16, color: cs.primary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _IndexErrorBanner extends StatelessWidget {
  const _IndexErrorBanner({required this.error});
  final String error;

  String? _extractUrl(String text) {
    final regExp = RegExp(r'https://console\.firebase\.google\.com/[^\s]+');
    final match = regExp.firstMatch(text);
    return match?.group(0);
  }

  @override
  Widget build(BuildContext context) {
    final url = _extractUrl(error);
    final cs = Theme.of(context).colorScheme;

    if (url == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.errorContainer.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: cs.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                error,
                style: TextStyle(color: cs.error, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.amber),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'FIRESTORE INDEX MISSING',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Attendance sorting and filtering requires a composite index in Firestore. Please click the button below to create it automatically.',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => launchUrl(Uri.parse(url)),
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: const Text('Create Index Now'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
