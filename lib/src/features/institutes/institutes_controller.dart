import 'package:educore/src/core/mvc/base_controller.dart';
import 'package:educore/src/features/institutes/models/institute.dart';

enum InstitutesFilter { all, active, expired, blocked }

class InstitutesController extends BaseController {
  final List<Institute> _all = <Institute>[];
  String _query = '';
  InstitutesFilter _filter = InstitutesFilter.all;

  int _page = 0;
  final int pageSize = 20;

  InstitutesController() {
    _seedMock();
  }

  String get query => _query;
  InstitutesFilter get filter => _filter;
  int get page => _page;

  List<Institute> get filtered {
    final q = _query.trim().toLowerCase();
    Iterable<Institute> list = _all;

    if (_filter != InstitutesFilter.all) {
      final status = switch (_filter) {
        InstitutesFilter.active => InstituteStatus.active,
        InstitutesFilter.expired => InstituteStatus.expired,
        InstitutesFilter.blocked => InstituteStatus.blocked,
        InstitutesFilter.all => InstituteStatus.active,
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

  void addInstitute(Institute institute) {
    _all.insert(0, institute);
    _page = 0;
    notifyListeners();
  }

  void toggleBlocked(String id) {
    final idx = _all.indexWhere((e) => e.id == id);
    if (idx < 0) return;
    final current = _all[idx];
    final nextStatus = current.status == InstituteStatus.blocked
        ? InstituteStatus.active
        : InstituteStatus.blocked;
    _all[idx] = Institute(
      id: current.id,
      name: current.name,
      ownerName: current.ownerName,
      email: current.email,
      phone: current.phone,
      plan: current.plan,
      status: nextStatus,
      studentsCount: current.studentsCount,
      createdAt: current.createdAt,
    );
    notifyListeners();
  }

  void _seedMock() {
    // Premium-feeling mock dataset for UI scaffolding. Replace with Firestore.
    final now = DateTime.now();
    final items = <Institute>[
      Institute(
        id: 'gv',
        name: 'Green Valley Academy',
        ownerName: 'Ahsan Khan',
        email: 'admin@greenvalley.edu.pk',
        phone: '+92 300 1234567',
        plan: InstitutePlan.standard,
        status: InstituteStatus.active,
        studentsCount: 1248,
        createdAt: now.subtract(const Duration(days: 92)),
      ),
      Institute(
        id: 'cs',
        name: 'City School – North Campus',
        ownerName: 'Sara Ali',
        email: 'hello@cityschool.pk',
        phone: '+92 301 5550192',
        plan: InstitutePlan.premium,
        status: InstituteStatus.active,
        studentsCount: 980,
        createdAt: now.subtract(const Duration(days: 121)),
      ),
      Institute(
        id: 'ap',
        name: 'Apex Institute',
        ownerName: 'Usman Raza',
        email: 'ops@apex.edu.pk',
        phone: '+92 333 1122044',
        plan: InstitutePlan.basic,
        status: InstituteStatus.blocked,
        studentsCount: 412,
        createdAt: now.subtract(const Duration(days: 64)),
      ),
      Institute(
        id: 'sr',
        name: 'Sunrise School',
        ownerName: 'Hina Ahmed',
        email: 'accounts@sunrise.edu.pk',
        phone: '+92 321 9911200',
        plan: InstitutePlan.standard,
        status: InstituteStatus.expired,
        studentsCount: 670,
        createdAt: now.subtract(const Duration(days: 210)),
      ),
    ];

    _all.addAll(items);

    // Add more items so the table + pagination feel realistic.
    for (var i = 1; i <= 38; i++) {
      _all.add(
        Institute(
          id: 'seed_$i',
          name: 'Institute ${i.toString().padLeft(2, '0')}',
          ownerName: 'Owner ${i.toString().padLeft(2, '0')}',
          email: 'owner$i@educore.pk',
          phone: '+92 300 000${i.toString().padLeft(4, '0')}',
          plan: i % 3 == 0
              ? InstitutePlan.premium
              : (i % 3 == 1 ? InstitutePlan.standard : InstitutePlan.basic),
          status: i % 10 == 0
              ? InstituteStatus.blocked
              : (i % 7 == 0 ? InstituteStatus.expired : InstituteStatus.active),
          studentsCount: 120 + (i * 12),
          createdAt: now.subtract(Duration(days: 10 + i * 3)),
        ),
      );
    }
  }
}

