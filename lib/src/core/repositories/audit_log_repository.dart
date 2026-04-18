import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educore/src/features/audit/models/audit_log.dart';

/// [AuditLogRepository] centralizes access to the platform's audit trail.
///
/// Implements pagination to handle potentially millions of log entries
/// in a high-traffic SaaS environment.
class AuditLogRepository {
  AuditLogRepository(this._firestore);
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('auditLogs');

  /// Fetches a paginated batch of audit logs.
  Future<QuerySnapshot<Map<String, dynamic>>> getRawLogsBatch({
    required int limit,
    DocumentSnapshot? lastDoc,
    String? module,
    String? actorId,
    String? academyId,
    String? severity,
    String? targetId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    Query<Map<String, dynamic>> query = 
        _collection.orderBy('createdAt', descending: true);

    if (academyId != null && academyId != 'all') {
      query = query.where('academyId', isEqualTo: academyId);
    }
    if (module != null && module != 'all') {
      query = query.where('module', isEqualTo: module);
    }
    if (actorId != null && actorId != 'all') {
      query = query.where('actorId', isEqualTo: actorId);
    }
    if (targetId != null && targetId != 'all') {
      query = query.where('targetId', isEqualTo: targetId);
    }
    if (severity != null && severity != 'all') {
      query = query.where('severity', isEqualTo: severity.toLowerCase());
    }

    if (startDate != null) {
      query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    if (endDate != null) {
      query = query.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    return query.limit(limit).get();
  }

  /// Convenience wrapper that returns AuditLog objects.
  Future<List<AuditLog>> getLogsBatch({
    int limit = 50,
    DocumentSnapshot? lastDoc,
    String? module,
    String? actorId,
    String? academyId,
    String? severity,
  }) async {
    final snapshot = await getRawLogsBatch(
      limit: limit,
      lastDoc: lastDoc,
      module: module,
      actorId: actorId,
      academyId: academyId,
      severity: severity,
    );
    
    return snapshot.docs
        .map((doc) => AuditLog.fromFirestore(doc))
        .toList();
  }
}
