import 'package:educore/src/core/models/app_user.dart';

class AuthSession {
  final AppUser user;
  final String academyId;
  final List<String> permissions;

  AuthSession({
    required this.user,
    required this.academyId,
    this.permissions = const [],
  });

  bool get isSuperAdmin {
    return user.role == AppUserRole.superAdmin;
  }

  bool get isInstituteAdmin {
    return user.role == AppUserRole.instituteAdmin;
  }

  bool get isStaff {
    return user.role == AppUserRole.staff;
  }

  bool get isTeacher {
    return user.role == AppUserRole.teacher;
  }
}
