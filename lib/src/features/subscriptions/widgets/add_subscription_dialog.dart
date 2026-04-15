import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/services/institute_service.dart';
import 'package:educore/src/features/plans/models/plan.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
import 'package:flutter/material.dart';

class AddSubscriptionDialog extends StatefulWidget {
  const AddSubscriptionDialog({
    super.key,
    required this.academies,
    required this.plans,
  });

  final List<Academy> academies;
  final List<Plan> plans;

  static Future<({String academyId, String planId, int durationMonths})?> show(
    BuildContext context, {
    required List<Academy> academies,
    required List<Plan> plans,
  }) {
    return showDialog<({String academyId, String planId, int durationMonths})>(
      context: context,
      builder: (_) => AddSubscriptionDialog(academies: academies, plans: plans),
    );
  }

  @override
  State<AddSubscriptionDialog> createState() => _AddSubscriptionDialogState();
}

class _AddSubscriptionDialogState extends State<AddSubscriptionDialog> {
  String? _selectedAcademyId;
  String? _selectedPlanId;
  int _durationMonths = 1;

  @override
  void initState() {
    super.initState();
    if (widget.plans.isNotEmpty) {
      _selectedPlanId = widget.plans.first.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Container(
        width: 500,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: AppRadii.r24,
          boxShadow: AppShadows.soft(Colors.black),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.1),
                      borderRadius: AppRadii.r16,
                    ),
                    child: Icon(Icons.add_card_rounded, color: cs.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Issue New Subscription',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        Text(
                          'Assign a plan to an institute manually.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Institute Selection
                    Text(
                      'Select Institute',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: AppRadii.r12,
                        border: Border.all(color: cs.outlineVariant),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedAcademyId,
                          hint: const Text('Choose an institute'),
                          items: widget.academies.map((a) {
                            return DropdownMenuItem(
                              value: a.id,
                              child: Text(a.name),
                            );
                          }).toList(),
                          onChanged: (v) => setState(() => _selectedAcademyId = v),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Plan Selection
                    Text(
                      'Select Plan',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: AppRadii.r12,
                        border: Border.all(color: cs.outlineVariant),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedPlanId,
                          items: widget.plans.map((p) {
                            return DropdownMenuItem(
                              value: p.id,
                              child: Text('${p.name} (PKR ${p.price.round()}/mo)'),
                            );
                          }).toList(),
                          onChanged: (v) => setState(() => _selectedPlanId = v),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Duration Selection
                    Text(
                      'Duration',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _DurationChip(
                          label: '1 Month',
                          selected: _durationMonths == 1,
                          onTap: () => setState(() => _durationMonths = 1),
                        ),
                        const SizedBox(width: 8),
                        _DurationChip(
                          label: '3 Months',
                          selected: _durationMonths == 3,
                          onTap: () => setState(() => _durationMonths = 3),
                        ),
                        const SizedBox(width: 8),
                        _DurationChip(
                          label: '1 Year',
                          selected: _durationMonths == 12,
                          onTap: () => setState(() => _durationMonths = 12),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Summary Card
                    if (_selectedPlanId != null) ...[
                      _TotalSummary(
                        plan: widget.plans.firstWhere((p) => p.id == _selectedPlanId),
                        durationMonths: _durationMonths,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const Divider(height: 1),
            // Footer
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: AppRadii.r12),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppPrimaryButton(
                      onPressed: _selectedAcademyId == null || _selectedPlanId == null
                          ? null
                          : () {
                              Navigator.pop(context, (
                                academyId: _selectedAcademyId!,
                                planId: _selectedPlanId!,
                                durationMonths: _durationMonths,
                              ));
                            },
                      label: 'Create Subscription',
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

class _DurationChip extends StatelessWidget {
  const _DurationChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
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

class _TotalSummary extends StatelessWidget {
  const _TotalSummary({required this.plan, required this.durationMonths});

  final Plan plan;
  final int durationMonths;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final total = (plan.price * durationMonths).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: AppRadii.r16,
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Amount',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
                Text(
                  'PKR ${total.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: cs.primary,
                      ),
                ),
              ],
            ),
          ),
          Icon(Icons.receipt_rounded, color: cs.primary.withValues(alpha: 0.5)),
        ],
      ),
    );
  }
}
