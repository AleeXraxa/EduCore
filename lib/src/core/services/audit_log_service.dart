import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/features/audit/models/audit_log.dart';
import 'dart:developer' as dev;

class AuditLogService {
  AuditLogService(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _collection => 
      _db.collection('auditLogs');

  /// Logs a structured action to the centralized auditLogs collection.
  Future<void> logAction({
    required String action,
    required String module,
    required String targetId,
    String? targetType,
    Map<String, dynamic>? before,
    Map<String, dynamic>? after,
    Map<String, dynamic>? metadata,
    AuditSeverity severity = AuditSeverity.info,
    AuditSource source = AuditSource.institute,
  }) async {
    try {
      final session = AppServices.instance.authService?.session;
      if (session == null) {
        dev.log('Skipping audit log: No active session', name: 'AuditLogService');
        return;
      }

      final log = {
        'action': action,
        'module': module,
        'academyId': session.academyId,
        'actorId': session.user.uid,
        'userName': session.user.name,
        'role': session.user.role,
        'targetId': targetId,
        'targetType': targetType,
        'before': before,
        'after': after,
        'metadata': metadata,
        'createdAt': FieldValue.serverTimestamp(),
        'source': source.name,
        'severity': severity.name,
        'sessionId': session.sessionId, // Future-ready
      };

      await _collection.add(log);
      dev.log('Audit log created: $action on $targetId', name: 'AuditLogService');
    } catch (e) {
      dev.log('Error creating audit log: $e', name: 'AuditLogService', error: e);
    }
  }

  /// Streams audit logs with real-time updates and basic filtering.
  Stream<List<AuditLog>> watchAcademyLogs({
    required String academyId,
    String? module,
    String? actorId,
    int limit = 50,
  }) {
    Query<Map<String, dynamic>> query = _collection
        .where('academyId', isEqualTo: academyId)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (module != null) query = query.where('module', isEqualTo: module);
    if (actorId != null) query = query.where('actorId', isEqualTo: actorId);

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => AuditLog.fromFirestore(doc)).toList();
    });
  }

  /// Fetches paginated logs for high-performance querying.
  Future<QuerySnapshot<Map<String, dynamic>>> getPaginatedLogs({
    required String academyId,
    String? module,
    String? actorId,
    String? targetId,
    DateTime? startDate,
    DateTime? endDate,
    DocumentSnapshot? startAfter,
    int limit = 20,
  }) async {
    Query<Map<String, dynamic>> query = _collection
        .where('academyId', isEqualTo: academyId)
        .orderBy('createdAt', descending: true);

    if (module != null) query = query.where('module', isEqualTo: module);
    if (actorId != null) query = query.where('actorId', isEqualTo: actorId);
    if (targetId != null) query = query.where('targetId', isEqualTo: targetId);
    
    if (startDate != null) {
      query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    if (endDate != null) {
      query = query.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    return query.limit(limit).get();
  }
}
