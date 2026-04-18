import 'package:cloud_firestore/cloud_firestore.dart';

enum AuditSeverity {
  info,
  warning,
  critical;

  static AuditSeverity fromString(String? value) {
    return AuditSeverity.values.firstWhere(
      (e) => e.name == value?.toLowerCase(),
      orElse: () => AuditSeverity.info,
    );
  }
}

enum AuditSource {
  superAdmin,
  institute;

  static AuditSource fromString(String? value) {
    return AuditSource.values.firstWhere(
      (e) => e.name == value?.toLowerCase() || e.name == value?.replaceAll('_', '').toLowerCase(),
      orElse: () => AuditSource.institute,
    );
  }
}

class AuditLog {
  const AuditLog({
    required this.id,
    required this.action,
    required this.module,
    required this.academyId,
    required this.actorId,
    required this.userName,
    required this.role,
    this.targetId,
    this.targetType,
    this.before,
    this.after,
    required this.createdAt,
    required this.source,
    required this.severity,
    this.metadata,
    this.sessionId,
  });

  final String id;
  final String action;
  final String module;
  final String academyId;
  final String actorId;
  final String userName;
  final String role;
  final String? targetId;
  final String? targetType;
  final Map<String, dynamic>? before;
  final Map<String, dynamic>? after;
  final DateTime createdAt;
  final AuditSource source;
  final AuditSeverity severity;
  final Map<String, dynamic>? metadata;
  final String? sessionId;

  factory AuditLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AuditLog(
      id: doc.id,
      action: data['action'] ?? '',
      module: data['module'] ?? '',
      academyId: data['academyId'] ?? '',
      actorId: data['actorId'] ?? data['uid'] ?? '',
      userName: data['userName'] ?? data['name'] ?? 'System User',
      role: data['role'] ?? '',
      targetId: data['targetId'] ?? data['targetDoc'],
      targetType: data['targetType'],
      before: data['before'],
      after: data['after'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? 
                 (data['timestamp'] as Timestamp?)?.toDate() ?? 
                 DateTime.now(),
      source: AuditSource.fromString(data['source']),
      severity: AuditSeverity.fromString(data['severity']),
      metadata: data['metadata'],
      sessionId: data['sessionId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'action': action,
      'module': module,
      'academyId': academyId,
      'actorId': actorId,
      'userName': userName,
      'role': role,
      'targetId': targetId,
      'targetType': targetType,
      'before': before,
      'after': after,
      'createdAt': Timestamp.fromDate(createdAt),
      'source': source.name,
      'severity': severity.name,
      'metadata': metadata,
      'sessionId': sessionId,
    };
  }
}
