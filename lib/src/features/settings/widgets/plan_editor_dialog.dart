import 'package:educore/src/core/ui/widgets/app_text_area.dart';
import 'package:educore/src/core/ui/widgets/app_text_field.dart';
import 'package:educore/src/features/settings/models/settings_models.dart';
import 'package:flutter/material.dart';

class PlanEditorDialog extends StatefulWidget {
  const PlanEditorDialog({super.key, this.initial});

  final SubscriptionPlan? initial;

  static Future<SubscriptionPlan?> show(
    BuildContext context, {
    SubscriptionPlan? initial,
  }) {
    return showDialog<SubscriptionPlan?>(
      context: context,
      barrierDismissible: true,
      builder: (_) => PlanEditorDialog(initial: initial),
    );
  }

  @override
  State<PlanEditorDialog> createState() => _PlanEditorDialogState();
}

class _PlanEditorDialogState extends State<PlanEditorDialog> {
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _duration;
  late final TextEditingController _features;

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _name = TextEditingController(text: p?.name ?? '');
    _price = TextEditingController(text: p?.pricePkr.toString() ?? '');
    _duration = TextEditingController(text: p?.durationDays.toString() ?? '30');
    _features = TextEditingController(
      text: p == null ? '' : p.features.join('\n'),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _duration.dispose();
    _features.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEdit = widget.initial != null;

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
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
                          isEdit ? 'Edit plan' : 'Add plan',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.4,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Define pricing and what the plan includes.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: cs.onSurfaceVariant),
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
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _name,
                      label: 'Plan name',
                      hintText: 'e.g. Premium',
                      prefixIcon: Icons.workspace_premium_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 200,
                    child: AppTextField(
                      controller: _price,
                      label: 'Price (PKR)',
                      hintText: '32000',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.payments_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 200,
                    child: AppTextField(
                      controller: _duration,
                      label: 'Duration (days)',
                      hintText: '30',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.calendar_month_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AppTextArea(
                controller: _features,
                label: 'Features (one per line)',
                hintText: '• Priority support\n• Advanced analytics',
                minLines: 5,
                maxLines: 10,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Tip: Keep plan features short and scannable.',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
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
                    style: FilledButton.styleFrom(
                      backgroundColor: cs.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: Icon(
                      isEdit ? Icons.check_rounded : Icons.add_rounded,
                    ),
                    label: Text(isEdit ? 'Save plan' : 'Add plan'),
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
    final price = int.tryParse(_price.text.trim());
    final duration = int.tryParse(_duration.text.trim());
    final lines = _features.text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);

    if (name.isEmpty || price == null || duration == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill required fields.')),
      );
      return;
    }

    final id =
        widget.initial?.id ??
        name.toLowerCase().replaceAll(' ', '_').replaceAll('-', '_');
    final plan = SubscriptionPlan(
      id: id,
      name: name,
      pricePkr: price,
      durationDays: duration,
      features: lines,
    );

    Navigator.of(context).pop(plan);
  }
}
