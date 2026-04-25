import 'package:educore/src/core/mvc/controller_builder.dart';
import 'package:educore/src/core/responsive/breakpoints.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/core/ui/widgets/app_dialogs.dart';
import 'package:educore/src/core/ui/widgets/app_action_menu.dart';
import 'package:educore/src/core/ui/widgets/app_search_field.dart';
import 'package:educore/src/core/ui/widgets/app_dropdown.dart';

import 'package:educore/src/features/classes/models/institute_class.dart';
import 'package:educore/src/core/ui/widgets/kpi_card.dart';
import 'package:educore/src/features/students/controllers/student_controller.dart';
import 'package:educore/src/features/students/models/student.dart';
import 'package:educore/src/features/students/models/custom_field.dart';
import 'package:educore/src/features/students/views/student_form_dialog.dart';
import 'package:educore/src/core/ui/widgets/access_denied_view.dart';
import 'package:educore/src/features/students/views/bulk_import_dialog.dart';
import 'package:educore/src/features/students/views/update_status_dialog.dart';
import 'package:educore/src/features/students/views/assign_fee_plan_dialog.dart';
import 'package:educore/src/core/ui/views/no_internet_view.dart';
import 'package:educore/src/core/ui/widgets/app_data_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';

class StudentsView extends StatefulWidget {
  const StudentsView({super.key});

  @override
  State<StudentsView> createState() => _StudentsViewState();
}

class _StudentsViewState extends State<StudentsView> {
  late final StudentController _controller;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = StudentController();
    _controller.loadInitialData();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _controller.fetchMore();
      }
    });

    _searchController.addListener(() {
      _controller.onSearchChanged(_searchController.text);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showStudentForm([Student? student]) async {
    final academyId = AppServices.instance.authService?.session?.academyId;
    if (academyId == null) return;

    // Fast check for classes
    final classes = await AppServices.instance.classService!.getClasses(
      academyId,
    );

    if (classes.isEmpty && mounted) {
      AppDialogs.showInfo(
        context,
        title: 'No Classes Found',
        message:
            'You cannot add a student without a class. Please create at least one class first in the Classes module.',
        buttonLabel: 'Got it',
      );
      return;
    }

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) =>
            StudentFormDialog(student: student, controller: _controller),
      );
    }
  }

  void _showBulkImport() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const BulkImportDialog(),
    );
  }

  void _showStudentProfile(Student student) {
    showDialog(
      context: context,
      builder: (_) => _StudentProfileDialog(
        student: student,
        customFields: _controller.customFieldDefinitions,
        onEdit: () {
          final featureSvc = AppServices.instance.featureAccessService;
          if (featureSvc != null && featureSvc.canAccess('student_create')) {
            _showStudentForm(student);
          }
        },
      ),
    );
  }

  void _showUpdateStatus(Student student) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          UpdateStudentStatusDialog(student: student, controller: _controller),
    );
  }

  void _showAssignFeePlan(Student student) {
    showDialog(
      context: context,
      builder: (_) => AssignFeePlanDialog(student: student),
    ).then((success) {
      if (success == true) {
        _controller.loadInitialData();
      }
    });
  }

  Future<void> _handleDelete(Student student) async {
    final confirmed = await AppDialogs.showDeleteConfirmation(
      context,
      title: 'Delete Student',
      message:
          'Are you sure you want to delete ${student.name}? This action cannot be undone.',
    );

    if (!mounted || confirmed != true) return;

    final success = await _controller.deleteStudent(context, student.id);
    
    if (mounted) {
      if (success) {
        AppDialogs.showSuccess(
          context,
          title: 'Record Deleted',
          message: '${student.name} has been removed from the system.',
        );
      } else {
        AppDialogs.showError(
          context,
          title: 'Delete Failed',
          message:
              'An error occurred while trying to delete the student record.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final featureSvc = AppServices.instance.featureAccessService;
    if (featureSvc == null || !featureSvc.canAccess('student_view')) {
      return const AccessDeniedView(featureName: 'Students Management');
    }

    final cs = Theme.of(context).colorScheme;
    final canCreate = featureSvc.canAccess('student_create');

    return ControllerBuilder<StudentController>(
      controller: _controller,
      builder: (context, controller, _) {
        return Scaffold(
          backgroundColor: cs.surfaceContainerLowest.withValues(alpha: 0.4),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StudentsPageHeader(
                  controller: controller,
                  onAddStudent: canCreate ? () => _showStudentForm() : null,
                  onBulkImport: featureSvc.canAccess('bulk_import')
                      ? _showBulkImport
                      : null,
                  searchController: _searchController,
                  errorMessage: controller.errorMessage,
                ),
                const SizedBox(height: 24),

                // KPI Stats Grid
                _StudentStatsGrid(controller: controller),
                const SizedBox(height: 24),

                // Table Container Card
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: cs.outlineVariant.withValues(alpha: 0.5),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Stats Bar inside the card
                        _TableStatsBar(controller: controller),
                        const Divider(height: 1),

                        // Table Body
                        Expanded(
                          child: controller.busy && controller.students.isEmpty
                              ? const _LoadingSkeleton()
                              : controller.hasError && controller.students.isEmpty
                                  ? NoInternetView(
                                      onRetry: () => controller.loadInitialData(),
                                    )
                                  : controller.students.isEmpty
                                      ? _EmptyStudents(
                                          onAdd: canCreate
                                              ? () => _showStudentForm()
                                              : null,
                                        )
                                      : _StudentTable(
                                          controller: controller,
                                          students: controller.students,
                                          onView: _showStudentProfile,
                                          onEdit: canCreate ? _showStudentForm : null,
                                          onDelete:
                                              featureSvc.canAccess('student_delete')
                                              ? _handleDelete
                                              : null,
                                          onUpdateStatus: _showUpdateStatus,
                                          onAssignFeePlan: _showAssignFeePlan,
                                        ),
                        ),

                        // Footer / Pagination
                        const Divider(height: 1),
                        _TableFooter(controller: controller),
                      ],
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

// ==========================================
// Sub-Widgets
// ==========================================

class _StudentStatsGrid extends StatelessWidget {
  const _StudentStatsGrid({required this.controller});
  final StudentController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = screenSizeForWidth(constraints.maxWidth);
        final columns = size == ScreenSize.compact
            ? 2
            : (size == ScreenSize.medium ? 2 : 4);

        const gap = 16.0;
        final cardWidth =
            (constraints.maxWidth - (gap * (columns - 1))) / columns;

        final stats = [
          (
            'all',
            KpiCardData(
              label: 'Total Students',
              value: controller.totalCount.toString(),
              icon: Icons.groups_rounded,
              gradient: [cs.primary, cs.primary.withValues(alpha: 0.7)],
              trendText: 'Academic Overview',
              trendUp: true,
            ),
          ),
          (
            'active',
            KpiCardData(
              label: 'Active',
              value: controller.activeCount.toString(),
              icon: Icons.check_circle_rounded,
              gradient: const [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
              trendText: 'Healthy enrollment',
              trendUp: true,
            ),
          ),
          (
            'passout',
            KpiCardData(
              label: 'Passed Out',
              value: controller.passoutCount.toString(),
              icon: Icons.school_rounded,
              gradient: const [Color(0xFF6366F1), Color(0xFF818CF8)],
              trendText: 'Successful graduates',
              trendUp: true,
            ),
          ),
          (
            'dropped',
            KpiCardData(
              label: 'Dropped',
              value: controller.droppedCount.toString(),
              icon: Icons.person_remove_rounded,
              gradient: const [Color(0xFFEF4444), Color(0xFFF87171)],
              trendText: 'Needs attention',
              trendUp: false,
            ),
          ),
        ];

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: stats.map((stat) {
            final isSelected =
                controller.statusFilter == stat.$1 ||
                (stat.$1 == 'all' && controller.statusFilter == null);

            return SizedBox(
              width: cardWidth,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => controller.onStatusFilterChanged(
                    stat.$1 == 'all' ? null : stat.$1,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? cs.primary : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: KpiCard(data: stat.$2),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ==========================================
// Sub-Widgets
// ==========================================

class _StudentsPageHeader extends StatelessWidget {
  const _StudentsPageHeader({
    required this.controller,
    required this.onAddStudent,
    this.onBulkImport,
    required this.searchController,
    this.errorMessage,
  });

  final StudentController controller;
  final VoidCallback? onAddStudent;
  final VoidCallback? onBulkImport;
  final TextEditingController searchController;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDesktop = MediaQuery.sizeOf(context).width >= Breakpoints.medium;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Students Management',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.0,
                  ),
                ),
                Text(
                  'Manage and monitor enrolled students',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
                ),
              ],
            ),
            const Spacer(),
            if (isDesktop) ...[
              SizedBox(
                width: 280,
                child: AppSearchField(
                  controller: searchController,
                  hintText: 'Search students...',
                ),
              ),
              const SizedBox(width: 12),
              _HeaderClassFilter(controller: controller),
              const SizedBox(width: 12),
              if (onBulkImport != null)
                OutlinedButton.icon(
                  onPressed: onBulkImport,
                  icon: const Icon(Icons.upload_file_rounded, size: 20),
                  label: const Text('Bulk Add'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              if (onAddStudent != null) ...[
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: onAddStudent,
                  icon: const Icon(Icons.person_add_rounded, size: 20),
                  label: const Text('Add Student'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ],
            if (!isDesktop)
              IconButton.filledTonal(
                onPressed: onAddStudent,
                icon: const Icon(Icons.add_rounded),
              ),
          ],
        ),
        if (errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: cs.errorContainer.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.error.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: cs.error, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    errorMessage!,
                    style: TextStyle(
                      color: cs.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _HeaderClassFilter extends StatefulWidget {
  const _HeaderClassFilter({required this.controller});
  final StudentController controller;

  @override
  State<_HeaderClassFilter> createState() => _HeaderClassFilterState();
}

class _HeaderClassFilterState extends State<_HeaderClassFilter> {
  List<InstituteClass> _classes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final academyId = AppServices.instance.authService!.session!.academyId;
    final classes = await AppServices.instance.classService!.getClasses(
      academyId,
    );
    if (mounted) {
      setState(() {
        _classes = classes;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: AppDropdown<String>(
        label: 'Filter by Class',
        showLabel: false,
        value: widget.controller.classIdFilter ?? 'all',
        hintText: _loading ? 'Loading...' : 'All Classes',
        items: ['all', ..._classes.map((c) => c.id)],
        itemLabel: (id) {
          if (id == 'all') return 'All Classes';
          try {
            return _classes.firstWhere((c) => c.id == id).displayName;
          } catch (_) {
            return 'Unknown';
          }
        },
        onChanged: widget.controller.onClassFilterChanged,
        prefixIcon: Icons.school_outlined,
        compact: true,
      ),
    );
  }
}

class _TableStatsBar extends StatelessWidget {
  const _TableStatsBar({required this.controller});
  final StudentController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.1),
      ),
      child: Row(
        children: [
          _miniStat(
            context,
            'Total Enrollments',
            controller.totalCount.toString(),
            cs.primary,
          ),
          _vDivider(context),
          _miniStat(
            context,
            'Active',
            controller.activeCount.toString(),
            const Color(0xFF10B981),
          ),
          _vDivider(context),
          _miniStat(
            context,
            'New this month',
            controller.newAdmissionsCount.toString(),
            const Color(0xFFF59E0B),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () => controller.loadInitialData(),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Refresh List'),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              textStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }

  Widget _vDivider(BuildContext context) {
    return Container(
      height: 12,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }
}

class _StudentTable extends StatelessWidget {
  const _StudentTable({
    required this.controller,
    required this.students,
    required this.onView,
    this.onEdit,
    this.onDelete,
    this.onUpdateStatus,
    this.onAssignFeePlan,
  });

  final StudentController controller;
  final List<Student> students;
  final Function(Student) onView;
  final Function(Student)? onEdit;
  final Function(Student)? onDelete;
  final Function(Student)? onUpdateStatus;
  final Function(Student)? onAssignFeePlan;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AppDataGrid<Student>(
      items: students,
      columns: const [
        AppDataGridColumn(label: 'Roll No', width: 100),
        AppDataGridColumn(label: 'Student', flex: 3),
        AppDataGridColumn(label: 'Class', flex: 2),
        AppDataGridColumn(label: 'Fee Plan', flex: 2),
        AppDataGridColumn(label: 'Status', width: 140, center: true),
        AppDataGridColumn(label: 'Last Updated', width: 150),
        AppDataGridColumn(label: '', width: 60),
      ],
      onSelectionChanged: (selected) {
        // Sync with controller if needed
        controller.clearSelection();
        for (final s in selected) {
          controller.toggleSelection(s.id);
        }
      },
      actions: [
        IconButton(
          onPressed: () {
            // Bulk update status
          },
          icon: const Icon(Icons.published_with_changes_rounded, color: Colors.white),
          tooltip: 'Update Status',
        ),
        IconButton(
          onPressed: () {
            // Bulk delete
          },
          icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
          tooltip: 'Delete Selected',
        ),
      ],
      onRowTap: onView,
      rowBuilder: (context, student) => [
        Text(
          student.rollNo ?? '-',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: cs.primary,
            fontSize: 13,
          ),
        ),
        Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: cs.primary.withValues(alpha: 0.1),
              child: Text(
                student.name[0].toUpperCase(),
                style: TextStyle(
                  color: cs.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    student.name,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                  ),
                  Text(
                    student.fatherName,
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: cs.secondaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            student.className,
            style: TextStyle(
              color: cs.onSecondaryContainer,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Text(
          student.feePlanName ?? '-',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        AppStatusPill(
          label: student.status,
          color: _getStatusColor(student.status, cs),
        ),
        Text(
          DateFormat('MMM dd, yyyy').format(student.updatedAt),
          style: TextStyle(
            color: cs.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        _actionCell(student),
      ],
    );
  }

  Color _getStatusColor(String status, ColorScheme cs) {
    switch (status.toLowerCase()) {
      case 'active':
        return const Color(0xFF10B981);
      case 'dropped':
        return cs.error;
      case 'passout':
        return cs.primary;
      default:
        return cs.outline;
    }
  }

  Widget _actionCell(Student student) {
    final featureSvc = AppServices.instance.featureAccessService;
    final canTransfer =
        featureSvc != null && featureSvc.canAccess('student_transfer');

    return AppActionMenu(
      actions: [
        AppActionItem(
          label: 'View',
          icon: Icons.visibility_outlined,
          onTap: () => onView(student),
        ),
        if (onEdit != null)
          AppActionItem(
            label: 'Edit',
            icon: Icons.edit_outlined,
            onTap: () => onEdit!(student),
          ),
        if (canTransfer)
          AppActionItem(
            label: 'Update Status',
            icon: Icons.published_with_changes_rounded,
            onTap: () => onUpdateStatus?.call(student),
          ),
        AppActionItem(
          label: 'Assign Fee Plan',
          icon: Icons.payments_outlined,
          onTap: () => onAssignFeePlan?.call(student),
        ),
        if (onDelete != null)
          AppActionItem(
            label: 'Delete',
            icon: Icons.delete_outline_rounded,
            type: AppActionType.delete,
            onTap: () => onDelete!(student),
          ),
      ],
    );
  }
}

class _TableFooter extends StatelessWidget {
  const _TableFooter({required this.controller});
  final StudentController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final count = controller.students.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Text(
            'Showing 1–$count of ${controller.totalCount} students',
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          OutlinedButton(
            onPressed: null, // Placeholder for pagination
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Previous'),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: controller.hasMore ? () => controller.fetchMore() : null,
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// Sub-Widgets
// ==========================================

class _EmptyStudents extends StatelessWidget {
  const _EmptyStudents({required this.onAdd});
  final VoidCallback? onAdd;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.people_alt_rounded,
                  size: 80,
                  color: cs.primary.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'No Students Found',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 400,
                child: Text(
                  'Add your first student to the institute to start tracking attendance, performance, and fees efficiently.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ),
              if (onAdd != null) ...[
                const SizedBox(height: 40),
                FilledButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.person_add_rounded),
                  label: const Text('Add Your First Student'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StudentProfileDialog extends StatelessWidget {
  const _StudentProfileDialog({
    required this.student,
    required this.customFields,
    required this.onEdit,
  });
  final Student student;
  final List<StudentCustomField> customFields;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Container(
        width: 700,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Gradient Section
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [cs.primary, cs.primary.withValues(alpha: 0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        child: Text(
                          student.name[0].toUpperCase(),
                          style: TextStyle(
                            color: cs.primary,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Roll No: ${student.rollNo ?? "N/A"}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _StatusBadge(status: student.status, isWhite: true),
                  ],
                ),
              ),

              // Content Section
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle(context, 'Personal & Academic Details'),
                      const SizedBox(height: 24),
                      _ProfileInfoGrid(student: student),

                      if (student.customFields.isNotEmpty) ...[
                        const SizedBox(height: 40),
                        _sectionTitle(context, 'Custom Information'),
                        const SizedBox(height: 24),
                        _ProfileCustomFields(
                          data: student.customFields,
                          definitions: customFields,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Footer Section
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 24,
                ),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                  border: Border(
                    top: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                      ),
                      child: const Text('Close Profile'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        onEdit();
                      },
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      label: const Text('Edit Student'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileInfoGrid extends StatelessWidget {
  const _ProfileInfoGrid({required this.student});
  final Student student;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 32,
      runSpacing: 32,
      children: [
        _InfoItem(
          label: 'Roll Number',
          value: student.rollNo ?? 'N/A',
          icon: Icons.tag_rounded,
        ),
        _InfoItem(
          label: 'Father Name',
          value: student.fatherName,
          icon: Icons.person_outline,
        ),
        _InfoItem(
          label: 'Fee Plan',
          value: student.feePlanName ?? 'No Plan',
          icon: Icons.payments_outlined,
        ),
        _InfoItem(
          label: 'Billing Model',
          value: student.feeMode == 'package'
              ? 'One-time Package'
              : 'Monthly Subscription',
          icon: student.feeMode == 'package'
              ? Icons.inventory_2_outlined
              : Icons.event_repeat_rounded,
        ),
        _InfoItem(
          label: 'Class',
          value: student.className,
          icon: Icons.school_outlined,
        ),
        _InfoItem(
          label: 'Enrollment Date',
          value: DateFormat.yMMMd().format(student.createdAt),
          icon: Icons.calendar_today_outlined,
        ),
      ],
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 220,
      child: Row(
        children: [
          Icon(icon, size: 20, color: cs.primary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _sectionTitle(BuildContext context, String title) {
  final cs = Theme.of(context).colorScheme;
  return Row(
    children: [
      Text(
        title.toUpperCase(),
        style: TextStyle(
          color: cs.primary,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
      const SizedBox(width: 16),
      Expanded(child: Divider(color: cs.primary.withValues(alpha: 0.1))),
    ],
  );
}

class _ProfileCustomFields extends StatelessWidget {
  const _ProfileCustomFields({required this.data, required this.definitions});
  final Map<String, dynamic> data;
  final List<StudentCustomField> definitions;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 32,
      runSpacing: 24,
      children: data.entries.map((entry) {
        StudentCustomField? def;
        try {
          def = definitions.firstWhere((d) => d.key == entry.key);
        } catch (_) {
          def = null;
        }

        final label = def?.label ?? entry.key;
        final type = def?.type ?? CustomFieldType.text;

        String displayValue = entry.value?.toString() ?? 'N/A';
        if (type == CustomFieldType.date && entry.value != null) {
          try {
            final date = entry.value is DateTime
                ? entry.value as DateTime
                : DateTime.parse(entry.value.toString());
            displayValue = DateFormat.yMMMd().format(date);
          } catch (_) {}
        }

        return _InfoItem(
          label: label,
          value: displayValue,
          icon: _getIconForType(type),
        );
      }).toList(),
    );
  }

  IconData _getIconForType(CustomFieldType type) {
    switch (type) {
      case CustomFieldType.text:
        return Icons.notes_rounded;
      case CustomFieldType.number:
        return Icons.tag_rounded;
      case CustomFieldType.date:
        return Icons.event_rounded;
      case CustomFieldType.dropdown:
        return Icons.list_rounded;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, this.isWhite = false});
  final String status;
  final bool isWhite;

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case 'active':
        color = const Color(0xFF10B981);
        label = 'Active';
        icon = Icons.check_circle_rounded;
        break;
      case 'passout':
        color = const Color(0xFF6366F1);
        label = 'Pass Out';
        icon = Icons.school_rounded;
        break;
      case 'dropped':
        color = const Color(0xFFEF4444);
        label = 'Dropped';
        icon = Icons.person_remove_rounded;
        break;
      default:
        color = const Color(0xFF64748B);
        label = status.toUpperCase();
        icon = Icons.help_outline_rounded;
    }

    final bgColor = isWhite ? Colors.white24 : color.withValues(alpha: 0.1);
    final textColor = isWhite ? Colors.white : color;
    final borderColor = isWhite ? Colors.white30 : color.withValues(alpha: 0.2);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SpinKitPulse(color: cs.primary.withValues(alpha: 0.3), size: 100),
          const SizedBox(height: 24),
          Text(
            'Retrieving student records...',
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
