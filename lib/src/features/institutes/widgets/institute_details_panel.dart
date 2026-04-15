import 'dart:ui';
import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/mvc/controller_builder.dart';
import 'package:educore/src/core/models/subscription_record.dart';
import 'package:educore/src/core/services/institute_service.dart';
import 'package:educore/src/features/institutes/institute_details_controller.dart';
import 'package:educore/src/features/institutes/models/institute.dart';
import 'package:educore/src/features/institutes/widgets/institute_status_badge.dart';
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
    final panelWidth = MediaQuery.of(context).size.width < 560
        ? double.infinity
        : 520.0;
    final maxHeight = MediaQuery.of(context).size.height - 36;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: const SizedBox.expand(),
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
                  color: cs.surface.withValues(alpha: 0.85),
                  borderRadius: AppRadii.r24,
                  border: Border.all(
                    color: cs.onSurface.withValues(alpha: 0.08),
                    width: 0.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 40,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: AppRadii.r24,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: ControllerBuilder<InstituteDetailsController>(
                      controller: _controller,
                      builder: (context, controller, _) {
                        final academy = controller.academy;
                        final planName =
                            controller.plan?.name.trim().isNotEmpty == true
                            ? controller.plan!.name.trim()
                            : widget.planLabel;
                        final subscription = controller.subscription;

                        return Column(
                          children: [
                            _Header(
                              instituteName:
                                  academy?.name ?? widget.institute.name,
                              planName: planName,
                              status:
                                  academy?.status ?? widget.institute.status,
                              onClose: () => Navigator.of(context).pop(),
                            ),
                            Expanded(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.fromLTRB(
                                  24,
                                  8,
                                  24,
                                  24,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _AnimatedSlideIn(
                                      delayIndex: 0,
                                      child: _InfoSection(
                                        title: 'INSTITUTE IDENTITY',
                                        icon: Icons.badge_rounded,
                                        child: _InfoGrid(
                                          items: [
                                            ('Academy ID', widget.institute.id),
                                            (
                                              'Owner',
                                              academy?.ownerName ??
                                                  widget.institute.ownerName,
                                            ),
                                            (
                                              'Email',
                                              academy?.email ??
                                                  widget.institute.email,
                                            ),
                                            (
                                              'Phone',
                                              academy?.phone ??
                                                  widget.institute.phone,
                                            ),
                                            (
                                              'Address',
                                              academy?.address ??
                                                  widget.institute.address,
                                            ),
                                            (
                                              'Member Since',
                                              _fmtDate(
                                                academy?.createdAt ??
                                                    widget.institute.createdAt,
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
                                        title: 'SUBSCRIPTION INTELLIGENCE',
                                        icon: Icons.auto_awesome_rounded,
                                        child: subscription == null
                                            ? Text(
                                                'No active subscription cycle found.',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelMedium
                                                    ?.copyWith(
                                                      color:
                                                          cs.onSurfaceVariant,
                                                    ),
                                              )
                                            : _InfoGrid(
                                                items: [
                                                  (
                                                    'Status',
                                                    _subStatusLabel(
                                                      subscription.status,
                                                    ),
                                                  ),
                                                  (
                                                    'Start Boundary',
                                                    _fmtDate(
                                                      subscription.startDate,
                                                    ),
                                                  ),
                                                  (
                                                    'Next Renewal',
                                                    _fmtDate(
                                                      subscription.endDate,
                                                    ),
                                                  ),
                                                  (
                                                    'Policy Overrides',
                                                    '${subscription.overrides.length} applied',
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
                                        icon:
                                            Icons.admin_panel_settings_rounded,
                                        child: controller.instituteAdmin == null
                                            ? Text(
                                                'Primary administrator account not linked.',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelMedium
                                                    ?.copyWith(
                                                      color:
                                                          cs.onSurfaceVariant,
                                                    ),
                                              )
                                            : _InfoGrid(
                                                items: [
                                                  (
                                                    'Primary Email',
                                                    controller
                                                        .instituteAdmin!
                                                        .email,
                                                  ),
                                                  (
                                                    'Account Auth',
                                                    controller
                                                        .instituteAdmin!
                                                        .status,
                                                  ),
                                                  (
                                                    'Role Permission',
                                                    'Institute Owner',
                                                  ),
                                                ],
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 32),
                                    _AnimatedSlideIn(
                                      delayIndex: 3,
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: _ActionBtn(
                                              isDanger:
                                                  (academy?.status ??
                                                      widget
                                                          .institute
                                                          .status) !=
                                                  AcademyStatus.blocked,
                                              onPressed: () {
                                                widget.onToggleBlocked();
                                                Navigator.of(context).pop();
                                              },
                                              icon:
                                                  (academy?.status ??
                                                          widget
                                                              .institute
                                                              .status) ==
                                                      AcademyStatus.blocked
                                                  ? Icons.lock_open_rounded
                                                  : Icons.block_rounded,
                                              label:
                                                  (academy?.status ??
                                                          widget
                                                              .institute
                                                              .status) ==
                                                      AcademyStatus.blocked
                                                  ? 'Restore Access'
                                                  : 'Restrict Access',
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _ActionBtn(
                                              isDanger: false,
                                              onPressed: () =>
                                                  Navigator.of(context).pop(),
                                              icon: Icons.close_rounded,
                                              label: 'Close View',
                                              outlined: true,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (controller.errorMessage
                                            ?.trim()
                                            .isNotEmpty ==
                                        true) ...[
                                      const SizedBox(height: 16),
                                      Text(
                                        controller.errorMessage!.trim(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium
                                            ?.copyWith(
                                              color: cs.error,
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primary, cs.primaryContainer],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.apartment_rounded,
              color: Colors.white,
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
                    const SizedBox(width: 10),
                    _PlanPill(label: planName),
                  ],
                ),
              ],
            ),
          ),
          Material(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
            child: IconButton(
              tooltip: 'Close',
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded, size: 20),
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
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.65)),
      ),
      child: Text(
        clean,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.w800,
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow.withValues(alpha: 0.4),
        borderRadius: AppRadii.r20,
        border: Border.all(
          color: cs.onSurface.withValues(alpha: 0.05),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: cs.primary),
              const SizedBox(width: 8),
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
          const SizedBox(height: 16),
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
          if (i != items.length - 1) const SizedBox(height: 12),
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

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.isDanger,
    this.outlined = false,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final bool isDanger;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (outlined) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: AppRadii.r16),
          side: BorderSide(color: cs.outlineVariant),
        ),
        label: Text(label),
      );
    }

    final color = isDanger ? const Color(0xFFDC2626) : cs.primary;

    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadii.r16,
        gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.8)]),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20, color: Colors.white),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: AppRadii.r16),
        ),
        label: Text(label, style: const TextStyle(color: Colors.white)),
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
