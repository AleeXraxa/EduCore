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
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.academyId,
    required this.status,
    required this.lastLoginAt,
    required this.createdAt,
    required this.createdBy,
  });

  final String uid;
  final String name;
  final String email;
  final String phone;
  final AppUserRole role;
  final String academyId;
  final String status;
  final DateTime? lastLoginAt;
  final DateTime? createdAt;
  final String createdBy;

  static AppUser fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return AppUser(
      uid: (data['uid'] as String?) ?? doc.id,
      name: (data['name'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
      phone: (data['phone'] as String?) ?? '',
      role: AppUserRole.fromValue(data['role'] as String?),
      academyId: (data['academyId'] as String?) ?? '',
      status: (data['status'] as String?) ?? 'active',
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      createdBy: (data['createdBy'] as String?) ?? '',
    );
  }
}
