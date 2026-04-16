import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educore/src/features/features/models/feature_overrides.dart';

class FeatureOverrideService {
  final FirebaseFirestore _firestore;

  FeatureOverrideService({required FirebaseFirestore firestore})
      : _firestore = firestore;

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
  }
}
