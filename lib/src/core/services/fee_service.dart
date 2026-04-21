import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:educore/src/features/fees/models/fee.dart';
import 'package:educore/src/features/fees/models/fee_transaction.dart';
import 'package:educore/src/features/fees/models/fee_plan.dart';
import 'package:educore/src/core/services/audit_log_service.dart';
import 'package:educore/src/core/services/fee_generation_lock_service.dart';

class FeeService {
  final FirebaseFirestore _firestore;
  final AuditLogService _audit;
  final FeeGenerationLockService? _lockService;

  FeeService({
    FirebaseFirestore? firestore,
    AuditLogService? auditLogService,
    FeeGenerationLockService? lockService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _audit = auditLogService ?? AuditLogService(firestore ?? FirebaseFirestore.instance),
       _lockService = lockService;

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
    required String feePlanId,
    required double amount,
    String? studentName,
    String? className,
  }) async {
    // Uniqueness check: No duplicate admission fee per student
    final existing = await _fees(academyId)
        .where('studentId', isEqualTo: studentId)
        .where('type', isEqualTo: FeeType.admission.name)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) return;

    final fee = Fee(
      id: '',
      academyId: academyId,
      studentId: studentId,
      classId: classId,
      feePlanId: feePlanId,
      type: FeeType.admission,
      title: 'Admission Fee',
      originalAmount: amount,
      finalAmount: amount,
      status: FeeStatus.pending,
      paidAmount: 0,
      studentName: studentName,
      className: className,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await createFee(academyId, fee);
  }

  /// Creates a package fee, providing strict uniqueness (limit 1 per student)
  Future<void> createPackageFee(
    String academyId, {
    required String studentId,
    required String classId,
    required String feePlanId,
    required double amount,
    String title = 'Full Course Package Fee',
    String? studentName,
    String? className,
  }) async {
    // Uniqueness check: No duplicate package fee per student
    final existing = await _fees(academyId)
        .where('studentId', isEqualTo: studentId)
        .where('type', isEqualTo: FeeType.package.name)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      return; // Already exists
    }

    final fee = Fee(
      id: '',
      academyId: academyId,
      studentId: studentId,
      classId: classId,
      feePlanId: feePlanId,
      type: FeeType.package,
      title: title,
      originalAmount: amount,
      finalAmount: amount,
      status: FeeStatus.pending,
      paidAmount: 0,
      studentName: studentName,
      className: className,
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
    final lockSvc = _lockService;
    if (lockSvc == null) {
      throw Exception('Fee generation lock service not available.');
    }
    
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
      // 0. Get the class to find metadata
      final classDoc = await _firestore
          .collection('academies')
          .doc(academyId)
          .collection('classes')
          .doc(classId)
          .get();

      final clsDefaultPlanId = classDoc.data()?['feePlanId'] as String?;
      final className = classDoc.data()?['name'] as String?;

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

      // 3. Pre-fetch existing fees for this month to avoid inner-loop queries
      final existingFeesSnapshot = await _fees(academyId)
          .where('classId', isEqualTo: classId)
          .where('month', isEqualTo: month)
          .where('type', isEqualTo: FeeType.monthly.name)
          .get();
      
      final existingStudentIds = existingFeesSnapshot.docs
          .map((d) => d.data()['studentId'] as String)
          .toSet();

      int generatedCount = 0;
      final batch = _firestore.batch();

      for (final studentDoc in studentsSnapshot.docs) {
        final studentId = studentDoc.id;
        final studentData = studentDoc.data();
        final studentName = studentData['name'] as String?;

        // SKIP students who are on a package plan
        final feeMode = studentData['feeMode'] as String? ?? 'monthly';
        if (feeMode == 'package') continue;

        // Uniqueness check: Use pre-fetched set
        if (!existingStudentIds.contains(studentId)) {
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
            studentName: studentName,
            className: className,
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

    debugPrint('FeeService: Starting collectPayment (using batch for Windows stability) for fee $feeId');
    
    // 1. Get current state outside batch (Read)
    final feeSnapshot = await feeRef.get();
    if (!feeSnapshot.exists) {
      throw Exception('Fee record not found.');
    }

    final fee = Fee.fromMap(feeSnapshot.id, feeSnapshot.data()!);
    final newPaidAmount = fee.paidAmount + paymentAmount;

    if (newPaidAmount > fee.finalAmount + 0.01) { // Adding small epsilon for float precision
      throw Exception('Payment exceeds total fee amount.');
    }

    final newStatus = newPaidAmount >= fee.finalAmount - 0.01
        ? FeeStatus.paid
        : FeeStatus.partial;

    final isLocked = newStatus == FeeStatus.paid;

    // 2. Prepare atomic updates (Write)
    final batch = _firestore.batch();

    // - Update Fee Record
    batch.update(feeRef, {
      'paidAmount': newPaidAmount,
      'status': newStatus.name,
      'isLocked': isLocked,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // - Update Summary record
    final summaryRef = _summary(academyId);
    batch.set(summaryRef, {
      'totalCollected': FieldValue.increment(paymentAmount),
      'lastTransactionAt': FieldValue.serverTimestamp(),
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // - Create Transaction Record
    final txn = FeeTransaction(
      id: txnRef.id,
      amount: paymentAmount,
      method: method,
      collectedBy: collectedBy,
      collectedAt: DateTime.now(),
      note: note,
    );
    batch.set(txnRef, txn.toMap());

    // 3. Commit
    await batch.commit();
    
    recordedNewPaidAmount = newPaidAmount;
    recordedStatus = newStatus.name;
    
    debugPrint('FeeService: Transaction completed successfully');

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

  /// Fetches fees with various filters and pagination support.
  Future<List<Fee>> getFees(
    String academyId, {
    String? studentId,
    String? classId,
    FeeType? type,
    FeeStatus? status,
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    Query<Map<String, dynamic>> query = _fees(academyId);

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

    // Default ordering
    query = query.orderBy('createdAt', descending: true);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.limit(limit).get();
    return snapshot.docs
        .map((doc) => Fee.fromMap(doc.id, doc.data()))
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

    // Windows C++ SDK does NOT support sum aggregates yet. 
    // We will fetch documents and sum them manually as a workaround.
    // For large datasets, this should be moved to a Cloud Function.
    
    double totalRevenue = 0.0;
    double totalPending = 0.0;
    double totalPackageRevenue = 0.0;
    double totalPackagePending = 0.0;

    final allFees = await rootQuery.get();
    for (final doc in allFees.docs) {
      final data = doc.data();
      final finalAmt = (data['finalAmount'] ?? 0.0).toDouble();
      final paidAmt = (data['paidAmount'] ?? 0.0).toDouble();
      final status = data['status'] as String?;
      final type = data['type'] as String?;

      if (status == FeeStatus.paid.name) {
        totalRevenue += finalAmt;
      } else {
        totalPending += (finalAmt - paidAmt);
      }

      if (type == FeeType.package.name) {
        totalPackageRevenue += paidAmt;
        totalPackagePending += (finalAmt - paidAmt);
      }
    }

    final result = {
      'totalRevenue': totalRevenue,
      'totalPending': totalPending,
      'totalPackageRevenue': totalPackageRevenue,
      'totalPackagePending': totalPackagePending,
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
