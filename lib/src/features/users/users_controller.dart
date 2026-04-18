import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educore/src/core/models/app_user.dart' as core_models;
import 'package:educore/src/core/mvc/base_controller.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/core/services/institute_service.dart';
import 'package:educore/src/core/repositories/user_repository.dart';
import 'package:educore/src/features/users/models/app_user.dart';

enum UsersRoleFilter { all, superAdmin, instituteAdmin, staff, teacher }

enum UsersStatusFilter { all, active, blocked }

class UsersController extends BaseController {
  UsersController() {
    _repository = AppServices.instance.userRepository;
    _instituteService = AppServices.instance.instituteService;
    _init();
  }

  UserRepository? _repository;
  InstituteService? _instituteService;

  StreamSubscription<List<Academy>>? _academiesSub;

  final List<AppUser> _all = <AppUser>[];
  Map<String, Academy> _academyById = const <String, Academy>{};

  // State
  String _query = '';
  UsersRoleFilter _role = UsersRoleFilter.all;
  UsersStatusFilter _status = UsersStatusFilter.all;
  String _instituteId = 'all';

  // Pagination State
  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  final int _pageSize = 50;

  String? errorMessage;

  bool get ready => _repository != null;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  String get query => _query;
  UsersRoleFilter get role => _role;
  UsersStatusFilter get status => _status;
  String get instituteId => _instituteId;

  @override
  void dispose() {
    _academiesSub?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    if (_repository == null) {
      await runBusy<void>(() async {
        await AppServices.instance.init();
      });
      _repository = AppServices.instance.userRepository;
      _instituteService = AppServices.instance.instituteService;
    }

    if (_repository != null) {
      _attachAcademies();
      await refresh();
    } else {
      errorMessage = AppServices.instance.firebaseInitError?.toString();
      notifyListeners();
    }
  }

  Future<void> retryInit() => _init();

  /// Initial load or filter change: reset and fetch first batch.
  Future<void> refresh() async {
    _lastDoc = null;
    _hasMore = true;
    _all.clear();

    await runBusy<void>(() async {
      await _fetchNextBatch();
    });
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      await _fetchNextBatch();
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> _fetchNextBatch() async {
    if (_repository == null) return;

    try {
      final core_models.AppUserRole? roleFilter = switch (_role) {
        UsersRoleFilter.superAdmin => core_models.AppUserRole.superAdmin,
        UsersRoleFilter.instituteAdmin =>
          core_models.AppUserRole.instituteAdmin,
        UsersRoleFilter.staff => core_models.AppUserRole.staff,
        UsersRoleFilter.teacher => core_models.AppUserRole.teacher,
        UsersRoleFilter.all => null,
      };

      final statusVal = switch (_status) {
        UsersStatusFilter.all => 'all',
        UsersStatusFilter.active => 'active',
        UsersStatusFilter.blocked => 'blocked',
      };

      final results = await _repository!.getUsersBatch(
        limit: _pageSize,
        lastDoc: _lastDoc,
        role: roleFilter,
        status: statusVal,
        academyId: _instituteId == 'all' ? null : _instituteId,
      );

      if (results.length < _pageSize) {
        _hasMore = false;
      }

      if (results.isNotEmpty) {
        final lastUser = results.last;
        final lastDocSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(lastUser.uid)
            .get();
        _lastDoc = lastDocSnap;

        _all.addAll(results.map(_mapToUi));
      }

      errorMessage = null;
    } catch (e) {
      errorMessage = e.toString();
      _hasMore = false;
    }
  }

  // --- UI Mappings & Filters ---

  List<AppUser> get list => filtered;

  List<AppUser> get filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _all;
    return _all.where((e) {
      return e.name.toLowerCase().contains(q) ||
          e.email.toLowerCase().contains(q) ||
          e.phone.toLowerCase().contains(q);
    }).toList();
  }

  int get allCount => _all.length;
  int get totalCount => _all.length;
  int get activeCount =>
      _all.where((e) => e.status == AppUserStatus.active).length;
  int get instituteAdminsCount =>
      _all.where((e) => e.role == AppUserRole.instituteAdmin).length;
  int get staffTeachersCount => _all
      .where(
        (e) => e.role == AppUserRole.teacher || e.role == AppUserRole.staff,
      )
      .length;

  List<String> get institutes {
    final ids = <String>{..._all.map((e) => e.instituteId)};
    ids.add('all');
    final sortedList = ids.toList(growable: true);
    sortedList.sort(
      (a, b) => instituteNameForId(a).compareTo(instituteNameForId(b)),
    );
    if (sortedList.remove('all')) {
      sortedList.insert(0, 'all');
    }
    return sortedList;
  }

  String instituteNameForId(String id) {
    if (id == 'all') return 'All institutes';
    return _academyById[id]?.name ?? id;
  }

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void setRole(UsersRoleFilter value) {
    _role = value;
    unawaited(refresh());
  }

  void setStatus(UsersStatusFilter value) {
    _status = value;
    unawaited(refresh());
  }

  void setInstitute(String value) {
    _instituteId = value;
    unawaited(refresh());
  }

  // Action Handlers

  Future<void> addUser(CreateUserDraft draft) async {
    if (_repository == null) return;

    final newUser = await _repository!.createUser(
      name: draft.name,
      email: draft.email,
      password: draft.password,
      phone: draft.phone,
      role: switch (draft.role) {
        AppUserRole.superAdmin => core_models.AppUserRole.superAdmin,
        AppUserRole.instituteAdmin => core_models.AppUserRole.instituteAdmin,
        AppUserRole.staff => core_models.AppUserRole.staff,
        AppUserRole.teacher => core_models.AppUserRole.teacher,
      },
      academyId: draft.instituteId,
      status: draft.status == AppUserStatus.active ? 'active' : 'blocked',
    );

    _all.insert(0, _mapToUiFromInternal(newUser));
    notifyListeners();
  }

  AppUser _mapToUiFromInternal(core_models.AppUser u) {
    return _mapToUi(u);
  }

  Future<void> toggleBlocked(String userId) async {
    final idx = _all.indexWhere((e) => e.id == userId);
    if (idx < 0 || _repository == null) return;

    final current = _all[idx];
    final nextStatus = current.status == AppUserStatus.blocked
        ? 'active'
        : 'blocked';

    await _repository!.setStatus(userId, nextStatus);

    _all[idx] = AppUser(
      id: current.id,
      name: current.name,
      email: current.email,
      phone: current.phone,
      role: current.role,
      instituteId: current.instituteId,
      instituteName: current.instituteName,
      status: nextStatus == 'blocked'
          ? AppUserStatus.blocked
          : AppUserStatus.active,
      lastLoginAt: current.lastLoginAt,
    );
    notifyListeners();
  }

  Future<void> updateUser(
    String userId, {
    required String name,
    required String phone,
    required core_models.AppUserRole role,
    required String instituteId,
  }) async {
    if (_repository == null) return;

    await _repository!.updateUser(userId, {
      'name': name,
      'phone': phone,
      'role': role.value,
      'academyId': instituteId,
    });

    final idx = _all.indexWhere((e) => e.id == userId);
    if (idx >= 0) {
      final current = _all[idx];
      _all[idx] = AppUser(
        id: current.id,
        name: name,
        email: current.email,
        phone: phone,
        role: switch (role) {
          core_models.AppUserRole.superAdmin => AppUserRole.superAdmin,
          core_models.AppUserRole.instituteAdmin => AppUserRole.instituteAdmin,
          core_models.AppUserRole.staff => AppUserRole.staff,
          core_models.AppUserRole.teacher => AppUserRole.teacher,
        },
        instituteId: instituteId,
        instituteName: role == core_models.AppUserRole.superAdmin
            ? 'EduCore Platform'
            : (_academyById[instituteId]?.name ?? instituteId),
        status: current.status,
        lastLoginAt: current.lastLoginAt,
      );
      notifyListeners();
    }
  }

  void _attachAcademies() {
    final svc = _instituteService ?? AppServices.instance.instituteService;
    if (svc == null) return;
    if (_academiesSub != null) return;

    _academiesSub = svc.watchAcademies().listen(
      (items) {
        final map = <String, Academy>{};
        for (final a in items) {
          map[a.id] = a;
        }
        _academyById = map;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('Academies stream error: $e');
      },
    );
  }

  AppUser _mapToUi(core_models.AppUser u) {
    final academyId = u.academyId.trim();
    final instituteName = u.role == core_models.AppUserRole.superAdmin
        ? 'EduCore Platform'
        : (_academyById[academyId]?.name ?? academyId);

    final role = switch (u.role) {
      core_models.AppUserRole.superAdmin => AppUserRole.superAdmin,
      core_models.AppUserRole.instituteAdmin => AppUserRole.instituteAdmin,
      core_models.AppUserRole.staff => AppUserRole.staff,
      core_models.AppUserRole.teacher => AppUserRole.teacher,
    };

    final status = u.status.toLowerCase().trim() == 'blocked'
        ? AppUserStatus.blocked
        : AppUserStatus.active;

    final name = u.name.trim().isNotEmpty
        ? u.name.trim()
        : _nameFromEmail(u.email);
    final phone = u.phone.trim().isNotEmpty ? u.phone.trim() : 'â€”';

    return AppUser(
      id: u.uid,
      name: name,
      email: u.email,
      phone: phone,
      role: role,
      instituteId: academyId,
      instituteName: instituteName,
      status: status,
      lastLoginAt: u.lastLoginAt,
    );
  }

  String _nameFromEmail(String email) {
    final clean = email.trim();
    if (clean.isEmpty) return 'Unknown';
    final local = clean.split('@').first;
    if (local.isEmpty) return 'Unknown';
    final parts = local.split(RegExp(r'[._-]+')).where((e) => e.isNotEmpty);
    return parts
        .map((p) => p.substring(0, 1).toUpperCase() + p.substring(1))
        .join(' ');
  }
}
