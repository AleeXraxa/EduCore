import 'package:educore/bootstrap.dart';
import 'package:educore/src/app/app.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await bootstrap();
  runApp(const EduCoreApp());
}
