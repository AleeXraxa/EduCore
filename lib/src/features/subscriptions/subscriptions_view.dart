import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/mvc/controller_builder.dart';
import 'package:educore/src/core/responsive/breakpoints.dart';
import 'package:educore/src/core/ui/widgets/app_animated_slide.dart';
import 'package:educore/src/core/ui/widgets/app_kpi_grid.dart';
import 'package:educore/src/core/ui/widgets/app_pagination_bar.dart';
import 'package:educore/src/core/ui/widgets/app_dialogs.dart';
import 'package:educore/src/core/ui/widgets/app_dropdown.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
import 'package:educore/src/core/ui/widgets/app_search_field.dart';
import 'package:educore/src/core/ui/widgets/kpi_card.dart';
import 'package:educore/src/features/subscriptions/subscriptions_controller.dart';
import 'package:educore/src/features/subscriptions/widgets/subscriptions_table.dart';
import 'package:educore/src/features/subscriptions/widgets/subscription_details_dialog.dart';
import 'package:educore/src/features/subscriptions/widgets/edit_subscription_dialog.dart';
import 'package:educore/src/features/subscriptions/widgets/add_subscription_dialog.dart';
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
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppAnimatedSlide(
                delayIndex: 0,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Subscriptions',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.8,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Manage institute subscriptions, renewals, and approvals.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 18),
                    AppSearchField(
                      width: 320,
                      controller: _search,
                      onChanged: controller.setQuery,
                      hintText: 'Search subscriptions…',
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
                    const SizedBox(width: 12),
                    AppPrimaryButton(
                      onPressed: () async {
                        final res = await AddSubscriptionDialog.show(
                          context,
                          academies: controller.academies,
                          plans: controller.plans,
                        );
                        if (res != null) {
                          try {
                            AppDialogs.showLoading(context,
                                message: 'Creating subscription...');
                            await controller.addSubscription(
                              academyId: res.academyId,
                              planId: res.planId,
                              durationMonths: res.durationMonths,
                            );
                            if (!context.mounted) return;
                            AppDialogs.hide(context);
                            AppDialogs.showSuccess(
                              context,
                              title: 'Subscription Active',
                              message:
                                  'A new subscription has been successfully provisioned and activated.',
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            AppDialogs.hide(context);
                            AppDialogs.showError(
                              context,
                              title: 'Activation Failed',
                              message: e.toString(),
                            );
                          }
                        }
                      },
                      icon: Icons.add_rounded,
                      label: 'Add Subscription',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              AppAnimatedSlide(
                delayIndex: 1,
                child: LayoutBuilder(
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

                    return AppKpiGrid(columns: columns, items: items);
                  },
                ),
              ),
              const SizedBox(height: 24),
              AppAnimatedSlide(
                delayIndex: 2,
                child: SubscriptionsTable(
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
                      case SubscriptionMenuAction.edit:
                        if (!context.mounted) return;
                        EditSubscriptionDialog.show(
                          context,
                          subscription: sub,
                          plans: controller.plans,
                          onSave: (planId, status, expiry) async {
                            try {
                              AppDialogs.showLoading(context,
                                  message: 'Updating subscription...');
                              await controller.updateSubscriptionDetails(
                                sub.id,
                                planId: planId,
                                status: status,
                                expiryDate: expiry,
                              );
                              if (!context.mounted) return;
                              AppDialogs.hide(context);
                              AppDialogs.showSuccess(
                                context,
                                title: 'Changes Saved',
                                message:
                                    'The subscription details have been updated successfully.',
                              );
                            } catch (e) {
                              if (!context.mounted) return;
                              AppDialogs.hide(context);
                              AppDialogs.showError(
                                context,
                                title: 'Update Failed',
                                message: e.toString(),
                              );
                            }
                          },
                        );
                        break;
                      case SubscriptionMenuAction.approve:
                        try {
                          AppDialogs.showLoading(context,
                              message: 'Approving subscription...');
                          await controller.approve(action.subscriptionId);
                          if (!context.mounted) return;
                          AppDialogs.hide(context);
                          AppDialogs.showSuccess(
                            context,
                            title: 'Approval Complete',
                            message:
                                'The subscription has been approved and moved to active status.',
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          AppDialogs.hide(context);
                          AppDialogs.showError(
                            context,
                            title: 'Operation Failed',
                            message: e.toString(),
                          );
                        }
                        break;
                      case SubscriptionMenuAction.reject:
                        await controller.reject(action.subscriptionId);
                        break;
                      case SubscriptionMenuAction.extend:
                        await controller.extend30Days(action.subscriptionId);
                        break;

                      case SubscriptionMenuAction.changePlan:
                        final ids = controller.planIds
                            .where((e) => e != 'all')
                            .toList();
                        if (ids.isEmpty) break;
                        final curIndex = ids.indexOf(sub.planId);
                        final next = ids[(curIndex < 0
                            ? 0
                            : (curIndex + 1) % ids.length)];
                        await controller.changePlan(
                          action.subscriptionId,
                          next,
                        );
                        break;
                    }
                  },
                ),
              ),
              const SizedBox(height: 20),
              AppAnimatedSlide(
                delayIndex: 3,
                child: Column(
                  children: [
                    AppPaginationBar(
                      total: controller.totalCount,
                      page: controller.page,
                      pageSize: controller.pageSize,
                      onPrev: controller.prevPage,
                      onNext: controller.nextPage,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.shield_outlined,
                            color: cs.primary, size: 14),
                        const SizedBox(width: 8),
                        Text(
                          'NOTE: All subscription changes and plan updates are securely logged for audit purposes.',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                        ),
                      ],
                    ),
                  ],
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

String _fmtMoney(int pkr) => 'PKR ${_fmtInt(pkr)}';

String _fmtInt(int v) {
  final s = v.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final idx = s.length - i;
    buf.write(s[i]);
    if (idx > 1 && idx % 3 == 1) buf.write(',');
  }
  return buf.toString();
}
