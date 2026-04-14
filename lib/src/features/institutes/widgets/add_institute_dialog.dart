import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/ui/widgets/app_dropdown.dart';
import 'package:educore/src/core/ui/widgets/app_text_field.dart';
import 'package:educore/src/features/institutes/models/institute.dart';
import 'package:flutter/material.dart';

class AddInstituteDialog extends StatefulWidget {
  const AddInstituteDialog({super.key});

  static Future<Institute?> show(BuildContext context) {
    return showDialog<Institute?>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const AddInstituteDialog(),
    );
  }

  @override
  State<AddInstituteDialog> createState() => _AddInstituteDialogState();
}

class _AddInstituteDialogState extends State<AddInstituteDialog> {
  final _name = TextEditingController();
  final _owner = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  InstitutePlan _plan = InstitutePlan.standard;
  InstituteStatus _status = InstituteStatus.active;

  @override
  void dispose() {
    _name.dispose();
    _owner.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Institute',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.4,
                                  ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Create a new tenant on EduCore.',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
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
              _GroupCard(
                title: 'Institute details',
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        controller: _owner,
                        label: 'Owner Name',
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
                        label: 'Email',
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
                title: 'Plan & status',
                child: Row(
                  children: [
                    Expanded(
                      child: AppDropdown<InstitutePlan>(
                        label: 'Plan',
                        items: const [
                          InstitutePlan.basic,
                          InstitutePlan.standard,
                          InstitutePlan.premium,
                        ],
                        value: _plan,
                        itemLabel: (p) => switch (p) {
                          InstitutePlan.basic => 'Basic',
                          InstitutePlan.standard => 'Standard',
                          InstitutePlan.premium => 'Premium',
                        },
                        onChanged: (v) => setState(
                          () => _plan = v ?? InstitutePlan.standard,
                        ),
                        hintText: 'Select plan',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppDropdown<InstituteStatus>(
                        label: 'Status',
                        items: const [
                          InstituteStatus.active,
                          InstituteStatus.expired,
                          InstituteStatus.blocked,
                        ],
                        value: _status,
                        itemLabel: (s) => switch (s) {
                          InstituteStatus.active => 'Active',
                          InstituteStatus.expired => 'Expired',
                          InstituteStatus.blocked => 'Blocked',
                        },
                        onChanged: (v) => setState(
                          () => _status = v ?? InstituteStatus.active,
                        ),
                        hintText: 'Select status',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'You can edit plan and status later from institute details.',
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
                  FilledButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.add_rounded),
                    style: FilledButton.styleFrom(
                      backgroundColor: cs.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    label: const Text('Create institute'),
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

    if (name.isEmpty || owner.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill required fields.')),
      );
      return;
    }

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final institute = Institute(
      id: id,
      name: name,
      ownerName: owner,
      email: email,
      phone: phone,
      plan: _plan,
      status: _status,
      studentsCount: 0,
      createdAt: DateTime.now(),
    );

    Navigator.of(context).pop(institute);
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
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
