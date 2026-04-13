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
    await firestore.collection('superAdmins').doc(uid).set({
      'uid': uid,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

