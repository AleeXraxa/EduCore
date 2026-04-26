import 'dart:math';
import 'package:educore/src/app/theme/app_tokens.dart';
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
import 'package:educore/src/features/classes/views/classes_view.dart';
import 'package:educore/src/features/students/views/students_view.dart';
import 'package:educore/src/features/attendance/views/attendance_view.dart';
import 'package:educore/src/features/staff/views/staff_list_view.dart';
import 'package:educore/src/features/fees/views/fee_plans_view.dart';
import 'package:educore/src/features/fees/views/fees_view.dart';
import 'package:educore/src/features/exams/views/exams_view.dart';
import 'package:educore/src/features/monthly_tests/views/monthly_tests_view.dart';
import 'package:educore/src/features/certificates/views/certificates_view.dart';
import 'package:educore/src/features/expenses/views/expenses_view.dart';
import 'package:educore/src/features/notifications/notifications_view.dart';
import 'package:educore/src/features/reports/views/reports_view.dart';
import 'package:educore/src/features/settings/settings_view.dart';
import 'package:educore/src/core/ui/widgets/access_denied_view.dart';
import 'package:educore/src/core/ui/widgets/app_shimmer.dart';
import 'package:educore/src/features/dashboard/widgets/app_pulse_feed.dart';
import 'package:educore/src/features/dashboard/widgets/attendance_heatmap.dart';
import 'package:educore/src/features/dashboard/models/dashboard_view_models.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class InstituteDashboardView extends StatefulWidget {
  const InstituteDashboardView({super.key});

  @override
  State<InstituteDashboardView> createState() => _InstituteDashboardViewState();
}

class _InstituteDashboardViewState extends State<InstituteDashboardView> {
  String _selected = _InstituteNav.dashboard.id;

  void _navigateTo(_InstituteNav nav) {
    setState(() => _selected = nav.id);
  }

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
          child: _buildBody(current),
        ),
      ),
    );
  }

  Widget _buildBody(_InstituteNav nav) {
    if (nav.featureKey != null) {
      final hasAccess = AppServices.instance.featureAccessService?.canAccess(nav.featureKey!) ?? true;
      if (!hasAccess) {
        return AccessDeniedView(featureName: nav.label);
      }
    }
    
    return switch (nav) {
      _InstituteNav.dashboard => const _InstituteDashboardHome(),
      _InstituteNav.students => const StudentsView(),
      _InstituteNav.classes => const ClassesView(),
      _InstituteNav.attendance => const AttendanceView(),
      _InstituteNav.expenses => const ExpensesView(),
      _InstituteNav.fees => const FeesView(),
      _InstituteNav.exams => const ExamsView(),
      _InstituteNav.monthlyTests => const MonthlyTestsView(),
      _InstituteNav.certificates => const CertificatesView(),
      _InstituteNav.feePlans => const FeePlansView(),
      _InstituteNav.staff => const StaffListView(),
      _InstituteNav.reports => const ReportsView(),
      _InstituteNav.notifications => const NotificationsView(), // This will be the NEW view
      _InstituteNav.settings => const SettingsView(),
    };
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
    featureKey: 'student_view',
  ),
  classes(
    'classes',
    'Classes',
    'Class Management',
    Icons.class_rounded,
    featureKey: 'class_view',
  ),
  attendance(
    'attendance',
    'Attendance',
    'Daily Attendance',
    Icons.fact_check_rounded,
    featureKey: 'attendance_mark',
  ),
  expenses(
    'expenses',
    'Expense Management',
    'Expenses & P/L',
    Icons.account_balance_wallet_rounded,
    featureKey: 'expense_view',
  ),
  fees(
    'fees',
    'Fees / Payments',
    'Fee Collection',
    Icons.request_quote_rounded,
    featureKey: 'fee_view',
  ),
  feePlans(
    'fee_plans',
    'Fee Plans',
    'Pricing Structures',
    Icons.payments_rounded,
    featureKey: 'fee_plan_view',
  ),
  staff(
    'staff',
    'Staff',
    'Staff Directory',
    Icons.badge_rounded,
    featureKey: 'staff_view',
  ),
  exams(
    'exams',
    'Exams & Results',
    'Academic Assessments',
    Icons.assessment_rounded,
    featureKey: 'exam_view',
  ),
  monthlyTests(
    'monthly_tests',
    'Monthly Tests',
    'Monthly Assessments',
    Icons.quiz_rounded,
    featureKey: 'monthly_test_view',
  ),
  certificates(
    'certificates',
    'Certificates',
    'Student Certificates',
    Icons.workspace_premium_rounded,
    featureKey: 'certificate_generate',
  ),
  reports(
    'reports',
    'Reports',
    'Reports & Analytics',
    Icons.analytics_rounded,
    featureKey: 'dashboard_analytics',
  ),
  settings(
    'settings',
    'Settings',
    'Institute Settings',
    Icons.settings_rounded,
    featureKey: 'settings_view',
  ),
  notifications(
    'notifications',
    'Notifications',
    'Notifications & WhatsApp',
    Icons.notifications_active_rounded,
    featureKey: 'whatsapp_integration',
  );

  const _InstituteNav(this.id, this.label, this.title, this.icon,
      {this.featureKey});
  final String id;
  final String label;
  final String title;
  final IconData icon;
  final String? featureKey;

  SidebarItemData toSidebarItem() =>
      SidebarItemData(id: id, label: label, icon: icon, requiredFeature: featureKey);

  static List<SidebarSectionData> get sections => [
    SidebarSectionData(
      title: 'Overview',
      items: [dashboard.toSidebarItem()],
    ),
    SidebarSectionData(
      title: 'Academic Management',
      items: [
        students.toSidebarItem(),
        classes.toSidebarItem(),
        attendance.toSidebarItem(),
        exams.toSidebarItem(),
        monthlyTests.toSidebarItem(),
        certificates.toSidebarItem(),
        staff.toSidebarItem(),
      ],
    ),
    SidebarSectionData(
      title: 'Finance/Financial Management',
      items: [
        fees.toSidebarItem(),
        expenses.toSidebarItem(),
      ],
    ),
    SidebarSectionData(
      title: 'Reports & Analytics',
      items: [
        reports.toSidebarItem(),
      ],
    ),
    SidebarSectionData(
      title: 'Communication',
      items: [
        notifications.toSidebarItem(),
      ],
    ),
    SidebarSectionData(
      title: 'Configuration',
      items: [
        feePlans.toSidebarItem(),
        settings.toSidebarItem(),
      ],
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
                    child: controller.busy
                        ? const AppSkeletonCard(height: 120)
                        : AppKpiGrid(
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
                                trendUp: false,
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
                    child: controller.busy
                        ? const AppSkeletonCard(height: 300)
                        : AppAttendanceHeatmap(data: controller.attendanceHeatmapData),
                  ),
                  const SizedBox(height: 32),

                  AppAnimatedSlide(
                    delayIndex: 6,
                    child: controller.busy
                        ? const AppSkeletonCard(height: 400)
                        : AppPulseFeed(
                            items: DashboardPulseData.fromRaw(
                              controller.recentStudents,
                              controller.recentPayments,
                            ),
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
      duration: const Duration(seconds: 12),
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
    final textTheme = Theme.of(context).textTheme;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          height: 240,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            color: cs.surface,
            border: Border.all(
              color: cs.primary.withValues(alpha: 0.1),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: cs.primary.withValues(alpha: 0.08),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Stack(
            children: [
              // --- Animated Background Blobs (Optimized with BoxShadow instead of BackdropFilter) ---
              _buildBlob(
                color: cs.primary.withValues(alpha: 0.1),
                size: 400,
                offset: Offset(
                  -150 + (sin(_controller.value * 2 * pi) * 80),
                  -150 + (cos(_controller.value * 2 * pi) * 40),
                ),
              ),
              _buildBlob(
                color: cs.tertiary.withValues(alpha: 0.08),
                size: 350,
                offset: Offset(
                  MediaQuery.of(context).size.width * 0.4 + (cos(_controller.value * 2 * pi) * 100),
                  -100 + (sin(_controller.value * 2 * pi) * 60),
                ),
              ),
              _buildBlob(
                color: cs.secondary.withValues(alpha: 0.06),
                size: 300,
                offset: Offset(
                  MediaQuery.of(context).size.width * 0.1 + (sin(_controller.value * 2 * pi + 1.5) * 70),
                  50 + (cos(_controller.value * 2 * pi + 1.5) * 80),
                ),
              ),

              // --- Glass Overlay ---
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        cs.surface.withValues(alpha: 0.4),
                        cs.surface.withValues(alpha: 0.1),
                      ],
                    ),
                  ),
                ),
              ),

              // --- Content ---
              Padding(
                padding: const EdgeInsets.all(40),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Pulsing dot
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: cs.primary.withValues(alpha: 0.3 + (sin(_controller.value * 4 * pi).abs() * 0.7)),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: cs.primary.withValues(alpha: 0.5),
                                        blurRadius: 4 + (sin(_controller.value * 4 * pi).abs() * 4),
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'INSTITUTE COMMAND CENTER',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: cs.primary,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            widget.academyName,
                            style: textTheme.displayMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -2.0,
                              color: cs.onSurface,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          RichText(
                            text: TextSpan(
                              style: textTheme.titleMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                              children: [
                                TextSpan(text: '${_getGreeting()}, '),
                                TextSpan(
                                  text: widget.userName,
                                  style: TextStyle(
                                    color: cs.onSurface,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const TextSpan(text: '. Welcome back to your dashboard.'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // --- Decorative Abstract Element ---
                    if (MediaQuery.of(context).size.width > 900)
                      _buildHeroGraphic(cs),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBlob({required Color color, required double size, required Offset offset}) {
    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color,
              blurRadius: 80,
              spreadRadius: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroGraphic(ColorScheme cs) {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Spinning Ring 1
          Transform.rotate(
            angle: _controller.value * 2 * pi,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: cs.primary.withValues(alpha: 0.15),
                  width: 1,
                  style: BorderStyle.solid,
                ),
              ),
              child: Stack(
                children: [
                   Positioned(
                    top: 0,
                    left: 80,
                    child: Container(width: 10, height: 10, decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.4), shape: BoxShape.circle)),
                   ),
                ],
              ),
            ),
          ),
          // Spinning Ring 2
          Transform.rotate(
            angle: -_controller.value * 3 * pi,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: cs.tertiary.withValues(alpha: 0.1),
                  width: 6,
                  style: BorderStyle.solid,
                ),
              ),
            ),
          ),
          // Center Icon with floating effect
          Transform.translate(
            offset: Offset(0, sin(_controller.value * 4 * pi) * 10),
            child: Container(
              width: 85,
              height: 85,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cs.primary, cs.tertiary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.4),
                    blurRadius: 25,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 44,
              ),
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
    final showCreateExam = featureSvc.canAccess('exam_create');
    final showMonthlyTest = featureSvc.canAccess('test_create');

    if (!showAddStudent && !showMarkAttendance && !showCollectFee && !showCreateExam && !showMonthlyTest) {
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
                onPressed: () {
                  final state = context.findAncestorStateOfType<_InstituteDashboardViewState>();
                  if (state != null) {
                    state._navigateTo(_InstituteNav.students);
                  }
                },
                gradient: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.tertiary],
              ),
            if (showMarkAttendance)
              _QuickActionButton(
                label: 'Mark Attendance',
                icon: Icons.fact_check_rounded,
                onPressed: () {
                  final state = context.findAncestorStateOfType<_InstituteDashboardViewState>();
                  if (state != null) {
                    state._navigateTo(_InstituteNav.attendance);
                  }
                },
                gradient: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.tertiary],
              ),
            if (showCollectFee)
              _QuickActionButton(
                label: 'Collect Fee',
                icon: Icons.payments_rounded,
                onPressed: () {
                  final state = context.findAncestorStateOfType<_InstituteDashboardViewState>();
                  if (state != null) {
                    state._navigateTo(_InstituteNav.fees);
                  }
                },
                gradient: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.tertiary],
              ),
            if (showCreateExam)
              _QuickActionButton(
                label: 'Create Exam',
                icon: Icons.assessment_rounded,
                onPressed: () {
                  final state = context.findAncestorStateOfType<_InstituteDashboardViewState>();
                  if (state != null) {
                    state._navigateTo(_InstituteNav.exams);
                  }
                },
                gradient: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.tertiary],
              ),
            if (showMonthlyTest)
              _QuickActionButton(
                label: 'Monthly Test',
                icon: Icons.quiz_rounded,
                onPressed: () {
                  final state = context.findAncestorStateOfType<_InstituteDashboardViewState>();
                  if (state != null) {
                    state._navigateTo(_InstituteNav.monthlyTests);
                  }
                },
                gradient: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.tertiary],
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
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0.0, _isHovered ? -8.0 : 0.0, 0.0)
          ..scale(_isHovered ? 1.05 : 1.0),
        child: Container(
          width: 180,
          height: 110,
          decoration: BoxDecoration(
            borderRadius: AppRadii.r24,
            gradient: LinearGradient(
              colors: [
                widget.gradient.first,
                widget.gradient.last.withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.gradient.first.withValues(alpha: _isHovered ? 0.4 : 0.2),
                blurRadius: _isHovered ? 32 : 16,
                offset: Offset(0, _isHovered ? 16 : 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onPressed,
              borderRadius: AppRadii.r24,
              child: Stack(
                children: [
                  Positioned(
                    right: -10,
                    top: -10,
                    child: Opacity(
                      opacity: 0.15,
                      child: Icon(widget.icon, size: 80, color: Colors.white),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: AppRadii.r12,
                          ),
                          child: Icon(widget.icon, size: 20, color: Colors.white),
                        ),
                        Text(
                          widget.label,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.2,
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
    this.badgeKey,
    this.isCurrency = false,
  });

  final String title;
  final List<Map<String, dynamic>> items;
  final IconData icon;
  final String emptyMessage;
  final String titleKey;
  final String subtitleKey;
  final String? badgeKey;
  final bool isCurrency;

  Color _getAvatarColor(String name) {
    final colors = [
      const Color(0xFF2563EB),
      const Color(0xFF10B981),
      const Color(0xFFF43F5E),
      const Color(0xFF8B5CF6),
      const Color(0xFFF59E0B),
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
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.04),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.1),
                    borderRadius: AppRadii.r12,
                  ),
                  child: Icon(icon, size: 18, color: cs.primary),
                ),
                const SizedBox(width: 16),
                Text(
                  title.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                      ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  child: const Text('View All'),
                ),
              ],
            ),
          ),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: _EmptyState(message: emptyMessage),
            )
          else
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: List.generate(items.length, (index) {
                  final item = items[index];
                  final name = (item[titleKey] ?? 'Unknown').toString();
                  final subtitleRaw = item[subtitleKey] ?? '';
                  final subtitle = isCurrency && subtitleRaw != null
                    ? 'PKR ${NumberFormat("#,##0").format(double.tryParse(subtitleRaw.toString()) ?? 0)}'
                    : subtitleRaw.toString();
                  final badge = badgeKey != null ? item[badgeKey]?.toString() : null;
                  
                  return _ListItem(
                    title: name,
                    subtitle: subtitle,
                    avatarInitials: _getInitials(name),
                    avatarColor: _getAvatarColor(name),
                    badge: badge,
                  );
                }),
              ),
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
    this.badge,
  });

  final String title;
  final String subtitle;
  final String avatarInitials;
  final Color avatarColor;
  final String? badge;

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
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: _isHovered ? cs.primary.withValues(alpha: 0.04) : Colors.transparent,
          borderRadius: AppRadii.r20,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: widget.avatarColor.withValues(alpha: 0.1),
                borderRadius: AppRadii.r16,
              ),
              alignment: Alignment.center,
              child: Text(
                widget.avatarInitials,
                style: TextStyle(
                  color: widget.avatarColor,
                  fontWeight: FontWeight.w900,
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
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.subtitle,
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (widget.badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.secondaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.badge!.toUpperCase(),
                  style: TextStyle(
                    color: cs.onSecondaryContainer,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
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

