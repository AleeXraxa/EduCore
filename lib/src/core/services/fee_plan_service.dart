import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educore/src/core/services/audit_log_service.dart';
import 'package:educore/src/features/audit/models/audit_log.dart';
import 'package:educore/src/features/fees/models/fee_plan.dart';

class FeePlanService {
  final FirebaseFirestore _firestore;
  final AuditLogService _audit;

  FeePlanService({
    required FirebaseFirestore firestore,
    required AuditLogService auditLogService,
  })  : _firestore = firestore,
        _audit = auditLogService;

  CollectionReference<Map<String, dynamic>> _col(String academyId) =>
      _firestore.collection('academies').doc(academyId).collection('fee_plans');

  Future<List<FeePlan>> getFeePlans(String academyId) async {
    final snap = await _col(academyId).orderBy('createdAt', descending: true).get();
    return snap.docs.map((doc) => FeePlan.fromMap(doc.id, doc.data())).toList();
  }

  Future<FeePlan?> getFeePlan(String academyId, String planId) async {
    final doc = await _col(academyId).doc(planId).get();
    if (!doc.exists) return null;
    return FeePlan.fromMap(doc.id, doc.data()!);
  }

  Future<void> createFeePlan({
    required String academyId,
    required String name,
    required String description,
    required String scope,
    String? classId,
    required double admissionFee,
    double monthlyFee = 0.0,
    int monthlyDueDay = 5,
    double totalCourseFee = 0.0,
    int? durationMonths,
    bool allowInstallments = false,
    int? installmentCount,
    FeePlanType planType = FeePlanType.monthly,
    double? lateFeePerDay,
    required bool allowPartialPayment,
    required String performedBy,
  }) async {
    final docRef = _col(academyId).doc();
    final plan = FeePlan(
      id: docRef.id,
      name: name,
      description: description,
      scope: scope,
      classId: classId,
      isActive: true,
      admissionFee: admissionFee,
      monthlyFee: monthlyFee,
      monthlyDueDay: monthlyDueDay,
      totalCourseFee: totalCourseFee,
      durationMonths: durationMonths,
      allowInstallments: allowInstallments,
      installmentCount: installmentCount,
      planType: planType,
      lateFeePerDay: lateFeePerDay,
      allowPartialPayment: allowPartialPayment,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await docRef.set(plan.toMap());

    await _audit.logAction(
      action: 'fee_plan_create',
      module: 'fee_plans',
      targetId: docRef.id,
      targetType: 'fee_plan',
      severity: AuditSeverity.info,
      after: plan.toMap(),
    );
  }

  Future<void> updateFeePlan({
    required String academyId,
    required String planId,
    required Map<String, dynamic> updates,
    required String performedBy,
  }) async {
    final docRef = _col(academyId).doc(planId);
    final beforeSnap = await docRef.get();
    
    await docRef.update({
      ...updates,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _audit.logAction(
      action: 'fee_plan_update',
      module: 'fee_plans',
      targetId: planId,
      targetType: 'fee_plan',
      severity: AuditSeverity.info,
      before: beforeSnap.data(),
      after: updates,
    );
  }

  Future<void> deleteFeePlan(String academyId, String planId, String performedBy) async {
    // SECURITY: Block if assigned to any class or student
    final classCheck = await _firestore
        .collection('academies')
        .doc(academyId)
        .collection('classes')
        .where('feePlanId', isEqualTo: planId)
        .limit(1)
        .get();

    if (classCheck.docs.isNotEmpty) {
      throw Exception('Cannot delete plan: It is currently assigned as a default for a class.');
    }

    final studentCheck = await _firestore
        .collection('academies')
        .doc(academyId)
        .collection('students')
        .where('feePlanId', isEqualTo: planId)
        .limit(1)
        .get();

    if (studentCheck.docs.isNotEmpty) {
      throw Exception('Cannot delete plan: It is assigned to one or more students.');
    }

    await _col(academyId).doc(planId).delete();

    await _audit.logAction(
      action: 'fee_plan_delete',
      module: 'fee_plans',
      targetId: planId,
      targetType: 'fee_plan',
      severity: AuditSeverity.critical,
    );
  }
}
