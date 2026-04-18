import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educore/src/core/models/app_user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// [UserRepository] provides a centralized data access layer for user-related
/// operations, enforcing pagination and strict query structuring.
class UserRepository {
  UserRepository(
    this._firestore, {
    required FirebaseApp primaryApp,
    required FirebaseAuth primaryAuth,
  })  : _primaryApp = primaryApp,
        _primaryAuth = primaryAuth;

  final FirebaseFirestore _firestore;
  final FirebaseApp _primaryApp;
  final FirebaseAuth _primaryAuth;

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
        .map((doc) =>
            AppUser.fromDoc(doc as DocumentSnapshot<Map<String, dynamic>>))
        .toList();
  }

  /// Internal helper to create an Auth user using a secondary app.
  /// Returns the [UserCredential] and handles secondary app cleanup.
  Future<UserCredential> provisionAuthUser({
    required String email,
    required String password,
  }) async {
    final secondaryAppName = 'user_provision_${DateTime.now().millisecondsSinceEpoch}';
    final secondaryApp = await Firebase.initializeApp(
      name: secondaryAppName,
      options: _primaryApp.options,
    );

    try {
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final cred = await secondaryAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await secondaryApp.delete();
      return cred;
    } catch (e) {
      await secondaryApp.delete();
      rethrow;
    }
  }

  /// Adds a user creation operation to a Firestore [WriteBatch].
  void batchCreateUser({
    required WriteBatch batch,
    required String uid,
    required String name,
    required String email,
    required String phone,
    required AppUserRole role,
    required String academyId,
    required String status,
    required String createdBy,
  }) {
    final now = FieldValue.serverTimestamp();
    final userRef = _collection.doc(uid);
    
    batch.set(userRef, {
      'uid': uid,
      'name': name.trim(),
      'email': email.trim(),
      'emailLower': email.trim().toLowerCase(),
      'phone': phone.trim(),
      'role': role.value,
      'academyId': academyId,
      'status': status.toLowerCase(),
      'createdAt': now,
      'updatedAt': now,
      'createdBy': createdBy,
    });
  }

  /// Creates a new user in both Firebase Auth and Firestore.
  /// This maintains backward compatibility but now uses the internal provisioning logic.
  Future<AppUser> createUser({
    required String name,
    required String email,
    required String password,
    required String phone,
    required AppUserRole role,
    required String academyId,
    required String status,
  }) async {
    final currentUserRef = _primaryAuth.currentUser;
    if (currentUserRef == null) {
      throw StateError('Authentication required to create users.');
    }

    UserCredential? userCred;
    try {
      userCred = await provisionAuthUser(email: email, password: password);
      final uid = userCred.user!.uid;

      final batch = _firestore.batch();
      batchCreateUser(
        batch: batch,
        uid: uid,
        name: name,
        email: email,
        phone: phone,
        role: role,
        academyId: academyId,
        status: status,
        createdBy: currentUserRef.uid,
      );
      await batch.commit();

      return AppUser(
        uid: uid,
        name: name.trim(),
        email: email.trim(),
        phone: phone.trim(),
        role: role,
        academyId: academyId,
        status: status.toLowerCase(),
        lastLoginAt: null,
        createdAt: null,
        createdBy: currentUserRef.uid,
      );
    } catch (e) {
      if (userCred != null) {
        try {
          await userCred.user?.delete();
        } catch (_) {}
      }
      rethrow;
    }
  }

  /// Updates a user's profile data.
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _collection.doc(uid).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
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
