import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educore/src/core/models/subscription_access.dart';
import 'package:educore/src/core/services/plan_limit_exception.dart';

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

  /// Checks if the academy has reached its plan limit for a specific resource.
  /// Throws [PlanLimitExceededException] if limit reached.
  Future<void> checkLimit(String academyId, String limitKey) async {
    // 1. Get Subscription Record
    final subSnap = await _doc(academyId).get();
    if (!subSnap.exists) return; // No subscription record = assume dev or trial unrestricted

    final planId = subSnap.data()?['planId'] ?? '';
    if (planId.isEmpty) return;

    // 2. Get Plan Limits
    final planSnap = await _firestore.collection('plans').doc(planId).get();
    if (!planSnap.exists) return;

    final limits = planSnap.data()?['limits'] as Map<String, dynamic>? ?? {};
    final limit = limits[limitKey] as num? ?? -1;

    if (limit == -1) return; // Unlimited

    // 3. Get Current Count
    int currentCount = 0;
    if (limitKey == 'maxStudents') {
      final snap = await _firestore
          .collection('academies')
          .doc(academyId)
          .collection('students')
          .where('status', isNotEqualTo: 'deleted')
          .count()
          .get();
      currentCount = snap.count ?? 0;
    } else if (limitKey == 'maxStaff') {
      final snap = await _firestore
          .collection('academies')
          .doc(academyId)
          .collection('staff')
          .where('status', isNotEqualTo: 'deleted')
          .count()
          .get();
      currentCount = snap.count ?? 0;
    } else if (limitKey == 'maxClasses') {
      final snap = await _firestore
          .collection('academies')
          .doc(academyId)
          .collection('classes')
          .count()
          .get();
      currentCount = snap.count ?? 0;
    }

    // 4. Validate
    if (currentCount >= limit) {
      throw PlanLimitExceededException(
        'Your plan limit of $limit ${limitKey.replaceFirst('max', '')} reached. Upgrade to continue.',
        limitKey: limitKey,
      );
    }
  }
}

