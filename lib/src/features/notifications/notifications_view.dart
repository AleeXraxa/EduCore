
import 'package:educore/src/core/mvc/controller_builder.dart';
import 'package:educore/src/core/responsive/breakpoints.dart';
import 'package:educore/src/core/ui/widgets/app_animated_slide.dart';
import 'package:educore/src/core/ui/widgets/app_kpi_grid.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
import 'package:educore/src/core/ui/widgets/kpi_card.dart';
import 'package:educore/src/features/notifications/notifications_controller.dart';
import 'package:educore/src/features/notifications/widgets/create_notification_dialog.dart';
import 'package:educore/src/features/notifications/widgets/notifications_table.dart';
import 'package:educore/src/core/ui/widgets/app_loading_overlay.dart';
import 'package:flutter/material.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  late final NotificationsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = NotificationsController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ControllerBuilder<NotificationsController>(
      controller: _controller,
      builder: (context, controller, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final size = screenSizeForWidth(constraints.maxWidth);
            final kpiCols = switch (size) {
              ScreenSize.compact => 1,
              ScreenSize.medium => 2,
              ScreenSize.expanded => 3,
            };

            final totalCount = controller.notifications.length;
            final broadcastCount = controller.notifications
                .where((e) => e.academyId == null)
                .length;
            final targetedCount = totalCount - broadcastCount;

            final kpis = [
              KpiCardData(
                label: 'Total Sent',
                value: totalCount.toString(),
                icon: Icons.notifications_rounded,
                gradient: const [Color(0xFF2563EB), Color(0xFF4F46E5)],
              ),
              KpiCardData(
                label: 'Global Broadcasts',
                value: broadcastCount.toString(),
                icon: Icons.campaign_rounded,
                gradient: const [Color(0xFF7C3AED), Color(0xFF6366F1)],
              ),
              KpiCardData(
                label: 'Targeted Alerts',
                value: targetedCount.toString(),
                icon: Icons.near_me_rounded,
                gradient: const [Color(0xFF0EA5E9), Color(0xFF22D3EE)],
              ),
            ];

            return SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
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
                                'Notifications',
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
                                'Broadcast messages and manage system-wide announcements.',
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
                        const SizedBox(width: 16),
                        AppPrimaryButton(
                          variant: AppButtonVariant.secondary,
                          onPressed: () => controller.triggerExpiryReminders(),
                          icon: Icons.auto_fix_high_rounded,
                          label: 'Run Expiry Check',
                        ),
                        const SizedBox(width: 12),
                        AppPrimaryButton(
                          onPressed: () =>
                              _showCreateDialog(context, controller),
                          icon: Icons.add_rounded,
                          label: 'New Notification',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  AppAnimatedSlide(
                    delayIndex: 1,
                    child: AppKpiGrid(columns: kpiCols, items: kpis),
                  ),
                  const SizedBox(height: 24),
                  AppLoadingOverlay(
                    isLoading: controller.busy,
                    message: 'Broadcasting Messages',
                    child: AppAnimatedSlide(
                      delayIndex: 2,
                      child: NotificationsTable(
                        notifications: controller.notifications,
                        onDelete: controller.deleteNotification,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppAnimatedSlide(
                    delayIndex: 3,
                    child: Row(
                      children: [
                        Icon(Icons.security_rounded,
                            color: cs.primary, size: 14),
                        const SizedBox(width: 8),
                        Text(
                          'AUDIT: All broadcast events are tracked and visible to institute administrators.',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCreateDialog(
      BuildContext context, NotificationsController controller) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CreateNotificationDialog(controller: controller),
    );
  }
}
