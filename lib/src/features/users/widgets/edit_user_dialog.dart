import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/ui/widgets/app_dropdown.dart';
import 'package:educore/src/core/ui/widgets/app_text_field.dart';
import 'package:educore/src/features/users/models/app_user.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
import 'package:educore/src/core/utils/validators.dart';
import 'package:flutter/material.dart';

class EditUserDialog extends StatefulWidget {
  const EditUserDialog({
    super.key,
    required this.user,
    required this.instituteIds,
    required this.instituteLabelForId,
  });

  final AppUser user;
  final List<String> instituteIds;
  final String Function(String id) instituteLabelForId;

  static Future<AppUser?> show(
    BuildContext context, {
    required AppUser user,
    required List<String> instituteIds,
    required String Function(String id) instituteLabelForId,
  }) {
    return showDialog<AppUser?>(
      context: context,
      barrierDismissible: true,
      builder: (_) => EditUserDialog(
        user: user,
        instituteIds: instituteIds,
        instituteLabelForId: instituteLabelForId,
      ),
    );
  }

  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  late final _name = TextEditingController(text: widget.user.name);
  late final _phone = TextEditingController(
    text: widget.user.phone == '—' ? '' : widget.user.phone,
  );

  late AppUserRole _role = widget.user.role;
  late String _instituteId = widget.user.instituteId;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    final name = _name.text.trim();
    final phone = _phone.text.trim();

    final instituteId =
        _role == AppUserRole.superAdmin ? 'all' : _instituteId.trim();
    final instituteName = _role == AppUserRole.superAdmin
        ? 'EduCore Platform'
        : widget.instituteLabelForId(instituteId);

    final user = AppUser(
      id: widget.user.id,
      name: name,
      email: widget.user.email,
      phone: phone.isEmpty ? '—' : phone,
      role: _role,
      instituteId: instituteId,
      instituteName: instituteName,
      status: widget.user.status,
      lastLoginAt: widget.user.lastLoginAt,
    );

    Navigator.of(context).pop(user);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final instituteEnabled = _role != AppUserRole.superAdmin;
    final instituteIds =
        widget.instituteIds.where((e) => e != 'all').toList(growable: false);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.r24),
      backgroundColor: cs.surface,
      surfaceTintColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              title: 'EDIT USER ACCOUNT',
              subtitle: 'Update account information and roles for ${widget.user.email}',
              onClose: () => Navigator.of(context).pop(),
            ),
            Flexible(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                  child: Column(
                    children: [
                    _AnimatedSlideIn(
                      delayIndex: 0,
                      child: _GroupCard(
                        title: 'IDENTITY DETAILS',
                        child: Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                controller: _name,
                                label: 'Full Name',
                                hintText: 'e.g. Sara Ali',
                                prefixIcon: Icons.person_rounded,
                                textInputAction: TextInputAction.next,
                                validator: (v) => Validators.validateText(v, label: 'Full Name'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: AppTextField(
                                controller: _phone,
                                label: 'Phone number',
                                hintText: '03001234567',
                                prefixIcon: Icons.phone_iphone_rounded,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.next,
                                validator: Validators.validatePhone,
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
                        title: 'ROLES & PERMISSIONS',
                        child: Column(
                          children: [
                            AppDropdown<AppUserRole>(
                              label: 'User Role',
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
                                AppUserRole.superAdmin => 'Platform Admin',
                                AppUserRole.instituteAdmin =>
                                  'Institute Admin',
                                AppUserRole.staff => 'Staff Member',
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
                            if (instituteEnabled) ...[
                              const SizedBox(height: 16),
                              AppDropdown<String>(
                                label: 'Assigned Institute',
                                hintText: 'Select institute...',
                                items: instituteIds,
                                value: instituteIds.contains(_instituteId)
                                    ? _instituteId
                                    : (instituteIds.isNotEmpty
                                        ? instituteIds.first
                                        : null),
                                prefixIcon: Icons.apartment_rounded,
                                itemLabel: widget.instituteLabelForId,
                                onChanged: (v) =>
                                    setState(() => _instituteId = v ?? _instituteId),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        AppPrimaryButton(
                          onPressed: _submit,
                          label: 'Update Account',
                          icon: Icons.check_circle_outline_rounded,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
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
      padding: const EdgeInsets.all(28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.manage_accounts_rounded, color: cs.primary, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
            style: IconButton.styleFrom(
              backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
            ),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
          ),
          const SizedBox(height: 20),
          child,
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
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
