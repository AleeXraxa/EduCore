import 'dart:async';

import 'package:educore/src/core/mvc/base_controller.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/core/services/feature_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educore/src/features/features/models/feature_flag.dart';

class FeaturesController extends BaseController {
  FeaturesController() {
    _service = AppServices.instance.featureService;
    _attachOrInit();
  }

  FeatureService? _service;
  StreamSubscription<List<FeatureFlag>>? _sub;

  List<FeatureFlag> features = const [];
  String? errorMessage;

  String selectedGroup = 'All';
  String groupQuery = '';
  String featureQuery = '';

  bool get ready => _service != null;

  List<String> get groups {
    final set = <String>{
      'All',
      'Students',
      'Fees',
      'Attendance',
      'Exams',
      'Certificates',
      'Staff',
      'Reports',
      'Communication',
      'System Access',
      'Integrations',
    };
    for (final f in features) {
      if (f.group.trim().isNotEmpty) set.add(f.group);
    }
    final list = set.toList(growable: true)..sort();
    if (list.remove('All')) list.insert(0, 'All');

    if (groupQuery.trim().isEmpty) return list;
    final q = groupQuery.toLowerCase();
    return list
        .where((g) => g.toLowerCase().contains(q))
        .toList(growable: false);
  }

  List<FeatureFlag> get filtered {
    final q = featureQuery.trim().toLowerCase();
    Iterable<FeatureFlag> list = features;

    if (selectedGroup != 'All') {
      list = list.where((f) => f.group == selectedGroup);
    }
    if (q.isNotEmpty) {
      list = list.where((f) {
        return f.label.toLowerCase().contains(q) ||
            f.key.toLowerCase().contains(q) ||
            f.description.toLowerCase().contains(q);
      });
    }
    return list.toList(growable: false);
  }

  int get totalCount => features.length;
  int get activeCount => features.where((f) => f.isActive).length;

  void setGroup(String value) {
    selectedGroup = value;
    notifyListeners();
  }

  void setGroupQuery(String value) {
    groupQuery = value;
    notifyListeners();
  }

  void setFeatureQuery(String value) {
    featureQuery = value;
    notifyListeners();
  }

  Future<void> createFeature(FeatureFlag draft) async {
    final svc = await _ensureService();
    await runBusy<void>(() async {
      await svc.createFeature(
        key: draft.key,
        label: draft.label,
        description: draft.description,
        group: draft.group,
        isActive: draft.isActive,
        icon: draft.icon,
        order: draft.order,
      );
    });
  }

  Future<void> createFeaturesBulk(List<FeatureFlag> drafts) async {
    final svc = await _ensureService();
    await runBusy<void>(() async {
      final now = DateTime.now();
      final items = <Map<String, dynamic>>[];
      final seenKeys = <String>{};
      final existingKeys =
          features.map((f) => f.key.toLowerCase()).toSet();

      for (final draft in drafts) {
        final key = draft.key.trim();
        if (key.isEmpty) continue;
        final keyLower = key.toLowerCase();
        if (!seenKeys.add(keyLower)) continue;
        if (existingKeys.contains(keyLower)) continue;
        items.add({
          'key': key,
          'keyLower': keyLower,
          'label': draft.label.trim(),
          'description': draft.description.trim(),
          'group': draft.group.trim(),
          'groupLower': draft.group.trim().toLowerCase(),
          'isActive': draft.isActive,
          if (draft.icon != null && draft.icon!.trim().isNotEmpty)
            'icon': draft.icon!.trim(),
          if (draft.order > 0) 'order': draft.order,
          'createdAt': Timestamp.fromDate(now),
          'updatedAt': Timestamp.fromDate(now),
        });
      }

      await svc.createFeaturesBatch(items);
    });
  }

  Future<void> updateFeature(FeatureFlag updated) async {
    final svc = await _ensureService();
    await runBusy<void>(() async {
      await svc.updateFeature(
        featureId: updated.id,
        key: updated.key,
        label: updated.label,
        description: updated.description,
        group: updated.group,
        isActive: updated.isActive,
        icon: updated.icon,
        order: updated.order,
      );
    });
  }

  Future<void> setActive(String id, bool value) async {
    final svc = await _ensureService();
    await runBusy<void>(() => svc.setActive(id, value));
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> retryInit() => _attachOrInit();

  void _attach(FeatureService svc) {
    if (_service == svc && _sub != null) return;
    _service = svc;
    _sub?.cancel();
    _sub = svc.watchFeatures().listen(
      (value) {
        features = value;
        errorMessage = null;
        notifyListeners();
      },
      onError: (e) {
        errorMessage = e.toString();
        // Log Firestore index errors so the console shows the clickable link.
        // ignore: avoid_print
        print('Features stream error: $e');
        notifyListeners();
      },
    );
    notifyListeners();
  }

  Future<void> _attachOrInit() async {
    if (_service != null) {
      _attach(_service!);
      return;
    }

    await runBusy<void>(() async {
      await AppServices.instance.init();
    });

    final svc = AppServices.instance.featureService;
    if (svc != null) {
      _attach(svc);
    } else {
      errorMessage = AppServices.instance.firebaseInitError?.toString();
      notifyListeners();
    }
  }

  Future<FeatureService> _ensureService() async {
    final existing = _service ?? AppServices.instance.featureService;
    if (existing != null) {
      if (_service != existing) _attach(existing);
      return existing;
    }

    await _attachOrInit();
    final svc = _service ?? AppServices.instance.featureService;
    if (svc == null) {
      throw StateError('Firestore is not ready.');
    }
    return svc;
  }
}
