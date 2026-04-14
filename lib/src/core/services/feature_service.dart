import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educore/src/features/features/models/feature_flag.dart';

class FeatureService {
  FeatureService({required FirebaseFirestore firestore}) : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('features');

  Stream<List<FeatureFlag>> watchFeatures() {
    return _col
        .orderBy('group', descending: false)
        .orderBy('order', descending: false)
        .orderBy('label', descending: false)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(FeatureFlag.fromDoc)
              .toList(growable: false),
        );
  }

  Future<String> createFeature({
    required String key,
    required String label,
    required String description,
    required String group,
    required bool isActive,
    String? icon,
    int? order,
  }) async {
    final cleanKey = key.trim();
    if (cleanKey.isEmpty) {
      throw ArgumentError.value(key, 'key', 'Key is required');
    }

    final keyLower = cleanKey.toLowerCase();
    final existing = await _col.where('keyLower', isEqualTo: keyLower).limit(1).get();
    if (existing.docs.isNotEmpty) {
      throw StateError('A feature with this key already exists.');
    }

    final doc = _col.doc();
    await doc.set({
      'key': cleanKey,
      'keyLower': keyLower,
      'label': label.trim(),
      'description': description.trim(),
      'group': group.trim(),
      'groupLower': group.trim().toLowerCase(),
      'isActive': isActive,
      if (icon != null && icon.trim().isNotEmpty) 'icon': icon.trim(),
      if (order != null) 'order': order,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return doc.id;
  }

  Future<void> updateFeature({
    required String featureId,
    required String key,
    required String label,
    required String description,
    required String group,
    required bool isActive,
    String? icon,
    int? order,
  }) async {
    final cleanKey = key.trim();
    if (cleanKey.isEmpty) {
      throw ArgumentError.value(key, 'key', 'Key is required');
    }

    final keyLower = cleanKey.toLowerCase();
    final existing = await _col.where('keyLower', isEqualTo: keyLower).limit(1).get();
    if (existing.docs.isNotEmpty && existing.docs.first.id != featureId) {
      throw StateError('A feature with this key already exists.');
    }

    await _col.doc(featureId).update({
      'key': cleanKey,
      'keyLower': keyLower,
      'label': label.trim(),
      'description': description.trim(),
      'group': group.trim(),
      'groupLower': group.trim().toLowerCase(),
      'isActive': isActive,
      'icon': icon?.trim() ?? '',
      'order': order ?? 0,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setActive(String featureId, bool value) async {
    await _col.doc(featureId).update({
      'isActive': value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> createFeaturesBatch(
    List<Map<String, dynamic>> items,
  ) async {
    if (items.isEmpty) return;
    final batch = _firestore.batch();
    for (final item in items) {
      final doc = _col.doc();
      batch.set(doc, item);
    }
    await batch.commit();
  }
}
