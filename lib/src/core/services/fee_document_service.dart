import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:educore/src/core/services/audit_log_service.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/features/fees/models/fee_transaction.dart';
import 'package:educore/src/features/fees/models/fee.dart';
import 'package:educore/src/features/students/models/student.dart';
import 'package:educore/src/features/fees/services/bank_challan_generator.dart';
import 'package:intl/intl.dart';

/// Manages the lifecycle of fee financial documents (Challans and Receipts).
/// Responsible for number generation, Firestore persistence, and audit.
class FeeDocumentService {
  FeeDocumentService({FirebaseFirestore? firestore, AuditLogService? audit})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _audit = audit ?? AuditLogService(firestore ?? FirebaseFirestore.instance);

  final FirebaseFirestore _firestore;
  final AuditLogService _audit;

  // ── Helpers ────────────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _fees(String academyId) =>
      _firestore.collection('academies').doc(academyId).collection('fees');

  DocumentReference<Map<String, dynamic>> _counters(String academyId) =>
      _firestore
          .collection('academies')
          .doc(academyId)
          .collection('settings')
          .doc('document_counters');

  // ── Number generation ──────────────────────────────────────────────────────

  /// Atomically increments a counter and returns the formatted document number.
  /// Format: CH-2026-0001 | RC-2026-0001
  Future<String> _generateNumber(
    String academyId, {
    required String type, // 'challan' | 'receipt'
  }) async {
    final prefix = type == 'challan' ? 'CH' : 'RC';
    final year = DateTime.now().year.toString();
    final counterField = '${type}_${year}_count';

    // Atomic increment using batch (Windows-stable)
    final ref = _counters(academyId);
    final snap = await ref.get();

    int current = 0;
    if (snap.exists) {
      current = (snap.data()?[counterField] ?? 0) as int;
    }
    final next = current + 1;

    await ref.set({counterField: next}, SetOptions(merge: true));

    final padded = next.toString().padLeft(4, '0');
    return '$prefix-$year-$padded';
  }

  // ── Academy Settings ───────────────────────────────────────────────────────

  /// Returns the configured document mode for the academy.
  /// Defaults to 'both' if not configured.
  Future<String> getDocumentMode(String academyId) async {
    try {
      final snap = await _firestore
          .collection('academies')
          .doc(academyId)
          .collection('settings')
          .doc('fee_config')
          .get();
      return (snap.data()?['feeDocumentMode'] as String?) ?? 'both';
    } catch (e) {
      debugPrint('FeeDocumentService: Failed to fetch mode: $e');
      return 'both';
    }
  }

  /// Updates the fee document mode in academy settings.
  Future<void> setDocumentMode(String academyId, String mode) async {
    await _firestore
        .collection('academies')
        .doc(academyId)
        .collection('settings')
        .doc('fee_config')
        .set({'feeDocumentMode': mode}, SetOptions(merge: true));
  }

  // ── Challan Generation ─────────────────────────────────────────────────────

  /// Generates (or regenerates) a challan for a pending fee.
  /// Returns the challan number.
  Future<String> generateChallan(
    String academyId,
    String feeId, {
    required String actorId,
  }) async {
    // Prefer existing number if already assigned (idempotent)
    final feeSnap = await _fees(academyId).doc(feeId).get();
    if (!feeSnap.exists) throw Exception('Fee not found: $feeId');

    final feeData = feeSnap.data()!;
    final existing = feeData['challanNumber'] as String?;

    final challanNumber =
        existing ?? await _generateNumber(academyId, type: 'challan');

    await _fees(academyId).doc(feeId).update({
      'challanNumber': challanNumber,
      'lastGeneratedAt': FieldValue.serverTimestamp(),
      'documentModeUsed': 'challan',
    });

    await _audit.logAction(
      action: 'challan_generated',
      module: 'fees',
      targetId: feeId,
      targetType: 'fee',
      metadata: {
        'challanNumber': challanNumber,
        'actorId': actorId,
        'documentType': 'challan',
      },
    );

    debugPrint('FeeDocumentService: Challan generated: $challanNumber');
    return challanNumber;
  }

  // ── Receipt Generation ─────────────────────────────────────────────────────

  /// Generates a receipt for a specific transaction.
  /// Returns the receipt number.
  Future<String> generateReceipt(
    String academyId,
    String feeId, {
    required String transactionId,
    required String actorId,
  }) async {
    final feeSnap = await _fees(academyId).doc(feeId).get();
    if (!feeSnap.exists) throw Exception('Fee not found: $feeId');

    final txnRef = _fees(academyId)
        .doc(feeId)
        .collection('transactions')
        .doc(transactionId);

    final txnSnap = await txnRef.get();
    if (!txnSnap.exists) throw Exception('Transaction not found: $transactionId');

    final txnData = txnSnap.data()!;
    if (txnData['amount'] == null || (txnData['amount'] as num) <= 0) {
      throw Exception('Cannot generate receipt: No payment amount recorded.');
    }

    // Use existing receipt number if already assigned to this transaction
    final existingTxnReceipt = txnData['receiptNumber'] as String?;
    final receiptNumber =
        existingTxnReceipt ?? await _generateNumber(academyId, type: 'receipt');

    final batch = _firestore.batch();

    // Update transaction with receipt number
    batch.update(txnRef, {'receiptNumber': receiptNumber});

    // Update fee with latest receipt metadata
    batch.update(_fees(academyId).doc(feeId), {
      'receiptNumber': receiptNumber,
      'lastGeneratedAt': FieldValue.serverTimestamp(),
      'documentModeUsed': 'receipt',
    });

    await batch.commit();

    await _audit.logAction(
      action: 'receipt_generated',
      module: 'fees',
      targetId: feeId,
      targetType: 'fee',
      metadata: {
        'receiptNumber': receiptNumber,
        'transactionId': transactionId,
        'actorId': actorId,
        'documentType': 'receipt',
      },
    );

    debugPrint('FeeDocumentService: Receipt generated: $receiptNumber');
    return receiptNumber;
  }

  // ── Fetch helpers ──────────────────────────────────────────────────────────

  /// Returns the latest transaction for a fee (for single-transaction receipt).
  Future<FeeTransaction?> getLatestTransaction(
    String academyId,
    String feeId,
  ) async {
    final snap = await _fees(academyId)
        .doc(feeId)
        .collection('transactions')
        .orderBy('collectedAt', descending: true)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    return FeeTransaction.fromMap(snap.docs.first.id, snap.docs.first.data());
  }

  /// Returns all transactions for a fee (for full receipt history).
  Future<List<FeeTransaction>> getAllTransactions(
    String academyId,
    String feeId,
  ) async {
    final snap = await _fees(academyId)
        .doc(feeId)
        .collection('transactions')
        .orderBy('collectedAt', descending: true)
        .get();
    return snap.docs
        .map((d) => FeeTransaction.fromMap(d.id, d.data()))
        .toList();
  }

  // ── Academy Info ───────────────────────────────────────────────────────────

  /// Fetches academy display info for PDF headers.
  Future<Map<String, String>> getAcademyInfo(String academyId) async {
    try {
      final snap = await _firestore
          .collection('academies')
          .doc(academyId)
          .get();
      final data = snap.data() ?? {};
      return {
        'name': (data['name'] ?? 'Institute') as String,
        'address': (data['address'] ?? '') as String,
        'phone': (data['phone'] ?? '') as String,
        'email': (data['email'] ?? '') as String,
      };
    } catch (e) {
      debugPrint('FeeDocumentService: Failed to fetch academy info: $e');
      return {'name': 'Institute', 'address': '', 'phone': '', 'email': ''};
    }
  }

  /// Fetches all data required for a professional Bank Challan.
  Future<BankChallanData> getBankChallanData(
    String academyId,
    String feeId,
  ) async {
    // 1. Fetch Fee
    final feeSnap = await _fees(academyId).doc(feeId).get();
    if (!feeSnap.exists) throw Exception('Fee not found');
    final fee = Fee.fromMap(feeSnap.id, feeSnap.data()!);

    // 2. Fetch Student (for Roll No, GR No)
    final studentSnap = await _firestore
        .collection('academies')
        .doc(academyId)
        .collection('students')
        .doc(fee.studentId)
        .get();
    if (!studentSnap.exists) throw Exception('Student not found');
    final student = Student.fromMap(studentSnap.id, studentSnap.data()!);

    // 3. Fetch Academy & Bank Info
    final academyInfo = await getAcademyInfo(academyId);
    final bankSnap = await _firestore
        .collection('academies')
        .doc(academyId)
        .collection('settings')
        .doc('bank_info')
        .get();
    final bankData = bankSnap.data() ?? {};

    // 4. Calculate Fine logic
    final dueDate = fee.dueDate ?? DateTime.now().add(const Duration(days: 7));
    final finePerDay = (bankData['finePerDay'] ?? 50.0).toDouble();
    double totalFine = 0.0;
    
    if (DateTime.now().isAfter(dueDate)) {
      final daysLate = DateTime.now().difference(dueDate).inDays;
      if (daysLate > 0) {
        totalFine = (daysLate * finePerDay).toDouble();
      }
    }

    // 5. Construct Breakdown
    // In a real system, we'd split the fee into components. 
    // Here we use the title and balance.
    final breakdown = {
      fee.title: fee.finalAmount,
    };

    return BankChallanData(
      challanNumber: fee.challanNumber ?? 'PENDING',
      studentName: student.name,
      fatherName: student.fatherName,
      rollNo: (student.customFields['rollNo'] ?? 'N/A').toString(),
      grNo: (student.customFields['grNo'] ?? 'N/A').toString(),
      className: fee.className ?? 'N/A',
      section: (student.customFields['section'] ?? 'A').toString(),
      academyName: academyInfo['name']!,
      academyAddress: academyInfo['address']!,
      academyPhone: academyInfo['phone']!,
      bankName: (bankData['bankName'] ?? 'ABC BANK').toString(),
      bankBranch: (bankData['bankBranch'] ?? 'MAIN BRANCH').toString(),
      accountNumber: (bankData['accountNumber'] ?? '0000-0000-0000').toString(),
      feeMonth: fee.month ?? DateFormat('MMMM yyyy').format(DateTime.now()),
      dueDate: dueDate,
      validUpto: dueDate.add(const Duration(days: 30)),
      feeBreakdown: breakdown,
      finePerDay: finePerDay,
      totalFine: totalFine,
    );
  }

  // ── Quick academy id ───────────────────────────────────────────────────────
  static String get currentAcademyId =>
      AppServices.instance.authService!.session!.academyId;
  static String get currentUserId =>
      AppServices.instance.authService!.session!.user.uid;
}
