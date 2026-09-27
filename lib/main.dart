import 'package:flutter/material.dart';

import 'app.dart';
import 'core/app_controller.dart';
import 'core/app_scope.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = AppController();
  await controller.init();
  runApp(AppScope(controller: controller, child: const QuranApp()));
}
