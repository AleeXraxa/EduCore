import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/ui/widgets/app_button.dart';
import 'package:educore/src/core/ui/widgets/app_section_header.dart';
import 'package:educore/src/core/ui/widgets/app_text_field.dart';
import 'package:educore/src/core/utils/validators.dart';
import 'package:flutter/material.dart';

class LoginFormCard extends StatelessWidget {
  const LoginFormCard({
    super.key,
    required this.email,
    required this.password,
    required this.busy,
    required this.obscurePassword,
    required this.onTogglePassword,
    required this.rememberMe,
    required this.onRememberChanged,
    required this.onSignIn,
  });

  final TextEditingController email;
  final TextEditingController password;
  final bool busy;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;
  final bool rememberMe;
  final ValueChanged<bool> onRememberChanged;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppRadii.r16,
        boxShadow: AppShadows.soft(Colors.black.withValues(alpha: 0.08)),
      ),
      child: AutofillGroup(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppSectionHeader(
              title: 'Welcome Back',
              subtitle: 'Sign in to EduCore',
            ),
            const SizedBox(height: 18),
            AppTextField(
              controller: email,
              enabled: !busy,
              label: 'Email',
              hintText: 'Enter your email address',
              prefixIcon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.username, AutofillHints.email],
              textInputAction: TextInputAction.next,
              validator: Validators.validateEmail,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: password,
              enabled: !busy,
              label: 'Password',
              hintText: 'Enter your password',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: obscurePassword,
              autofillHints: const [AutofillHints.password],
              suffix: IconButton(
                tooltip: obscurePassword ? 'Show password' : 'Hide password',
                onPressed: busy ? null : onTogglePassword,
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
              validator: Validators.validatePassword,
              onSubmitted: (_) => onSignIn(),
            ),
            const SizedBox(height: 12),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.spaceBetween,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: rememberMe,
                      onChanged:
                          busy ? null : (v) => onRememberChanged(v ?? false),
                    ),
                    Text(
                      'Remember me',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
                TextButton(
                  onPressed: busy ? null : () {},
                  child: const Text('Forgot password?'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: 'Sign In →',
                icon: Icons.arrow_forward_rounded,
                busy: busy,
                onPressed: busy ? null : onSignIn,
                variant: AppButtonVariant.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'For schools, academies, and training institutes',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
