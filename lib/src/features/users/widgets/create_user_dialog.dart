import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/ui/widgets/app_dropdown.dart';
import 'package:educore/src/core/ui/widgets/app_text_field.dart';
import 'package:educore/src/features/users/models/app_user.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
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

  void _submit() {
    final name = _name.text.trim();
    final email = _email.text.trim();
    final phone = _phone.text.trim();

    if (name.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill required fields.'),
          behavior: SnackBarBehavior.floating,
        ),
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final instituteEnabled = _role != AppUserRole.superAdmin;
    final instituteIds =
        widget.instituteIds.where((e) => e != 'all').toList(growable: false);

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
              title: 'NEW USER ACCOUNT',
              subtitle: 'Set up a new user account and assign roles.',
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
                        title: 'USER INFORMATION',
                        child: Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                controller: _name,
                                label: 'Full Name',
                                hintText: 'e.g. Sara Ali',
                                prefixIcon: Icons.person_rounded,
                                textInputAction: TextInputAction.next,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: AppTextField(
                                controller: _phone,
                                label: 'Phone number',
                                hintText: '+92 300 1234567',
                                prefixIcon: Icons.phone_iphone_rounded,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.next,
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
                        title: 'ACCOUNT SETTINGS',
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: AppTextField(
                                    controller: _email,
                                    label: 'Email Address',
                                    hintText: 'user@institute.com',
                                    prefixIcon: Icons.alternate_email_rounded,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: AppDropdown<AppUserRole>(
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
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: AppDropdown<String>(
                                    label: 'Institute',
                                    items: instituteIds,
                                    value:
                                        instituteEnabled ? _instituteId : null,
                                    enabled: instituteEnabled,
                                    hintText:
                                        instituteEnabled
                                            ? 'Select institute'
                                            : 'EduCore Platform (Global)',
                                    prefixIcon: Icons.hub_rounded,
                                    itemLabel: widget.instituteLabelForId,
                                    onChanged: (v) {
                                      if (!instituteEnabled) return;
                                      if (v == null) return;
                                      if (v == _instituteId) return;
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                        if (!mounted) return;
                                        setState(() => _instituteId = v);
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: AppDropdown<AppUserStatus>(
                                    label: 'Account Status',
                                    items: const [
                                      AppUserStatus.active,
                                      AppUserStatus.blocked,
                                    ],
                                    value: _status,
                                    hintText: 'Select status',
                                    prefixIcon: Icons.verified_user_rounded,
                                    itemLabel: (s) => switch (s) {
                                      AppUserStatus.active => 'Permit Access',
                                      AppUserStatus.blocked => 'Suspend Access',
                                    },
                                    onChanged: (v) => setState(
                                      () => _status = v ?? _status,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _AnimatedSlideIn(
                      delayIndex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.05),
                          borderRadius: AppRadii.r12,
                          border: Border.all(
                            color: cs.primary.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded, size: 16, color: cs.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'All account creation events are logged for security purposes.',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: cs.primary.withValues(alpha: 0.8),
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
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
              'Discard',
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          AppPrimaryButton(
            onPressed: onSave,
            label: 'Create Account',
            icon: Icons.vpn_key_rounded,
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
      width: double.infinity,
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

