import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/services/institute_service.dart';
import 'package:educore/src/core/ui/widgets/app_dialogs.dart';
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

  void _submit() {
    final name = _name.text.trim();
    final owner = _owner.text.trim();
    final email = _email.text.trim();
    final phone = _phone.text.trim();
    final address = _address.text.trim();
    final planId = _plan?.id ?? widget.institute.planId;

    if (name.isEmpty ||
        owner.isEmpty ||
        email.isEmpty ||
        planId.trim().isEmpty) {
      AppDialogs.showError(
        context,
        title: 'Incomplete Details',
        message: 'Please fill all required highlighted fields to save changes.',
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final activePlans =
        widget.plans.where((p) => p.isActive).toList(growable: false);
    final endLabel = _endDate == null ? 'Not set' : _fmtDate(_endDate!);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: AppRadii.r24),
      backgroundColor: cs.surface,
      surfaceTintColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              title: 'EDIT INSTITUTE',
              subtitle: 'Update institute details and subscription status.',
              onClose: () => Navigator.of(context).pop(),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                child: Column(
                  children: [
                    _AnimatedSlideIn(
                      delayIndex: 0,
                      child: _GroupCard(
                        title: 'BASIC INFORMATION',
                        child: Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                controller: _name,
                                label: 'Institute Name',
                                hintText: 'e.g. Green Valley Academy',
                                prefixIcon: Icons.apartment_rounded,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: AppTextField(
                                controller: _owner,
                                label: 'Primary Contact',
                                hintText: 'e.g. Ahsan Khan',
                                prefixIcon: Icons.person_rounded,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _AnimatedSlideIn(
                      delayIndex: 1,
                      child: _GroupCard(
                        title: 'CONTACT INFO',
                        child: Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                controller: _email,
                                label: 'Email Address',
                                hintText: 'admin@institute.com',
                                prefixIcon: Icons.alternate_email_rounded,
                                keyboardType: TextInputType.emailAddress,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: AppTextField(
                                controller: _phone,
                                label: 'Phone Number',
                                hintText: '+92 300 1234567',
                                prefixIcon: Icons.phone_iphone_rounded,
                                keyboardType: TextInputType.phone,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _AnimatedSlideIn(
                      delayIndex: 2,
                      child: _GroupCard(
                        title: 'LOCATION',
                        child: AppTextArea(
                          controller: _address,
                          label: 'Full Address',
                          hintText: 'Enter institute address...',
                          minLines: 2,
                          maxLines: 4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _AnimatedSlideIn(
                      delayIndex: 3,
                      child: _GroupCard(
                        title: 'PLAN & STATUS',
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: AppDropdown<AcademyStatus>(
                                    label: 'Account Status',
                                    items: const [
                                      AcademyStatus.active,
                                      AcademyStatus.pending,
                                      AcademyStatus.blocked,
                                    ],
                                    value: _status,
                                    hintText: 'Select status',
                                    prefixIcon: Icons.security_rounded,
                                    itemLabel: (s) => switch (s) {
                                      AcademyStatus.active => 'Active Status',
                                      AcademyStatus.pending => 'Pending Approval',
                                      AcademyStatus.blocked => 'Account Suspended',
                                    },
                                    onChanged: (v) =>
                                        setState(() => _status = v ?? _status),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: AppDropdown<Plan>(
                                    label: 'Select Plan',
                                    items: activePlans,
                                    value: _plan,
                                    itemLabel: (p) => p.name,
                                    onChanged: (v) => setState(() {
                                      _plan = v;
                                      _endDate ??=
                                          DateTime.now().add(const Duration(days: 30));
                                    }),
                                    hintText: activePlans.isEmpty
                                        ? 'No tiers available'
                                        : 'Select tier',
                                    prefixIcon: Icons.workspace_premium_rounded,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _PickTile(
                              label: 'Subscription Expiry',
                              value: endLabel,
                              icon: Icons.event_available_rounded,
                              onPick: () async {
                                final initial = _endDate ??
                                    DateTime.now().add(const Duration(days: 30));
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: initial,
                                  firstDate:
                                      DateTime.now().subtract(const Duration(days: 365)),
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
                    ),
                  ],
                ),
              ),
            ),
            _Footer(
              onCancel: () => Navigator.of(context).pop(),
              onSave: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    required this.onClose,
  });
  final String title;
  final String subtitle;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                ),
              ],
            ),
          ),
          Material(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            child: IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded, size: 20),
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.onCancel, required this.onSave});
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow.withValues(alpha: 0.5),
        border: Border(
          top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: onCancel,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            ),
            child: Text(
              'Discard changes',
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          AppPrimaryButton(
            onPressed: onSave,
            label: 'Save Changes',
            icon: Icons.done_all_rounded,
          ),
        ],
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppRadii.r20,
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  color: cs.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 20),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow.withValues(alpha: 0.5),
        borderRadius: AppRadii.r16,
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.08),
              borderRadius: AppRadii.r12,
            ),
            child: Icon(icon, color: cs.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (onClear != null)
            IconButton(
              tooltip: 'Reset',
              onPressed: onClear,
              icon: const Icon(Icons.restart_alt_rounded, size: 18),
              color: cs.onSurfaceVariant,
            ),
          const SizedBox(width: 4),
          FilledButton.tonal(
            onPressed: onPick,
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: AppRadii.r12,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}

class _AnimatedSlideIn extends StatelessWidget {
  const _AnimatedSlideIn({required this.child, required this.delayIndex});
  final Widget child;
  final int delayIndex;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (delayIndex * 100)),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}


String _fmtDate(DateTime value) {
  final y = value.year.toString().padLeft(4, '0');
  final m = value.month.toString().padLeft(2, '0');
  final d = value.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
