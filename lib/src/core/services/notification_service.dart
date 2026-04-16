import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educore/src/features/notifications/models/app_notification.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  NotificationService({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _firestore.collection('notifications');

  /// Send a broadcast notification to all institutes
  Future<void> sendBroadcastNotification({
    required String title,
    required String message,
  }) async {
    final uid = _auth.currentUser?.uid ?? 'system';
    final doc = _notifications.doc();
    
    final notification = AppNotification(
      id: doc.id,
      title: title,
      message: message,
      type: NotificationType.broadcast,
      targetType: NotificationTargetType.all,
      status: NotificationStatus.sent,
      createdAt: DateTime.now(),
      createdBy: uid,
    );

    await doc.set(notification.toFirestore());
  }

  /// Send a targeted notification to a specific institute
  Future<void> sendTargetedNotification({
    required String academyId,
    required String academyName,
    required String title,
    required String message,
  }) async {
    final uid = _auth.currentUser?.uid ?? 'system';
    final doc = _notifications.doc();
    
    final notification = AppNotification(
      id: doc.id,
      title: title,
      message: message,
      type: NotificationType.targeted,
      targetType: NotificationTargetType.single,
      academyId: academyId,
      academyName: academyName,
      status: NotificationStatus.sent,
      createdAt: DateTime.now(),
      createdBy: uid,
    );

    await doc.set(notification.toFirestore());
  }

  /// Automated job to send expiry reminders
  /// Normally this would be a Cloud Function, but providing a hook for manually triggering
  Future<void> sendExpiryReminders() async {
    final now = DateTime.now();
    final reminderTarget = now.add(const Duration(days: 3));
    
    // We fetch active subscriptions whose expiry date is near
    // In a real system, we'd also check if a reminder was already sent
    final subscriptions = await _firestore
        .collection('subscriptions')
        .where('status', isEqualTo: 'active')
        .get();

    for (final doc in subscriptions.docs) {
      final data = doc.data();
      final expiryDate = (data['expiryDate'] as Timestamp).toDate();
      
      // If expiring in exactly 3 days (or between 2 and 3)
      final diff = expiryDate.difference(now).inDays;
      if (diff == 3) {
        final instituteId = data['instituteId'] as String;
        final instituteName = data['instituteName'] as String;
        
        await sendTargetedNotification(
          academyId: instituteId,
          academyName: instituteName,
          title: 'Subscription Expiring Soon',
          message: 'Your subscription will expire in 3 days. Please renew to avoid service interruption.',
        );
      }
    }
  }

  /// Fetch all notifications for the super admin panel (paginated/ordered)
  Stream<List<AppNotification>> watchNotifications() {
    return _notifications
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppNotification.fromFirestore(doc))
            .toList());
  }

  Future<void> deleteNotification(String id) async {
    await _notifications.doc(id).delete();
  }
}
