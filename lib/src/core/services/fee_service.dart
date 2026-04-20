import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:educore/src/features/fees/models/fee.dart';
import 'package:educore/src/features/fees/models/fee_transaction.dart';
import 'package:educore/src/features/fees/models/fee_plan.dart';
import 'package:educore/src/core/services/audit_log_service.dart';
import 'package:educore/src/core/services/fee_generation_lock_service.dart';
import 'package:educore/src/core/services/app_services.dart';

class FeeService {
  final FirebaseFirestore _firestore;
  final AuditLogService _audit;

  FeeService({FirebaseFirestore? firestore, AuditLogService? auditLogService})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _audit =
          auditLogService ??
          AuditLogService(firestore ?? FirebaseFirestore.instance);

  CollectionReference<Map<String, dynamic>> _fees(String academyId) =>
      _firestore.collection('academies').doc(academyId).collection('fees');

  /// Creates a single fee record with audit logging
  Future<Fee> createFee(
    String academyId,
    Fee fee, {
    String? overrideBy,
    DateTime? overrideAt,
  }) async {
    final docRef = _fees(academyId).doc();

    final newFee = fee.copyWith(
      id: docRef.id,
      academyId: academyId,
      overriddenBy: overrideBy,
      overriddenAt: overrideAt,
    );

    await docRef.set(newFee.toMap());

    // Original amount logging for overrides
    final metadata = {
      'type': newFee.type.name,
      'studentId': newFee.studentId,
      'finalAmount': newFee.finalAmount,
      'originalAmount': newFee.originalAmount,
    };

    if (newFee.isOverridden) {
      metadata['isOverridden'] = true;
      metadata['reason'] = newFee.overrideReason ?? 'No reason provided';
      metadata['actorId'] = overrideBy ?? 'unknown';
    }

    if (newFee.discountType != DiscountType.none) {
      metadata['discountType'] = newFee.discountType.name;
      metadata['discountValue'] = newFee.discountValue;
      metadata['discountAmount'] = newFee.discountAmount;
    }

    await _audit.logAction(
      action: newFee.isOverridden ? 'fee_override' : 'fee_create',
      module: 'fees',
      targetId: newFee.id,
      targetType: 'fee',
      metadata: metadata,
    );

    // Refreshes aggregate stats for consistency
    try {
      await refreshFeeStats(academyId);
    } catch (e) {
      debugPrint('Background stats refresh failed: $e');
    }

    return newFee;
  }

  /// Creates an admission fee, ensuring no duplicates exist for the student
  Future<void> createAdmissionFee(
    String academyId, {
    required String studentId,
    required String classId,
    required double amount,
  }) async {
    // Check for existing admission fee
    final existing = await _fees(academyId)
        .where('studentId', isEqualTo: studentId)
        .where('type', isEqualTo: FeeType.admission.name)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('Admission fee already exists for this student.');
    }

    final fee = Fee(
      id: '',
      academyId: academyId,
      studentId: studentId,
      classId: classId,
      feePlanId: '', // To be filled if plan is known
      type: FeeType.admission,
      title: 'Admission Fee',
      originalAmount: amount,
      finalAmount: amount,
      status: FeeStatus.pending,
      paidAmount: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await createFee(academyId, fee);
  }

  /// Generates monthly fees for a class.
  /// Prevents duplicate billing using a Firestore-backed generation lock.
  /// If [amount] is null, it resolves the fee from each student's FeePlan.
  Future<int> generateMonthlyFees(
    String academyId, {
    required String classId,
    required String month, // YYYY-MM
    double? amount, // If provided, overrides the plan amount
    String? overrideReason,
    String? overriddenBy,
    required String title,
    DateTime? dueDate,
  }) async {
    // --- Lock acquisition ---
    final lockSvc = AppServices.instance.feeGenerationLockService!;
    final lockResult = await lockSvc.acquireLock(
      academyId,
      classId: classId,
      month: month,
    );

    if (lockResult is LockBlocked) {
      final msg = lockResult.status == 'completed'
          ? 'Fees for this class and month have already been generated.'
          : 'Generation is already in progress for this class and month. Please wait.';
      throw Exception(msg);
    }

    // --- Generation ---
    try {
      // 0. Get the class to find the default plan
      final classDoc = await _firestore
          .collection('academies')
          .doc(academyId)
          .collection('classes')
          .doc(classId)
          .get();

      final clsDefaultPlanId = classDoc.data()?['feePlanId'] as String?;

      // 1. Get all active students in class
      final studentsSnapshot = await _firestore
          .collection('academies')
          .doc(academyId)
          .collection('students')
          .where('classId', isEqualTo: classId)
          .where('status', isEqualTo: 'active')
          .get();

      // 2. Fetch all fee plans for lookup
      final plansSnapshot = await _firestore
          .collection('academies')
          .doc(academyId)
          .collection('fee_plans')
          .get();

      final plansMap = {
        for (final doc in plansSnapshot.docs)
          doc.id: FeePlan.fromMap(doc.id, doc.data()),
      };

      int generatedCount = 0;
      final batch = _firestore.batch();

      for (final studentDoc in studentsSnapshot.docs) {
        final studentId = studentDoc.id;
        final studentData = studentDoc.data();

        // Uniqueness check: One monthly fee per student per month
        final existing = await _fees(academyId)
            .where('studentId', isEqualTo: studentId)
            .where('month', isEqualTo: month)
            .where('type', isEqualTo: FeeType.monthly.name)
            .limit(1)
            .get();

        if (existing.docs.isEmpty) {
          final planId =
              studentData['feePlanId'] as String? ?? clsDefaultPlanId;
          final plan = plansMap[planId];
          final originalAmount = plan?.monthlyFee ?? 0.0;

          double currentFinalAmount = amount ?? originalAmount;
          bool isOverridden = amount != null && amount != originalAmount;

          DiscountType dType = DiscountType.none;
          double dValue = 0.0;
          double dAmount = 0.0;

          // Apply plan discount if no manual override was provided
          if (!isOverridden &&
              plan != null &&
              plan.discountType != DiscountType.none) {
            final calculated = Fee.calculateDiscount(
              originalAmount,
              plan.discountType,
              plan.discountValue,
            );
            dType = plan.discountType;
            dValue = plan.discountValue;
            dAmount = calculated.$1;
            currentFinalAmount = calculated.$2;
          }

          if (currentFinalAmount <= 0 && dAmount == 0) continue;

          final docRef = _fees(academyId).doc();
          final fee = Fee(
            id: docRef.id,
            academyId: academyId,
            studentId: studentId,
            classId: classId,
            feePlanId: planId ?? '',
            type: FeeType.monthly,
            title: title,
            originalAmount: originalAmount,
            finalAmount: currentFinalAmount,
            discountType: dType,
            discountValue: dValue,
            discountAmount: dAmount,
            isOverridden: isOverridden,
            overrideReason: isOverridden ? overrideReason : null,
            overriddenBy: isOverridden ? overriddenBy : null,
            overriddenAt: isOverridden ? DateTime.now() : null,
            status: FeeStatus.pending,
            paidAmount: 0,
            month: month,
            dueDate: dueDate,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          batch.set(docRef, fee.toMap());
          generatedCount++;
        }
      }

      if (generatedCount > 0) {
        await batch.commit();

        await _audit.logAction(
          action: 'fee_monthly_generate',
          module: 'fees',
          targetId: classId,
          targetType: 'class',
          metadata: {
            'month': month,
            'count': generatedCount,
            'amountMode': amount == null ? 'plan_driven' : 'override',
            'amountOverride': amount,
            'overrideReason': overrideReason,
            'actorId': overriddenBy,
          },
        );
      }

      // Mark lock as completed on success
      await lockSvc.completeLock(academyId, classId: classId, month: month);

      // Refreshes aggregate stats for consistency
      try {
        await refreshFeeStats(academyId);
      } catch (e) {
        debugPrint('Background stats refresh failed: $e');
      }

      return generatedCount;
    } catch (e) {
      // Release the lock on failure so the admin can retry
      await lockSvc.releaseLock(academyId, classId: classId, month: month);
      rethrow;
    }
  }

  /// Records a payment for a specific fee using atomic transaction
  Future<void> collectPayment(
    String academyId, {
    required String feeId,
    required double paymentAmount,
    required PaymentMethod method,
    required String collectedBy, // uid of the admin
    String? note,
  }) async {
    final feeRef = _fees(academyId).doc(feeId);
    final txnRef = feeRef.collection('transactions').doc();

    double recordedNewPaidAmount = 0.0;
    String recordedStatus = '';

    await _firestore.runTransaction((tx) async {
      final feeSnapshot = await tx.get(feeRef);
      if (!feeSnapshot.exists) {
        throw Exception('Fee record not found.');
      }

      final fee = Fee.fromMap(feeSnapshot.id, feeSnapshot.data()!);
      final newPaidAmount = fee.paidAmount + paymentAmount;

      if (newPaidAmount > fee.finalAmount) {
        throw Exception('Payment exceeds total fee amount.');
      }

      final newStatus = newPaidAmount >= fee.finalAmount
          ? FeeStatus.paid
          : FeeStatus.partial;

      // Ensure that we can't accidentally mark as paid if we somehow exceeded finalAmount via float inaccuracies - though handled by check above

      final isLocked = newStatus == FeeStatus.paid;

      tx.update(feeRef, {
        'paidAmount': newPaidAmount,
        'status': newStatus.name,
        'isLocked': isLocked,
        'updatedAt': Timestamp.now(),
      });

      final txn = FeeTransaction(
        id: txnRef.id,
        amount: paymentAmount,
        method: method,
        collectedBy: collectedBy,
        collectedAt: DateTime.now(),
        note: note,
      );

      tx.set(txnRef, txn.toMap());

      recordedNewPaidAmount = newPaidAmount;
      recordedStatus = newStatus.name;
    });

    // Run audit logging OUTSIDE transaction to prevent C++ SDK crashes on Windows
    await _audit.logAction(
      action: 'fee_collect',
      module: 'fees',
      targetId: feeId,
      targetType: 'fee',
      metadata: {
        'amountCollected': paymentAmount,
        'method': method.name,
        'transactionId': txnRef.id,
        'totalPaid': recordedNewPaidAmount,
        'status': recordedStatus,
      },
    );

    // Refreshes aggregate stats for consistency
    try {
      await refreshFeeStats(academyId);
    } catch (e) {
      debugPrint('Background stats refresh failed: $e');
    }
  }

  /// Fetches transactions for a specific fee
  Future<List<FeeTransaction>> getTransactions(
    String academyId,
    String feeId,
  ) async {
    final snapshot = await _fees(academyId)
        .doc(feeId)
        .collection('transactions')
        .orderBy('collectedAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => FeeTransaction.fromMap(doc.id, doc.data()))
        .toList();
  }

  /// Fetches transactions for a specific fee as a stream
  Stream<List<FeeTransaction>> transactionsStream(
    String academyId,
    String feeId,
  ) {
    return _fees(academyId)
        .doc(feeId)
        .collection('transactions')
        .orderBy('collectedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FeeTransaction.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Fetches fees with various filters
  Future<List<Fee>> getFees(
    String academyId, {
    String? studentId,
    String? classId,
    FeeType? type,
    FeeStatus? status,
    int limit = 50,
  }) async {
    Query query = _fees(
      academyId,
    ).orderBy('createdAt', descending: true).limit(limit);

    if (studentId != null) {
      query = query.where('studentId', isEqualTo: studentId);
    }
    if (classId != null) {
      query = query.where('classId', isEqualTo: classId);
    }
    if (type != null) {
      query = query.where('type', isEqualTo: type.name);
    }
    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => Fee.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  }

  DocumentReference<Map<String, dynamic>> _summary(String academyId) =>
      _firestore
          .collection('academies')
          .doc(academyId)
          .collection('finance_summary')
          .doc('data');

  /// Dashboard statistics using server-side aggregate queries for consistency.
  /// Result is cached in a summary document in the academy's subcollection.
  Future<Map<String, dynamic>> getFeeStats(String academyId) async {
    try {
      final summarySnapshot = await _summary(academyId).get();
      if (summarySnapshot.exists) {
        final data = summarySnapshot.data()!;
        final lastUpdated = (data['lastUpdated'] as Timestamp).toDate();

        // If updated in the last 5 minutes, return the cache
        if (DateTime.now().difference(lastUpdated).inMinutes < 5) {
          return data;
        }
      }

      // Re-calculate using server-side aggregates
      return await refreshFeeStats(academyId);
    } catch (e) {
      debugPrint('Error getting fee stats: $e');
      return {
        'totalRevenue': 0.0,
        'totalPending': 0.0,
        'typeDistribution': <String, double>{},
      };
    }
  }

  /// Force a fresh calculation of financial stats using server-side aggregation
  Future<Map<String, dynamic>> refreshFeeStats(String academyId) async {
    final rootQuery = _fees(academyId);

    // 1. Calculate Revenue (SUM of finalAmount where status == paid)
    final revenueQuery = rootQuery.where(
      'status',
      isEqualTo: FeeStatus.paid.name,
    );
    final revenueAggregate = await revenueQuery
        .aggregate(sum('finalAmount'))
        .get();
    final totalRevenue = (revenueAggregate.getSum('finalAmount') ?? 0.0)
        .toDouble();

    // 2. Calculate Pending (Strictly: sum(finalAmount) - sum(paidAmount) where status != paid)
    final pendingQuery = rootQuery.where(
      'status',
      isNotEqualTo: FeeStatus.paid.name,
    );
    final pendingAggregate = await pendingQuery
        .aggregate(sum('finalAmount'), sum('paidAmount'))
        .get();

    final totalPending =
        (pendingAggregate.getSum('finalAmount') ?? 0.0).toDouble() -
        (pendingAggregate.getSum('paidAmount') ?? 0.0).toDouble();

    // 3. Distribution (Requires specific sums per type)
    final result = {
      'totalRevenue': totalRevenue,
      'totalPending': totalPending,
      'lastUpdated': FieldValue.serverTimestamp(),
    };

    // Save to cache
    await _summary(academyId).set(result, SetOptions(merge: true));

    // Distribution is still manual for now as we can't 'group by' in firestore,
    // but we usually have few enough types to run a few counts if needed.
    // For now, we return empty distribution to prioritize speed and core KPIs.
    result['typeDistribution'] = <String, double>{};

    return result;
  }
}
