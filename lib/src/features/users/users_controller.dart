import 'package:educore/src/core/mvc/base_controller.dart';
import 'package:educore/src/features/users/models/app_user.dart';

enum UsersRoleFilter { all, superAdmin, instituteAdmin, staff, teacher }

enum UsersStatusFilter { all, active, blocked }

class UsersController extends BaseController {
  final List<AppUser> _all = <AppUser>[];

  String _query = '';
  UsersRoleFilter _role = UsersRoleFilter.all;
  UsersStatusFilter _status = UsersStatusFilter.all;
  String _instituteId = 'all';

  int _page = 0;
  final int pageSize = 20;

  UsersController() {
    _seedMock();
  }

  String get query => _query;
  UsersRoleFilter get role => _role;
  UsersStatusFilter get status => _status;
  String get instituteId => _instituteId;
  int get page => _page;

  List<String> get institutes {
    final ids = <String>{..._all.map((e) => e.instituteId)};
    ids.add('all');
    final list = ids.toList(growable: true);
    list.sort((a, b) => instituteNameForId(a).compareTo(instituteNameForId(b)));
    if (list.remove('all')) {
      list.insert(0, 'all');
    }
    return list;
  }

  String instituteNameForId(String id) {
    if (id == 'all') return 'All institutes';
    return _all.firstWhere((e) => e.instituteId == id).instituteName;
  }

  List<AppUser> get filtered {
    final q = _query.trim().toLowerCase();
    Iterable<AppUser> list = _all;

    if (_role != UsersRoleFilter.all) {
      final role = switch (_role) {
        UsersRoleFilter.superAdmin => AppUserRole.superAdmin,
        UsersRoleFilter.instituteAdmin => AppUserRole.instituteAdmin,
        UsersRoleFilter.staff => AppUserRole.staff,
        UsersRoleFilter.teacher => AppUserRole.teacher,
        UsersRoleFilter.all => AppUserRole.staff,
      };
      list = list.where((e) => e.role == role);
    }

    if (_status != UsersStatusFilter.all) {
      final st = switch (_status) {
        UsersStatusFilter.active => AppUserStatus.active,
        UsersStatusFilter.blocked => AppUserStatus.blocked,
        UsersStatusFilter.all => AppUserStatus.active,
      };
      list = list.where((e) => e.status == st);
    }

    if (_instituteId != 'all') {
      list = list.where((e) => e.instituteId == _instituteId);
    }

    if (q.isNotEmpty) {
      list = list.where((e) {
        return e.name.toLowerCase().contains(q) ||
            e.email.toLowerCase().contains(q) ||
            e.phone.toLowerCase().contains(q) ||
            e.instituteName.toLowerCase().contains(q);
      });
    }

    return list.toList(growable: false);
  }

  int get totalCount => filtered.length;

  int get allCount => _all.length;

  int get activeCount =>
      _all.where((e) => e.status == AppUserStatus.active).length;

  int get instituteAdminsCount =>
      _all.where((e) => e.role == AppUserRole.instituteAdmin).length;

  int get staffTeachersCount => _all
      .where(
        (e) => e.role == AppUserRole.staff || e.role == AppUserRole.teacher,
      )
      .length;

  List<AppUser> get paged {
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

  void setRole(UsersRoleFilter value) {
    _role = value;
    _page = 0;
    notifyListeners();
  }

  void setStatus(UsersStatusFilter value) {
    _status = value;
    _page = 0;
    notifyListeners();
  }

  void setInstitute(String value) {
    _instituteId = value;
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

  void toggleBlocked(String userId) {
    final idx = _all.indexWhere((e) => e.id == userId);
    if (idx < 0) return;
    final current = _all[idx];
    _all[idx] = AppUser(
      id: current.id,
      name: current.name,
      email: current.email,
      phone: current.phone,
      role: current.role,
      instituteId: current.instituteId,
      instituteName: current.instituteName,
      status: current.status == AppUserStatus.blocked
          ? AppUserStatus.active
          : AppUserStatus.blocked,
      lastLoginAt: current.lastLoginAt,
    );
    notifyListeners();
  }

  void addUser(AppUser user) {
    _all.insert(0, user);
    _page = 0;
    notifyListeners();
  }

  void _seedMock() {
    // Replace with Firestore later. This dataset exists to validate UX at scale.
    final now = DateTime.now();
    final institutes = <({String id, String name})>[
      (id: 'all', name: 'All institutes'),
      (id: 'gv', name: 'Green Valley Academy'),
      (id: 'cs', name: 'City School — North Campus'),
      (id: 'ap', name: 'Apex Institute'),
      (id: 'sr', name: 'Sunrise School'),
    ];

    _all.addAll([
      AppUser(
        id: 'super_alee',
        name: 'Alee',
        email: 'alee@tryunity.com',
        phone: '+92 300 0000000',
        role: AppUserRole.superAdmin,
        instituteId: 'all',
        instituteName: 'EduCore Platform',
        status: AppUserStatus.active,
        lastLoginAt: now.subtract(const Duration(minutes: 18)),
      ),
      AppUser(
        id: 'super_ops',
        name: 'Platform Ops',
        email: 'ops@educore.com',
        phone: '+92 300 1112223',
        role: AppUserRole.superAdmin,
        instituteId: 'all',
        instituteName: 'EduCore Platform',
        status: AppUserStatus.active,
        lastLoginAt: now.subtract(const Duration(hours: 7)),
      ),
    ]);

    for (var i = 1; i <= 66; i++) {
      final institute = institutes[(i % (institutes.length - 1)) + 1];
      final role = switch (i % 4) {
        0 => AppUserRole.instituteAdmin,
        1 => AppUserRole.staff,
        2 => AppUserRole.teacher,
        _ => AppUserRole.staff,
      };
      final status = i % 17 == 0 ? AppUserStatus.blocked : AppUserStatus.active;
      final name = switch (role) {
        AppUserRole.instituteAdmin =>
          'Institute Admin ${i.toString().padLeft(2, '0')}',
        AppUserRole.teacher => 'Teacher ${i.toString().padLeft(2, '0')}',
        AppUserRole.staff => 'Staff ${i.toString().padLeft(2, '0')}',
        AppUserRole.superAdmin => 'Super Admin',
      };

      _all.add(
        AppUser(
          id: 'u_$i',
          name: name,
          email: 'user$i@${institute.id}.edu.pk',
          phone: '+92 301 55${(10000 + i).toString()}',
          role: role,
          instituteId: institute.id,
          instituteName: institute.name,
          status: status,
          lastLoginAt: i % 6 == 0
              ? null
              : now.subtract(Duration(days: i % 14, hours: i % 9)),
        ),
      );
    }
  }
}
