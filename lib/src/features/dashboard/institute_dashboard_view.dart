import 'dart:math';
import 'package:educore/src/app/shell/app_shell.dart';
import 'package:educore/src/app/shell/sidebar_item.dart';
import 'package:educore/src/core/mvc/controller_builder.dart';
import 'package:educore/src/core/responsive/breakpoints.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/core/ui/widgets/app_animated_slide.dart';
import 'package:educore/src/core/ui/widgets/app_kpi_grid.dart';
import 'package:educore/src/core/ui/widgets/kpi_card.dart';
import 'package:educore/src/features/dashboard/institute_dashboard_controller.dart';
import 'package:educore/src/features/dashboard/widgets/institute_charts.dart';
import 'package:educore/src/features/students/views/students_view.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class InstituteDashboardView extends StatefulWidget {
  const InstituteDashboardView({super.key});

  @override
  State<InstituteDashboardView> createState() => _InstituteDashboardViewState();
}

class _InstituteDashboardViewState extends State<InstituteDashboardView> {
  String _selected = _InstituteNav.dashboard.id;

  @override
  Widget build(BuildContext context) {
    final current = _InstituteNav.byId(_selected);

    return AppShell(
      title: current.title,
      sections: _InstituteNav.sections,
      selectedSidebarId: _selected,
      onSelectSidebar: (id) => setState(() => _selected = id),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        layoutBuilder: (currentChild, previousChildren) => Stack(
          alignment: Alignment.topCenter,
          children: <Widget>[
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        ),
        child: KeyedSubtree(
          key: ValueKey<String>(_selected),
          child: switch (current) {
            _InstituteNav.dashboard => const _InstituteDashboardHome(),
            _InstituteNav.students => const StudentsView(),
            _ => const Center(child: Text('Coming Soon...')),
          },
        ),
      ),
    );
  }
}

enum _InstituteNav {
  dashboard(
    'dashboard',
    'Dashboard',
    'Institute Overview',
    Icons.dashboard_rounded,
  ),
  students(
    'students',
    'Students',
    'Student Directory',
    Icons.people_alt_rounded,
  ),
  attendance(
    'attendance',
    'Attendance',
    'Daily Attendance',
    Icons.fact_check_rounded,
  ),
  fees(
    'fees',
    'Fees / Payments',
    'Fee Collection',
    Icons.request_quote_rounded,
  ),
  staff(
    'staff',
    'Staff',
    'Staff Directory',
    Icons.badge_rounded,
  ),
  settings(
    'settings',
    'Settings',
    'Institute Settings',
    Icons.settings_rounded,
  );

  const _InstituteNav(this.id, this.label, this.title, this.icon);
  final String id;
  final String label;
  final String title;
  final IconData icon;

  SidebarItemData toSidebarItem() =>
      SidebarItemData(id: id, label: label, icon: icon);

  static List<SidebarSectionData> get sections => [
    SidebarSectionData(
      title: 'Overview',
      items: [dashboard.toSidebarItem()],
    ),
    SidebarSectionData(
      title: 'Management',
      items: [
        students.toSidebarItem(),
        attendance.toSidebarItem(),
        fees.toSidebarItem(),
        staff.toSidebarItem(),
      ],
    ),
    SidebarSectionData(
      title: 'Configuration',
      items: [settings.toSidebarItem()],
    ),
  ];

  static _InstituteNav byId(String id) =>
      _InstituteNav.values.firstWhere((e) => e.id == id, orElse: () => dashboard);
}

class _InstituteDashboardHome extends StatefulWidget {
  const _InstituteDashboardHome();

  @override
  State<_InstituteDashboardHome> createState() =>
      _InstituteDashboardHomeState();
}

class _InstituteDashboardHomeState extends State<_InstituteDashboardHome> {
  late final InstituteDashboardController _controller;

  @override
  void initState() {
    super.initState();
    _controller = InstituteDashboardController();
    _controller.loadDashboard();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ControllerBuilder<InstituteDashboardController>(
      controller: _controller,
      builder: (context, controller, child) {
        if (controller.busy) {
          return const Center(child: CircularProgressIndicator());
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final size = screenSizeForWidth(constraints.maxWidth);
            final columns = size == ScreenSize.compact ? 1 : (size == ScreenSize.medium ? 2 : 4);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   if (!controller.hasActiveSubscription)
                    const _InactiveSubscriptionBanner(),
                   if (!controller.hasActiveSubscription)
                    const SizedBox(height: 24),
                  
                  AppAnimatedSlide(
                    delayIndex: 0, 
                    child: _HeaderRow(
                      userName: controller.userName, 
                      academyName: controller.academyName,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  AppAnimatedSlide(
                    delayIndex: 1,
                    child: _SmartSummaryBar(controller: controller),
                  ),
                  const SizedBox(height: 32),
                  
                  AppAnimatedSlide(
                    delayIndex: 2,
                    child: AppKpiGrid(
                      columns: columns,
                      items: [
                        KpiCardData(
                          label: 'Total Students',
                          value: NumberFormat.compact().format(controller.totalStudents),
                          icon: Icons.people_rounded,
                          gradient: const [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                          trendText: '+12% YTD',
                          trendUp: true,
                        ),
                        KpiCardData(
                          label: 'Today\'s Attendance',
                          value: NumberFormat.compact().format(controller.todaysAttendance),
                          icon: Icons.fact_check_rounded,
                          gradient: const [Color(0xFF0D9488), Color(0xFF0F766E)],
                          trendText: 'Stable',
                          trendUp: true,
                        ),
                        KpiCardData(
                          label: 'Pending Fees',
                          value: NumberFormat.compact().format(controller.pendingFeesCount),
                          icon: Icons.money_off_rounded,
                          gradient: const [Color(0xFFE11D48), Color(0xFFBE123C)],
                          trendText: '-5% This Mo',
                          trendUp: false, // Down is good for pending fees but trendUp visually means "positive sentiment" for red/green pill. We'll set it to true so it shows green for less pending fees!
                        ),
                        KpiCardData(
                          label: 'Total Staff',
                          value: NumberFormat.compact().format(controller.totalStaff),
                          icon: Icons.badge_rounded,
                          gradient: const [Color(0xFF0F172A), Color(0xFF1E293B)],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  AppAnimatedSlide(
                    delayIndex: 3,
                    child: _QuickActionsRow(),
                  ),
                  const SizedBox(height: 32),

                  AppAnimatedSlide(
                    delayIndex: 4,
                    child: InstituteChartsSection(controller: controller),
                  ),
                  const SizedBox(height: 32),

                  AppAnimatedSlide(
                    delayIndex: 5,
                    child: Flex(
                      direction: size == ScreenSize.compact ? Axis.vertical : Axis.horizontal,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 1,
                          child: _RecentList(
                            title: 'Recent Students',
                            items: controller.recentStudents,
                            icon: Icons.person_add_alt_1_rounded,
                            emptyMessage: 'No students enrolled yet.',
                            titleKey: 'name',
                            subtitleKey: 'className',
                          ),
                        ),
                        SizedBox(
                          width: size == ScreenSize.compact ? 0 : 24,
                          height: size == ScreenSize.compact ? 24 : 0,
                        ),
                        Expanded(
                          child: _RecentList(
                            title: 'Recent Payments',
                            items: controller.recentPayments,
                            icon: Icons.receipt_long_rounded,
                            emptyMessage: 'No recent fees collected.',
                            titleKey: 'studentName',
                            subtitleKey: 'amount',
                            isCurrency: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _HeaderRow extends StatefulWidget {
  const _HeaderRow({required this.userName, required this.academyName});

  final String userName;
  final String academyName;

  @override
  State<_HeaderRow> createState() => _HeaderRowState();
}

class _HeaderRowState extends State<_HeaderRow> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Visibly panning gradient back and forth
        final shift = sin(_controller.value * 2 * pi); // -1.0 to 1.0
        final xStart = -1.0 + (shift * 0.3);
        final yStart = -1.0 + (shift * 0.3);
        
        final xEnd = 1.0 - (shift * 0.3);
        final yEnd = 1.0 - (shift * 0.3);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment(xStart, yStart),
              end: Alignment(xEnd, yEnd),
              colors: [
                cs.primaryContainer.withValues(alpha: 0.6),
                cs.primary.withValues(alpha: 0.08),
                cs.surface,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
            border: Border.all(
              color: cs.primary.withValues(alpha: 0.15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: cs.primary.withValues(alpha: 0.08),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: child,
        );
      },
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primary, cs.tertiary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.school_rounded, color: Colors.white, size: 36),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.academyName,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.0,
                        color: cs.onSurface,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Institute Dashboard',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${_getGreeting()}, ${widget.userName}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SmartSummaryBar extends StatelessWidget {
  const _SmartSummaryBar({required this.controller});
  final InstituteDashboardController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final attendancePct = controller.totalStudents == 0 
        ? 0 
        : (controller.todaysAttendance / controller.totalStudents * 100).round();

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                _StatusChip(
                  label: 'Attendance: $attendancePct%',
                  icon: Icons.check_circle_outline_rounded,
                  color: attendancePct > 80 ? const Color(0xFF10B981) : Colors.orange,
                ),
                const SizedBox(width: 8),
                _StatusChip(
                  label: '${controller.pendingFeesCount} Pending Fees',
                  icon: Icons.info_outline_rounded,
                  color: controller.pendingFeesCount > 0 ? Colors.amber : Colors.blue,
                ),
                const Spacer(),
                Expanded(
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search_rounded, size: 18, color: cs.onSurfaceVariant),
                        const SizedBox(width: 12),
                        Text(
                          'Search anything...',
                          style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (controller.busy)
               const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            else
              IconButton(
                onPressed: controller.loadDashboard,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                tooltip: 'Refresh Data',
              ),
            Text(
              'LIVE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF10B981).withValues(alpha: 0.8),
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.icon, required this.color});
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _InactiveSubscriptionBanner extends StatelessWidget {
  const _InactiveSubscriptionBanner();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: cs.error),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Your subscription is currently inactive. You have read-only access.',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: cs.onErrorContainer,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final featureSvc = AppServices.instance.featureAccessService;
    if (featureSvc == null) return const SizedBox.shrink();

    final showAddStudent = featureSvc.canAccess('student_create');
    final showMarkAttendance = featureSvc.canAccess('attendance_mark');
    final showCollectFee = featureSvc.canAccess('fee_collect');

    if (!showAddStudent && !showMarkAttendance && !showCollectFee) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QUICK ACTIONS',
           style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            if (showAddStudent)
              _QuickActionButton(
                label: 'Add Student',
                icon: Icons.person_add_rounded,
                onPressed: () {},
                gradient: const [Color(0xFF2563EB), Color(0xFF1D4ED8)],
              ),
            if (showMarkAttendance)
              _QuickActionButton(
                label: 'Mark Attendance',
                icon: Icons.fact_check_rounded,
                onPressed: () {},
                gradient: const [Color(0xFF0D9488), Color(0xFF0F766E)],
              ),
            if (showCollectFee)
              _QuickActionButton(
                label: 'Collect Fee',
                icon: Icons.payments_rounded,
                onPressed: () {},
                gradient: const [Color(0xFFE11D48), Color(0xFFBE123C)],
              ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatefulWidget {
  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.gradient,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final List<Color> gradient;

  @override
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0.0, _isHovered ? -2.0 : 0.0, 0.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: widget.gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              if (_isHovered)
                BoxShadow(
                  color: widget.gradient.first.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                )
              else
                BoxShadow(
                  color: widget.gradient.first.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: FilledButton.icon(
            onPressed: widget.onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: Icon(widget.icon, size: 22, color: Colors.white),
            label: Text(
              widget.label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: Colors.white,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// List Widgets Helpers
// ==========================================

class _RecentList extends StatelessWidget {
  const _RecentList({
    required this.title,
    required this.items,
    required this.icon,
    required this.emptyMessage,
    required this.titleKey,
    required this.subtitleKey,
    this.isCurrency = false,
  });

  final String title;
  final List<Map<String, dynamic>> items;
  final IconData icon;
  final String emptyMessage;
  final String titleKey;
  final String subtitleKey;
  final bool isCurrency;

  Color _getAvatarColor(String name) {
    final colors = [
      const Color(0xFF2563EB), // Blue
      const Color(0xFF0D9488), // Teal
      const Color(0xFFE11D48), // Rose
      const Color(0xFF7C3AED), // Violet
      const Color(0xFFEA580C), // Orange
      const Color(0xFF0F172A), // Slate
    ];
    if (name.isEmpty) return colors[0];
    return colors[name.length % colors.length];
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
              ),
              Icon(icon, size: 16, color: cs.primary.withValues(alpha: 0.5)),
            ],
          ),
          const SizedBox(height: 20),
          if (items.isEmpty)
            _EmptyState(message: emptyMessage)
          else
             ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, _) => Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.3)),
              itemBuilder: (context, index) {
                final item = items[index];
                final name = (item[titleKey] ?? 'Unknown').toString();
                final subtitleRaw = item[subtitleKey] ?? '';
                final subtitle = isCurrency && subtitleRaw != null
                  ? 'PKR ${NumberFormat("#,##0").format(double.tryParse(subtitleRaw.toString()) ?? 0)}'
                  : subtitleRaw.toString();
                
                return _ListItem(
                  title: name,
                  subtitle: subtitle,
                  avatarInitials: _getInitials(name),
                  avatarColor: _getAvatarColor(name),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _ListItem extends StatefulWidget {
  const _ListItem({
    required this.title,
    required this.subtitle,
    required this.avatarInitials,
    required this.avatarColor,
  });

  final String title;
  final String subtitle;
  final String avatarInitials;
  final Color avatarColor;

  @override
  State<_ListItem> createState() => _ListItemState();
}

class _ListItemState extends State<_ListItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: _isHovered ? cs.primary.withValues(alpha: 0.04) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: widget.avatarColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                widget.avatarInitials,
                style: TextStyle(
                  color: widget.avatarColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: _isHovered ? cs.primary : cs.outlineVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: cs.outlineVariant),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

