enum AdminNotificationType { announcement, reminder, alert }

enum AdminNotificationAudience { allInstitutes, specificInstitutes }

enum AdminNotificationStatus { sent, scheduled, failed }

class AdminNotification {
  const AdminNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.audience,
    required this.targets,
    required this.status,
    required this.createdAt,
    this.scheduledFor,
  });

  final String id;
  final String title;
  final String message;
  final AdminNotificationType type;
  final AdminNotificationAudience audience;

  /// Institute names (or ids later). Empty if audience = all.
  final List<String> targets;

  final AdminNotificationStatus status;
  final DateTime createdAt;
  final DateTime? scheduledFor;
}

