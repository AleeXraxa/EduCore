import 'package:flutter/material.dart';

enum AppUserRole { superAdmin, instituteAdmin, staff, teacher }

enum AppUserStatus { active, blocked }

@immutable
class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.instituteId,
    required this.instituteName,
    required this.status,
    required this.lastLoginAt,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final AppUserRole role;
  final String instituteId;
  final String instituteName;
  final AppUserStatus status;
  final DateTime? lastLoginAt;
}
class CreateUserDraft {
  const CreateUserDraft({
    required this.name,
    required this.email,
    required this.password,
    required this.phone,
    required this.role,
    required this.instituteId,
    required this.status,
  });

  final String name;
  final String email;
  final String password;
  final String phone;
  final AppUserRole role;
  final String instituteId;
  final AppUserStatus status;
}
