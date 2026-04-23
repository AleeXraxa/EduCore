import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:educore/src/core/services/audit_log_service.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/features/fees/models/fee_transaction.dart';
import 'package:educore/src/features/fees/models/fee.dart';
import 'package:educore/src/features/students/models/student.dart';
import 'package:educore/src/features/fees/services/bank_challan_generator.dart';
import 'package:educore/src/features/fees/models/document_settings.dart';
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

  DocumentReference<Map<String, dynamic>> _settings(String academyId) =>
      _firestore
          .collection('academies')
          .doc(academyId)
          .collection('settings')
          .doc('document_settings');

  // ── Number generation ──────────────────────────────────────────────────────

  /// Atomically increments a counter and returns the formatted document number.
  /// Format: CH-2026-0001 | RC-2026-0001
  Future<String> _generateNumber(
    String academyId, {
    required String type, // 'challan' | 'receipt'
    Transaction? existingTransaction,
  }) async {
    final prefix = type == 'challan' ? 'CH' : 'RC';
    final year = DateTime.now().year.toString();
    final counterField = '${type}_${year}_count';
    final ref = _counters(academyId);

    if (existingTransaction != null) {
      final snap = await existingTransaction.get(ref);
      int current = 0;
      if (snap.exists) {
        current = (snap.data()?[counterField] ?? 0) as int;
      }
      final next = current + 1;
      existingTransaction.set(
        ref,
        {counterField: next},
        SetOptions(merge: true),
      );
      final padded = next.toString().padLeft(4, '0');
      return '$prefix-$year-$padded';
    } else {
      // Fallback for Windows or non-transactional generation
      // We use a simple get-and-set approach which is safer on the Windows C++ SDK
      final snap = await ref.get();
      int current = 0;
      if (snap.exists) {
        current = (snap.data()?[counterField] ?? 0) as int;
      }
      final next = current + 1;
      await ref.set(
        {counterField: next},
        SetOptions(merge: true),
      );
      final padded = next.toString().padLeft(4, '0');
      return '$prefix-$year-$padded';
    }
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
    final feeRef = _fees(academyId).doc(feeId);

    // Sequential flow instead of Transaction for Windows stability
    final feeSnap = await feeRef.get();
    if (!feeSnap.exists) throw Exception('Fee not found: $feeId');

    final feeData = feeSnap.data()!;
    final existing = feeData['challanNumber'] as String?;

    if (existing != null) return existing;

    final challanNumber = await _generateNumber(
      academyId,
      type: 'challan',
    );

    await feeRef.update({
      'challanNumber': challanNumber,
      'lastGeneratedAt': DateTime.now(),
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
    debugPrint('FeeDocumentService: generateReceipt starting for fee $feeId, txn $transactionId');
    final feeRef = _fees(academyId).doc(feeId);
    final txnRef = feeRef.collection('transactions').doc(transactionId);

    // Sequential flow instead of Transaction for Windows stability
    final feeSnap = await feeRef.get();
    if (!feeSnap.exists) throw Exception('Fee not found: $feeId');

    final txnSnap = await txnRef.get();
    if (!txnSnap.exists) throw Exception('Transaction not found: $transactionId');

    final txnData = txnSnap.data()!;
    if (txnData['amount'] == null || (txnData['amount'] as num) <= 0) {
      throw Exception('Cannot generate receipt: No payment amount recorded.');
    }

    final existingTxnReceipt = txnData['receiptNumber'] as String?;
    if (existingTxnReceipt != null) {
      return existingTxnReceipt;
    }

    final receiptNumber = await _generateNumber(
      academyId,
      type: 'receipt',
    );

    // Update records sequentially
    await txnRef.update({'receiptNumber': receiptNumber});
    await feeRef.update({
      'receiptNumber': receiptNumber,
      'lastGeneratedAt': DateTime.now(),
      'documentModeUsed': 'receipt',
    });

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

    // 3. Fetch Academy & Bank Info
    final academyInfo = await getAcademyInfo(academyId);
    final bankSnap = await _firestore
        .collection('academies')
        .doc(academyId)
        .collection('settings')
        .doc('bank_info')
        .get();

    // 4. Student
    final studentData = studentSnap.data() as Map<String, dynamic>;
    final student = Student.fromMap(studentSnap.id, studentData);

    // 5. Bank Info
    final bankData = bankSnap.data() ?? {};

    // 6. Fine & Date Logic
    final finePerDay = (bankData['finePerDay'] ?? 50.0).toDouble();
    final dueDate = fee.dueDate ?? DateTime.now().add(const Duration(days: 10));
    const totalFine = 0.0; // Typically 0 for a new challan

    // 7. Fee Breakdown (Simple for now: one line for the fee title)
    final breakdown = {
      fee.title.isNotEmpty ? fee.title : 'Monthly Fee': fee.finalAmount,
    };

    return BankChallanData(
      challanNumber: fee.challanNumber ?? '---',
      studentName: student.name,
      fatherName: student.fatherName,
      rollNo: (student.rollNo ?? student.customFields['rollNo'] ?? 'N/A').toString(),
      grNo: (student.customFields['grNo'] ?? 'N/A').toString(),
      className: student.className.isNotEmpty ? student.className : (fee.className ?? 'N/A'),
      section: (student.customFields['section'] ?? 'N/A').toString(),
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

  // ── Document Customization ─────────────────────────────────────────────────

  /// Fetches the dynamic document settings for an academy.
  Future<DocumentSettings> getDocumentSettings(String academyId) async {
    try {
      final snap = await _settings(academyId).get();
      if (!snap.exists) return const DocumentSettings();
      return DocumentSettings.fromMap(snap.data()!);
    } catch (e) {
      debugPrint('FeeDocumentService: Failed to fetch settings: $e');
      return const DocumentSettings();
    }
  }

  /// Updates document settings and logs the audit trail.
  Future<void> updateDocumentSettings(
    String academyId,
    DocumentSettings settings, {
    required String actorId,
  }) async {
    final oldSnap = await _settings(academyId).get();
    final oldData = oldSnap.data() ?? {};

    await _settings(academyId).set(settings.toMap());

    await _audit.logAction(
      action: 'document_settings_updated',
      module: 'fees',
      targetId: academyId,
      targetType: 'academy',
      metadata: {
        'actorId': actorId,
        'before': oldData,
        'after': settings.toMap(),
      },
    );
    debugPrint('FeeDocumentService: Settings updated for $academyId');
  }

  // ── Quick academy id ───────────────────────────────────────────────────────
  static String get currentAcademyId =>
      AppServices.instance.authService!.session!.academyId;
  static String get currentUserId =>
      AppServices.instance.authService!.session!.user.uid;
}
