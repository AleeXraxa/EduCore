import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educore/src/core/models/app_user.dart' as core_models;

class AdminUsersService {
  AdminUsersService({required FirebaseFirestore firestore}) : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col => _firestore.collection('users');

  Stream<List<core_models.AppUser>> watchUsers() {
    return _col
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(core_models.AppUser.fromDoc).toList(growable: false));
  }

  Stream<List<core_models.AppUser>> watchUsersForAcademy(String academyId) {
    return _col
        .where('academyId', isEqualTo: academyId)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(core_models.AppUser.fromDoc)
              .toList(growable: false),
        );
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
