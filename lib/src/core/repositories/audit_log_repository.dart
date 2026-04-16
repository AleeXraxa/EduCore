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
  Future<List<AuditLog>> getLogsBatch({
    int limit = 50,
    DocumentSnapshot? lastDoc,
    String? module,
    String? action,
    String? academyId,
    String? severity,
  }) async {
    Query query = _collection.orderBy('timestamp', descending: true);

    if (module != null && module != 'all') {
      query = query.where('module', isEqualTo: module);
    }
    if (action != null && action != 'all') {
      query = query.where('action', isEqualTo: action);
    }
    if (academyId != null && academyId != 'all') {
      query = query.where('academyId', isEqualTo: academyId);
    }
    if (severity != null && severity != 'all') {
      query = query.where('severity', isEqualTo: severity);
    }

    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    final snapshot = await query.limit(limit).get();
    
    return snapshot.docs
        .map((doc) => AuditLog.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
        .toList();
  }

  /// Low-level logging (usually called from services or other repositories).
  Future<void> addLog(Map<String, dynamic> logData) async {
    await _collection.add({
      ...logData,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
