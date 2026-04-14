import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educore/src/core/models/subscription_access.dart';

class SubscriptionService {
  SubscriptionService({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _doc(String academyId) {
    return _firestore.collection('subscriptions').doc(academyId);
  }

  Stream<SubscriptionAccess?> watchSubscription(String academyId) {
    return _doc(academyId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return SubscriptionAccess.fromDoc(snap);
    });
  }
}

