import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educore/src/core/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SeedService {
  SeedService({
    required this.authService,
    required this.firestore,
  });

  final AuthService authService;
  final FirebaseFirestore firestore;

  Future<UserCredential> ensureUser({
    required String email,
    required String password,
  }) async {
    try {
      return await authService.createUserWithEmailPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return authService.signInWithEmailPassword(
          email: email,
          password: password,
        );
      }
      rethrow;
    }
  }

  Future<void> markAsSuperAdmin({
    required String uid,
    required String email,
  }) async {
    final batch = firestore.batch();

    // 1. Unified 'users' collection (Required for login)
    batch.set(
      firestore.collection('users').doc(uid),
      {
        'uid': uid,
        'email': email,
        'emailLower': email.toLowerCase(),
        'name': 'Platform Developer',
        'role': 'super_admin',
        'academyId': 'all',
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    // 2. Legacy 'superAdmins' collection (Optional but kept for compatibility)
    batch.set(
      firestore.collection('superAdmins').doc(uid),
      {
        'uid': uid,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }
}

