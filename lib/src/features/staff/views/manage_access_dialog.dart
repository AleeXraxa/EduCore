import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
import 'package:educore/src/features/staff/controllers/staff_controller.dart';
import 'package:educore/src/features/staff/models/staff_member.dart';
import 'package:educore/src/features/features/models/feature_flag.dart';
import 'package:educore/src/features/features/models/feature_group.dart';
import 'package:flutter/material.dart';

class ManageAccessDialog extends StatefulWidget {
  const ManageAccessDialog({
    super.key,
    required this.staff,
    required this.controller,
  });

  final StaffMember staff;
  final StaffController controller;

  @override
  State<ManageAccessDialog> createState() => _ManageAccessDialogState();
}

class _ManageAccessDialogState extends State<ManageAccessDialog> {
  late Set<String> _allowed = {};
  Set<String> _denied = {};

  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _allowed = widget.staff.assignedFeatureKeys.toSet();
    _denied = widget.staff.deniedFeatureKeys.toSet();
  }

  bool _hasAccess(String key) {
    // Zero Trust: Staff ONLY get what is explicitly in the _allowed set.
    return _allowed.contains(key);
  }

  void _toggle(String key) {
    setState(() {
      if (_allowed.contains(key)) {
        _allowed.remove(key);
        _denied.add(key);
      } else {
        _allowed.add(key);
        _denied.remove(key);
      }
    });
  }

  Future<void> _save() async {
    setState(() => _isBusy = true);
    await widget.controller.updatePermissions(
      widget.staff.id,
      _allowed.toList(),
      _denied.toList(),
    );
    if (mounted) Navigator.pop(context);
  }

  void _applyRolePreset(StaffRole role) {
    setState(() {
      _denied.clear();
      if (role == StaffRole.teacher) {
        _allowed = {
          'student_view',
          'class_view',
          'staff_attendance',
          'exam_entry',
          'timetable_view',
          'homework_management',
        };
      } else if (role == StaffRole.accountant) {
        _allowed = {
          'fee_management',
          'expense_tracking',
          'salary_management',
          'financial_reports',
          'payment_gateway_config',
        };
      } else if (role == StaffRole.admin) {
        _allowed = {
          'staff_add',
          'staff_edit',
          'staff_delete',
          'role_management',
          'staff_attendance',
          'student_add',
          'student_edit',
          'class_management',
          'settings_edit',
          'reports_view',
        };
      } else {
        _allowed.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final groups = widget.controller.featureGroups;
    final features = widget.controller.allFeatures;

    return Dialog(
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.r24),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 800),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            _Header(staff: widget.staff),

            // Role Presets
            _PresetBar(onSelect: _applyRolePreset),

            // Feature List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  final group = groups[index];
                  final groupFeatures = features
                      .where((f) => f.group == group.name)
                      .toList();
                  if (groupFeatures.isEmpty) return const SizedBox.shrink();

                  return _GroupSection(
                    group: group,
                    features: groupFeatures,
                    hasAccess: _hasAccess,
                    onToggle: _toggle,
                  );
                },
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppPrimaryButton(
                      label: 'Save Permissions',
                      onPressed: _save,
                      busy: _isBusy,
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

class _Header extends StatelessWidget {
  const _Header({required this.staff});
  final StaffMember staff;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.05),
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: cs.primary,
            child: Icon(Icons.security_rounded, color: cs.onPrimary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Access Control: ${staff.name}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                Text(
                  'Define granular feature permissions for this staff member.',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PresetBar extends StatelessWidget {
  const _PresetBar({required this.onSelect});
  final Function(StaffRole) onSelect;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          const Text(
            'Quick Presets:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(width: 12),
          _PresetChip(
            label: 'Teacher',
            color: Colors.blue,
            onTap: () => onSelect(StaffRole.teacher),
          ),
          const SizedBox(width: 8),
          _PresetChip(
            label: 'Accountant',
            color: Colors.orange,
            onTap: () => onSelect(StaffRole.accountant),
          ),
          const SizedBox(width: 8),
          _PresetChip(
            label: 'Manager',
            color: Colors.purple,
            onTap: () => onSelect(StaffRole.admin),
          ),
        ],
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.color,
    required this.onTap,
  });
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _GroupSection extends StatelessWidget {
  const _GroupSection({
    required this.group,
    required this.features,
    required this.hasAccess,
    required this.onToggle,
  });

  final FeatureGroup group;
  final List<FeatureFlag> features;
  final bool Function(String) hasAccess;
  final Function(String) onToggle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 12),
          child: Row(
            children: [
              Text(
                group.name.toUpperCase(),
                style: TextStyle(
                  color: cs.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 1.2,
                ),
              ),
              const Expanded(child: Divider(indent: 12)),
            ],
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisExtent: 72,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: features.length,
          itemBuilder: (context, idx) {
            final f = features[idx];
            final allowed = hasAccess(f.key);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          f.label,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          f.description,
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: allowed,
                    onChanged: (_) => onToggle(f.key),
                    activeTrackColor: cs.primary,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
