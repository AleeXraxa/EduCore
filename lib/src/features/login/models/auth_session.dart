import 'package:educore/src/core/models/app_user.dart';

class AuthSession {
  final AppUser user;
  final String academyId;
  final String? academyName;
  final String? logoUrl;
  final List<String> permissions;

  AuthSession({
    required this.user,
    required this.academyId,
    this.academyName,
    this.logoUrl,
    this.permissions = const [],
    String? sessionId,
  }) : sessionId = sessionId ?? DateTime.now().millisecondsSinceEpoch.toString();

  final String sessionId;

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
