import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educore/src/features/settings/models/global_settings.dart';

import 'package:educore/src/core/services/audit_log_service.dart';
import 'package:educore/src/features/audit/models/audit_log.dart';

class SettingsService {
  final FirebaseFirestore _firestore;
  final AuditLogService _audit;
  
  SettingsService({
    required FirebaseFirestore firestore,
    required AuditLogService auditLogService,
  })  : _firestore = firestore,
        _audit = auditLogService;

  Future<GlobalSettings?> getGlobalSettings() async {
    final doc = await _firestore.collection('settings').doc('global').get();
    if (!doc.exists) return null;
    return GlobalSettings.fromFirestore(doc);
  }

  Stream<GlobalSettings?> watchGlobalSettings() {
    return _firestore.collection('settings').doc('global').snapshots().map((doc) {
      if (!doc.exists) return null;
      return GlobalSettings.fromFirestore(doc);
    });
  }

  Future<void> updateGlobalSettings(GlobalSettings settings, {String? userId}) async {
    final data = settings.toFirestore();
    if (userId != null) {
      data['updatedBy'] = userId;
    }
    await _firestore.collection('settings').doc('global').set(
      data,
      SetOptions(merge: true),
    );

    // Log Action
    await _audit.logAction(
      action: 'SETTINGS_UPDATED',
      module: 'settings',
      uid: userId ?? 'super_admin_system',
      role: 'super_admin',
      targetDoc: 'settings/global',
      after: data,
      severity: AuditSeverity.medium,
    );
  }
}
