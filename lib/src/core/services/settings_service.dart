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

  Future<GlobalSettings?> getAcademySettings(String academyId) async {
    final doc = await _firestore
        .collection('academies')
        .doc(academyId)
        .collection('settings')
        .doc('institute')
        .get();
    if (!doc.exists) return null;
    return GlobalSettings.fromFirestore(doc);
  }

  Stream<GlobalSettings?> watchAcademySettings(String academyId) {
    return _firestore
        .collection('academies')
        .doc(academyId)
        .collection('settings')
        .doc('institute')
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return GlobalSettings.fromFirestore(doc);
    });
  }

  Future<void> updateAcademySettings(
    String academyId,
    GlobalSettings settings, {
    String? userId,
  }) async {
    final data = settings.toFirestore();
    if (userId != null) {
      data['updatedBy'] = userId;
    }
    await _firestore
        .collection('academies')
        .doc(academyId)
        .collection('settings')
        .doc('institute')
        .set(data, SetOptions(merge: true));

    // Log Action
    await _audit.logAction(
      action: 'ACADEMY_SETTINGS_UPDATED',
      module: 'settings',
      targetId: academyId,
      targetType: 'academy_settings',
      after: data,
      severity: AuditSeverity.warning,
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // GLOBAL PLATFORM SETTINGS (Super Admin Only)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Future<GlobalSettings?> getGlobalSettings() async {
    final doc = await _firestore.collection('system').doc('settings').collection('platform').doc('config').get();
    if (!doc.exists) return null;
    return GlobalSettings.fromFirestore(doc);
  }

  Stream<GlobalSettings?> watchGlobalSettings() {
    return _firestore
        .collection('system')
        .doc('settings')
        .collection('platform')
        .doc('config')
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return GlobalSettings.fromFirestore(doc);
    });
  }

  Future<void> updateGlobalSettings(
    GlobalSettings settings, {
    String? userId,
  }) async {
    final data = settings.toFirestore();
    if (userId != null) {
      data['updatedBy'] = userId;
    }
    await _firestore
        .collection('system')
        .doc('settings')
        .collection('platform')
        .doc('config')
        .set(data, SetOptions(merge: true));

    // Log Action
    await _audit.logAction(
      action: 'GLOBAL_SETTINGS_UPDATED',
      module: 'settings',
      targetId: 'global',
      targetType: 'global_settings',
      after: data,
      severity: AuditSeverity.critical,
    );
  }
}
