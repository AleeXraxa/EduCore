import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educore/src/features/fees/models/fee.dart';
import 'package:educore/src/core/services/audit_log_service.dart';

class FeeService {
  final FirebaseFirestore _firestore;
  final AuditLogService _audit;

  FeeService({FirebaseFirestore? firestore, AuditLogService? audit})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _audit = audit ?? AuditLogService(firestore ?? FirebaseFirestore.instance);

  CollectionReference<Map<String, dynamic>> _fees(String academyId) =>
      _firestore.collection('academies').doc(academyId).collection('fees');

  /// Creates a single fee record with audit logging
  Future<Fee> createFee(String academyId, Fee fee) async {
    final docRef = _fees(academyId).doc();
    final newFee = fee.copyWith(id: docRef.id, academyId: academyId);
    
    await docRef.set(newFee.toMap());

    await _audit.logAction(
      action: 'fee_create',
      module: 'fees',
      targetId: newFee.id,
      targetType: 'fee',
      metadata: {
        'type': newFee.type.name,
        'studentId': newFee.studentId,
        'amount': newFee.amount,
      },
    );

    return newFee;
  }

  /// Creates an admission fee, ensuring no duplicates exist for the student
  Future<void> createAdmissionFee(String academyId, {
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
      type: FeeType.admission,
      title: 'Admission Fee',
      amount: amount,
      status: FeeStatus.pending,
      paidAmount: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await createFee(academyId, fee);
  }

  /// Generates monthly fees for a class
  /// Prevents duplicates for (studentId + month + type: monthly)
  Future<int> generateMonthlyFees(String academyId, {
    required String classId,
    required String month, // YYYY-MM
    required double amount,
    required String title,
    DateTime? dueDate,
  }) async {
    // 1. Get all students in class
    final studentsSnapshot = await _firestore
        .collection('academies')
        .doc(academyId)
        .collection('students')
        .where('classId', isEqualTo: classId)
        .where('status', isEqualTo: 'active')
        .get();

    int generatedCount = 0;
    final batch = _firestore.batch();

    for (final studentDoc in studentsSnapshot.docs) {
      final studentId = studentDoc.id;

      // Uniqueness check: One monthly fee per student per month
      final existing = await _fees(academyId)
          .where('studentId', isEqualTo: studentId)
          .where('month', isEqualTo: month)
          .where('type', isEqualTo: FeeType.monthly.name)
          .limit(1)
          .get();

      if (existing.docs.isEmpty) {
        final docRef = _fees(academyId).doc();
        final fee = Fee(
          id: docRef.id,
          academyId: academyId,
          studentId: studentId,
          classId: classId,
          type: FeeType.monthly,
          title: title,
          amount: amount,
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
          'amountPerStudent': amount,
        },
      );
    }

    return generatedCount;
  }

  /// Records a payment for a specific fee
  Future<void> collectPayment(String academyId, {
    required String feeId,
    required double paymentAmount,
  }) async {
    final docRef = _fees(academyId).doc(feeId);
    
    double recordedNewPaidAmount = 0.0;
    String recordedStatus = '';

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) throw Exception('Fee record not found.');
      
      final fee = Fee.fromMap(snapshot.id, snapshot.data()!);
      final newPaidAmount = fee.paidAmount + paymentAmount;
      
      if (newPaidAmount > fee.amount) {
        throw Exception('Payment exceeds total fee amount.');
      }

      final newStatus = newPaidAmount >= fee.amount 
          ? FeeStatus.paid 
          : FeeStatus.partial;

      transaction.update(docRef, {
        'paidAmount': newPaidAmount,
        'status': newStatus.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

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
        'totalPaid': recordedNewPaidAmount,
        'status': recordedStatus,
      },
    );
  }

  /// Fetches fees with various filters
  Future<List<Fee>> getFees(String academyId, {
    String? studentId,
    String? classId,
    FeeType? type,
    FeeStatus? status,
    int limit = 50,
  }) async {
    Query query = _fees(academyId).orderBy('createdAt', descending: true).limit(limit);

    if (studentId != null) query = query.where('studentId', isEqualTo: studentId);
    if (classId != null) query = query.where('classId', isEqualTo: classId);
    if (type != null) query = query.where('type', isEqualTo: type.name);
    if (status != null) query = query.where('status', isEqualTo: status.name);

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => Fee.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  }

  /// Dashboard statistics
  Future<Map<String, dynamic>> getFeeStats(String academyId) async {
    final snapshot = await _fees(academyId).get();
    
    double totalRevenue = 0;
    double totalPending = 0;
    Map<String, double> typeDistribution = {};

    for (final doc in snapshot.docs) {
      final fee = Fee.fromMap(doc.id, doc.data());
      totalRevenue += fee.paidAmount;
      totalPending += (fee.amount - fee.paidAmount);
      
      typeDistribution[fee.type.name] = (typeDistribution[fee.type.name] ?? 0) + fee.paidAmount;
    }

    return {
      'totalRevenue': totalRevenue,
      'totalPending': totalPending,
      'typeDistribution': typeDistribution,
    };
  }
}
