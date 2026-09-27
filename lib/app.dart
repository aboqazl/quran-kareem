import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/app_scope.dart';
import 'core/app_theme.dart';
import 'screens/root_shell.dart';

class QuranApp extends StatelessWidget {
  const QuranApp({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'القرآن الكريم',
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: controller.materialThemeMode,
      home: controller.initError != null
          ? DataErrorScreen(error: controller.initError!)
          : controller.initialized
              ? const RootShell()
              : const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}

class DataErrorScreen extends StatelessWidget {
  const DataErrorScreen({super.key, required this.error});
  final Object error;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.gpp_bad_outlined, size: 72),
                const SizedBox(height: 18),
                Text('تم إيقاف القراءة لحماية سلامة النص', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Text('$error', textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      );
}
