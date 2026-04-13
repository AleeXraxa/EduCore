import 'package:educore/src/core/mvc/base_controller.dart';

class StartupController extends BaseController {
  Future<void> continueToApp() async {
    await runBusy<void>(() async {
      await Future<void>.delayed(const Duration(milliseconds: 450));
    });
  }
}
