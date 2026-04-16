import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educore/src/core/models/app_user.dart';
import 'package:educore/src/core/models/subscription_record.dart';
import 'package:educore/src/core/services/auth_exceptions.dart';
import 'package:educore/src/core/services/institute_service.dart';
import 'package:educore/src/features/login/models/auth_session.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// [AuthService] implements a HIGH SECURITY multi-tenant authentication system.
///
/// It enforces strict data isolation and validates the account health of both
/// the user and their associated institute (Academy) before granting access.
class AuthService extends ChangeNotifier {
  AuthService({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  })  : _auth = auth,
        _firestore = firestore;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthSession? _session;

  /// The currently active in-memory session.
  /// This should be the source of truth for the app state.
  AuthSession? get session => _session;

  User? get currentUser => _auth.currentUser;

  /// Returns true if a session is currently active.
  bool get isAuthenticated => _session != null;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// Logs in a user and performs a 5-step security validation.
  /// 
  /// 1. Firebase Auth verify credentials
  /// 2. Fetch User Profile & check status
  /// 3. Validate Institute status (if not super admin)
  /// 4. Validate Subscription health (if not super admin)
  /// 5. Build secure session context
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    try {
      // Step 1: Firebase Authentication
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = cred.user?.uid;
      if (uid == null) throw Exception('No UID returned');

      // Step 2: Fetch User Profile
      final appUser = await getUserProfile(uid);

      // Enforce user-level status check
      if (appUser.status.toLowerCase() == 'blocked') {
        await _auth.signOut();
        throw UserBlockedException();
      }

      // Step 3 & 4: Validate Institute & Subscription (Skip for Super Admin)
      if (appUser.role != AppUserRole.superAdmin) {
        await validateInstitute(appUser.academyId);
        await validateSubscription(appUser.academyId);
      }

      // Step 5: Build Session Context
      _session = buildSessionContext(appUser);
      notifyListeners();

      return _session!;
    } catch (e) {
      // Ensure local state is cleared if validation fails after Firebase Auth success
      _session = null;
      notifyListeners();
      rethrow;
    }
  }

  /// Fetches the [AppUser] profile from Firestore.
  /// Throws [UserNotFoundException] if missing.
  Future<AppUser> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) {
      throw UserNotFoundException();
    }
    return AppUser.fromDoc(doc);
  }

  /// Validates that the academy is active.
  /// Throws [InstituteBlockedException] if blocked or missing.
  Future<void> validateInstitute(String academyId) async {
    if (academyId.isEmpty) throw InstituteBlockedException();

    final doc = await _firestore.collection('academies').doc(academyId).get();
    if (!doc.exists) {
      throw InstituteBlockedException();
    }

    final academy = Academy.fromDoc(doc);
    if (academy.status != AcademyStatus.active) {
      throw InstituteBlockedException();
    }
  }

  /// Validates the subscription health for an academy.
  /// Throws [SubscriptionInactiveException] or [SubscriptionExpiredException].
  Future<void> validateSubscription(String academyId) async {
    if (academyId.isEmpty) throw SubscriptionInactiveException();

    final doc =
        await _firestore.collection('subscriptions').doc(academyId).get();
    if (!doc.exists) {
      throw SubscriptionInactiveException();
    }

    final sub = SubscriptionRecord.fromDoc(doc);

    // Enforce active status
    if (sub.status != SubscriptionRecordStatus.active) {
      throw SubscriptionInactiveException();
    }

    // Enforce expiry check
    if (sub.endDate != null && sub.endDate!.isBefore(DateTime.now())) {
      throw SubscriptionExpiredException();
    }
  }

  /// Constructs the in-memory [AuthSession].
  AuthSession buildSessionContext(AppUser appUser) {
    return AuthSession(
      user: appUser,
      academyId: appUser.academyId,
    );
  }

  /// Periodically re-validates the current session.
  /// Used on app start or during long sessions to enforce gating.
  Future<void> refreshSession() async {
    final user = _auth.currentUser;
    if (user == null) {
      _session = null;
      notifyListeners();
      return;
    }

    try {
      final appUser = await getUserProfile(user.uid);

      if (appUser.status.toLowerCase() == 'blocked') {
        throw UserBlockedException();
      }

      if (appUser.role != AppUserRole.superAdmin) {
        await validateInstitute(appUser.academyId);
        await validateSubscription(appUser.academyId);
      }

      _session = buildSessionContext(appUser);
      notifyListeners();
    } catch (e) {
      debugPrint('Security Re-validation failed: $e');
      await signOut();
    }
  }

  /// Signs out of Firebase and clears the in-memory session.
  Future<void> signOut() async {
    await _auth.signOut();
    _session = null;
    notifyListeners();
  }

  // --- Underlying Auth Helpers (Low-Level) ---

  /// Underlying Firebase sign-in helper.
  /// Used by internal services. Prefer [login] for standard application usage.
  Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// Underlying Firebase registration helper.
  Future<UserCredential> createUserWithEmailPassword({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
        email: email, password: password);
  }
}


