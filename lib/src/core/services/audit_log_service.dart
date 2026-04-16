import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/features/audit/models/audit_log.dart';
import 'dart:developer' as dev;

class AuditLogService {
  AuditLogService(this._db);
  final FirebaseFirestore _db;

  CollectionReference get _collection => _db.collection('auditLogs');

  /// Logs a critical action to the centralized auditLogs collection.
  Future<void> logAction({
    required String action,
    required String module,
    String? academyId,
    required String uid,
    String? userName,
    required String role,
    String? targetDoc,
    Map<String, dynamic>? before,
    Map<String, dynamic>? after,
    AuditSource source = AuditSource.superAdmin,
    AuditSeverity severity = AuditSeverity.low,
  }) async {
    try {
      final session = AppServices.instance.authService?.session;
      final firebaseUser = AppServices.instance.auth?.currentUser;

      String? nameCandidate = userName;
      if (nameCandidate == null || nameCandidate.isEmpty) {
        nameCandidate = session?.user.name;
      }
      if (nameCandidate == null || nameCandidate.isEmpty) {
        nameCandidate = firebaseUser?.displayName;
      }
      if (nameCandidate == null || nameCandidate.isEmpty) {
        nameCandidate = firebaseUser?.email?.split('@').first;
      }

      final resolvedName = nameCandidate ?? 'System Action';

      final log = {
        'action': action,
        'module': module,
        'academyId': academyId,
        'uid': uid,
        'userName': resolvedName,
        'role': role,
        'targetDoc': targetDoc,
        'before': before,
        'after': after,
        'timestamp': FieldValue.serverTimestamp(),
        'source': source.name,
        'severity': severity.name,
      };

      await _collection.add(log);
      dev.log('Audit log created: $action', name: 'AuditLogService');
    } catch (e) {
      dev.log(
        'Error creating audit log: $e',
        name: 'AuditLogService',
        error: e,
      );
    }
  }

  /// Streams the latest audit logs for the Super Admin.
  Stream<List<AuditLog>> watchLogs({
    int limit = 100,
    String? module,
    String? action,
    String? academyId,
    AuditSeverity? severity,
  }) {
    Query query = _collection
        .orderBy('timestamp', descending: true)
        .limit(limit);

    if (module != null) query = query.where('module', isEqualTo: module);
    if (action != null) query = query.where('action', isEqualTo: action);
    if (academyId != null)
      query = query.where('academyId', isEqualTo: academyId);
    if (severity != null)
      query = query.where('severity', isEqualTo: severity.name);

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => AuditLog.fromFirestore(doc)).toList();
    });
  }
}
