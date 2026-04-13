import 'package:educore/src/core/mvc/base_controller.dart';
import 'package:educore/src/core/services/app_services.dart';

class SplashController extends BaseController {
  Future<void> initializeApp() async {
    await runBusy<void>(() async {
      await AppServices.instance.init();
    });
  }
}
