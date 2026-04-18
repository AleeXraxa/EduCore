import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/ui/widgets/app_dropdown.dart';
import 'package:educore/src/features/plans/models/plan.dart';
import 'package:educore/src/features/subscriptions/models/subscription.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
import 'package:flutter/material.dart';

class EditSubscriptionDialog extends StatefulWidget {
  const EditSubscriptionDialog({
    super.key,
    required this.subscription,
    required this.plans,
    required this.onSave,
  });

  final Subscription subscription;
  final List<Plan> plans;
  final Function(String planId, SubscriptionStatus status, DateTime expiryDate)
  onSave;

  static Future<void> show(
    BuildContext context, {
    required Subscription subscription,
    required List<Plan> plans,
    required Function(
      String planId,
      SubscriptionStatus status,
      DateTime expiryDate,
    )
    onSave,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierLabel: 'Edit subscription',
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, anim, secondary) => EditSubscriptionDialog(
        subscription: subscription,
        plans: plans,
        onSave: onSave,
      ),
      transitionBuilder: (context, anim, secondary, child) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutQuart,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<EditSubscriptionDialog> createState() => _EditSubscriptionDialogState();
}

class _EditSubscriptionDialogState extends State<EditSubscriptionDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _planId;
  late SubscriptionStatus _status;
  late DateTime _expiryDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _planId = widget.subscription.planId;
    _status = widget.subscription.status;
    _expiryDate = widget.subscription.expiryDate;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Theme.of(context).colorScheme.primary,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _expiryDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.r24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(
                title: 'Update Subscription',
                subtitle: widget.subscription.instituteName,
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
                          title: 'SUBSCRIPTION DETAILS',
                          child: Column(
                            children: [
                              AppDropdown<String>(
                                label: 'Subscription Plan',
                                value: _planId,
                                items: widget.plans.map((e) => e.id).toList(),
                                itemLabel: (id) => widget.plans
                                    .firstWhere((e) => e.id == id)
                                    .name,
                                onChanged: (v) {
                                  if (v != null) setState(() => _planId = v);
                                },
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Please select a plan'
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              AppDropdown<SubscriptionStatus>(
                                label: 'Subscription Status',
                                value: _status,
                                items: SubscriptionStatus.values,
                                itemLabel: (s) => switch (s) {
                                  SubscriptionStatus.active => 'Active',
                                  SubscriptionStatus.pendingApproval =>
                                    'Pending Approval',
                                  SubscriptionStatus.expired =>
                                    'Expired / Overdue',
                                  SubscriptionStatus.canceled =>
                                    'Canceled / Suspended',
                                },
                                onChanged: (v) {
                                  if (v != null) setState(() => _status = v);
                                },
                                validator: (v) => v == null
                                    ? 'Please select a status'
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _AnimatedSlideIn(
                        delayIndex: 1,
                        child: _GroupCard(
                          title: 'EXPIRY DATE',
                          child: _DateTile(
                            label: 'Service expiry date',
                            value: _expiryDate,
                            onTap: _pickDate,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _AnimatedSlideIn(
                        delayIndex: 2,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.05),
                            borderRadius: AppRadii.r16,
                            border: Border.all(
                              color: cs.primary.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: cs.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Changes to plan, status, or expiry date take effect immediately for this institute.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: cs.onSurfaceVariant,
                                        fontWeight: FontWeight.w600,
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
                saving: _saving,
                onCancel: () => Navigator.of(context).pop(),
                onSave: () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    setState(() => _saving = true);
                    final nav = Navigator.of(context);
                    await widget.onSave(_planId, _status, _expiryDate);
                    if (mounted) nav.pop();
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
                    fontWeight: FontWeight.w700,
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
  const _Footer({
    required this.onCancel,
    required this.onSave,
    required this.saving,
  });
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final bool saving;

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
            onPressed: saving ? null : onCancel,
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
            onPressed: saving ? null : onSave,
            busy: saving,
            label: 'Save Changes',
            icon: Icons.published_with_changes_rounded,
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



class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dateStr =
        '${value.year}-${value.month.toString().padLeft(2, "0")}-${value.day.toString().padLeft(2, "0")}';

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.r12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: AppRadii.r12,
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateStr,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.calendar_month_rounded,
              color: cs.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}


