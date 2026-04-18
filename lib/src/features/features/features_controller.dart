import 'dart:async';

import 'package:educore/src/core/mvc/base_controller.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/core/services/feature_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educore/src/features/features/models/feature_flag.dart';
import 'package:educore/src/features/audit/models/audit_log.dart';
import 'package:educore/src/features/features/models/feature_group.dart';

class FeaturesController extends BaseController {
  FeaturesController() {
    _service = AppServices.instance.featureService;
    _attachOrInit();
  }

  FeatureService? _service;
  StreamSubscription<List<FeatureFlag>>? _sub;
  StreamSubscription<List<FeatureGroup>>? _groupsSub;

  List<FeatureFlag> features = const [];
  List<FeatureGroup> featureGroups = const [];
  String? errorMessage;

  String selectedGroup = 'All';
  String groupQuery = '';
  String featureQuery = '';

  bool get ready => _service != null;

  List<String> get groups {
    final set = <String>{'All'};
    // ONLY names from formal groups
    for (final g in featureGroups) {
      if (g.name.trim().isNotEmpty) set.add(g.name);
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
      final id = await svc.createFeature(
        key: draft.key,
        label: draft.label,
        description: draft.description,
        group: draft.group,
        isActive: draft.isActive,
        isSystem: draft.isSystem,
        icon: draft.icon,
        order: draft.order,
      );

      _logAudit(
        action: 'create_feature',
        targetDoc: id,
        after: {
          'key': draft.key,
          'label': draft.label,
          'group': draft.group,
          'isSystem': draft.isSystem,
        },
      );
    });
  }

  Future<void> createFeaturesBulk(List<FeatureFlag> drafts) async {
    final svc = await _ensureService();
    await runBusy<void>(() async {
      final now = DateTime.now();
      final items = <Map<String, dynamic>>[];
      final seenKeys = <String>{};
      final existingKeys = features.map((f) => f.key.toLowerCase()).toSet();

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
          'isSystem': draft.isSystem,
          'isDeleted': false,
          if (draft.icon != null && draft.icon!.trim().isNotEmpty)
            'icon': draft.icon!.trim(),
          if (draft.order > 0) 'order': draft.order,
          'createdAt': Timestamp.fromDate(now),
          'updatedAt': Timestamp.fromDate(now),
        });
      }

      await svc.createFeaturesBatch(items);

      _logAudit(action: 'bulk_create_features', after: {'count': items.length});
    });
  }

  Future<void> updateFeature(FeatureFlag updated) async {
    final svc = await _ensureService();
    final before = features.firstWhere((f) => f.id == updated.id);

    await runBusy<void>(() async {
      await svc.updateFeature(
        featureId: updated.id,
        key: updated.key,
        label: updated.label,
        description: updated.description,
        group: updated.group,
        isActive: updated.isActive,
        isSystem: updated.isSystem,
        icon: updated.icon,
        order: updated.order,
      );

      _logAudit(
        action: 'update_feature',
        targetDoc: updated.id,
        before: {
          'label': before.label,
          'group': before.group,
          'isActive': before.isActive,
          'isSystem': before.isSystem,
        },
        after: {
          'label': updated.label,
          'group': updated.group,
          'isActive': updated.isActive,
          'isSystem': updated.isSystem,
        },
      );
    });
  }

  Future<void> deleteFeature(String id) async {
    final svc = await _ensureService();
    final feature = features.firstWhere((f) => f.id == id);
    if (feature.isSystem) return;

    await runBusy<void>(() async {
      await svc.deleteFeature(id);
      _logAudit(
        action: 'delete_feature',
        targetDoc: id,
        before: {'key': feature.key, 'label': feature.label},
      );
    });
  }

  Future<void> toggleFeatureStatus(String id, bool value) async {
    final svc = await _ensureService();
    await runBusy<void>(() async {
      await svc.setActive(id, value);
      _logAudit(
        action: 'toggle_feature_status',
        targetDoc: id,
        after: {'isActive': value},
      );
    });
  }

  Future<void> assignGroupToFeature(String id, String group) async {
    final svc = await _ensureService();
    final feature = features.firstWhere((f) => f.id == id);
    if (feature.group == group) return;

    await runBusy<void>(() async {
      await svc.updateFeature(
        featureId: id,
        key: feature.key,
        label: feature.label,
        description: feature.description,
        group: group,
        isActive: feature.isActive,
        icon: feature.icon,
        order: feature.order,
      );
      _logAudit(
        action: 'assign_feature_group',
        targetDoc: id,
        before: {'group': feature.group},
        after: {'group': group},
      );
    });
  }

  Future<void> setActive(String id, bool value) =>
      toggleFeatureStatus(id, value);

  Future<void> createFeatureGroup(FeatureGroup draft) async {
    final svc = await _ensureService();
    await runBusy<void>(() async {
      await svc.createGroup(
        name: draft.name,
        description: draft.description,
        icon: draft.icon,
        order: draft.order,
        isSystem: draft.isSystem,
      );
      _logAudit(
        action: 'create_feature_group',
        after: {'name': draft.name, 'isSystem': draft.isSystem},
      );
    });
  }

  Future<void> updateFeatureGroup(FeatureGroup updated) async {
    final svc = await _ensureService();
    final before = featureGroups.firstWhere((g) => g.id == updated.id);

    await runBusy<void>(() async {
      await svc.updateGroup(
        id: updated.id,
        name: updated.name,
        description: updated.description,
        icon: updated.icon,
        order: updated.order,
        isSystem: updated.isSystem,
      );

      _logAudit(
        action: 'update_feature_group',
        targetDoc: updated.id,
        before: {
          'name': before.name,
          'order': before.order,
          'isSystem': before.isSystem,
        },
        after: {
          'name': updated.name,
          'order': updated.order,
          'isSystem': updated.isSystem,
        },
      );
    });
  }

  Future<void> deleteFeatureGroup(String id) async {
    final svc = await _ensureService();
    final group = featureGroups.firstWhere((g) => g.id == id);
    if (group.isSystem) return;

    await runBusy<void>(() async {
      await svc.deleteGroup(id);
      _logAudit(
        action: 'delete_feature_group',
        targetDoc: id,
        before: {'name': group.name},
      );
    });
  }

  void _logAudit({
    required String action,
    String? targetDoc,
    Map<String, dynamic>? before,
    Map<String, dynamic>? after,
  }) {
    final audit = AppServices.instance.auditLogService;
    if (audit == null) return;

    audit.logAction(
      action: action,
      module: 'features',
      targetId: targetDoc ?? 'platform',
      targetType: 'feature_management',
      before: before,
      after: after,
      severity: AuditSeverity.warning,
      source: AuditSource.superAdmin,
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    _groupsSub?.cancel();
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
        // ignore: avoid_print
        print('Features stream error: $e');
        notifyListeners();
      },
    );

    _groupsSub?.cancel();
    _groupsSub = svc.watchGroups().listen(
      (value) {
        featureGroups = value;
        notifyListeners();
      },
      onError: (e) {
        // ignore: avoid_print
        print('Groups stream error: $e');
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
