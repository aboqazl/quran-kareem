import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'app.dart';
import 'core/app_controller.dart';
import 'core/app_scope.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.quran.kareem.audio',
    androidNotificationChannelName: 'تلاوة القرآن',
    androidNotificationOngoing: true,
  );
  final controller = AppController();
  await controller.init();
  runApp(AppScope(controller: controller, child: const QuranApp()));
}
