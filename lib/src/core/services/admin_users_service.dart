import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educore/src/core/models/app_user.dart' as core_models;

class AdminUsersService {
  AdminUsersService({required FirebaseFirestore firestore}) : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col => _firestore.collection('users');

  /// Fetches a batch of users with pagination support.
  Future<List<core_models.AppUser>> getUsersBatch({
    int limit = 20,
    DocumentSnapshot? startAfter,
    String? academyId,
  }) async {
    Query<Map<String, dynamic>> query = _col.orderBy('createdAt', descending: true);

    if (academyId != null) {
      query = query.where('academyId', isEqualTo: academyId);
    }

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snap = await query.limit(limit).get();
    return snap.docs.map(core_models.AppUser.fromDoc).toList(growable: false);
  }

  /// Only for small sets or critical real-time.
  Stream<List<core_models.AppUser>> watchUsers() {
    return _col
        .orderBy('createdAt', descending: true)
        .limit(50) // Added limit safety
        .snapshots()
        .map((snap) => snap.docs.map(core_models.AppUser.fromDoc).toList(growable: false));
  }

  Future<void> setStatus(String uid, String status) async {
    await _col.doc(uid).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _col.doc(uid).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
