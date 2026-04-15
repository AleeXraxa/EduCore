import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/services/institute_service.dart';
import 'package:educore/src/core/ui/widgets/app_dropdown.dart';
import 'package:educore/src/core/ui/widgets/app_text_area.dart';
import 'package:educore/src/core/ui/widgets/app_text_field.dart';
import 'package:educore/src/features/institutes/models/institute.dart';
import 'package:educore/src/features/plans/models/plan.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
import 'package:flutter/material.dart';

class EditInstituteDraft {
  const EditInstituteDraft({
    required this.name,
    required this.ownerName,
    required this.email,
    required this.phone,
    required this.address,
    required this.planId,
    required this.status,
    required this.endDate,
  });

  final String name;
  final String ownerName;
  final String email;
  final String phone;
  final String address;
  final String planId;
  final AcademyStatus status;
  final DateTime? endDate;
}

class EditInstituteDialog extends StatefulWidget {
  const EditInstituteDialog({
    super.key,
    required this.institute,
    required this.plans,
    required this.initialEndDate,
  });

  final Institute institute;
  final List<Plan> plans;
  final DateTime? initialEndDate;

  static Future<EditInstituteDraft?> show(
    BuildContext context, {
    required Institute institute,
    required List<Plan> plans,
    required DateTime? initialEndDate,
  }) {
    return showDialog<EditInstituteDraft?>(
      context: context,
      barrierDismissible: true,
      builder: (_) => EditInstituteDialog(
        institute: institute,
        plans: plans,
        initialEndDate: initialEndDate,
      ),
    );
  }

  @override
  State<EditInstituteDialog> createState() => _EditInstituteDialogState();
}

class _EditInstituteDialogState extends State<EditInstituteDialog> {
  late final TextEditingController _name;
  late final TextEditingController _owner;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _address;

  Plan? _plan;
  AcademyStatus _status = AcademyStatus.active;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    final i = widget.institute;
    _name = TextEditingController(text: i.name);
    _owner = TextEditingController(text: i.ownerName);
    _email = TextEditingController(text: i.email);
    _phone = TextEditingController(text: i.phone);
    _address = TextEditingController(text: i.address);
    _status = i.status;
    _endDate = widget.initialEndDate;

    if (widget.plans.isNotEmpty) {
      _plan = widget.plans.firstWhere(
        (p) => p.id == i.planId,
        orElse: () => widget.plans.first,
      );
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _owner.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final activePlans =
        widget.plans.where((p) => p.isActive).toList(growable: false);
    final endLabel = _endDate == null ? 'Not set' : _fmtDate(_endDate!);

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 860,
          maxHeight: MediaQuery.sizeOf(context).height * 0.90,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit institute',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.4,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Update tenant profile and subscription metadata.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(right: 4),
                  child: Column(
                    children: [
                      _GroupCard(
                        title: 'Institute details',
                        child: Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                controller: _name,
                                label: 'Institute name',
                                hintText: 'e.g. Green Valley Academy',
                                prefixIcon: Icons.apartment_rounded,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppTextField(
                                controller: _owner,
                                label: 'Owner name',
                                hintText: 'e.g. Ahsan Khan',
                                prefixIcon: Icons.person_rounded,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _GroupCard(
                        title: 'Contact',
                        child: Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                controller: _email,
                                label: 'Institute email',
                                hintText: 'owner@institute.com',
                                prefixIcon: Icons.email_rounded,
                                keyboardType: TextInputType.emailAddress,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppTextField(
                                controller: _phone,
                                label: 'Phone',
                                hintText: '+92 300 1234567',
                                prefixIcon: Icons.phone_rounded,
                                keyboardType: TextInputType.phone,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _GroupCard(
                        title: 'Address',
                        child: AppTextArea(
                          controller: _address,
                          label: 'Address',
                          hintText: 'Optional (street, city, etc.)',
                          minLines: 2,
                          maxLines: 4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _GroupCard(
                        title: 'Access & subscription',
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: AppDropdown<AcademyStatus>(
                                    label: 'Status',
                                    items: const [
                                      AcademyStatus.active,
                                      AcademyStatus.pending,
                                      AcademyStatus.blocked,
                                    ],
                                    value: _status,
                                    hintText: 'Select status',
                                    prefixIcon: Icons.shield_rounded,
                                    itemLabel: (s) => switch (s) {
                                      AcademyStatus.active => 'Active',
                                      AcademyStatus.pending => 'Pending',
                                      AcademyStatus.blocked => 'Blocked',
                                    },
                                    onChanged: (v) =>
                                        setState(() => _status = v ?? _status),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: AppDropdown<Plan>(
                                    label: 'Plan',
                                    items: activePlans,
                                    value: _plan,
                                    itemLabel: (p) => p.name,
                                    onChanged: (v) => setState(() {
                                      _plan = v;
                                      _endDate ??=
                                          DateTime.now().add(const Duration(days: 30));
                                    }),
                                    hintText: activePlans.isEmpty
                                        ? 'No active plans'
                                        : 'Select plan',
                                    prefixIcon: Icons.workspace_premium_rounded,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _PickTile(
                              label: 'Subscription end date',
                              value: endLabel,
                              icon: Icons.event_rounded,
                              onPick: () async {
                                final initial = _endDate ??
                                    DateTime.now().add(const Duration(days: 30));
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: initial,
                                  firstDate:
                                      DateTime.now().subtract(const Duration(days: 1)),
                                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                                );
                                if (picked == null) return;
                                if (!context.mounted) return;
                                setState(() => _endDate = picked);
                              },
                              onClear: _endDate == null
                                  ? null
                                  : () => setState(() => _endDate = null),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Changes update `academies/` and `subscriptions/` in real time.',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  AppPrimaryButton(
                    onPressed: _submit,
                    icon: Icons.save_rounded,
                    label: 'Save changes',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    final name = _name.text.trim();
    final owner = _owner.text.trim();
    final email = _email.text.trim();
    final phone = _phone.text.trim();
    final address = _address.text.trim();
    final planId = _plan?.id ?? widget.institute.planId;

    if (name.isEmpty || owner.isEmpty || email.isEmpty || planId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill required fields.')),
      );
      return;
    }

    Navigator.of(context).pop(
      EditInstituteDraft(
        name: name,
        ownerName: owner,
        email: email,
        phone: phone,
        address: address,
        planId: planId,
        status: _status,
        endDate: _endDate,
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppRadii.r16,
        border: Border.all(color: cs.outlineVariant),
        boxShadow: AppShadows.soft(Colors.black),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _PickTile extends StatelessWidget {
  const _PickTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.onPick,
    this.onClear,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppRadii.r16,
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: cs.primary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (onClear != null)
            IconButton(
              tooltip: 'Clear',
              onPressed: onClear,
              icon: const Icon(Icons.close_rounded, size: 18),
            ),
          FilledButton.tonal(
            onPressed: onPick,
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            child: const Text('Pick'),
          ),
        ],
      ),
    );
  }
}

String _fmtDate(DateTime value) {
  final y = value.year.toString().padLeft(4, '0');
  final m = value.month.toString().padLeft(2, '0');
  final d = value.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
