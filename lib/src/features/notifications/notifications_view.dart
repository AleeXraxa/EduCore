import 'package:educore/src/core/mvc/controller_builder.dart';
import 'package:educore/src/features/notifications/notifications_controller.dart';
import 'package:educore/src/features/notifications/widgets/create_notification_dialog.dart';
import 'package:educore/src/features/notifications/widgets/notifications_table.dart';
import 'package:flutter/material.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  final _controller = NotificationsController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ControllerBuilder(
      controller: _controller,
      builder: (context, controller, child) {
        return Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notifications Management',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Broadcast messages and manage system announcements',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => controller.triggerExpiryReminders(),
                          icon: const Icon(Icons.auto_fix_high_rounded),
                          label: const Text('Run Expiry Check'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: () => _showCreateDialog(context, controller),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('New Notification'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: controller.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: NotificationsTable(
                            notifications: controller.notifications,
                            onDelete: controller.deleteNotification,
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCreateDialog(BuildContext context, NotificationsController controller) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CreateNotificationDialog(controller: controller),
    );
  }
}
