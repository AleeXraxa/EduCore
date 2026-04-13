import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService({required FirebaseAuth auth}) : _auth = auth;

  final FirebaseAuth _auth;

  Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> createUserWithEmailPassword({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(email: email, password: password);
  }
}

