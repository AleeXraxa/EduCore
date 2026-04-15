import 'dart:async';

import 'package:educore/src/core/mvc/base_controller.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/core/services/admin_subscriptions_service.dart';
import 'package:educore/src/core/services/institute_service.dart';
import 'package:educore/src/core/services/plan_service.dart';
import 'package:educore/src/features/institutes/models/institute.dart';
import 'package:educore/src/features/plans/models/plan.dart';

enum InstitutesFilter { all, pending, active, blocked }

class InstitutesController extends BaseController {
  InstitutesController() {
    _instituteService = AppServices.instance.instituteService;
    _planService = AppServices.instance.planService;
    _subsService = AppServices.instance.adminSubscriptionsService;
    _attachOrInit();
  }

  InstituteService? _instituteService;
  PlanService? _planService;
  AdminSubscriptionsService? _subsService;
  StreamSubscription<List<Academy>>? _sub;
  StreamSubscription<List<Plan>>? _planSub;

  List<Institute> _all = const [];
  Map<String, String> _planNameById = const {};

  String _query = '';
  InstitutesFilter _filter = InstitutesFilter.all;

  int _page = 0;
  final int pageSize = 20;

  List<Plan> plans = const [];
  String? errorMessage;

  bool get ready => _instituteService != null;
  String get query => _query;
  InstitutesFilter get filter => _filter;
  int get page => _page;

  List<Institute> get filtered {
    final q = _query.trim().toLowerCase();
    Iterable<Institute> list = _all;

    if (_filter != InstitutesFilter.all) {
      final status = switch (_filter) {
        InstitutesFilter.pending => AcademyStatus.pending,
        InstitutesFilter.active => AcademyStatus.active,
        InstitutesFilter.blocked => AcademyStatus.blocked,
        InstitutesFilter.all => AcademyStatus.active,
      };
      list = list.where((e) => e.status == status);
    }

    if (q.isNotEmpty) {
      list = list.where((e) {
        return e.name.toLowerCase().contains(q) ||
            e.ownerName.toLowerCase().contains(q) ||
            e.email.toLowerCase().contains(q) ||
            e.phone.toLowerCase().contains(q);
      });
    }

    return list.toList(growable: false);
  }

  int get totalCount => filtered.length;

  List<Institute> get paged {
    final start = _page * pageSize;
    final list = filtered;
    if (start >= list.length) return const [];
    final end = (start + pageSize).clamp(0, list.length);
    return list.sublist(start, end);
  }

  String planLabel(String planId) {
    final id = planId.trim();
    if (id.isEmpty) return '-';
    return _planNameById[id] ?? '-';
  }

  void setQuery(String value) {
    _query = value;
    _page = 0;
    notifyListeners();
  }

  void setFilter(InstitutesFilter value) {
    _filter = value;
    _page = 0;
    notifyListeners();
  }

  void nextPage() {
    final maxPage = ((totalCount - 1) / pageSize).floor();
    if (_page >= maxPage) return;
    _page += 1;
    notifyListeners();
  }

  void prevPage() {
    if (_page <= 0) return;
    _page -= 1;
    notifyListeners();
  }

  Future<void> createInstitute({
    required String name,
    required String ownerName,
    required String email,
    required String phone,
    required String address,
    required String adminEmail,
    required String adminPassword,
  }) async {
    final svc = await _ensureService();
    await runBusy<void>(() async {
      await svc.createInstitute(
        name: name,
        ownerName: ownerName,
        email: email,
        phone: phone,
        address: address,
        adminEmail: adminEmail,
        adminPassword: adminPassword,
        planId: '',
        endDate: null,
      );
    });
  }

  Future<void> toggleBlocked(String academyId) async {
    final svc = await _ensureService();
    final idx = _all.indexWhere((e) => e.id == academyId);
    if (idx < 0) return;
    final current = _all[idx];
    final next = current.status == AcademyStatus.blocked
        ? AcademyStatus.active
        : AcademyStatus.blocked;
    await runBusy<void>(() => svc.setAcademyStatus(academyId, next));
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
    final svc = await _ensureService();
    await runBusy<void>(() async {
      await svc.updateInstitute(
        academyId: academyId,
        name: name,
        ownerName: ownerName,
        email: email,
        phone: phone,
        address: address,
      );

      await svc.setAcademyStatus(academyId, status);

      final idx = _all.indexWhere((e) => e.id == academyId);
      final currentPlanId = idx < 0 ? '' : _all[idx].planId;
      if (planId.trim().isNotEmpty && planId.trim() != currentPlanId.trim()) {
        await svc.setPlan(academyId, planId);
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

  Future<void> retryInit() => _attachOrInit();

  @override
  void dispose() {
    _sub?.cancel();
    _planSub?.cancel();
    super.dispose();
  }

  Future<void> _attachOrInit() async {
    if (_instituteService == null) {
      await runBusy<void>(() async {
        await AppServices.instance.init();
      });
      _instituteService = AppServices.instance.instituteService;
      _planService = AppServices.instance.planService;
      if (_instituteService == null) {
        errorMessage = AppServices.instance.firebaseInitError?.toString();
        notifyListeners();
        return;
      }
    }

    final svc = _instituteService!;
    _sub?.cancel();
    _sub = svc.watchAcademies().listen(
      (value) {
        _all = value
            .map(
              (a) => Institute(
                id: a.id,
                name: a.name,
                ownerName: a.ownerName,
                email: a.email,
                phone: a.phone,
                address: a.address,
                planId: a.planId,
                status: a.status,
                studentsCount: 0,
                createdAt: a.createdAt,
              ),
            )
            .toList(growable: false);
        errorMessage = null;
        notifyListeners();
      },
      onError: (e) {
        errorMessage = e.toString();
        notifyListeners();
      },
    );

    final planSvc = _planService;
    if (planSvc != null) {
      _planSub?.cancel();
      _planSub = planSvc.watchPlans().listen(
        (value) {
          plans = value;
          _planNameById = {for (final p in value) p.id: p.name};
          notifyListeners();
        },
        onError: (e) {
          errorMessage = e.toString();
          notifyListeners();
        },
      );
    }
  }

  Future<InstituteService> _ensureService() async {
    final existing = _instituteService ?? AppServices.instance.instituteService;
    if (existing != null) {
      _instituteService = existing;
      return existing;
    }
    await _attachOrInit();
    final svc = _instituteService ?? AppServices.instance.instituteService;
    if (svc == null) throw StateError('Firestore is not ready.');
    return svc;
  }
}
