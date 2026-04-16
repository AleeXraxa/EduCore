import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/services/institute_service.dart';
import 'package:educore/src/core/ui/widgets/app_dropdown.dart';
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
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: AppRadii.r24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              title: 'New Subscription',
              subtitle: 'Assign a plan to an institute.',
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
                        title: 'SELECT INSTITUTE',
                        child: AppDropdown<String>(
                          label: 'Institute',
                          items: widget.academies.map((a) => a.id).toList(),
                          value: _selectedAcademyId,
                          hintText: 'Select an institute',
                          prefixIcon: Icons.apartment_rounded,
                          itemLabel: (id) => widget.academies
                              .firstWhere((a) => a.id == id)
                              .name,
                          onChanged: (v) =>
                              setState(() => _selectedAcademyId = v),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _AnimatedSlideIn(
                      delayIndex: 1,
                      child: _GroupCard(
                        title: 'PLAN & DURATION',
                        child: Column(
                          children: [
                            AppDropdown<String>(
                              label: 'Subscription Plan',
                              items: widget.plans.map((p) => p.id).toList(),
                              value: _selectedPlanId,
                              prefixIcon: Icons.workspace_premium_rounded,
                              itemLabel: (id) {
                                final p = widget.plans.firstWhere(
                                  (p) => p.id == id,
                                );
                                return '${p.name} (PKR ${p.price.round()}/mo)';
                              },
                              onChanged: (v) =>
                                  setState(() => _selectedPlanId = v),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _DurationChip(
                                    label: '1 Month',
                                    selected: _durationMonths == 1,
                                    onTap: () =>
                                        setState(() => _durationMonths = 1),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _DurationChip(
                                    label: '3 Months',
                                    selected: _durationMonths == 3,
                                    onTap: () =>
                                        setState(() => _durationMonths = 3),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _DurationChip(
                                    label: '1 Year',
                                    selected: _durationMonths == 12,
                                    onTap: () =>
                                        setState(() => _durationMonths = 12),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_selectedPlanId != null)
                      _AnimatedSlideIn(
                        delayIndex: 2,
                        child: _TotalSummary(
                          plan: widget.plans.firstWhere(
                            (p) => p.id == _selectedPlanId,
                          ),
                          durationMonths: _durationMonths,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            _Footer(
              onCancel: () => Navigator.of(context).pop(),
              onSave: _selectedAcademyId == null || _selectedPlanId == null
                  ? null
                  : () {
                      Navigator.pop(context, (
                        academyId: _selectedAcademyId!,
                        planId: _selectedPlanId!,
                        durationMonths: _durationMonths,
                      ));
                    },
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
            label: 'Create Subscription',
            icon: Icons.add_moderator_rounded,
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
        color: cs.surfaceContainerLow,
        borderRadius: AppRadii.r16,
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total amount',
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
                Text(
                  'PKR ${total.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]},")}',
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
