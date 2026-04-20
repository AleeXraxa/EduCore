import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/ui/widgets/app_dropdown.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
import 'package:educore/src/core/ui/widgets/app_text_field.dart';
import 'package:educore/src/core/services/plan_limit_exception.dart';
import 'package:educore/src/core/ui/widgets/app_toasts.dart';
import 'package:educore/src/core/ui/widgets/app_dialogs.dart';
import 'package:educore/src/features/staff/controllers/staff_controller.dart';
import 'package:educore/src/features/staff/models/staff_member.dart';
import 'package:flutter/material.dart';

class AddEditStaffDialog extends StatefulWidget {
  const AddEditStaffDialog({super.key, this.staff, required this.controller});

  final StaffMember? staff;
  final StaffController controller;

  @override
  State<AddEditStaffDialog> createState() => _AddEditStaffDialogState();
}

class _AddEditStaffDialogState extends State<AddEditStaffDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _passwordCtrl;
  late final TextEditingController _customRoleCtrl;
  StaffRole _selectedRole = StaffRole.teacher;

  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    final s = widget.staff;
    _nameCtrl = TextEditingController(text: s?.name);
    _emailCtrl = TextEditingController(text: s?.email);
    _phoneCtrl = TextEditingController(text: s?.phone);
    _passwordCtrl = TextEditingController();
    _customRoleCtrl = TextEditingController(text: s?.customRoleName);
    _selectedRole = s?.role ?? StaffRole.teacher;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _customRoleCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isBusy = true);
    try {
      if (widget.staff == null) {
        await widget.controller.addStaff(
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          phone: _phoneCtrl.text.trim(),
          role: _selectedRole,
          customRoleName: _selectedRole == StaffRole.custom ? _customRoleCtrl.text.trim() : null,
        );
      } else {
        await widget.controller.updateStaff(
          widget.staff!.copyWith(
            name: _nameCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            role: _selectedRole,
            customRoleName: _selectedRole == StaffRole.custom ? _customRoleCtrl.text.trim() : null,
          ),
        );
      }
      if (mounted) {
        Navigator.pop(context);
        AppToasts.showSuccess(
          context,
          message: 'Staff ${widget.staff == null ? 'created' : 'updated'} successfully.',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isBusy = false);
        if (e is PlanLimitExceededException) {
          AppDialogs.showLimitReached(
            context,
            message: e.message,
            onUpgrade: () {
              // TODO: Navigate to pricing/plans page
            },
          );
        } else {
          AppToasts.showError(
            context,
            message: 'Error: ${e.toString()}',
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.staff != null;

    return Dialog(
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.r24),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            _Header(isEditing: isEditing),
            
            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppTextField(
                        controller: _nameCtrl,
                        label: 'Full Name',
                        hintText: 'e.g. John Doe',
                        prefixIcon: Icons.person_outline_rounded,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 20),
                      AppTextField(
                        controller: _emailCtrl,
                        label: 'Email Address',
                        hintText: 'email@example.com',
                        prefixIcon: Icons.email_outlined,
                        enabled: !isEditing, // Email cannot be changed for existing users
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 20),
                      AppTextField(
                        controller: _phoneCtrl,
                        label: 'Phone Number',
                        hintText: '03xx xxxxxxx',
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 20),
                      if (!isEditing) ...[
                        AppTextField(
                          controller: _passwordCtrl,
                          label: 'Initial Password',
                          hintText: 'Min 6 characters',
                          prefixIcon: Icons.lock_outline_rounded,
                          obscureText: true,
                          validator: (v) => (v?.length ?? 0) < 6 ? 'Min 6 characters' : null,
                        ),
                        const SizedBox(height: 20),
                      ],
                      AppDropdown<StaffRole>(
                        label: 'Role',
                        items: StaffRole.values,
                        value: _selectedRole,
                        onChanged: (v) => setState(() => _selectedRole = v!),
                        itemLabel: (r) => r.name.substring(0, 1).toUpperCase() + r.name.substring(1),
                        prefixIcon: Icons.badge_outlined,
                      ),
                      if (_selectedRole == StaffRole.custom) ...[
                        const SizedBox(height: 20),
                        AppTextField(
                          controller: _customRoleCtrl,
                          label: 'Custom Role Name',
                          hintText: 'e.g. Driver, Warden',
                          prefixIcon: Icons.edit_note_rounded,
                          validator: (v) => _selectedRole == StaffRole.custom && (v?.isEmpty ?? true) ? 'Required' : null,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppPrimaryButton(
                      label: isEditing ? 'Update Staff' : 'Create Account',
                      onPressed: _submit,
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
  const _Header({required this.isEditing});
  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 24),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.1),
        border: Border(bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(isEditing ? Icons.edit_rounded : Icons.person_add_rounded, color: cs.primary),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEditing ? 'Edit Staff Member' : 'Add New Staff',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                  ),
                  Text(
                    isEditing ? 'Update internal information' : 'Provisioning a new team account',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
