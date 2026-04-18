import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/features/classes/classes_controller.dart';
import 'package:educore/src/features/classes/models/institute_class.dart';
import 'package:flutter/material.dart';

/// Opens the class details as a premium, design-consistent dialog.
class ClassDetailsView extends StatelessWidget {
  const ClassDetailsView({
    super.key,
    required this.classData,
    required this.controller,
  });

  final InstituteClass classData;
  final ClassesController controller;

  static Future<void> show(
    BuildContext context, {
    required InstituteClass classData,
    required ClassesController controller,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (_) => ClassDetailsView(
        classData: classData,
        controller: controller,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.r24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860, maxHeight: 680),
        child: DefaultTabController(
          length: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ─────────────────────────────────────────────
              _ClassDetailsHeader(
                classData: classData,
                onClose: () => Navigator.of(context).pop(),
              ),
              // ── Tab Bar ────────────────────────────────────────────
              Container(
                color: cs.surface,
                child: const TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicatorWeight: 3,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  tabs: [
                    Tab(text: 'Overview'),
                    Tab(text: 'Students'),
                    Tab(text: 'Subjects'),
                    Tab(text: 'Timetable'),
                    Tab(text: 'Teacher Info'),
                  ],
                ),
              ),
              const Divider(height: 1),
              // ── Tab Content ────────────────────────────────────────
              Expanded(
                child: TabBarView(
                  children: [
                    _OverviewTab(classData: classData),
                    const _PlaceholderTab(
                      title: 'Students List',
                      icon: Icons.groups_rounded,
                      message: 'Manage students enrolled in this class.',
                    ),
                    const _PlaceholderTab(
                      title: 'Subjects',
                      icon: Icons.book_outlined,
                      message: 'Map subjects and teachers to this class.',
                    ),
                    const _PlaceholderTab(
                      title: 'Timetable',
                      icon: Icons.calendar_view_week_rounded,
                      message: 'Setup the weekly schedule for this class.',
                    ),
                    _TeacherTab(classData: classData),
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

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _ClassDetailsHeader extends StatelessWidget {
  const _ClassDetailsHeader({
    required this.classData,
    required this.onClose,
  });

  final InstituteClass classData;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          // Class icon badge
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [cs.primary, cs.primary.withValues(alpha: 0.75)],
              ),
              borderRadius: AppRadii.r12,
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              classData.name.isNotEmpty
                  ? classData.name[0].toUpperCase()
                  : 'C',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  classData.displayName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        height: 1.1,
                      ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _HeaderChip(
                      icon: Icons.people_outline_rounded,
                      label: '${classData.studentCount} students',
                    ),
                    const SizedBox(width: 8),
                    _HeaderChip(
                      icon: Icons.book_outlined,
                      label: '${classData.subjectIds.length} subjects',
                    ),
                    const SizedBox(width: 8),
                    _StatusChip(active: classData.isActive),
                  ],
                ),
              ],
            ),
          ),
          Material(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
            child: IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: AppRadii.r8,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: cs.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadii.r8,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            active ? 'Active' : 'Inactive',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Overview Tab
// ─────────────────────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.classData});
  final InstituteClass classData;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _InfoCard(
              title: 'BASIC INFORMATION',
              icon: Icons.info_outline_rounded,
              rows: [
                _InfoRow(label: 'Class Name', value: classData.name),
                _InfoRow(
                  label: 'Section',
                  value: classData.section.isEmpty ? '—' : classData.section,
                ),
                _InfoRow(
                  label: 'Display Name',
                  value: classData.displayName,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _InfoCard(
              title: 'ACADEMICS',
              icon: Icons.school_outlined,
              rows: [
                _InfoRow(
                  label: 'Class Teacher',
                  value: classData.classTeacherName ?? 'Not Assigned',
                ),
                _InfoRow(
                  label: 'Total Students',
                  value: classData.studentCount.toString(),
                ),
                _InfoRow(
                  label: 'Total Subjects',
                  value: classData.subjectIds.length.toString(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.icon,
    required this.rows,
  });
  final String title;
  final IconData icon;
  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppRadii.r16,
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: cs.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color: cs.primary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...rows.expand((w) => [w, const SizedBox(height: 12)]).toList()
            ..removeLast(),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Teacher Info Tab
// ─────────────────────────────────────────────────────────────────────────────

class _TeacherTab extends StatelessWidget {
  const _TeacherTab({required this.classData});
  final InstituteClass classData;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasTeacher = classData.classTeacherName != null &&
        classData.classTeacherName!.isNotEmpty;

    if (!hasTeacher) {
      return const _PlaceholderTab(
        title: 'No Teacher Assigned',
        icon: Icons.person_off_outlined,
        message: 'Edit this class to assign a class teacher.',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: AppRadii.r16,
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [cs.primary, cs.primary.withValues(alpha: 0.7)],
                ),
                borderRadius: AppRadii.r16,
              ),
              alignment: Alignment.center,
              child: Text(
                (classData.classTeacherName ?? 'T')[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    classData.classTeacherName ?? '',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Class Teacher',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Placeholder Tab (coming soon)
// ─────────────────────────────────────────────────────────────────────────────

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({
    required this.title,
    required this.icon,
    required this.message,
  });
  final String title;
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.07),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 36, color: cs.primary.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
