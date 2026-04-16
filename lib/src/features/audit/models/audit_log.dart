import 'package:cloud_firestore/cloud_firestore.dart';

enum AuditSeverity {
  low,
  medium,
  high;

  static AuditSeverity fromString(String? value) {
    return AuditSeverity.values.firstWhere(
      (e) => e.name == value?.toLowerCase(),
      orElse: () => AuditSeverity.low,
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
    this.academyId,
    required this.uid,
    required this.userName,
    required this.role,
    this.targetDoc,
    this.before,
    this.after,
    required this.timestamp,
    required this.source,
    required this.severity,
  });

  final String id;
  final String action;
  final String module;
  final String? academyId;
  final String uid;
  final String userName;
  final String role;
  final String? targetDoc;
  final Map<String, dynamic>? before;
  final Map<String, dynamic>? after;
  final DateTime timestamp;
  final AuditSource source;
  final AuditSeverity severity;

  factory AuditLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AuditLog(
      id: doc.id,
      action: data['action'] ?? '',
      module: data['module'] ?? '',
      academyId: data['academyId'],
      uid: data['uid'] ?? '',
      userName: data['userName'] ?? data['name'] ?? 'System User',
      role: data['role'] ?? '',
      targetDoc: data['targetDoc'],
      before: data['before'],
      after: data['after'],
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      source: AuditSource.fromString(data['source']),
      severity: AuditSeverity.fromString(data['severity']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'action': action,
      'module': module,
      'academyId': academyId,
      'uid': uid,
      'userName': userName,
      'role': role,
      'targetDoc': targetDoc,
      'before': before,
      'after': after,
      'timestamp': Timestamp.fromDate(timestamp),
      'source': source.name,
      'severity': severity.name,
    };
  }
}
