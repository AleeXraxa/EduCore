import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educore/src/features/features/models/feature_flag.dart';
import 'package:educore/src/features/features/models/feature_group.dart';

class FeatureService {
  FeatureService({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('features');

  CollectionReference<Map<String, dynamic>> get _groupsCol =>
      _firestore.collection('featureGroups');

  List<FeatureFlag>? _cachedFeatures;
  List<FeatureGroup>? _cachedGroups;
  DateTime? _lastFetch;

  /// Loads features with memory caching (valid for 15 mins)
  Future<List<FeatureFlag>> getFeaturesCached({bool force = false}) async {
    final now = DateTime.now();
    if (!force && _cachedFeatures != null && _lastFetch != null) {
      if (now.difference(_lastFetch!).inMinutes < 15) {
        return _cachedFeatures!;
      }
    }
    
    _cachedFeatures = await getFeatures();
    _lastFetch = now;
    return _cachedFeatures!;
  }

  /// Loads groups with memory caching
  Future<List<FeatureGroup>> getGroupsCached({bool force = false}) async {
    if (!force && _cachedGroups != null) return _cachedGroups!;
    _cachedGroups = await getGroups();
    return _cachedGroups!;
  }

  /// Limited to 500 docs for platform-scale features.
  Stream<List<FeatureFlag>> watchFeatures() {
    return _col.limit(500).snapshots().map((snap) {
      final list = snap.docs
          .map(FeatureFlag.fromDoc)
          .where((f) => !f.isDeleted)
          .toList();

      list.sort((a, b) {
        final g = a.group.compareTo(b.group);
        if (g != 0) return g;
        final o = a.order.compareTo(b.order);
        if (o != 0) return o;
        return a.label.compareTo(b.label);
      });

      return List<FeatureFlag>.unmodifiable(list);
    });
  }

  Stream<List<FeatureGroup>> watchGroups() {
    return _groupsCol.limit(200).snapshots().map((snap) {
      final list = snap.docs
          .map(FeatureGroup.fromDoc)
          .where((g) => !g.isDeleted)
          .toList();

      list.sort((a, b) => a.order.compareTo(b.order));
      return List<FeatureGroup>.unmodifiable(list);
    });
  }

  Future<List<FeatureFlag>> getFeatures() async {
    final snap = await _col.get();
    final list = snap.docs
        .map(FeatureFlag.fromDoc)
        .where((f) => !f.isDeleted)
        .toList();

    list.sort((a, b) {
      final g = a.group.compareTo(b.group);
      if (g != 0) return g;
      final o = a.order.compareTo(b.order);
      if (o != 0) return o;
      return a.label.compareTo(b.label);
    });

    return List<FeatureFlag>.unmodifiable(list);
  }

  Future<List<FeatureGroup>> getGroups() async {
    final snap = await _groupsCol.get();
    final list = snap.docs
        .map(FeatureGroup.fromDoc)
        .where((g) => !g.isDeleted)
        .toList();

    list.sort((a, b) => a.order.compareTo(b.order));
    return List<FeatureGroup>.unmodifiable(list);
  }

  Future<String> createFeature({
    required String key,
    required String label,
    required String description,
    required String group,
    required bool isActive,
    bool isSystem = false,
    String? icon,
    int? order,
  }) async {
    final cleanKey = key.trim();
    if (cleanKey.isEmpty) {
      throw ArgumentError.value(key, 'key', 'Key is required');
    }

    final keyLower = cleanKey.toLowerCase();
    
    // We use keyLower as the document ID for features to ensure uniqueness
    final docRef = _col.doc(keyLower);
    final existing = await docRef.get();

    if (existing.exists) {
      final data = existing.data()!;
      if (data['isDeleted'] == true) {
        // Reuse the deleted record by updating it
        await docRef.update({
          'label': label.trim(),
          'description': description.trim(),
          'group': group.trim(),
          'groupLower': group.trim().toLowerCase(),
          'isActive': isActive,
          'isSystem': isSystem,
          'isDeleted': false,
          'icon': icon?.trim() ?? '',
          'order': order ?? 0,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return existing.id;
      }
      throw StateError(
        'A feature with the key "$keyLower" already exists in the system. '
        'If you cannot see it, check if it belongs to a different group or search by key.',
      );
    }

    await docRef.set({
      'key': cleanKey,
      'keyLower': keyLower,
      'label': label.trim(),
      'description': description.trim(),
      'group': group.trim(),
      'groupLower': group.trim().toLowerCase(),
      'isActive': isActive,
      'isSystem': isSystem,
      'isDeleted': false,
      if (icon != null && icon.trim().isNotEmpty) 'icon': icon.trim(),
      if (order != null) 'order': order,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  Future<void> updateFeature({
    required String featureId,
    required String key,
    required String label,
    required String description,
    required String group,
    required bool isActive,
    bool? isSystem,
    String? icon,
    int? order,
  }) async {
    final cleanKey = key.trim();
    if (cleanKey.isEmpty) {
      throw ArgumentError.value(key, 'key', 'Key is required');
    }

    await _col.doc(featureId).update({
      'label': label.trim(),
      'description': description.trim(),
      'group': group.trim(),
      'groupLower': group.trim().toLowerCase(),
      'isActive': isActive,
      if (isSystem != null) 'isSystem': isSystem,
      'icon': icon?.trim() ?? '',
      'order': order ?? 0,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteFeature(String featureId) async {
    final doc = await _col.doc(featureId).get();
    if (!doc.exists) return;

    final data = doc.data()!;
    if (data['isSystem'] == true) {
      throw StateError('Cannot delete system features.');
    }

    await _col.doc(featureId).update({
      'isDeleted': true,
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setActive(String featureId, bool value) async {
    await _col.doc(featureId).update({
      'isActive': value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> createFeaturesBatch(List<Map<String, dynamic>> items) async {
    if (items.isEmpty) return;
    final batch = _firestore.batch();
    for (final item in items) {
      final key = (item['key'] as String?)?.trim() ?? (item['id'] as String?)?.trim();
      final keyLower = key?.toLowerCase();
      
      final doc = keyLower != null && keyLower.isNotEmpty ? _col.doc(keyLower) : _col.doc();
      
      final data = Map<String, dynamic>.from(item);
      data['keyLower'] = keyLower ?? (data['key'] as String?)?.toLowerCase() ?? '';
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();
      
      // Ensure essential fields exist
      data['isDeleted'] = data['isDeleted'] ?? false;
      data['isActive'] = data['isActive'] ?? true;
      
      batch.set(doc, data);
    }
    await batch.commit();
  }

  Future<void> createGroup({
    required String name,
    String description = '',
    String icon = 'folder',
    int order = 0,
    bool isSystem = false,
  }) async {
    await _groupsCol.add({
      'name': name.trim(),
      'description': description.trim(),
      'icon': icon.trim(),
      'order': order,
      'isSystem': isSystem,
      'isDeleted': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateGroup({
    required String id,
    required String name,
    required String description,
    required String icon,
    required int order,
    bool? isSystem,
  }) async {
    await _groupsCol.doc(id).update({
      'name': name.trim(),
      'description': description.trim(),
      'icon': icon.trim(),
      'order': order,
      if (isSystem != null) 'isSystem': isSystem,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteGroup(String id) async {
    final doc = await _groupsCol.doc(id).get();
    if (doc.exists && (doc.data()?['isSystem'] == true)) {
      throw Exception('Cannot delete system-protected group');
    }

    await _groupsCol.doc(id).update({
      'isDeleted': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> syncGroupsFromFeaturesBatch(List<String> groupNames) async {
    if (groupNames.isEmpty) return;

    // 1. Get existing formal groups to avoid duplicates
    final existingSnap = await _groupsCol.get();
    final existingNames = existingSnap.docs
        .map((d) => d.data()['name'] as String? ?? '')
        .map((n) => n.trim().toLowerCase())
        .toSet();

    final batch = _firestore.batch();
    int count = 0;

    for (final name in groupNames) {
      if (name.isEmpty) continue;
      final normalized = name.trim();
      if (existingNames.contains(normalized.toLowerCase())) continue;

      final doc = _groupsCol.doc();
      batch.set(doc, {
        'name': normalized,
        'description': 'Auto-discovered from existing features',
        'icon': 'folder_shared',
        'order': 50,
        'isSystem': false,
        'isDeleted': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      count++;
    }

    if (count > 0) {
      await batch.commit();
    }
  }
}
