import 'package:educore/src/core/mvc/base_controller.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/features/login/seed/super_admin_seed.dart';

class LoginController extends BaseController {
  Future<void> signIn({required String email, required String password}) async {
    await runBusy<void>(() async {
      final authService = AppServices.instance.authService;
      if (authService == null) {
        throw StateError('Firebase not initialized');
      }
      await authService.signInWithEmailPassword(
        email: email,
        password: password,
      );
    });
  }

  Future<void> seedSuperAdmin() async {
    await runBusy<void>(() async {
      final seedService = AppServices.instance.seedService;
      if (seedService == null) {
        throw StateError('Firebase not initialized');
      }
      final credential = await seedService.ensureUser(
        email: SuperAdminSeed.email,
        password: SuperAdminSeed.password,
      );
      final uid = credential.user?.uid;
      if (uid == null) return;
      await seedService.markAsSuperAdmin(uid: uid, email: SuperAdminSeed.email);
    });
  }
}
