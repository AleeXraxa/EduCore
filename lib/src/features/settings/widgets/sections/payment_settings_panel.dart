import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/ui/widgets/app_text_area.dart';
import 'package:educore/src/features/settings/settings_controller.dart';
import 'package:flutter/material.dart';

class PaymentSettingsPanel extends StatefulWidget {
  const PaymentSettingsPanel({super.key, required this.controller});

  final SettingsController controller;

  @override
  State<PaymentSettingsPanel> createState() => _PaymentSettingsPanelState();
}

class _PaymentSettingsPanelState extends State<PaymentSettingsPanel> {
  late final TextEditingController _instructions;

  @override
  void initState() {
    super.initState();
    _instructions =
        TextEditingController(text: widget.controller.paymentInstructions);
    _instructions.addListener(() {
      widget.controller.paymentInstructions = _instructions.text;
    });
  }

  @override
  void dispose() {
    _instructions.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment settings',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Enable payment methods and define instructions for proof submission.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: AppRadii.r16,
            border: Border.all(color: cs.outlineVariant),
            boxShadow: AppShadows.soft(Colors.black),
          ),
          child: Column(
            children: [
              _ToggleRow(
                title: 'JazzCash',
                subtitle: 'Allow institutes to submit JazzCash proof.',
                value: widget.controller.enableJazzCash,
                onChanged: (v) => setState(
                  () => widget.controller.enableJazzCash = v,
                ),
                icon: Icons.account_balance_wallet_rounded,
              ),
              const Divider(height: 24),
              _ToggleRow(
                title: 'EasyPaisa',
                subtitle: 'Allow institutes to submit EasyPaisa proof.',
                value: widget.controller.enableEasyPaisa,
                onChanged: (v) => setState(
                  () => widget.controller.enableEasyPaisa = v,
                ),
                icon: Icons.qr_code_2_rounded,
              ),
              const Divider(height: 24),
              _ToggleRow(
                title: 'Bank transfer',
                subtitle: 'Allow institutes to submit bank transfer proof.',
                value: widget.controller.enableBankTransfer,
                onChanged: (v) => setState(
                  () => widget.controller.enableBankTransfer = v,
                ),
                icon: Icons.account_balance_rounded,
              ),
              const SizedBox(height: 16),
              AppTextArea(
                controller: _instructions,
                label: 'Payment instructions',
                hintText:
                    'Explain how to submit proof and what details are required.',
                minLines: 5,
                maxLines: 10,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: cs.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}
