import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  broadcast,
  targeted,
  system,
}

enum NotificationTargetType {
  all,
  single,
}

enum NotificationStatus {
  sent,
  scheduled,
}

class AppNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final NotificationTargetType targetType;
  final String? academyId;
  final String? academyName;
  final NotificationStatus status;
  final DateTime createdAt;
  final String createdBy;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.targetType,
    this.academyId,
    this.academyName,
    required this.status,
    required this.createdAt,
    required this.createdBy,
  });

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: NotificationType.values.byName(data['type'] ?? 'broadcast'),
      targetType: NotificationTargetType.values.byName(data['targetType'] ?? 'all'),
      academyId: data['academyId'],
      academyName: data['academyName'],
      status: NotificationStatus.values.byName(data['status'] ?? 'sent'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'message': message,
      'type': type.name,
      'targetType': targetType.name,
      'academyId': academyId,
      'academyName': academyName,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
    };
  }

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    NotificationTargetType? targetType,
    String? academyId,
    String? academyName,
    NotificationStatus? status,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      targetType: targetType ?? this.targetType,
      academyId: academyId ?? this.academyId,
      academyName: academyName ?? this.academyName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
