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

  /// Creates a new user in both Firebase Auth and Firestore.
  /// This uses a secondary Firebase App to avoid signing out the current user.
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

    // Initialize/Get secondary app for Auth management
    final secondaryAppName = 'user_provision_${DateTime.now().millisecondsSinceEpoch}';
    final secondaryApp = await Firebase.initializeApp(
      name: secondaryAppName,
      options: _primaryApp.options,
    );

    UserCredential? userCred;
    try {
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      
      // 1. Create Auth User
      userCred = await secondaryAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = userCred.user?.uid;
      if (uid == null) {
        throw Exception('Failed to retrieve UID for new user.');
      }

      // 2. Create Firestore Record
      final now = FieldValue.serverTimestamp();
      final userData = {
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
        'createdBy': currentUserRef.uid,
      };

      await _collection.doc(uid).set(userData);

      // 3. Clean up secondary app
      await secondaryApp.delete();

      // Return local model
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
      // Cleanup: if Auth user was created but Firestore failed
      try {
        if (userCred != null) {
          await userCred.user?.delete();
        }
        await secondaryApp.delete();
      } catch (_) {}
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
