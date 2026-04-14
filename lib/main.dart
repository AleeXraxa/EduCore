import 'package:educore/src/app/app.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppServices.instance.init();
  runApp(const EduCoreApp());
}
