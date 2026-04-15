import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/ui/widgets/app_text_field.dart';
import 'package:educore/src/features/settings/models/global_settings.dart';
import 'package:educore/src/features/settings/settings_controller.dart';
import 'package:flutter/material.dart';

class PaymentSettingsPanel extends StatefulWidget {
  const PaymentSettingsPanel({super.key, required this.controller});

  final SettingsController controller;

  @override
  State<PaymentSettingsPanel> createState() => _PaymentSettingsPanelState();
}

class _PaymentSettingsPanelState extends State<PaymentSettingsPanel> {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final settings = widget.controller.settings;
    if (settings == null) return const Center(child: CircularProgressIndicator());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Methods',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Configure payment collection methods for your platform subscriptions.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 24),
        _PaymentMethodCard(
          title: 'JazzCash',
          icon: Icons.account_balance_wallet_rounded,
          config: settings.paymentMethods['jazzcash'] ??
              PaymentMethodConfig(isActive: false),
          onChanged: (config) => _updateMethod('jazzcash', config),
          fields: (config, onUpdate) => [
            AppTextField(
              label: 'JazzCash Number',
              hintText: '0300 0000000',
              initialValue: config.number,
              onChanged: (v) => onUpdate(config.copyWith(number: v)),
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Account Title',
              hintText: 'EduCore',
              initialValue: config.accountTitle,
              onChanged: (v) => onUpdate(config.copyWith(accountTitle: v)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _PaymentMethodCard(
          title: 'EasyPaisa',
          icon: Icons.qr_code_2_rounded,
          config: settings.paymentMethods['easypaisa'] ??
              PaymentMethodConfig(isActive: false),
          onChanged: (config) => _updateMethod('easypaisa', config),
          fields: (config, onUpdate) => [
            AppTextField(
              label: 'EasyPaisa Number',
              hintText: '0300 0000000',
              initialValue: config.number,
              onChanged: (v) => onUpdate(config.copyWith(number: v)),
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Account Title',
              hintText: 'EduCore',
              initialValue: config.accountTitle,
              onChanged: (v) => onUpdate(config.copyWith(accountTitle: v)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _PaymentMethodCard(
          title: 'Bank Transfer',
          icon: Icons.account_balance_rounded,
          config:
              settings.paymentMethods['bank'] ?? PaymentMethodConfig(isActive: false),
          onChanged: (config) => _updateMethod('bank', config),
          fields: (config, onUpdate) => [
            AppTextField(
              label: 'Bank Name',
              hintText: 'Meezan Bank',
              initialValue: config.bankName,
              onChanged: (v) => onUpdate(config.copyWith(bankName: v)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Account Number',
                    hintText: '1234567890',
                    initialValue: config.accountNumber,
                    onChanged: (v) => onUpdate(config.copyWith(accountNumber: v)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    label: 'Account Title',
                    hintText: 'EduCore Solutions',
                    initialValue: config.accountTitle,
                    onChanged: (v) => onUpdate(config.copyWith(accountTitle: v)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  void _updateMethod(String key, PaymentMethodConfig config) {
    final current = widget.controller.settings;
    if (current == null) return;

    final methods = Map<String, PaymentMethodConfig>.from(current.paymentMethods);
    methods[key] = config;
    widget.controller.updateSettings(current.copyWith(paymentMethods: methods));
  }
}

class _PaymentMethodCard extends StatelessWidget {
  const _PaymentMethodCard({
    required this.title,
    required this.icon,
    required this.config,
    required this.onChanged,
    required this.fields,
  });

  final String title;
  final IconData icon;
  final PaymentMethodConfig config;
  final ValueChanged<PaymentMethodConfig> onChanged;
  final List<Widget> Function(
      PaymentMethodConfig config, ValueChanged<PaymentMethodConfig> onUpdate) fields;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppRadii.r16,
        border: Border.all(
          color: config.isActive
              ? cs.primary.withValues(alpha: 0.5)
              : cs.outlineVariant,
          width: config.isActive ? 2 : 1,
        ),
        boxShadow: AppShadows.soft(Colors.black),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: config.isActive
                        ? cs.primary.withValues(alpha: 0.1)
                        : cs.surfaceContainerHighest,
                    borderRadius: AppRadii.r12,
                  ),
                  child: Icon(
                    icon,
                    color: config.isActive ? cs.primary : cs.onSurfaceVariant,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      Text(
                        config.isActive ? 'Active' : 'Disabled',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: config.isActive
                                  ? Colors.green
                                  : cs.onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: config.isActive,
                  onChanged: (v) => onChanged(config.copyWith(isActive: v)),
                ),
              ],
            ),
          ),
          if (config.isActive) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: fields(config, onChanged),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
