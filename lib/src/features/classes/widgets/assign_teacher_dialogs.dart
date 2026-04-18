import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
import 'package:educore/src/core/ui/widgets/app_search_field.dart';
import 'package:educore/src/features/classes/classes_controller.dart';
import 'package:educore/src/features/classes/models/institute_class.dart';
import 'package:educore/src/features/staff/models/staff_member.dart';
import 'package:flutter/material.dart';

/// FLOW 1: ASSIGN CLASS TEACHER (SINGLE)
class AssignClassTeacherDialog extends StatefulWidget {
  const AssignClassTeacherDialog({
    super.key,
    required this.controller,
    required this.classData,
  });

  final ClassesController controller;
  final InstituteClass classData;

  @override
  State<AssignClassTeacherDialog> createState() => _AssignClassTeacherDialogState();
}

class _AssignClassTeacherDialogState extends State<AssignClassTeacherDialog> {
  String _searchQuery = '';
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final teachers = widget.controller.availableTeachers.where((t) {
      if (_searchQuery.isEmpty) return true;
      return t.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Dialog(
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.r24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Assign Class Teacher',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select the primary owner for ${widget.classData.displayName}.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 32),
              AppSearchField(
                hintText: 'Search teachers...',
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: teachers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final t = teachers[index];
                    final count = widget.controller.getTeacherClassCount(t.id);
                    final isSelected = widget.classData.classTeacherId == t.id;

                    return ListTile(
                      onTap: isSelected || _saving ? null : () => _assign(t),
                      shape: const RoundedRectangleBorder(borderRadius: AppRadii.r12),
                      tileColor: isSelected
                          ? cs.primaryContainer.withValues(alpha: 0.3)
                          : cs.surfaceContainerHighest.withValues(alpha: 0.3),
                      leading: CircleAvatar(
                        backgroundColor: isSelected ? cs.primary : cs.outlineVariant,
                        child: Text(t.name[0].toUpperCase(), style: TextStyle(color: isSelected ? cs.onPrimary : cs.onSurface)),
                      ),
                      title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('$count classes assigned', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                      trailing: isSelected 
                          ? Icon(Icons.check_circle_rounded, color: cs.primary)
                          : _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : null,
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Close', style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _assign(StaffMember teacher) async {
    setState(() => _saving = true);
    final ok = await widget.controller.assignClassTeacher(
      widget.classData.id,
      teacher.id,
      teacher.name,
    );
    if (mounted) {
      if (ok) {
        Navigator.pop(context);
      } else {
        setState(() => _saving = false);
      }
    }
  }
}

/// FLOW 2: ASSIGN MULTIPLE TEACHERS
class AssignMultipleTeachersDialog extends StatefulWidget {
  const AssignMultipleTeachersDialog({
    super.key,
    required this.controller,
    required this.classData,
    this.removeMode = false,
  });

  final ClassesController controller;
  final InstituteClass classData;
  final bool removeMode;

  @override
  State<AssignMultipleTeachersDialog> createState() => _AssignMultipleTeachersDialogState();
}

class _AssignMultipleTeachersDialogState extends State<AssignMultipleTeachersDialog> {
  String _searchQuery = '';
  late Set<String> _selectedIds;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedIds = Set.from(widget.classData.teacherIds);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    final teachers = widget.removeMode
        ? widget.controller.availableTeachers.where((t) => widget.classData.teacherIds.contains(t.id)).toList()
        : widget.controller.availableTeachers.where((t) {
            if (_searchQuery.isEmpty) return true;
            return t.name.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();

    return Dialog(
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.r24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.removeMode ? 'Remove Teachers' : 'Assign Teachers',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.removeMode 
                    ? 'Deselect teachers to remove them from ${widget.classData.displayName}.'
                    : 'Select teachers to contribute to ${widget.classData.displayName}.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (!widget.removeMode) ...[
                const SizedBox(height: 32),
                AppSearchField(
                  hintText: 'Search teachers...',
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ],
              const SizedBox(height: 24),
              // Chips for selection
              if (_selectedIds.isNotEmpty && !widget.removeMode) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedIds.map((id) {
                    final t = widget.controller.availableTeachers.firstWhere((e) => e.id == id, orElse: () => StaffMember(id: id, name: 'Unknown', email: '', phone: '', role: StaffRole.teacher, assignedFeatureKeys: [], deniedFeatureKeys: [], isActive: true, createdAt: DateTime.now()));
                    return Chip(
                      label: Text(t.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onDeleted: () => setState(() => _selectedIds.remove(id)),
                      backgroundColor: cs.primaryContainer.withValues(alpha: 0.5),
                      side: BorderSide.none,
                      shape: const RoundedRectangleBorder(borderRadius: AppRadii.r8),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
              Expanded(
                child: ListView.separated(
                  itemCount: teachers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final t = teachers[index];
                    final isSelected = _selectedIds.contains(t.id);

                    return CheckboxListTile.adaptive(
                      value: isSelected,
                      onChanged: (v) {
                        setState(() {
                          if (v == true) {
                            _selectedIds.add(t.id);
                          } else {
                            _selectedIds.remove(t.id);
                          }
                        });
                      },
                      tileColor: cs.surfaceContainerHighest.withValues(alpha: 0.2),
                      shape: const RoundedRectangleBorder(borderRadius: AppRadii.r12),
                      title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(t.role.name.toUpperCase(),
                          style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontSize: 11,
                              fontWeight: FontWeight.w900)),
                      activeColor: cs.primary,
                      controlAffinity: ListTileControlAffinity.leading,
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    child: Text('Cancel',
                        style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 16),
                  AppPrimaryButton(
                    onPressed: _saving ? () {} : _save,
                    label: _saving ? 'Saving...' : 'Apply Changes',
                    busy: _saving,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    bool ok;
    if (widget.removeMode) {
      // Find what was removed
      final removed = widget.classData.teacherIds
          .where((id) => !_selectedIds.contains(id))
          .toList();
      if (removed.isEmpty) {
        Navigator.pop(context);
        return;
      }
      ok = await widget.controller.removeTeachers(widget.classData.id, removed);
    } else {
      ok = await widget.controller.assignMultipleTeachers(
          widget.classData.id, _selectedIds.toList());
    }

    if (mounted) {
      if (ok) {
        Navigator.pop(context);
      } else {
        setState(() => _saving = false);
      }
    }
  }
}
