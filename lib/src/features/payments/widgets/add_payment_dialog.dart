import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/models/payment_record.dart';
import 'package:educore/src/core/services/institute_service.dart';
import 'package:educore/src/core/ui/widgets/app_dropdown.dart';
import 'package:educore/src/features/plans/models/plan.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AddPaymentDialog extends StatefulWidget {
  const AddPaymentDialog({
    super.key,
    required this.academies,
    required this.plans,
  });

  final List<Academy> academies;
  final List<Plan> plans;

  static Future<
      ({
        String academyId,
        String planId,
        int amount,
        PaymentMethod method,
        String? transactionId
      })?> show(
    BuildContext context, {
    required List<Academy> academies,
    required List<Plan> plans,
  }) {
    return showDialog<
        ({
          String academyId,
          String planId,
          int amount,
          PaymentMethod method,
          String? transactionId
        })>(
      context: context,
      builder: (_) => AddPaymentDialog(academies: academies, plans: plans),
    );
  }

  @override
  State<AddPaymentDialog> createState() => _AddPaymentDialogState();
}

class _AddPaymentDialogState extends State<AddPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedAcademyId;
  String? _selectedPlanId;
  final _amountController = TextEditingController();
  final _txController = TextEditingController();
  PaymentMethod _method = PaymentMethod.bankTransfer;

  @override
  void initState() {
    super.initState();
    if (widget.plans.isNotEmpty) {
      _selectedPlanId = widget.plans.first.id;
      _amountController.text = widget.plans.first.price.round().toString();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _txController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.r24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(
                title: 'Record Offline Payment',
                subtitle: 'Manually record a payment received from an institute.',
                onClose: () => Navigator.of(context).pop(),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    children: [
                      _AnimatedSlideIn(
                        delayIndex: 0,
                        child: _GroupCard(
                          title: 'SOURCE INSTITUTE',
                          child: AppDropdown<String>(
                            label: 'Institute',
                            items: widget.academies.map((a) => a.id).toList(),
                            value: _selectedAcademyId,
                            hintText: 'Select which institute paid',
                            prefixIcon: Icons.apartment_rounded,
                            itemLabel: (id) => widget.academies
                                .firstWhere((a) => a.id == id)
                                .name,
                            onChanged: (v) =>
                                setState(() => _selectedAcademyId = v),
                            validator: (v) => v == null || v.isEmpty
                                ? 'Please select an institute'
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _AnimatedSlideIn(
                        delayIndex: 1,
                        child: _GroupCard(
                          title: 'PAYMENT DETAILS',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppDropdown<String>(
                                label: 'For Subscription Plan',
                                items: widget.plans.map((p) => p.id).toList(),
                                value: _selectedPlanId,
                                prefixIcon: Icons.workspace_premium_rounded,
                                itemLabel: (id) {
                                  final p = widget.plans.firstWhere(
                                    (p) => p.id == id,
                                  );
                                  return '${p.name} (PKR ${p.price.round()}/mo)';
                                },
                                onChanged: (v) {
                                  setState(() {
                                    _selectedPlanId = v;
                                    if (v != null) {
                                      final p = widget.plans
                                          .firstWhere((p) => p.id == v);
                                      _amountController.text =
                                          p.price.round().toString();
                                    }
                                  });
                                },
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Please select a plan'
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      controller: _amountController,
                                      enabled: true,
                                      style: const TextStyle(fontWeight: FontWeight.w900),
                                      decoration: InputDecoration(
                                        labelText: 'Amount (PKR)',
                                        prefixIcon: const Icon(Icons.payments_rounded),
                                        border: OutlineInputBorder(borderRadius: AppRadii.r12),
                                      ),
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 3,
                                    child: TextFormField(
                                      controller: _txController,
                                      decoration: InputDecoration(
                                        labelText: 'Transaction ID (Optional)',
                                        hintText: 'e.g. TRX-123456',
                                        prefixIcon: const Icon(Icons.tag_rounded),
                                        border: OutlineInputBorder(borderRadius: AppRadii.r12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Payment Method',
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: cs.onSurfaceVariant,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _MethodChip(
                                    label: 'EasyPaisa',
                                    method: PaymentMethod.easyPaisa,
                                    selected: _method == PaymentMethod.easyPaisa,
                                    onTap: () => setState(() => _method = PaymentMethod.easyPaisa),
                                  ),
                                  const SizedBox(width: 8),
                                  _MethodChip(
                                    label: 'JazzCash',
                                    method: PaymentMethod.jazzCash,
                                    selected: _method == PaymentMethod.jazzCash,
                                    onTap: () => setState(() => _method = PaymentMethod.jazzCash),
                                  ),
                                  const SizedBox(width: 8),
                                  _MethodChip(
                                    label: 'Bank Transfer',
                                    method: PaymentMethod.bankTransfer,
                                    selected: _method == PaymentMethod.bankTransfer,
                                    onTap: () => setState(() => _method = PaymentMethod.bankTransfer),
                                  ),
                                ],
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
                onSave: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    Navigator.pop(context, (
                      academyId: _selectedAcademyId!,
                      planId: _selectedPlanId!,
                      amount: int.parse(_amountController.text),
                      method: _method,
                      transactionId: _txController.text.trim().isEmpty ? null : _txController.text.trim(),
                    ));
                  }
                },
              ),
            ],
          ),
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
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          Material(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
            child: IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded, size: 20),
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
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
            child: Text(
              'Discard',
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          AppPrimaryButton(
            onPressed: onSave,
            label: 'Record Payment',
            icon: Icons.check_circle_rounded,
          ),
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
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppRadii.r16,
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  color: cs.primary,
                ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _MethodChip extends StatelessWidget {
  const _MethodChip({
    required this.label,
    required this.method,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final PaymentMethod method;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: cs.primary.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: selected ? cs.primary : cs.onSurfaceVariant,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
