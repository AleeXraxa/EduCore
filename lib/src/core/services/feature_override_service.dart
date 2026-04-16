import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educore/src/features/features/models/feature_overrides.dart';

import 'package:educore/src/core/services/audit_log_service.dart';
import 'package:educore/src/features/audit/models/audit_log.dart';

class FeatureOverrideService {
  final FirebaseFirestore _firestore;
  final AuditLogService _audit;

  FeatureOverrideService({
    required FirebaseFirestore firestore,
    required AuditLogService auditLogService,
  })  : _firestore = firestore,
        _audit = auditLogService;

  CollectionReference<Map<String, dynamic>> get _subscriptions =>
      _firestore.collection('subscriptions');

  /// Fetch overrides for a specific institute
  Future<FeatureOverrides> getOverrides(String academyId) async {
    final doc = await _subscriptions.doc(academyId).get();
    if (!doc.exists) return const FeatureOverrides();
    
    final data = doc.data();
    final overridesData = data?['overrides'];
    
    if (overridesData is Map) {
      return FeatureOverrides.fromMap(overridesData.cast<String, dynamic>());
    }
    
    return const FeatureOverrides();
  }

  /// Update overrides for a specific institute
  Future<void> updateOverrides({
    required String academyId,
    required List<String> enabled,
    required List<String> disabled,
  }) async {
    final overrides = FeatureOverrides(
      enabled: enabled,
      disabled: disabled,
    );

    await _subscriptions.doc(academyId).update({
      'overrides': overrides.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Log Action
    await _audit.logAction(
      action: 'FEATURE_OVERRIDE_UPDATED',
      module: 'features',
      academyId: academyId,
      uid: 'super_admin_system', // TODO: pass actual uid
      role: 'super_admin',
      targetDoc: 'subscriptions/$academyId',
      after: overrides.toMap(),
      severity: AuditSeverity.high,
    );
  }
}
