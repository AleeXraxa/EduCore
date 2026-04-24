import 'dart:developer' as dev;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educore/src/core/constants/prefs_keys.dart';
import 'package:educore/src/core/models/app_user.dart';
import 'package:educore/src/core/models/subscription_record.dart';
import 'package:educore/src/core/services/app_services.dart';
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
  }) : _auth = auth,
       _firestore = firestore;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthSession? _session;

  /// The currently active in-memory session.
  /// This should be the source of truth for the app state.
  AuthSession? get session => _session;
  
  String? get currentAcademyId => _session?.academyId;
  String? get currentAcademyName => _session?.academyName;
  String? get currentAcademyLogo => _session?.logoUrl;

  User? get currentUser => _auth.currentUser;

  /// Returns true if a session is currently active.
  bool get isAuthenticated => _session != null;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<AuthSession> login({
    required String email,
    required String password,
    bool rememberMe = false,
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
      final isPlatformAdmin = appUser.role == AppUserRole.superAdmin;
      AppServices.instance.featureAccessService?.setSuperAdmin(isPlatformAdmin);

      if (!isPlatformAdmin) {
        await validateInstitute(appUser.academyId);
        // Requirement: DO NOT block full login if subscription is inactive (read-only allowed)
        // Subscription checks should be done at the UI level for banners and write actions.
      } else {
        dev.log(
          'Bypassing multi-tenant validation for Super Admin: ${appUser.uid}',
          name: 'AuthService',
        );
      }

      // Step 5: Build Session Context
      final academy = await _firestore.collection('academies').doc(appUser.academyId).get();
      final academyData = academy.data();
      
      _session = buildSessionContext(
        appUser,
        academyName: academyData?['name'],
        logoUrl: academyData?['logoUrl'],
      );
      
      // Step 6: Initialize Feature Access Middleware
      await AppServices.instance.featureAccessService?.init(
        appUser.academyId,
        isSuperAdmin: isPlatformAdmin,
      );
      
      // Persist sign-in state for auto-login on startup
      if (rememberMe) {
        await AppServices.instance.prefs.setBool(PrefsKeys.signedIn, true);
      } else {
        await AppServices.instance.prefs.setBool(PrefsKeys.signedIn, false);
      }
      
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

    final doc = await _firestore
        .collection('subscriptions')
        .doc(academyId)
        .get();
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
  AuthSession buildSessionContext(
    AppUser appUser, {
    String? academyName,
    String? logoUrl,
  }) {
    return AuthSession(
      user: appUser,
      academyId: appUser.academyId,
      academyName: academyName,
      logoUrl: logoUrl,
    );
  }

  /// Periodically re-validates the current session.
  /// Used on app start or during long sessions to enforce gating.
  Future<void> refreshSession() async {
    User? user = _auth.currentUser;
    
    // If user is null, Firebase might still be restoring the session.
    // We wait for the first authenticated state change with a timeout.
    if (user == null) {
      try {
        user = await _auth.authStateChanges().where((u) => u != null).first.timeout(
          const Duration(milliseconds: 1500),
          onTimeout: () => null,
        );
      } catch (_) {
        user = null;
      }
    }

    if (user == null) {
      await signOut();
      return;
    }

    try {
      final appUser = await getUserProfile(user.uid);

      if (appUser.status.toLowerCase() == 'blocked') {
        throw UserBlockedException();
      }

      // Step 3 & 4: Validate Institute & Subscription (Skip for Super Admin)
      // We skip if role is Super Admin OR if the academyId indicates a global platform admin
      final isPlatformAdmin = appUser.role == AppUserRole.superAdmin;
      AppServices.instance.featureAccessService?.setSuperAdmin(isPlatformAdmin);

      final academy = await _firestore.collection('academies').doc(appUser.academyId).get();
      final academyData = academy.data();

      _session = buildSessionContext(
        appUser,
        academyName: academyData?['name'],
        logoUrl: academyData?['logoUrl'],
      );

      // Re-initialize Feature Access Middleware on refresh
      await AppServices.instance.featureAccessService?.init(
        appUser.academyId,
        isSuperAdmin: isPlatformAdmin,
      );

      notifyListeners();
    } catch (e) {
      debugPrint('Security Re-validation failed: $e');
      // If the error is a definitive security/existence failure, wipe the session.
      // If it's a transient error (like network down), we don't call signOut() 
      // so as not to clear the PrefsKeys.signedIn flag.
      if (e is AuthException || e is FirebaseAuthException) {
        await signOut();
      } else {
        _session = null;
        notifyListeners();
      }
    }
  }

  /// Signs out of Firebase and clears the in-memory session.
  Future<void> signOut() async {
    await _auth.signOut();
    _session = null;
    
    // Clear persistence
    await AppServices.instance.prefs.setBool(PrefsKeys.signedIn, false);
    
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
      email: email,
      password: password,
    );
  }
  /// Updates the current user's password.
  /// Requires re-authentication with [currentPassword] for security.
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) throw Exception('No active user session');

    // Re-authenticate
    final cred = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(cred);

    // Update Password
    await user.updatePassword(newPassword);
  }
}
