import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educore/src/core/models/app_user.dart';

/// [UserRepository] provides a centralized data access layer for user-related
/// operations, enforcing pagination and strict query structuring.
class UserRepository {
  UserRepository(this._firestore);
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('users');

  /// Fetches a paginated batch of users with optional filtering.
  ///
  /// This implements the mandatory pagination system for production-grade scaling.
  Future<List<AppUser>> getUsersBatch({
    int limit = 20,
    DocumentSnapshot? lastDoc,
    String? academyId,
    AppUserRole? role,
    String? status,
  }) async {
    // Initial query with mandatory ordering for pagination
    Query query = _collection.orderBy('createdAt', descending: true);

    // Apply Filters
    if (academyId != null && academyId.isNotEmpty) {
      query = query.where('academyId', isEqualTo: academyId);
    }
    if (role != null) {
      query = query.where('role', isEqualTo: role.value);
    }
    if (status != null && status != 'all') {
      query = query.where('status', isEqualTo: status.toLowerCase());
    }

    // Apply Pagination cursor
    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    final snapshot = await query.limit(limit).get();
    
    return snapshot.docs
        .map((doc) => AppUser.fromDoc(doc as DocumentSnapshot<Map<String, dynamic>>))
        .toList();
  }

  /// Updates a user's profile data.
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _collection.doc(uid).update(data);
  }

  /// Sets the administrative status of a user (e.g., active, blocked).
  Future<void> setStatus(String uid, String status) async {
    await _collection.doc(uid).update({
      'status': status.toLowerCase(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
  
  /// Fetches a single user by UID.
  Future<AppUser?> getUser(String uid) async {
    final doc = await _collection.doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromDoc(doc);
  }
}
