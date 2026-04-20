import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educore/src/core/models/app_user.dart';
import 'package:educore/src/core/repositories/user_repository.dart';
import 'package:educore/src/features/staff/models/staff_member.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/core/services/audit_log_service.dart';
import 'package:educore/src/core/services/subscription_service.dart';
import 'package:educore/src/features/audit/models/audit_log.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StaffService {
  StaffService({
    required FirebaseFirestore firestore,
    required UserRepository userRepository,
    required AuditLogService auditLogService,
    required SubscriptionService subscriptionService,
  }) : _firestore = firestore,
       _userRepository = userRepository,
       _auditLogService = auditLogService,
       _subscriptionService = subscriptionService;

  final FirebaseFirestore _firestore;
  final UserRepository _userRepository;
  final AuditLogService _auditLogService;
  final SubscriptionService _subscriptionService;

  CollectionReference<Map<String, dynamic>> _staffCol(String academyId) =>
      _firestore.collection('academies').doc(academyId).collection('staff');

  DocumentReference<Map<String, dynamic>> _userRef(String uid) =>
      _firestore.collection('users').doc(uid);

  Stream<List<StaffMember>> watchStaff(String academyId) {
    return _staffCol(academyId)
        .snapshots()
        .map((snap) => snap.docs
            .map(StaffMember.fromFirestore)
            .where((s) => s.status != 'deleted')
            .toList());
  }

  Future<List<StaffMember>> getStaff(String academyId) async {
    final snap = await _staffCol(academyId).get();
    return snap.docs
        .map(StaffMember.fromFirestore)
        .where((s) => s.status != 'deleted')
        .toList();
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
    // 1. Enforce Plan Limits
    await _subscriptionService.checkLimit(academyId, 'maxStaff');

    UserCredential? userCred;
    try {
      // 1. Provision Auth User first (cannot be batched)
      userCred = await _userRepository.provisionAuthUser(
        email: email,
        password: password,
      );

      final uid = userCred.user!.uid;
      final batch = _firestore.batch();

      // Map StaffRole to AppUserRole
      AppUserRole userRole = role == StaffRole.teacher
          ? AppUserRole.teacher
          : AppUserRole.staff;

      // 2. Add to Global Users (Atomic Item 1)
      _userRepository.batchCreateUser(
        batch: batch,
        uid: uid,
        name: name,
        email: email,
        phone: phone,
        role: userRole,
        academyId: academyId,
        status: 'active',
        createdBy:
            AppServices.instance.authService?.currentUser?.uid ?? 'system',
      );

      // 3. Add to Academy Staff (Atomic Item 2)
      final staffMember = StaffMember(
        id: uid,
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
      batch.set(_staffCol(academyId).doc(uid), staffMember.toFirestore());

      // 4. Commit Both
      await batch.commit();

      // 5. Log Action
      await _auditLogService.logAction(
        action: 'staff_create',
        module: 'staff',
        targetId: uid,
        targetType: 'staff',
        after: staffMember.toFirestore(),
        severity: AuditSeverity.warning,
      );
    } catch (e) {
      if (userCred != null) {
        try {
          await userCred.user?.delete();
        } catch (_) {}
      }
      rethrow;
    }
  }

  Future<void> updateStaff(String academyId, StaffMember staff) async {
    final batch = _firestore.batch();

    // Update Staff Doc
    batch.update(_staffCol(academyId).doc(staff.id), staff.toFirestore());

    // Sync to Global User (Identity + Role)
    batch.update(_userRef(staff.id), {
      'name': staff.name,
      'phone': staff.phone,
      'role': staff.role == StaffRole.teacher
          ? AppUserRole.teacher.value
          : AppUserRole.staff.value,
      'status': staff.isActive ? 'active' : 'blocked',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<void> deleteStaff(String academyId, String staffId) async {
    final batch = _firestore.batch();

    // Soft delete in academy staff
    batch.update(_staffCol(academyId).doc(staffId), {
      'isActive': false,
      'status': 'deleted', // Setting a status field for filtering
    });

    // Soft delete in global users
    batch.update(_userRef(staffId), {
      'status': 'deleted',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    await _auditLogService.logAction(
      action: 'staff_delete_soft',
      module: 'staff',
      targetId: staffId,
      targetType: 'staff',
      severity: AuditSeverity.critical,
    );
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
      targetId: staffId,
      targetType: 'staff',
      before: before,
      after: {'assignedFeatureKeys': allowed, 'deniedFeatureKeys': denied},
      severity: AuditSeverity.critical,
    );
  }

  Future<void> toggleStatus(
    String academyId,
    String staffId,
    bool isActive,
  ) async {
    final batch = _firestore.batch();
    final status = isActive ? 'active' : 'blocked';

    batch.update(_staffCol(academyId).doc(staffId), {'isActive': isActive});
    batch.update(_userRef(staffId), {
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    await _auditLogService.logAction(
      action: isActive ? 'staff_unblock' : 'staff_block',
      module: 'staff',
      targetId: staffId,
      targetType: 'staff',
      severity: AuditSeverity.warning,
    );
  }
}
