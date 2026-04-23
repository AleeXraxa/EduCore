import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:educore/src/core/services/institute_service.dart';
import 'package:educore/src/core/mvc/base_controller.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/core/services/admin_subscriptions_service.dart';
import 'package:educore/src/core/repositories/institute_repository.dart';
import 'package:educore/src/core/services/plan_service.dart';
import 'package:educore/src/features/institutes/models/institute.dart';
import 'package:educore/src/features/plans/models/plan.dart';

enum InstitutesFilter { all, pending, active, blocked }

class InstitutesController extends BaseController {
  InstitutesController() {
    _repository = AppServices.instance.instituteRepository;
    _planService = AppServices.instance.planService;
    _subsService = AppServices.instance.adminSubscriptionsService;
    _init();
  }

  InstituteRepository? _repository;
  PlanService? _planService;
  AdminSubscriptionsService? _subsService;
  StreamSubscription<List<Plan>>? _planSub;

  final List<Institute> _all = [];
  Map<String, String> _planNameById = const {};

  String _query = '';
  InstitutesFilter _filter = InstitutesFilter.all;

  // Pagination
  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  final int _pageSize = 50;

  List<Plan> plans = const [];
  String? errorMessage;

  bool get ready => _repository != null;
  String get query => _query;
  InstitutesFilter get filter => _filter;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;
  List<Institute> get list => _all;

  Future<void> _init() async {
    if (_repository == null) {
      await runBusy<void>(() async {
        await AppServices.instance.init();
      });
      _repository = AppServices.instance.instituteRepository;
      _planService = AppServices.instance.planService;
    }

    await refresh();
    _subscribeToPlans();
  }

  Future<void> retryInit() => _init();

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
      final statusVal = switch (_filter) {
        InstitutesFilter.all => 'all',
        InstitutesFilter.pending => 'pending',
        InstitutesFilter.active => 'active',
        InstitutesFilter.blocked => 'blocked',
      };

      final results = await _repository!.getInstitutesBatch(
        limit: _pageSize,
        lastDoc: _lastDoc,
        status: statusVal,
      );

      if (results.length < _pageSize) {
        _hasMore = false;
      }

      if (results.isNotEmpty) {
        final lastInst = results.last;
        final doc = await FirebaseFirestore.instance
            .collection('academies')
            .doc(lastInst.id)
            .get();
        _lastDoc = doc;
        _all.addAll(results);
      }
      notifyListeners();
    } catch (e) {
      _hasMore = false;
    }
  }

  void _subscribeToPlans() {
    final planSvc = _planService;
    if (planSvc != null) {
      _planSub?.cancel();
      _planSub = planSvc.watchPlans().listen((value) {
        plans = value;
        _planNameById = {for (final p in value) p.id: p.name};
        notifyListeners();
      }, onError: (e) => errorMessage = e.toString());
    }
  }

  String planLabel(String planId) {
    final id = planId.trim();
    if (id.isEmpty) return '-';
    return _planNameById[id] ?? '-';
  }

  void setQuery(String value) {
    _query = value;
    // Local filtering for query is fine for smallish sets,
    // but in large scale this should be a server search.
    notifyListeners();
  }

  void setFilter(InstitutesFilter value) {
    _filter = value;
    unawaited(refresh());
  }

  Future<bool> createInstitute({
    required String name,
    required String ownerName,
    required String email,
    required String phone,
    required String address,
    required String adminEmail,
    required String adminPassword,
  }) async {
    if (_repository == null) return false;
    errorMessage = null;

    bool success = false;
    try {
      setBusy(true);
      await _repository!.createInstitute(
        name: name,
        ownerName: ownerName,
        email: email,
        phone: phone,
        address: address,
        adminEmail: adminEmail,
        adminPassword: adminPassword,
      );
      success = true;
    } on FirebaseAuthException catch (e) {
      errorMessage = _authErrorMessage(e.code);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      setBusy(false);
      notifyListeners();
    }

    if (success) await refresh();
    return success;
  }

  /// Maps Firebase Auth error codes to human-readable messages.
  String _authErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered. Please use a different email for the admin account.';
      case 'invalid-email':
        return 'The admin email address is not valid.';
      case 'weak-password':
        return 'The password is too weak. Please use at least 6 characters.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled. Contact support.';
      default:
        return 'Authentication error: $code';
    }
  }

  Future<void> toggleBlocked(String academyId) async {
    if (_repository == null) return;
    final idx = _all.indexWhere((e) => e.id == academyId);
    if (idx < 0) return;
    final current = _all[idx];
    final next = current.status == AcademyStatus.blocked
        ? AcademyStatus.active
        : AcademyStatus.blocked;

    await runBusy<void>(
      () => _repository!.updateInstituteStatus(academyId, next.name),
    );

    // Local sync
    _all[idx] = current.copyWith(status: next);
    notifyListeners();
  }

  Future<void> updateInstitute({
    required String academyId,
    required String name,
    required String ownerName,
    required String email,
    required String phone,
    required String address,
    required String planId,
    required AcademyStatus status,
    DateTime? endDate,
  }) async {
    if (_repository == null) return;
    await runBusy<void>(() async {
      await _repository!.updateInstitute(academyId, {
        'name': name,
        'ownerName': ownerName,
        'email': email,
        'phone': phone,
        'address': address,
      });

      await _repository!.updateInstituteStatus(academyId, status.name);

      final idx = _all.indexWhere((e) => e.id == academyId);
      final currentPlanId = idx < 0 ? '' : _all[idx].planId;
      if (planId.trim().isNotEmpty && planId.trim() != currentPlanId.trim()) {
        await _repository!.updateInstitutePlan(academyId, planId);
      }

      final subs =
          _subsService ?? AppServices.instance.adminSubscriptionsService;
      if (subs != null) {
        await subs.updateSubscription(
          academyId,
          endDate: endDate,
          setEndDate: true,
        );
      }
    });
    await refresh();
  }

  Future<DateTime?> getSubscriptionEndDate(String academyId) async {
    final svc = _subsService ?? AppServices.instance.adminSubscriptionsService;
    if (svc == null) return null;
    try {
      final record = await svc.getSubscription(academyId);
      return record?.endDate;
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _planSub?.cancel();
    super.dispose();
  }
}
