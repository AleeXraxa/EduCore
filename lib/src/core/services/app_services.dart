import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educore/src/core/services/local_db_service.dart';
import 'package:educore/src/core/services/noop_local_db_service.dart';
import 'package:educore/src/core/services/sqlite_local_db_service.dart';
import 'package:educore/src/core/services/auth_service.dart';
import 'package:educore/src/core/services/noop_prefs_service.dart';
import 'package:educore/src/core/services/prefs_service.dart';
import 'package:educore/src/core/services/shared_prefs_service.dart';
import 'package:educore/src/core/services/seed_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:educore/firebase_options.dart';

class AppServices {
  AppServices._();

  static final AppServices instance = AppServices._();

  late final LocalDbService localDb;
  late final PrefsService prefs;
  FirebaseApp? firebaseApp;
  FirebaseAuth? auth;
  FirebaseFirestore? firestore;
  AuthService? authService;
  SeedService? seedService;
  bool firebaseReady = false;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    // TODO: Switch to `SqliteLocalDbService` once SQLite is integrated.
    // Keep the default as a no-op to avoid breaking first-run development.
    final useSqlite =
        const bool.fromEnvironment('EDUCORE_USE_SQLITE', defaultValue: false);
    localDb = useSqlite ? SqliteLocalDbService() : NoopLocalDbService();
    await localDb.init();

    try {
      prefs = SharedPrefsService();
      await prefs.init();
    } catch (e) {
      prefs = NoopPrefsService();
      if (kDebugMode) {
        // ignore: avoid_print
        print('Prefs init skipped: $e');
      }
    }

    try {
      firebaseApp = await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      auth = FirebaseAuth.instance;
      firestore = FirebaseFirestore.instance;
      authService = AuthService(auth: auth!);
      seedService =
          SeedService(authService: authService!, firestore: firestore!);
      firebaseReady = true;
    } catch (e) {
      // Allow the app to boot during early development or tests even if
      // Firebase plugins are not available in the current runtime.
      if (kDebugMode) {
        // ignore: avoid_print
        print('Firebase init skipped: $e');
      }
    }

    _initialized = true;
  }
}
