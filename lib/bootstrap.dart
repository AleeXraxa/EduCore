import 'package:educore/src/core/services/app_services.dart';

Future<void> bootstrap() async {
  await AppServices.instance.init();
}
