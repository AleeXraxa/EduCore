import 'dart:ui';
import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/mvc/controller_builder.dart';
import 'package:educore/src/core/models/subscription_record.dart';
import 'package:educore/src/core/services/institute_service.dart';
import 'package:educore/src/features/institutes/institute_details_controller.dart';
import 'package:educore/src/features/institutes/models/institute.dart';
import 'package:educore/src/features/institutes/widgets/institute_status_badge.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
import 'package:flutter/material.dart';

class InstituteDetailsPanel {
  static Future<void> show(
    BuildContext context, {
    required Institute institute,
    required String planLabel,
    required VoidCallback onToggleBlocked,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierLabel: 'Institute details',
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.22),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, anim, secondary) {
        return _InstituteDetailsDialog(
          institute: institute,
          planLabel: planLabel,
          onToggleBlocked: onToggleBlocked,
        );
      },
      transitionBuilder: (context, anim, secondary, child) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutCubic,
        );
        final slide = Tween<Offset>(
          begin: const Offset(0.12, 0),
          end: Offset.zero,
        ).animate(curved);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(position: slide, child: child),
        );
      },
    );
  }
}

class _InstituteDetailsDialog extends StatefulWidget {
  const _InstituteDetailsDialog({
    required this.institute,
    required this.planLabel,
    required this.onToggleBlocked,
  });

  final Institute institute;
  final String planLabel;
  final VoidCallback onToggleBlocked;

  @override
  State<_InstituteDetailsDialog> createState() =>
      _InstituteDetailsDialogState();
}

class _InstituteDetailsDialogState extends State<_InstituteDetailsDialog> {
  late final InstituteDetailsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = InstituteDetailsController(academyId: widget.institute.id);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final panelWidth = MediaQuery.of(context).size.width < 560 ? double.infinity : 520.0;
    final maxHeight = MediaQuery.of(context).size.height - 36;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                color: Colors.black.withValues(alpha: 0.15),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: panelWidth.isFinite ? panelWidth : 0,
                maxWidth: panelWidth.isFinite ? panelWidth : double.infinity,
                maxHeight: maxHeight,
              ),
              child: Container(
                margin: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: AppRadii.r24,
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 40,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: ControllerBuilder<InstituteDetailsController>(
                  controller: _controller,
                  builder: (context, controller, _) {
                    final academy = controller.academy;
                    final planName = controller.plan?.name.trim().isNotEmpty == true
                        ? controller.plan!.name.trim()
                        : widget.planLabel;
                    final subscription = controller.subscription;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Header(
                          instituteName: academy?.name ?? widget.institute.name,
                          planName: planName,
                          status: academy?.status ?? widget.institute.status,
                          onClose: () => Navigator.of(context).pop(),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _AnimatedSlideIn(
                                  delayIndex: 0,
                                  child: _InfoSection(
                                    title: 'INSTITUTE DETAILS',
                                    icon: Icons.info_outline_rounded,
                                    child: _InfoGrid(
                                      items: [
                                        ('Institute ID', widget.institute.id),
                                        (
                                          'Primary Contact',
                                          academy?.ownerName ?? widget.institute.ownerName,
                                        ),
                                        (
                                          'Email Address',
                                          academy?.email ?? widget.institute.email,
                                        ),
                                        (
                                          'Phone Number',
                                          academy?.phone ?? widget.institute.phone,
                                        ),
                                        (
                                          'Address',
                                          academy?.address ?? widget.institute.address,
                                        ),
                                        (
                                          'Joined On',
                                          _fmtDate(
                                            academy?.createdAt ?? widget.institute.createdAt,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _AnimatedSlideIn(
                                  delayIndex: 1,
                                  child: _InfoSection(
                                    title: 'SUBSCRIPTION DETAILS',
                                    icon: Icons.auto_awesome_rounded,
                                    child: subscription == null
                                        ? Text(
                                            'No active subscription cycle found.',
                                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                                  color: cs.onSurfaceVariant,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          )
                                        : _InfoGrid(
                                            items: [
                                              (
                                                'Subscription Status',
                                                _subStatusLabel(subscription.status),
                                              ),
                                              (
                                                'Activation Date',
                                                _fmtDate(subscription.startDate),
                                              ),
                                              (
                                                'Next Billing Cycle',
                                                _fmtDate(subscription.endDate),
                                              ),
                                              (
                                                'Feature Overrides',
                                                '${subscription.overrides.length} active',
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _AnimatedSlideIn(
                                  delayIndex: 2,
                                  child: _InfoSection(
                                    title: 'ADMINISTRATIVE ACCESS',
                                    icon: Icons.admin_panel_settings_rounded,
                                    child: controller.instituteAdmin == null
                                        ? Text(
                                            'Primary administrator account not found.',
                                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                                  color: cs.onSurfaceVariant,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          )
                                        : _InfoGrid(
                                            items: [
                                              (
                                                'Administrative Email',
                                                controller.instituteAdmin!.email,
                                              ),
                                              (
                                                'Account Status',
                                                controller.instituteAdmin!.status.toUpperCase(),
                                              ),
                                              (
                                                'System Role',
                                                'Primary Contact',
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                                if (controller.errorMessage?.trim().isNotEmpty == true) ...[
                                  const SizedBox(height: 20),
                                  _AnimatedSlideIn(
                                    delayIndex: 3,
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: cs.errorContainer.withValues(alpha: 0.5),
                                        borderRadius: AppRadii.r12,
                                        border: Border.all(color: cs.error.withValues(alpha: 0.2)),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.error_outline_rounded, size: 16, color: cs.error),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              controller.errorMessage!.trim(),
                                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                    color: cs.error,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        _Footer(
                          status: academy?.status ?? widget.institute.status,
                          onToggleBlocked: () {
                            widget.onToggleBlocked();
                            Navigator.of(context).pop();
                          },
                          onClose: () => Navigator.of(context).pop(),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.instituteName,
    required this.planName,
    required this.status,
    required this.onClose,
  });

  final String instituteName;
  final String planName;
  final AcademyStatus status;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.primary.withValues(alpha: 0.1)),
            ),
            child: Icon(
              Icons.business_rounded,
              color: cs.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  instituteName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    InstituteStatusBadge(status: status),
                    const SizedBox(width: 8),
                    _PlanPill(label: planName),
                  ],
                ),
              ],
            ),
          ),
          Material(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            child: IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded, size: 20),
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.status,
    required this.onToggleBlocked,
    required this.onClose,
  });

  final AcademyStatus status;
  final VoidCallback onToggleBlocked;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isBlocked = status == AcademyStatus.blocked;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow.withValues(alpha: 0.5),
        border: Border(
          top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: AppPrimaryButton(
              color: !isBlocked ? const Color(0xFFDC2626) : null,
              onPressed: onToggleBlocked,
              icon: isBlocked ? Icons.lock_open_rounded : Icons.block_rounded,
              label: isBlocked ? 'Restore Institute Access' : 'Suspend Institute Access',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: onClose,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: AppRadii.r16),
                side: BorderSide(color: cs.outlineVariant),
              ),
              child: Text(
                'Close Details',
                style: TextStyle(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanPill extends StatelessWidget {
  const _PlanPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final clean = label.trim().isEmpty ? '-' : label.trim();
    final fg = clean == '-' ? cs.onSurfaceVariant : cs.primary;
    final bg = clean == '-'
        ? cs.surfaceContainerHighest.withValues(alpha: 0.65)
        : cs.primary.withValues(alpha: 0.10);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Text(
        clean.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
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
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: cs.primary),
              const SizedBox(width: 10),
              Text(
                title,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: cs.primary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.items});

  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          _InfoRow(label: items[i].$1, value: items[i].$2),
          if (i != items.length - 1)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Divider(
                color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
                height: 1,
              ),
            ),
        ],
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cleanValue = value.trim().isEmpty ? '—' : value.trim();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: Text(
            cleanValue,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cleanValue == '—' ? cs.onSurfaceVariant : cs.onSurface,
                ),
          ),
        ),
      ],
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
            offset: Offset(0, 16 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

String _fmtDate(DateTime? value) {
  if (value == null) return '—';
  final y = value.year.toString().padLeft(4, '0');
  final m = value.month.toString().padLeft(2, '0');
  final d = value.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

String _subStatusLabel(SubscriptionRecordStatus status) {
  return switch (status) {
    SubscriptionRecordStatus.active => 'Active',
    SubscriptionRecordStatus.expired => 'Expired',
    SubscriptionRecordStatus.pending => 'Pending',
    SubscriptionRecordStatus.canceled => 'Canceled',
  };
}

