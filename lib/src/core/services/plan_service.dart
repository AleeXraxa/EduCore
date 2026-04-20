import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educore/src/features/plans/models/plan.dart';

class PlanService {
  PlanService({required FirebaseFirestore firestore}) : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('plans');

  Stream<List<Plan>> watchPlans() {
    return _col
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(Plan.fromDoc).toList(growable: false));
  }

  Future<List<Plan>> getPlans() async {
    final snap = await _col.orderBy('createdAt', descending: false).get();
    return snap.docs.map(Plan.fromDoc).toList(growable: false);
  }

  Future<String> createPlan({
    required String name,
    required num price,
    required String description,
    required bool isActive,
    required List<String> features,
    int durationDays = 30,
    Map<String, num>? limits,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Name is required');
    }

    final nameLower = trimmed.toLowerCase();
    final existing = await _col.where('nameLower', isEqualTo: nameLower).limit(1).get();
    if (existing.docs.isNotEmpty) {
      throw StateError('A plan with this name already exists.');
    }

    final doc = _col.doc();
    await doc.set({
      'name': trimmed,
      'nameLower': nameLower,
      'price': price,
      'description': description.trim(),
      'isActive': isActive,
      'features': _cleanFeatureKeys(features),
      'durationDays': durationDays,
      if (limits != null) 'limits': limits,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return doc.id;
  }

  Future<void> createPlansBatch(List<Map<String, dynamic>> items) async {
    if (items.isEmpty) return;
    final batch = _firestore.batch();
    for (final item in items) {
      final key = (item['key'] as String?)?.trim() ?? (item['id'] as String?)?.trim();
      final doc = key != null && key.isNotEmpty ? _col.doc(key) : _col.doc();
      
      final data = Map<String, dynamic>.from(item);
      final name = (data['name'] as String? ?? '').trim();
      data['name'] = name;
      data['nameLower'] = name.toLowerCase();
      data['features'] = _cleanFeatureKeys(List<String>.from(data['features'] ?? []));
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();
      
      // Remove key/id from data to avoid redundancy if it was used as docId
      data.remove('key');
      data.remove('id');
      
      batch.set(doc, data);
    }
    await batch.commit();
  }

  Future<void> updatePlan({
    required String planId,
    required String name,
    required num price,
    required String description,
    required bool isActive,
    required List<String> features,
    int durationDays = 30,
    Map<String, num>? limits,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Name is required');
    }

    final nameLower = trimmed.toLowerCase();
    final existing = await _col.where('nameLower', isEqualTo: nameLower).limit(1).get();
    if (existing.docs.isNotEmpty && existing.docs.first.id != planId) {
      throw StateError('A plan with this name already exists.');
    }

    await _col.doc(planId).update({
      'name': trimmed,
      'nameLower': nameLower,
      'price': price,
      'description': description.trim(),
      'isActive': isActive,
      'features': _cleanFeatureKeys(features),
      'durationDays': durationDays,
      'limits': limits ?? <String, num>{},
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> softDeletePlan(String planId) async {
    await _col.doc(planId).update({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setActive(String planId, bool value) async {
    await _col.doc(planId).update({
      'isActive': value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deletePlan(String planId) async {
    await _col.doc(planId).delete();
  }

  Future<void> toggleFeature({
    required String planId,
    required String featureKey,
    required bool enabled,
  }) async {
    final key = featureKey.trim();
    if (key.isEmpty) return;
    await _col.doc(planId).update({
      'features': enabled
          ? FieldValue.arrayUnion([key])
          : FieldValue.arrayRemove([key]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<Plan> watchPlan(String planId) {
    return _col.doc(planId).snapshots().map(Plan.fromDoc);
  }

  Future<Plan?> getPlan(String planId) async {
    final doc = await _col.doc(planId).get();
    if (!doc.exists) return null;
    return Plan.fromDoc(doc);
  }
}

List<String> _cleanFeatureKeys(List<String> input) {
  final set = <String>{};
  for (final raw in input) {
    final key = raw.trim();
    if (key.isEmpty) continue;
    set.add(key);
  }
  return set.toList(growable: false);
}
