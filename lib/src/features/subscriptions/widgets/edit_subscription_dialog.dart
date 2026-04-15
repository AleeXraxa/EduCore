import 'dart:ui';
import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/ui/widgets/app_dropdown.dart';
import 'package:educore/src/features/plans/models/plan.dart';
import 'package:educore/src/features/subscriptions/models/subscription.dart';
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
  final Function(String planId, SubscriptionStatus status, DateTime expiryDate) onSave;

  static Future<void> show(
    BuildContext context, {
    required Subscription subscription,
    required List<Plan> plans,
    required Function(String planId, SubscriptionStatus status, DateTime expiryDate) onSave,
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
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutQuart);
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
    final size = MediaQuery.sizeOf(context);
    final isMobile = size.width < 600;

    return Center(
      child: Container(
        width: isMobile ? size.width * 0.92 : 460,
        margin: const EdgeInsets.symmetric(vertical: 24),
        child: Material(
          color: cs.surface.withValues(alpha: 0.92),
          borderRadius: AppRadii.r24,
          elevation: 24,
          clipBehavior: Clip.antiAlias,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(instituteName: widget.subscription.instituteName),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionHeader(title: 'Service Plan', icon: Icons.workspace_premium_rounded),
                        const SizedBox(height: 12),
                        AppDropdown<String>(
                          label: 'Plan',
                          showLabel: false,
                          value: _planId,
                          items: widget.plans.map((e) => e.id).toList(),
                          itemLabel: (id) => widget.plans.firstWhere((e) => e.id == id).name,
                          onChanged: (v) {
                            if (v != null) setState(() => _planId = v);
                          },
                        ),
                        const SizedBox(height: 24),
                        const _SectionHeader(title: 'Lifecycle Status', icon: Icons.sync_rounded),
                        const SizedBox(height: 12),
                        AppDropdown<SubscriptionStatus>(
                          label: 'Status',
                          showLabel: false,
                          value: _status,
                          items: SubscriptionStatus.values,
                          itemLabel: (s) => switch (s) {
                            SubscriptionStatus.active => 'Active / Verified',
                            SubscriptionStatus.pendingApproval => 'Pending Approval',
                            SubscriptionStatus.expired => 'Expired / Overdue',
                            SubscriptionStatus.canceled => 'Canceled / Suspended',
                          },
                          onChanged: (v) {
                            if (v != null) setState(() => _status = v);
                          },
                        ),
                        const SizedBox(height: 24),
                        const _SectionHeader(title: 'Validity Period', icon: Icons.event_rounded),
                        const SizedBox(height: 12),
                        _DateTile(
                          label: 'Expiry Date',
                          value: _expiryDate,
                          onTap: _pickDate,
                        ),
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.05),
                            borderRadius: AppRadii.r16,
                            border: Border.all(color: cs.primary.withValues(alpha: 0.1)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline_rounded, color: cs.primary, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Changing these values will take effect immediately for the institute.',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: cs.onSurfaceVariant,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                            ],
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
                    setState(() => _saving = true);
                    final nav = Navigator.of(context);
                    await widget.onSave(_planId, _status, _expiryDate);
                    if (mounted) nav.pop();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.instituteName});
  final String instituteName;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow.withValues(alpha: 0.5),
        border: Border(bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.edit_rounded, color: cs.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Override Subscription',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
             instituteName,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 14, color: cs.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: cs.onSurfaceVariant,
              ),
        ),
      ],
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
    final dateStr = '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

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
            Icon(Icons.calendar_month_rounded, color: cs.onSurfaceVariant, size: 20),
          ],
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow.withValues(alpha: 0.5),
        border: Border(top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: saving ? null : onCancel,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: AppRadii.r12),
                side: BorderSide(color: cs.outlineVariant),
              ),
              child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: saving ? null : onSave,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: AppRadii.r12),
              ),
              child: saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}
