import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum AppUserRole {
  superAdmin('super_admin'),
  instituteAdmin('institute_admin'),
  staff('staff'),
  teacher('teacher');

  const AppUserRole(this.value);
  final String value;

  static AppUserRole fromValue(String? value) {
    switch ((value ?? '').trim().toLowerCase()) {
      case 'super_admin':
        return AppUserRole.superAdmin;
      case 'institute_admin':
        return AppUserRole.instituteAdmin;
      case 'teacher':
        return AppUserRole.teacher;
      case 'staff':
      default:
        return AppUserRole.staff;
    }
  }
}

@immutable
class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.role,
    required this.academyId,
    required this.createdAt,
    required this.createdBy,
  });

  final String uid;
  final String email;
  final AppUserRole role;
  final String academyId;
  final DateTime? createdAt;
  final String createdBy;

  static AppUser fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return AppUser(
      uid: (data['uid'] as String?) ?? doc.id,
      email: (data['email'] as String?) ?? '',
      role: AppUserRole.fromValue(data['role'] as String?),
      academyId: (data['academyId'] as String?) ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      createdBy: (data['createdBy'] as String?) ?? '',
    );
  }
}
