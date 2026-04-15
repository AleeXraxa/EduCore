import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/mvc/controller_builder.dart';
import 'package:educore/src/core/responsive/breakpoints.dart';
import 'package:educore/src/core/ui/widgets/app_dropdown.dart';
import 'package:educore/src/core/ui/widgets/kpi_card.dart';
import 'package:educore/src/features/subscriptions/subscriptions_controller.dart';
import 'package:educore/src/features/subscriptions/widgets/subscriptions_table.dart';
import 'package:educore/src/features/subscriptions/widgets/subscription_details_dialog.dart';
import 'package:flutter/material.dart';

class SubscriptionsView extends StatefulWidget {
  const SubscriptionsView({super.key});

  @override
  State<SubscriptionsView> createState() => _SubscriptionsViewState();
}

class _SubscriptionsViewState extends State<SubscriptionsView> {
  late final SubscriptionsController _controller;
  final _search = TextEditingController();
  SubscriptionsFilter _filter = SubscriptionsFilter.all;
  String _planId = 'all';

  @override
  void initState() {
    super.initState();
    _controller = SubscriptionsController();
  }

  @override
  void dispose() {
    _search.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const toolbarHeight = 48.0;

    return ControllerBuilder<SubscriptionsController>(
      controller: _controller,
      builder: (context, controller, _) {
        if (!controller.ready) {
          return _NotReadyPanel(
            busy: controller.busy,
            message: controller.errorMessage,
            onRetry: controller.retryInit,
          );
        }

        final kpis = controller.kpis;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Subscriptions',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.4,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Manage plans, approvals, and subscription lifecycle.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 18),
                  SizedBox(
                    width: 340,
                    height: toolbarHeight,
                    child: TextField(
                      controller: _search,
                      onChanged: controller.setQuery,
                      decoration: InputDecoration(
                        hintText: 'Search by institute name',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: cs.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AppRadii.r12,
                          borderSide: BorderSide(color: cs.outlineVariant),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AppRadii.r12,
                          borderSide: BorderSide(color: cs.primary, width: 1.2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 190,
                    height: toolbarHeight,
                    child: AppDropdown<SubscriptionsFilter>(
                      label: 'Status',
                      showLabel: false,
                      compact: true,
                      prefixIcon: Icons.filter_alt_rounded,
                      items: const [
                        SubscriptionsFilter.all,
                        SubscriptionsFilter.active,
                        SubscriptionsFilter.pending,
                        SubscriptionsFilter.expired,
                        SubscriptionsFilter.canceled,
                      ],
                      value: _filter,
                      hintText: 'Status',
                      itemLabel: (f) => switch (f) {
                        SubscriptionsFilter.all => 'All',
                        SubscriptionsFilter.active => 'Active',
                        SubscriptionsFilter.pending => 'Pending approval',
                        SubscriptionsFilter.expired => 'Expired',
                        SubscriptionsFilter.canceled => 'Canceled',
                      },
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _filter = value);
                        controller.setFilter(value);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 180,
                    height: toolbarHeight,
                    child: AppDropdown<String>(
                      label: 'Plan',
                      showLabel: false,
                      compact: true,
                      prefixIcon: Icons.workspace_premium_rounded,
                      items: controller.planIds,
                      value: _planId,
                      hintText: 'Plan',
                      itemLabel: controller.planNameForId,
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _planId = value);
                        controller.setPlanIdFilter(value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  final size = screenSizeForWidth(constraints.maxWidth);
                  final columns = switch (size) {
                    ScreenSize.compact => 1,
                    ScreenSize.medium => 2,
                    ScreenSize.expanded => 4,
                  };

                  final items = [
                    KpiCardData(
                      label: 'Total Subscriptions',
                      value: _fmtInt(kpis.total),
                      icon: Icons.receipt_long_rounded,
                      gradient: const [Color(0xFF2563EB), Color(0xFF6366F1)],
                    ),
                    KpiCardData(
                      label: 'Active Subscriptions',
                      value: _fmtInt(kpis.active),
                      icon: Icons.verified_rounded,
                      gradient: const [Color(0xFF16A34A), Color(0xFF22C55E)],
                    ),
                    KpiCardData(
                      label: 'Expired Subscriptions',
                      value: _fmtInt(kpis.expired),
                      icon: Icons.warning_rounded,
                      gradient: const [Color(0xFFF59E0B), Color(0xFFF97316)],
                    ),
                    KpiCardData(
                      label: 'Monthly Revenue',
                      value: _fmtMoney(kpis.monthRevenuePkr),
                      icon: Icons.payments_rounded,
                      gradient: const [Color(0xFF2563EB), Color(0xFF8B5CF6)],
                    ),
                  ];

                  const gap = 12.0;
                  final totalGap = gap * (columns - 1);
                  final cardWidth = (constraints.maxWidth - totalGap) / columns;

                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (final kpi in items)
                        SizedBox(
                          width: cardWidth,
                          child: KpiCard(data: kpi),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              SubscriptionsTable(
                items: controller.paged,
                onAction: (action) async {
                  final sub = controller.paged.firstWhere(
                    (e) => e.id == action.subscriptionId,
                  );

                  switch (action.action) {
                    case SubscriptionMenuAction.view:
                      if (!context.mounted) return;
                      SubscriptionDetailsDialog.show(
                        context,
                        subscription: sub,
                      );
                      break;
                    case SubscriptionMenuAction.approve:
                      await controller.approve(action.subscriptionId);
                      break;
                    case SubscriptionMenuAction.reject:
                      await controller.reject(action.subscriptionId);
                      break;
                    case SubscriptionMenuAction.extend:
                      await controller.extend30Days(action.subscriptionId);
                      break;
                    case SubscriptionMenuAction.cancel:
                      await controller.cancel(action.subscriptionId);
                      break;
                    case SubscriptionMenuAction.changePlan:
                      final ids = controller.planIds
                          .where((e) => e != 'all')
                          .toList();
                      if (ids.isEmpty) break;
                      final curIndex = ids.indexOf(sub.planId);
                      final next =
                          ids[(curIndex < 0 ? 0 : (curIndex + 1) % ids.length)];
                      await controller.changePlan(action.subscriptionId, next);
                      break;
                  }
                },
              ),
              const SizedBox(height: 12),
              _PaginationBar(
                total: controller.totalCount,
                page: controller.page,
                pageSize: controller.pageSize,
                onPrev: controller.prevPage,
                onNext: controller.nextPage,
              ),
              const SizedBox(height: 4),
              Text(
                'Tip: Expiring subscriptions are subtly highlighted for fast review.',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NotReadyPanel extends StatelessWidget {
  const _NotReadyPanel({
    this.busy = false,
    this.message,
    required this.onRetry,
  });

  final bool busy;
  final String? message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: AppRadii.r16,
          border: Border.all(color: cs.outlineVariant),
          boxShadow: AppShadows.soft(Colors.black),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.cloud_off_rounded, color: cs.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    busy ? 'Initializing Firebase…' : 'Firestore not ready',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message?.trim().isNotEmpty == true
                        ? message!.trim()
                        : 'Subscriptions require Firebase Firestore. Initialize Firebase to enable this module.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: busy ? null : () async => onRetry(),
              icon: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(
                backgroundColor: cs.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.total,
    required this.page,
    required this.pageSize,
    required this.onPrev,
    required this.onNext,
  });

  final int total;
  final int page;
  final int pageSize;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final start = total == 0 ? 0 : (page * pageSize) + 1;
    final end = (page * pageSize + pageSize).clamp(0, total);

    return Row(
      children: [
        Text(
          '$start–$end of $total',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        _PagerIcon(
          icon: Icons.chevron_left_rounded,
          tooltip: 'Previous',
          onTap: onPrev,
        ),
        const SizedBox(width: 8),
        _PagerIcon(
          icon: Icons.chevron_right_rounded,
          tooltip: 'Next',
          onTap: onNext,
        ),
      ],
    );
  }
}

class _PagerIcon extends StatefulWidget {
  const _PagerIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  State<_PagerIcon> createState() => _PagerIconState();
}

class _PagerIconState extends State<_PagerIcon> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = _hovered ? cs.surfaceContainerHighest : cs.surface;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: widget.onTap,
            child: Icon(widget.icon, color: cs.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}

String _fmtMoney(int pkr) => 'PKR ${_fmtInt(pkr)}';

String _fmtInt(int v) {
  final s = v.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final idx = s.length - 1 - i;
    b.write(s[idx]);
    if ((i + 1) % 3 == 0 && idx != 0) b.write(',');
  }
  return b.toString().split('').reversed.join();
}
