import 'package:flutter/material.dart';
import 'package:educore/src/core/mvc/controller_builder.dart';
import 'package:educore/src/features/notifications/controllers/institute_notifications_controller.dart';
import 'package:educore/src/features/notifications/widgets/whatsapp_connect_panel.dart';
import 'package:educore/src/features/notifications/widgets/send_individual_message_panel.dart';
import 'package:educore/src/features/notifications/widgets/broadcast_message_panel.dart';
import 'package:educore/src/features/notifications/widgets/whatsapp_logs_table.dart';

class InstituteNotificationsView extends StatelessWidget {
  const InstituteNotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ControllerBuilder<InstituteNotificationsController>(
      controller: InstituteNotificationsController(),
      builder: (context, controller, child) {
        return DefaultTabController(
          length: 4,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Notifications Hub'),
              bottom: const TabBar(
                isScrollable: true,
                tabs: [
                  Tab(icon: Icon(Icons.chat_bubble_rounded), text: 'Connection'),
                  Tab(icon: Icon(Icons.send_rounded), text: 'Single Message'),
                  Tab(icon: Icon(Icons.campaign_rounded), text: 'Bulk Broadcast'),
                  Tab(icon: Icon(Icons.history_rounded), text: 'Delivery Logs'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                WhatsAppConnectPanel(controller: controller),
                SendIndividualMessagePanel(controller: controller),
                BroadcastMessagePanel(controller: controller),
                WhatsAppLogsTable(controller: controller),
              ],
            ),
          ),
        );
      },
    );
  }
}
