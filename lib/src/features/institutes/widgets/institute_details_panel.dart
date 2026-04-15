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
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
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
  State<_InstituteDetailsDialog> createState() => _InstituteDetailsDialogState();
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
    final panelWidth =
        MediaQuery.of(context).size.width < 560 ? double.infinity : 520.0;
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
                  color: cs.surface,
                  borderRadius: AppRadii.r16,
                  border: Border.all(color: cs.outlineVariant),
                  boxShadow: AppShadows.soft(Colors.black),
                ),
                child: ClipRRect(
                  borderRadius: AppRadii.r16,
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
                            instituteName: academy?.name ?? widget.institute.name,
                            planName: planName,
                            status: academy?.status ?? widget.institute.status,
                            onClose: () => Navigator.of(context).pop(),
                          ),
                          const Divider(height: 1),
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _SectionTitle('Institute'),
                                  const SizedBox(height: 10),
                                  _InfoGrid(
                                    items: [
                                      ('Academy ID', widget.institute.id),
                                      (
                                        'Owner',
                                        academy?.ownerName ??
                                            widget.institute.ownerName
                                      ),
                                      ('Email', academy?.email ?? widget.institute.email),
                                      ('Phone', academy?.phone ?? widget.institute.phone),
                                      ('Address', academy?.address ?? widget.institute.address),
                                      ('Plan', planName),
                                      (
                                        'Created',
                                        _fmtDateTime(academy?.createdAt ?? widget.institute.createdAt),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 18),
                                  _SectionTitle('Subscription'),
                                  const SizedBox(height: 10),
                                  if (subscription == null)
                                    Text(
                                      'No subscription record found yet.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(
                                            color: cs.onSurfaceVariant,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    )
                                  else
                                    _InfoGrid(
                                      items: [
                                        ('Status', _subStatusLabel(subscription.status)),
                                        ('Start', _fmtDate(subscription.startDate)),
                                        ('End', _fmtDate(subscription.endDate)),
                                        ('Overrides', '${subscription.overrides.length}'),
                                        (
                                          'Updated',
                                          _fmtDateTime(subscription.updatedAt),
                                        ),
                                      ],
                                    ),
                                  const SizedBox(height: 18),
                                  _SectionTitle('Admin Account'),
                                  const SizedBox(height: 10),
                                  if (controller.instituteAdmin == null)
                                    Text(
                                      'No institute admin user found in `users/` for this academy.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(
                                            color: cs.onSurfaceVariant,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    )
                                  else
                                    _InfoGrid(
                                      items: [
                                        ('Email', controller.instituteAdmin!.email),
                                        ('Status', controller.instituteAdmin!.status),
                                        ('Created', _fmtDateTime(controller.instituteAdmin!.createdAt)),
                                      ],
                                    ),
                                  const SizedBox(height: 18),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: FilledButton.icon(
                                          onPressed: () {
                                            widget.onToggleBlocked();
                                            Navigator.of(context).pop();
                                          },
                                          icon: Icon(
                                            (academy?.status ??
                                                        widget.institute.status) ==
                                                    AcademyStatus.blocked
                                                ? Icons.lock_open_rounded
                                                : Icons.block_rounded,
                                          ),
                                          style: FilledButton.styleFrom(
                                            backgroundColor:
                                                (academy?.status ??
                                                            widget.institute.status) ==
                                                        AcademyStatus.blocked
                                                    ? cs.primary
                                                    : const Color(0xFFB91C1C),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 14,
                                            ),
                                          ),
                                          label: Text(
                                            (academy?.status ??
                                                        widget.institute.status) ==
                                                    AcademyStatus.blocked
                                                ? 'Unblock institute'
                                                : 'Block institute',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () =>
                                              Navigator.of(context).pop(),
                                          icon: const Icon(Icons.close_rounded),
                                          style: OutlinedButton.styleFrom(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 14,
                                            ),
                                          ),
                                          label: const Text('Close'),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (controller.errorMessage?.trim().isNotEmpty ==
                                      true) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      controller.errorMessage!.trim(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(
                                            color: const Color(0xFFB91C1C),
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
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.apartment_rounded, color: cs.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  instituteName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    InstituteStatusBadge(status: status),
                    _PlanPill(label: planName),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.2,
          ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.items});

  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          _InfoRow(label: items[i].$1, value: items[i].$2),
          if (i != items.length - 1)
            Divider(height: 14, color: cs.outlineVariant.withValues(alpha: 0.7)),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value.trim().isEmpty ? '—' : value.trim(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
      ],
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

String _fmtDateTime(DateTime? value) {
  if (value == null) return '—';
  final date = _fmtDate(value);
  final hh = value.hour.toString().padLeft(2, '0');
  final mm = value.minute.toString().padLeft(2, '0');
  return '$date $hh:$mm';
}

String _subStatusLabel(SubscriptionRecordStatus status) {
  return switch (status) {
    SubscriptionRecordStatus.active => 'Active',
    SubscriptionRecordStatus.expired => 'Expired',
    SubscriptionRecordStatus.pending => 'Pending',
    SubscriptionRecordStatus.canceled => 'Canceled',
  };
}
