import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/ui/widgets/app_dropdown.dart';
import 'package:educore/src/core/ui/widgets/app_text_field.dart';
import 'package:educore/src/features/users/models/app_user.dart';
import 'package:flutter/material.dart';

class CreateUserDialog extends StatefulWidget {
  const CreateUserDialog({
    super.key,
    required this.instituteIds,
    required this.instituteLabelForId,
  });

  final List<String> instituteIds;
  final String Function(String id) instituteLabelForId;

  static Future<AppUser?> show(
    BuildContext context, {
    required List<String> instituteIds,
    required String Function(String id) instituteLabelForId,
  }) {
    return showDialog<AppUser?>(
      context: context,
      barrierDismissible: true,
      builder: (_) => CreateUserDialog(
        instituteIds: instituteIds,
        instituteLabelForId: instituteLabelForId,
      ),
    );
  }

  @override
  State<CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<CreateUserDialog> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();

  AppUserRole _role = AppUserRole.staff;
  String _instituteId = 'gv';
  AppUserStatus _status = AppUserStatus.active;

  @override
  void initState() {
    super.initState();
    final candidates = widget.instituteIds.where((e) => e != 'all').toList();
    _instituteId = candidates.isEmpty ? 'all' : candidates.first;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final instituteEnabled = _role != AppUserRole.superAdmin;
    final instituteIds =
        widget.instituteIds.where((e) => e != 'all').toList(growable: false);

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
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
                          'Create user',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.4,
                                  ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Add a new account to the EduCore platform.',
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
                title: 'Profile',
                child: Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _name,
                        label: 'Full name',
                        hintText: 'e.g. Sara Ali',
                        prefixIcon: Icons.person_rounded,
                        textInputAction: TextInputAction.next,
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
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _GroupCard(
                title: 'Access',
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _email,
                            label: 'Email',
                            hintText: 'user@institute.com',
                            prefixIcon: Icons.email_rounded,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppDropdown<AppUserRole>(
                            label: 'Role',
                            items: const [
                              AppUserRole.superAdmin,
                              AppUserRole.instituteAdmin,
                              AppUserRole.staff,
                              AppUserRole.teacher,
                            ],
                            value: _role,
                            hintText: 'Select role',
                            prefixIcon: Icons.badge_rounded,
                            itemLabel: (r) => switch (r) {
                              AppUserRole.superAdmin => 'Super Admin',
                              AppUserRole.instituteAdmin => 'Institute Admin',
                              AppUserRole.staff => 'Staff / Operator',
                              AppUserRole.teacher => 'Teacher',
                            },
                            onChanged: (v) => setState(() {
                              _role = v ?? _role;
                              if (_role == AppUserRole.superAdmin) {
                                _instituteId = 'all';
                              } else if (_instituteId == 'all' &&
                                  instituteIds.isNotEmpty) {
                                _instituteId = instituteIds.first;
                              }
                            }),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: AppDropdown<String>(
                            label: 'Institute',
                            items: instituteIds,
                            value: instituteEnabled ? _instituteId : null,
                            enabled: instituteEnabled,
                            hintText: instituteEnabled
                                ? 'Select institute'
                                : 'EduCore Platform',
                            prefixIcon: Icons.apartment_rounded,
                            itemLabel: widget.instituteLabelForId,
                            onChanged: (v) {
                              if (!instituteEnabled) return;
                              if (v == null) return;
                              if (v == _instituteId) return;
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (!mounted) return;
                                setState(() => _instituteId = v);
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppDropdown<AppUserStatus>(
                            label: 'Status',
                            items: const [
                              AppUserStatus.active,
                              AppUserStatus.blocked,
                            ],
                            value: _status,
                            hintText: 'Select status',
                            prefixIcon: Icons.shield_rounded,
                            itemLabel: (s) => switch (s) {
                              AppUserStatus.active => 'Active',
                              AppUserStatus.blocked => 'Blocked',
                            },
                            onChanged: (v) =>
                                setState(() => _status = v ?? _status),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Tip: Use "Blocked" to create the user first, then enable access later.',
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
                    label: const Text('Create user'),
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
    final email = _email.text.trim();
    final phone = _phone.text.trim();

    if (name.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill required fields.')),
      );
      return;
    }

    final instituteId =
        _role == AppUserRole.superAdmin ? 'all' : _instituteId.trim();
    final instituteName = _role == AppUserRole.superAdmin
        ? 'EduCore Platform'
        : widget.instituteLabelForId(instituteId);

    final user = AppUser(
      id: 'u_${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      email: email,
      phone: phone.isEmpty ? '—' : phone,
      role: _role,
      instituteId: instituteId,
      instituteName: instituteName,
      status: _status,
      lastLoginAt: null,
    );

    Navigator.of(context).pop(user);
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
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.22),
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
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
