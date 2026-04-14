import 'package:educore/src/core/mvc/base_controller.dart';
import 'package:educore/src/features/notifications/models/admin_notification.dart';

class NotificationsController extends BaseController {
  final List<AdminNotification> _history = <AdminNotification>[];
  List<AdminNotification> get history => List.unmodifiable(_history);

  final List<String> institutes = const [
    'Green Valley Academy',
    'City School – North Campus',
    'Apex Institute',
    'Sunrise School',
    'Beacon Academy',
    'NextGen Institute',
  ];

  NotificationsController() {
    _seedMock();
  }

  Future<void> send({
    required String title,
    required String message,
    required AdminNotificationType type,
    required AdminNotificationAudience audience,
    required List<String> targets,
    DateTime? scheduledFor,
  }) async {
    await runBusy<void>(() async {
      await Future<void>.delayed(const Duration(milliseconds: 220));
      final now = DateTime.now();
      final status = scheduledFor == null
          ? AdminNotificationStatus.sent
          : AdminNotificationStatus.scheduled;
      _history.insert(
        0,
        AdminNotification(
          id: now.microsecondsSinceEpoch.toString(),
          title: title,
          message: message,
          type: type,
          audience: audience,
          targets: audience == AdminNotificationAudience.allInstitutes
              ? const []
              : List<String>.unmodifiable(targets),
          status: status,
          createdAt: now,
          scheduledFor: scheduledFor,
        ),
      );
    });
    notifyListeners();
  }

  void delete(String id) {
    _history.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  void resend(String id) {
    final idx = _history.indexWhere((e) => e.id == id);
    if (idx < 0) return;
    final cur = _history[idx];
    final now = DateTime.now();
    _history[idx] = AdminNotification(
      id: cur.id,
      title: cur.title,
      message: cur.message,
      type: cur.type,
      audience: cur.audience,
      targets: cur.targets,
      status: AdminNotificationStatus.sent,
      createdAt: now,
    );
    notifyListeners();
  }

  void _seedMock() {
    final now = DateTime.now();
    _history.addAll([
      AdminNotification(
        id: 'n1',
        title: 'Maintenance window',
        message:
            'We will perform scheduled maintenance tonight. Some services may be intermittently unavailable.',
        type: AdminNotificationType.alert,
        audience: AdminNotificationAudience.allInstitutes,
        targets: const [],
        status: AdminNotificationStatus.sent,
        createdAt: now.subtract(const Duration(hours: 6)),
      ),
      AdminNotification(
        id: 'n2',
        title: 'Subscription renewal reminder',
        message:
            'Your subscription is expiring soon. Please submit payment proof to avoid access restrictions.',
        type: AdminNotificationType.reminder,
        audience: AdminNotificationAudience.specificInstitutes,
        targets: const ['Green Valley Academy', 'Sunrise School'],
        status: AdminNotificationStatus.scheduled,
        createdAt: now.subtract(const Duration(days: 1)),
        scheduledFor: now.add(const Duration(hours: 12)),
      ),
      AdminNotification(
        id: 'n3',
        title: 'New feature: Monthly stats',
        message:
            'You can now view pre-aggregated monthly stats in the dashboard for faster insights.',
        type: AdminNotificationType.announcement,
        audience: AdminNotificationAudience.allInstitutes,
        targets: const [],
        status: AdminNotificationStatus.sent,
        createdAt: now.subtract(const Duration(days: 3)),
      ),
    ]);
  }
}

