import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educore/src/core/models/payment_record.dart';

class AdminPaymentsService {
  AdminPaymentsService({required FirebaseFirestore firestore}) : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col => _firestore.collection('payments');

  Stream<List<PaymentRecord>> watchPayments() {
    // Avoid composite index requirements by not chaining orderBy/where here.
    // Consumers can sort/filter in memory for dashboards.
    return _col.snapshots().map(
          (snap) => snap.docs
              .map(PaymentRecord.fromDoc)
              .toList(growable: false),
        );
  }
}
