import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educore/src/features/plans_import/models/plan_import_models.dart';

class PlanImportService {
  PlanImportService({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _plans =>
      _firestore.collection('plans');
  CollectionReference<Map<String, dynamic>> get _features =>
      _firestore.collection('features');

  Future<PlanImportParseResult> parseJson(String raw) async {
    final errors = <String>[];
    final drafts = <PlanImportDraft>[];
    if (raw.trim().isEmpty) {
      return PlanImportParseResult(drafts: drafts, errors: const ['Input is empty.']);
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return PlanImportParseResult(
          drafts: drafts,
          errors: const ['JSON must be an array of plans.'],
        );
      }
      for (var i = 0; i < decoded.length; i++) {
        final item = decoded[i];
        if (item is! Map) {
          errors.add('Row ${i + 1}: expected an object.');
          continue;
        }
        final draft = _parseMap(item.cast<String, dynamic>(), row: i + 1, errors: errors);
        if (draft != null) drafts.add(draft);
      }
    } catch (e) {
      errors.add('Invalid JSON: $e');
    }

    return PlanImportParseResult(drafts: drafts, errors: errors);
  }

  Future<PlanImportParseResult> parseCsv(String raw) async {
    final errors = <String>[];
    final drafts = <PlanImportDraft>[];
    final rows = raw
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (rows.isEmpty) {
      return PlanImportParseResult(drafts: drafts, errors: const ['Input is empty.']);
    }

    var start = 0;
    final header = rows.first.toLowerCase();
    if (header.startsWith('key,') && header.contains('features')) {
      start = 1;
    }

    for (var i = start; i < rows.length; i++) {
      final parts = rows[i].split(',');
      if (parts.length < 7) {
        errors.add('Row ${i + 1}: expected 7 columns.');
        continue;
      }
      final key = parts[0].trim();
      final name = parts[1].trim();
      final description = parts[2].trim();
      final priceRaw = parts[3].trim();
      final featuresRaw = parts[4].trim();
      final limitsRaw = parts[5].trim();
      final activeRaw = parts[6].trim();

      final price = num.tryParse(priceRaw) ?? 0;
      final features = featuresRaw.isEmpty
          ? <String>[]
          : featuresRaw.split(';').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      final limits = _parseLimits(limitsRaw);
      final isActive = _parseBool(activeRaw, fallback: true);

      final draft = _parseMap(
        {
          'key': key,
          'name': name,
          'description': description,
          'price': price,
          'features': features,
          'limits': limits,
          'isActive': isActive,
        },
        row: i + 1,
        errors: errors,
      );
      if (draft != null) drafts.add(draft);
    }

    return PlanImportParseResult(drafts: drafts, errors: errors);
  }

  Future<PlanImportValidationResult> validateDrafts(
    List<PlanImportDraft> drafts,
  ) async {
    final errors = <String>[];
    final invalidByPlan = <String, List<String>>{};
    final duplicateKeys = <String>{};
    final keyRegex = RegExp(r'^[a-z0-9_]+$');

    final registryKeys = await _fetchFeatureKeys();
    final existingMap = await _fetchExistingPlanKeyMap();

    final seen = <String>{};
    for (final draft in drafts) {
      final key = _normalizeKey(draft.key);
      if (key.isEmpty) {
        errors.add('Plan key is required.');
        continue;
      }
      if (!keyRegex.hasMatch(key)) {
        errors.add('Plan "$key": key must be lowercase with underscores.');
      }
      if (seen.contains(key)) {
        duplicateKeys.add(key);
        errors.add('Duplicate key in input: "$key".');
      } else {
        seen.add(key);
      }

      final features = _cleanFeatures(draft.features);
      if (features.isEmpty && key != 'demo') {
        errors.add('Plan "$key": features cannot be empty.');
      }

      final invalid = features.where((f) => !registryKeys.contains(f)).toList();
      if (invalid.isNotEmpty) {
        invalidByPlan[key] = invalid;
        errors.add('Plan "$key": invalid features: ${invalid.join(', ')}.');
      }
    }

    return PlanImportValidationResult(
      drafts: drafts,
      errors: errors,
      invalidFeaturesByPlan: invalidByPlan,
      duplicateKeys: duplicateKeys,
      existingKeys: existingMap.keys.toSet(),
    );
  }

  Future<PlanImportCommitResult> importPlans(
    List<PlanImportDraft> drafts,
  ) async {
    final validation = await validateDrafts(drafts);
    if (!validation.canImport) {
      throw StateError('Validation failed. Fix errors before importing.');
    }

    final existingMap = await _fetchExistingPlanKeyMap();
    var created = 0;
    var updated = 0;

    final batch = _firestore.batch();
    for (final draft in drafts) {
      final key = _normalizeKey(draft.key);
      final docId = existingMap[key] ?? key;
      final ref = _plans.doc(docId);
      final data = _planToMap(draft, keyLower: key);

      if (existingMap.containsKey(key)) {
        batch.update(ref, {
          ...data,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        updated++;
      } else {
        batch.set(ref, {
          ...data,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        created++;
      }
    }

    await batch.commit();
    return PlanImportCommitResult(created: created, updated: updated);
  }

  Future<Set<String>> _fetchFeatureKeys() async {
    final snap = await _features.get();
    final keys = <String>{};
    for (final doc in snap.docs) {
      final data = doc.data();
      final raw = data['keyLower'] ?? data['key'];
      final key = raw?.toString().trim().toLowerCase();
      if (key != null && key.isNotEmpty) keys.add(key);
    }
    return keys;
  }

  Future<Map<String, String>> _fetchExistingPlanKeyMap() async {
    final snap = await _plans.get();
    final keys = <String, String>{};
    for (final doc in snap.docs) {
      final data = doc.data();
      final raw = data['keyLower'] ?? data['key'];
      final key = raw?.toString().trim().toLowerCase();
      if (key != null && key.isNotEmpty) {
        keys[key] = doc.id;
      }
    }
    return keys;
  }

  PlanImportDraft? _parseMap(
    Map<String, dynamic> map, {
    required int row,
    required List<String> errors,
  }) {
    final key = map['key']?.toString().trim() ?? '';
    final name = map['name']?.toString().trim() ?? '';
    final description = map['description']?.toString().trim() ?? '';
    final priceRaw = map['price'];
    final price = priceRaw is num ? priceRaw : num.tryParse(priceRaw?.toString() ?? '') ?? 0;
    final features = _toStringList(map['features']);
    final limits = _toNumMap(map['limits']);
    final isActive = _parseBool(map['isActive'], fallback: true);

    if (key.isEmpty || name.isEmpty) {
      errors.add('Row $row: key and name are required.');
      return null;
    }

    return PlanImportDraft(
      key: key,
      name: name,
      description: description,
      price: price,
      features: features,
      limits: limits,
      isActive: isActive,
    );
  }

  Map<String, dynamic> _planToMap(PlanImportDraft draft, {required String keyLower}) {
    return {
      'key': keyLower,
      'keyLower': keyLower,
      'name': draft.name.trim(),
      'nameLower': draft.name.trim().toLowerCase(),
      'price': draft.price,
      'description': draft.description.trim(),
      'features': _cleanFeatures(draft.features),
      'limits': draft.limits,
      'isActive': draft.isActive,
    };
  }

  List<String> _toStringList(Object? value) {
    if (value is List) {
      return value.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    }
    if (value is String) {
      return value
          .split(';')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const <String>[];
  }

  Map<String, num> _toNumMap(Object? value) {
    if (value is Map) {
      return value.map((k, v) {
        final numValue = v is num ? v : num.tryParse(v?.toString() ?? '') ?? 0;
        return MapEntry(k.toString(), numValue);
      });
    }
    if (value is String) {
      return _parseLimits(value);
    }
    return const <String, num>{};
  }

  Map<String, num> _parseLimits(String raw) {
    if (raw.trim().isEmpty) return const <String, num>{};
    final result = <String, num>{};
    final entries = raw.split(';');
    for (final entry in entries) {
      final parts = entry.split('=');
      if (parts.length != 2) continue;
      final key = parts[0].trim();
      final valueRaw = parts[1].trim();
      if (key.isEmpty) continue;
      final value = num.tryParse(valueRaw) ?? 0;
      result[key] = value;
    }
    return result;
  }

  List<String> _cleanFeatures(List<String> input) {
    final set = <String>{};
    for (final raw in input) {
      final key = _normalizeKey(raw);
      if (key.isEmpty) continue;
      set.add(key);
    }
    return set.toList(growable: false);
  }

  String _normalizeKey(String key) => key.trim().toLowerCase();

  bool _parseBool(Object? raw, {required bool fallback}) {
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    final value = raw?.toString().trim().toLowerCase();
    if (value == null || value.isEmpty) return fallback;
    return value == 'true' || value == '1' || value == 'yes';
  }
}
