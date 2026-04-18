import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educore/src/core/models/app_user.dart';
import 'package:educore/src/core/repositories/user_repository.dart';
import 'package:educore/src/features/staff/models/staff_member.dart';
import 'package:educore/src/core/services/audit_log_service.dart';
import 'package:educore/src/features/audit/models/audit_log.dart';

class StaffService {
  StaffService({
    required FirebaseFirestore firestore,
    required UserRepository userRepository,
    required AuditLogService auditLogService,
  })  : _firestore = firestore,
        _userRepository = userRepository,
        _auditLogService = auditLogService;

  final FirebaseFirestore _firestore;
  final UserRepository _userRepository;
  final AuditLogService _auditLogService;

  CollectionReference<Map<String, dynamic>> _staffCol(String academyId) =>
      _firestore.collection('academies').doc(academyId).collection('staff');

  Stream<List<StaffMember>> watchStaff(String academyId) {
    return _staffCol(academyId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(StaffMember.fromFirestore).toList());
  }

  Future<void> createStaff({
    required String academyId,
    required String name,
    required String email,
    required String password,
    required String phone,
    required StaffRole role,
    String? customRoleName,
    List<String> assignedFeatureKeys = const [],
  }) async {
    // 1. Create User in Auth & Global Users via Repository
    // Map StaffRole to AppUserRole
    AppUserRole userRole = AppUserRole.staff;
    if (role == StaffRole.teacher) {
      userRole = AppUserRole.teacher;
    }

    final appUser = await _userRepository.createUser(
      name: name,
      email: email,
      password: password,
      phone: phone,
      role: userRole,
      academyId: academyId,
      status: 'active',
    );

    // 2. Create Staff Document in Academy
    final staffMember = StaffMember(
      id: appUser.uid, // Unified ID
      name: name,
      email: email,
      phone: phone,
      role: role,
      customRoleName: customRoleName,
      assignedFeatureKeys: assignedFeatureKeys,
      deniedFeatureKeys: [],
      isActive: true,
      createdAt: DateTime.now(),
    );

    await _staffCol(academyId).doc(appUser.uid).set(staffMember.toFirestore());

    // 3. Log Action
    await _auditLogService.logAction(
      action: 'staff_create',
      module: 'staff',
      academyId: academyId,
      uid: appUser.uid,
      role: 'admin',
      targetDoc: appUser.uid,
      after: staffMember.toFirestore(),
      source: AuditSource.institute,
      severity: AuditSeverity.medium,
    );
  }

  Future<void> updateStaff(String academyId, StaffMember staff) async {
    await _staffCol(academyId).doc(staff.id).update(staff.toFirestore());

    // Sync status to global user if changed
    await _userRepository.setStatus(staff.id, staff.isActive ? 'active' : 'blocked');
    
    // Sync name/phone to global user
    await _userRepository.updateUser(staff.id, {
      'name': staff.name,
      'phone': staff.phone,
    });
  }

  Future<void> deleteStaff(String academyId, String staffId) async {
    // Note: We don't usually delete Auth users from here for safety, 
    // but we block them. For a "hard delete" as requested:
    await _staffCol(academyId).doc(staffId).delete();
    await _userRepository.setStatus(staffId, 'deleted');
  }

  Future<void> updatePermissions({
    required String academyId,
    required String staffId,
    required List<String> allowed,
    required List<String> denied,
  }) async {
    final doc = await _staffCol(academyId).doc(staffId).get();
    final before = doc.data();

    await _staffCol(academyId).doc(staffId).update({
      'assignedFeatureKeys': allowed,
      'deniedFeatureKeys': denied,
    });

    await _auditLogService.logAction(
      action: 'permissions_update',
      module: 'staff',
      academyId: academyId,
      uid: staffId,
      role: 'admin',
      targetDoc: staffId,
      before: before,
      after: {
        'assignedFeatureKeys': allowed,
        'deniedFeatureKeys': denied,
      },
      source: AuditSource.institute,
      severity: AuditSeverity.high,
    );
  }

  Future<void> toggleStatus(String academyId, String staffId, bool isActive) async {
    await _staffCol(academyId).doc(staffId).update({
      'isActive': isActive,
    });
    await _userRepository.setStatus(staffId, isActive ? 'active' : 'blocked');

    await _auditLogService.logAction(
      action: isActive ? 'staff_unblock' : 'staff_block',
      module: 'staff',
      academyId: academyId,
      uid: staffId,
      role: 'admin',
      targetDoc: staffId,
      source: AuditSource.institute,
      severity: AuditSeverity.medium,
    );
  }
}
