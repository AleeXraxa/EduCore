import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/ui/widgets/app_dropdown.dart';
import 'package:educore/src/core/ui/widgets/app_text_area.dart';
import 'package:educore/src/core/ui/widgets/app_text_field.dart';
import 'package:educore/src/features/plans/models/plan.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
import 'package:flutter/material.dart';

class CreateInstituteDraft {
  const CreateInstituteDraft({
    required this.name,
    required this.ownerName,
    required this.email,
    required this.phone,
    required this.address,
    required this.adminEmail,
    required this.adminPassword,
  });

  final String name;
  final String ownerName;
  final String email;
  final String phone;
  final String address;
  final String adminEmail;
  final String adminPassword;
}

class AddInstituteDialog extends StatefulWidget {
  const AddInstituteDialog({super.key});



  static Future<CreateInstituteDraft?> show(
    BuildContext context,
  ) {
    return showDialog<CreateInstituteDraft?>(
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
  final _address = TextEditingController();

  final _adminEmail = TextEditingController();
  final _adminPassword = TextEditingController();

  Plan? _plan;
  DateTime? _endDate;
  bool _showPassword = false;

  @override
  void dispose() {
    _name.dispose();
    _owner.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    _adminEmail.dispose();
    _adminPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;


    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 820,
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
                          'Add Institute',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.4,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Create a new tenant on EduCore and provision the admin account.',
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
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                        title: 'Institute admin account',
                        child: Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                controller: _adminEmail,
                                label: 'Admin email',
                                hintText: 'admin@institute.com',
                                prefixIcon: Icons.admin_panel_settings_rounded,
                                keyboardType: TextInputType.emailAddress,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _adminPassword,
                                obscureText: !_showPassword,
                                decoration: InputDecoration(
                                  labelText: 'Admin password',
                                  hintText: 'Create a secure password',
                                  prefixIcon: const Icon(Icons.lock_rounded),
                                  filled: true,
                                  fillColor: cs.surface,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 14,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: AppRadii.r12,
                                    borderSide: BorderSide(color: cs.outlineVariant),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: AppRadii.r12,
                                    borderSide: BorderSide(color: cs.primary, width: 1.2),
                                  ),
                                  suffixIcon: IconButton(
                                    tooltip: _showPassword ? 'Hide' : 'Show',
                                    onPressed: () => setState(() => _showPassword = !_showPassword),
                                    icon: Icon(
                                      _showPassword
                                          ? Icons.visibility_off_rounded
                                          : Icons.visibility_rounded,
                                    ),
                                  ),
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
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'This creates the academy, an admin user, and a global user record.',
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
                    icon: Icons.add_rounded,
                    label: 'Create institute',
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

    final adminEmail = _adminEmail.text.trim();
    final adminPassword = _adminPassword.text;
    final planId = _plan?.id ?? '';

    if (name.isEmpty ||
        owner.isEmpty ||
        email.isEmpty ||
        adminEmail.isEmpty ||
        adminPassword.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill required fields.')),
      );
      return;
    }

    Navigator.of(context).pop(
      CreateInstituteDraft(
        name: name,
        ownerName: owner,
        email: email,
        phone: phone,
        address: address,
        adminEmail: adminEmail,
        adminPassword: adminPassword,
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
