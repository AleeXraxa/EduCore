import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/ui/widgets/app_text_area.dart';
import 'package:educore/src/core/ui/widgets/app_text_field.dart';
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

  static Future<CreateInstituteDraft?> show(BuildContext context) {
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
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: Colors.transparent,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutQuart,
        tween: Tween(begin: 0.95, end: 1.0),
        builder: (context, scale, child) => Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: ((scale - 0.95) / 0.05).clamp(0.0, 1.0),
            child: child,
          ),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 860,
            maxHeight: MediaQuery.sizeOf(context).height * 0.90,
          ),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: AppRadii.r24,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 32, 32, 24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.1),
                        borderRadius: AppRadii.r16,
                      ),
                      child: Icon(
                        Icons.add_business_rounded,
                        color: cs.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add New Institute',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1.0,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Register a new institute and set up administrative credentials.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, size: 20),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: cs.outlineVariant.withValues(alpha: 0.5),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      _AnimatedSlideIn(
                        delay: 0,
                        child: _GroupCard(
                        title: 'INSTITUTE INFO',
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
                      const SizedBox(height: 24),
                      _AnimatedSlideIn(
                        delay: 100,
                        child: _GroupCard(
                          title: 'CONTACT DETAILS',
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: AppTextField(
                                      controller: _email,
                                      label: 'Official Email',
                                      hintText: 'owner@institute.com',
                                      prefixIcon: Icons.email_rounded,
                                      keyboardType: TextInputType.emailAddress,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: AppTextField(
                                      controller: _phone,
                                      label: 'Phone Number',
                                      hintText: '+92 300 1234567',
                                      prefixIcon: Icons.phone_rounded,
                                      keyboardType: TextInputType.phone,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              AppTextArea(
                                controller: _address,
                                label: 'Address',
                                hintText:
                                    'Physical address of the institute',
                                minLines: 2,
                                maxLines: 3,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _AnimatedSlideIn(
                        delay: 200,
                        child: _GroupCard(
                          title: 'ADMINISTRATOR ACCOUNT',
                          child: Row(
                            children: [
                              Expanded(
                                child: AppTextField(
                                  controller: _adminEmail,
                                  label: 'Admin Email',
                                  hintText: 'admin@institute.com',
                                  prefixIcon:
                                      Icons.admin_panel_settings_rounded,
                                  keyboardType: TextInputType.emailAddress,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: AppTextField(
                                  controller: _adminPassword,
                                  label: 'Admin Password',
                                  hintText: '••••••••',
                                  prefixIcon: Icons.lock_rounded,
                                  obscureText: !_showPassword,
                                  suffix: IconButton(
                                    onPressed: () => setState(
                                      () => _showPassword = !_showPassword,
                                    ),
                                    icon: Icon(
                                      _showPassword
                                          ? Icons.visibility_off_rounded
                                          : Icons.visibility_rounded,
                                      size: 20,
                                    ),
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

              // Footer
              Divider(
                height: 1,
                color: cs.outlineVariant.withValues(alpha: 0.5),
              ),
              Padding(
                padding: const EdgeInsets.all(32),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: cs.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Adding this institute will automatically create its account and root administrator profile.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 32),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                      ),
                      child: Text(
                        'Discard',
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    AppPrimaryButton(
                      onPressed: _submit,
                      icon: Icons.rocket_launch_rounded,
                      label: 'Add Institute',
                    ),
                  ],
                ),
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

    if (name.isEmpty ||
        owner.isEmpty ||
        email.isEmpty ||
        adminEmail.isEmpty ||
        adminPassword.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please verify all required operational fields.'),
          behavior: SnackBarBehavior.floating,
        ),
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
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppRadii.r20,
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
              letterSpacing: 1.0,
              color: cs.primary,
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
  const _AnimatedSlideIn({required this.child, required this.delay});
  final Widget child;
  final int delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + delay),
      curve: Curves.easeOutQuart,
      tween: Tween(begin: 0.0, end: 1.0),
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
