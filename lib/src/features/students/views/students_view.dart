import 'package:educore/src/core/mvc/controller_builder.dart';
import 'package:educore/src/core/responsive/breakpoints.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/core/ui/widgets/app_dialogs.dart';
import 'package:educore/src/core/ui/widgets/app_action_menu.dart';
import 'package:educore/src/core/ui/widgets/app_toasts.dart';
import 'package:educore/src/features/classes/models/institute_class.dart';
import 'package:educore/src/core/ui/widgets/kpi_card.dart';
import 'package:educore/src/features/students/controllers/student_controller.dart';
import 'package:educore/src/features/students/models/student.dart';
import 'package:educore/src/features/students/models/custom_field.dart';
import 'package:educore/src/features/students/views/student_form_dialog.dart';
import 'package:educore/src/features/students/views/bulk_import_dialog.dart';
import 'package:flutter/material.dart';
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
  String? _selectedClassId;
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    _controller = StudentController();
    _controller.loadInitialData();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _controller.loadMore();
      }
    });

    _searchController.addListener(() {
      _controller.setSearchQuery(_searchController.text);
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
    final classes = await AppServices.instance.classService!.getClasses(academyId);
    
    if (classes.isEmpty && mounted) {
      AppDialogs.showInfo(
        context,
        title: 'No Classes Found',
        message: 'You cannot add a student without a class. Please create at least one class first in the Classes module.',
        icon: Icons.school_rounded,
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
      ),
    );
  }

  Future<void> _handleDelete(Student student) async {
    final confirmed = await AppDialogs.showConfirm(
      context,
      title: 'Delete Student',
      message: 'Are you sure you want to delete ${student.name}? This action cannot be fully undone.',
      confirmLabel: 'Delete',
      isDanger: true,
    );

    if (confirmed == true) {
      if (mounted) AppDialogs.showLoading(context, message: 'Deleting student...');
      final success = await _controller.deleteStudent(student.id);
      if (mounted) {
        AppDialogs.hide(context);
        if (success) {
          AppToasts.showSuccess(context, message: 'Student deleted successfully.');
        } else {
          AppToasts.showError(context, message: 'Failed to delete student.');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final featureSvc = AppServices.instance.featureAccessService;
    if (featureSvc == null || !featureSvc.canAccess('student_view')) {
      return const Center(child: Text('Access Denied. Missing permissions.'));
    }

    final cs = Theme.of(context).colorScheme;
    final canCreate = featureSvc.canAccess('student_create');

    return ControllerBuilder<StudentController>(
      controller: _controller,
      builder: (context, controller, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final size = screenSizeForWidth(constraints.maxWidth);
            final isCompact = size == ScreenSize.compact;

            return Scaffold(
              backgroundColor: cs.surfaceContainerLowest.withValues(alpha: 0.5),
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header & Insights
                   _StudentsHeader(
                    controller: controller,
                    searchController: _searchController,
                    onAddStudent: canCreate ? () => _showStudentForm() : null,
                    onBulkImport: canCreate ? _showBulkImport : null,
                    onRefresh: () => controller.loadInitialData(),
                    errorMessage: controller.errorMessage,
                    selectedClass: _selectedClassId,
                    selectedStatus: _selectedStatus,
                    onStatusFilter: (status) {
                      setState(() => _selectedStatus = status);
                      controller.setFilter(
                        _selectedClassId,
                        status == 'all' ? null : status,
                      );
                    },
                    onClassChanged: (val) {
                      setState(() => _selectedClassId = val);
                      controller.setFilter(
                        _selectedClassId,
                        _selectedStatus == 'all' ? null : _selectedStatus,
                      );
                    },
                    onStatusChanged: (val) {
                      setState(() => _selectedStatus = val);
                      controller.setFilter(
                        _selectedClassId,
                        _selectedStatus == 'all' ? null : _selectedStatus,
                      );
                    },
                  ),

                  const Divider(height: 1),

                  // List Area
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => controller.loadInitialData(),
                      child: controller.busy && controller.students.isEmpty
                          ? _LoadingSkeleton()
                          : controller.students.isEmpty
                          ? _EmptyStudents(
                              onAdd: canCreate
                                  ? () => _showStudentForm()
                                  : null,
                            )
                          : ListView.separated(
                              controller: _scrollController,
                              padding: const EdgeInsets.fromLTRB(
                                32,
                                24,
                                32,
                                80,
                              ),
                              itemCount:
                                  controller.students.length +
                                  (controller.hasMore ? 1 : 0),
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                if (index == controller.students.length) {
                                  return const _BottomLoader();
                                }

                                final student = controller.students[index];
                                return _StudentCard(
                                  student: student,
                                  onView: () => _showStudentProfile(student),
                                  onEdit: featureSvc.canAccess('student_update')
                                      ? () => _showStudentForm(student)
                                      : null,
                                  onDelete:
                                      featureSvc.canAccess('student_delete')
                                      ? () => _handleDelete(student)
                                      : null,
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
              floatingActionButton: isCompact && canCreate
                  ? FloatingActionButton.extended(
                      onPressed: () => _showStudentForm(),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Student'),
                    )
                  : null,
            );
          },
        );
      },
    );
  }
}

// ==========================================
// Sub-Widgets
// ==========================================

class _QuickInsights extends StatelessWidget {
  const _QuickInsights({
    required this.controller,
    required this.onStatusFilter,
  });

  final StudentController controller;
  final Function(String) onStatusFilter;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = screenSizeForWidth(constraints.maxWidth);
        final columns = size == ScreenSize.compact
            ? 1
            : (size == ScreenSize.medium ? 2 : 4);
        const gap = 12.0;
        final totalGap = gap * (columns - 1);
        final cardWidth = (constraints.maxWidth - totalGap) / columns;

        final items = [
          (
            'all',
            KpiCardData(
              label: 'Total Students',
              value: controller.totalCount.toString(),
              icon: Icons.people_rounded,
              gradient: [cs.primary, cs.primary.withValues(alpha: 0.7)],
              trendText: 'Overview',
              trendUp: true,
            ),
          ),
          (
            'active',
            KpiCardData(
              label: 'Active',
              value: controller.activeCount.toString(),
              icon: Icons.check_circle_rounded,
              gradient: const [Color(0xFF10B981), Color(0xFF34D399)],
              trendText: 'Healthy',
              trendUp: true,
            ),
          ),
          (
            'inactive',
            KpiCardData(
              label: 'Inactive',
              value: controller.inactiveCount.toString(),
              icon: Icons.pause_circle_rounded,
              gradient: const [Color(0xFF64748B), Color(0xFF94A3B8)],
              trendText: 'Follow up',
              trendUp: false,
            ),
          ),
          (
            'all', // New admissions doesn't have a status filter yet
            KpiCardData(
              label: 'New Admissions',
              value: controller.newAdmissionsCount.toString(),
              icon: Icons.auto_awesome_rounded,
              gradient: const [Color(0xFFF59E0B), Color(0xFFFBBF24)],
              trendText: '+5 this month',
              trendUp: true,
            ),
          ),
        ];

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: items
              .map(
                (item) => SizedBox(
                  width: cardWidth,
                  child: GestureDetector(
                    onTap: () => onStatusFilter(item.$1),
                    behavior: HitTestBehavior.opaque,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: KpiCard(data: item.$2),
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _StudentsHeader extends StatelessWidget {
  const _StudentsHeader({
    required this.controller,
    required this.searchController,
    required this.onAddStudent,
    this.onBulkImport,
    required this.onRefresh,
    this.errorMessage,
    required this.selectedClass,
    required this.selectedStatus,
    required this.onStatusFilter,
    required this.onClassChanged,
    required this.onStatusChanged,
  });

  final StudentController controller;
  final TextEditingController searchController;
  final VoidCallback? onAddStudent;
  final VoidCallback? onBulkImport;
  final VoidCallback onRefresh;
  final String? errorMessage;
  final String? selectedClass;
  final String selectedStatus;
  final Function(String) onStatusFilter;
  final Function(String?) onClassChanged;
  final Function(String) onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDesktop =
        screenSizeForWidth(MediaQuery.sizeOf(context).width) !=
        ScreenSize.compact;

    return Container(
      color: cs.surface,
      padding: EdgeInsets.all(isDesktop ? 32 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Students',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                tooltip: 'Refresh List',
                style: IconButton.styleFrom(
                  backgroundColor: cs.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              if (isDesktop && onAddStudent != null)
                FilledButton.icon(
                  onPressed: onAddStudent,
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('Add Student'),
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
              if (isDesktop && onBulkImport != null) ...[
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: onBulkImport,
                  icon: const Icon(Icons.upload_file_rounded, size: 20),
                  label: const Text('Bulk Import'),
                  style: OutlinedButton.styleFrom(
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
            ],
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: cs.errorContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.error.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 16, color: cs.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      errorMessage!,
                      style: TextStyle(
                        color: cs.error,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          _QuickInsights(
            controller: controller,
            onStatusFilter: onStatusFilter,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _SearchBar(controller: searchController),
              ),
              if (isDesktop) ...[
                const SizedBox(width: 16),
                _ClassSelector(
                  selected: selectedClass,
                  onChanged: onClassChanged,
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          _FilterChips(
            selectedStatus: selectedStatus,
            onChanged: onStatusChanged,
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatefulWidget {
  const _SearchBar({required this.controller});
  final TextEditingController controller;

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateState);
  }

  void _updateState() {
    if (mounted) setState(() => _hasText = widget.controller.text.isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: TextField(
        controller: widget.controller,
        decoration: InputDecoration(
          hintText: 'Search by name or phone...',
          hintStyle: TextStyle(
            color: cs.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          prefixIcon: Icon(Icons.search_rounded, color: cs.primary, size: 20),
          suffixIcon: _hasText
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () => widget.controller.clear(),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.selectedStatus, required this.onChanged});
  final String selectedStatus;
  final Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    final filters = [
      ('all', 'All Students'),
      ('active', 'Active'),
      ('inactive', 'Inactive'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = selectedStatus == f.$1;
          final cs = Theme.of(context).colorScheme;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(f.$2),
              selected: isSelected,
              onSelected: (_) => onChanged(f.$1),
              showCheckmark: false,
              selectedColor: cs.primary,
              labelStyle: TextStyle(
                color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(
                color: isSelected
                    ? cs.primary
                    : cs.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

 class _ClassSelector extends StatefulWidget {
  const _ClassSelector({this.selected, required this.onChanged});
  final String? selected;
  final Function(String?) onChanged;

  @override
  State<_ClassSelector> createState() => _ClassSelectorState();
}

class _ClassSelectorState extends State<_ClassSelector> {
  List<InstituteClass> _classes = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final academyId = AppServices.instance.authService!.session!.academyId;
    final classes = await AppServices.instance.classService!.getClasses(academyId);
    if (mounted) setState(() => _classes = classes);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 52,
      width: 200,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: widget.selected,
          hint: const Text('Filter by Class'),
          borderRadius: BorderRadius.circular(16),
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          items: [
            const DropdownMenuItem(value: null, child: Text('All Classes')),
            ..._classes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.displayName))),
          ],
          onChanged: widget.onChanged,
        ),
      ),
    );
  }
}

class _StudentCard extends StatefulWidget {
  const _StudentCard({
    required this.student,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  final Student student;
  final VoidCallback onView;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  State<_StudentCard> createState() => _StudentCardState();
}

class _StudentCardState extends State<_StudentCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isActive = widget.student.status == 'active';
    final isDesktop =
        screenSizeForWidth(MediaQuery.sizeOf(context).width) !=
        ScreenSize.compact;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        transform: Matrix4.diagonal3Values(
          _isHovered ? 1.01 : 1.0,
          _isHovered ? 1.01 : 1.0,
          1.0,
        ),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isHovered
                ? cs.primary.withValues(alpha: 0.4)
                : cs.outlineVariant.withValues(alpha: 0.5),
            width: _isHovered ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _isHovered ? 0.08 : 0.02),
              blurRadius: _isHovered ? 32 : 12,
              offset: Offset(0, _isHovered ? 12 : 4),
            ),
          ],
        ),
        child: InkWell(
          onTap: widget.onView,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Avatar Area
                _StudentAvatar(name: widget.student.name),
                const SizedBox(width: 20),

                // Info Area
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              widget.student.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StatusBadge(active: isActive),
                          if (widget.student.feeMode == 'package') ...[
                            const SizedBox(width: 8),
                            _BillingBadge(isPackage: true),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Father: ${widget.student.fatherName}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                      if (!isDesktop) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${widget.student.className} • ${widget.student.phone}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),

                if (isDesktop) ...[
                  // Desktop only columns
                  Expanded(
                    child: Text(
                      widget.student.className,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      widget.student.phone,
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  ),
                ],

                // Actions Area
                _CardActions(
                  onView: widget.onView,
                  onEdit: widget.onEdit,
                  onDelete: widget.onDelete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StudentAvatar extends StatelessWidget {
  const _StudentAvatar({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: cs.primary,
          fontWeight: FontWeight.w900,
          fontSize: 18,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        active ? 'Active' : 'Inactive',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _BillingBadge extends StatelessWidget {
  const _BillingBadge({required this.isPackage});
  final bool isPackage;

  @override
  Widget build(BuildContext context) {
    if (!isPackage) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    final color = cs.secondary;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Package',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _CardActions extends StatelessWidget {
  const _CardActions({
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  final VoidCallback onView;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    if (onEdit == null && onDelete == null) {
      return IconButton(
        onPressed: onView,
        icon: const Icon(Icons.visibility_outlined, size: 20),
        tooltip: 'View Profile',
      );
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onView,
          icon: const Icon(Icons.visibility_outlined, size: 20),
          tooltip: 'View Profile',
        ),
        AppActionMenu(
          actions: [
            if (onEdit != null)
              AppActionItem(
                label: 'Edit Student',
                icon: Icons.edit_rounded,
                type: AppActionType.edit,
                onTap: onEdit!,
              ),
            if (onDelete != null)
              AppActionItem(
                label: 'Delete Student',
                icon: Icons.delete_forever_rounded,
                type: AppActionType.delete,
                onTap: onDelete!,
              ),
          ],
        ),
      ],
    );
  }
}

class _LoadingSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(32),
      itemCount: 6,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => Container(
        height: 88,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: SizedBox(width: 40, child: LinearProgressIndicator()),
        ),
      ),
    );
  }
}

class _BottomLoader extends StatelessWidget {
  const _BottomLoader();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _EmptyStudents extends StatelessWidget {
  const _EmptyStudents({required this.onAdd});
  final VoidCallback? onAdd;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_rounded, size: 80, color: cs.outlineVariant),
          const SizedBox(height: 24),
          Text(
            'No students yet',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Add your first student to start managing your institute.',
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
          if (onAdd != null) ...[
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add First Student'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 20,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StudentProfileDialog extends StatelessWidget {
  const _StudentProfileDialog({
    required this.student,
    required this.customFields,
  });
  final Student student;
  final List<StudentCustomField> customFields;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _StudentAvatar(name: student.name),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        'Student Enrollment • ${student.id.substring(0, 8)}',
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(active: student.status == 'active'),
              ],
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 32),
            _ProfileInfoGrid(student: student),
            const SizedBox(height: 32),
            if (student.customFields.isNotEmpty) ...[
              _sectionTitle(context, 'Additional Information'),
              const SizedBox(height: 20),
              _ProfileCustomFields(
                data: student.customFields,
                definitions: customFields,
              ),
            ],
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          ],
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
          value: student.feeMode == 'package' ? 'One-time Package' : 'Monthly Subscription',
          icon: student.feeMode == 'package' ? Icons.inventory_2_outlined : Icons.event_repeat_rounded,
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
      case CustomFieldType.text: return Icons.notes_rounded;
      case CustomFieldType.number: return Icons.tag_rounded;
      case CustomFieldType.date: return Icons.event_rounded;
      case CustomFieldType.dropdown: return Icons.list_rounded;
    }
  }
}
