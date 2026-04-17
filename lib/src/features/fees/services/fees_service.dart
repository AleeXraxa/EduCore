import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educore/src/features/fees/models/fee_record.dart';

class FeesService {
  FeesService(this._firestore);
  final FirebaseFirestore _firestore;

  CollectionReference _feesRef(String academyId) =>
      _firestore.collection('academies').doc(academyId).collection('fees');

  Future<List<FeeRecord>> getFees({
    required String academyId,
    FeeType? type,
    FeeStatus? status,
  }) async {
    Query query = _feesRef(academyId);

    if (type != null) {
      query = query.where('type', isEqualTo: type.name);
    }
    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    final docs = await query.orderBy('createdAt', descending: true).get();
    return docs.docs.map((e) => FeeRecord.fromFirestore(e)).toList();
  }

  Future<void> createFee({
    required String academyId,
    required FeeRecord fee,
  }) async {
    // Business Rule: Admission Fee only once per student
    if (fee.type == FeeType.admission) {
      final existing = await _feesRef(academyId)
          .where('studentId', isEqualTo: fee.studentId)
          .where('type', isEqualTo: FeeType.admission.name)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        throw Exception('Admission fee already exists for this student.');
      }
    }

    // Business Rule: Monthly Fee check (optional: prevent duplicate for same month)
    if (fee.type == FeeType.monthly && fee.month != null) {
      final existing = await _feesRef(academyId)
          .where('studentId', isEqualTo: fee.studentId)
          .where('type', isEqualTo: FeeType.monthly.name)
          .where('month', isEqualTo: fee.month)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
         throw Exception('Monthly fee for ${fee.month} already exists for this student.');
      }
    }

    await _feesRef(academyId).add(fee.toMap());
  }

  Future<void> updateFeeStatus(String academyId, String feeId, FeeStatus status) async {
    final updateData = {
      'status': status.name,
      if (status == FeeStatus.paid) 'paidAt': Timestamp.now(),
    };
    await _feesRef(academyId).doc(feeId).update(updateData);
  }
}
