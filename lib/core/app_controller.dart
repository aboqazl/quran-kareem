import 'dart:async';

import 'package:flutter/material.dart';

import 'audio_manager.dart';
import 'models.dart';
import 'notification_service.dart';
import 'preferences.dart';
import 'quran_repository.dart';

class AppController extends ChangeNotifier {
  final QuranRepository quran = QuranRepository();
  final AppPreferences prefs = AppPreferences();
  final QuranAudioManager audio = QuranAudioManager();
  final ReminderService reminders = ReminderService();

  bool initialized = false;
  Object? initError;
  late Set<String> bookmarks;
  late Map<String, String> notes;
  late Set<int> readPages;
  late Set<String> mastered;
  late String themeMode;
  late double fontScale;
  late String reciter;
  late int khatmaDaily;
  late bool reminderEnabled;
  late TimeOfDay reminderTime;

  Future<void> init() async {
    try {
      await Future.wait([quran.load(), prefs.init()]);
      bookmarks = prefs.bookmarks;
      notes = prefs.notes;
      readPages = prefs.readPages;
      mastered = prefs.mastered;
      themeMode = prefs.themeMode;
      fontScale = prefs.fontScale;
      reciter = prefs.reciter;
      khatmaDaily = prefs.khatmaDaily;
      reminderEnabled = prefs.reminderEnabled;
      reminderTime = TimeOfDay(hour: prefs.reminderHour, minute: prefs.reminderMinute);
      audio.setReciter(reciter);
      try {
        await reminders.init();
      } catch (_) {
        // Reminders are optional and must never block app startup.
      }
      initialized = true;
    } catch (e) {
      initError = e;
    }
    notifyListeners();
  }

  ThemeMode get materialThemeMode => switch (themeMode) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  int get lastPage => prefs.lastPage.clamp(1, 604).toInt();
  String? get lastAyah => prefs.lastAyah;
  double get completion => readPages.length / 604.0;

  String surahName(int number) => quran.surah(number).nameAr;

  Future<void> markRead(Ayah ayah) async {
    await prefs.setLastRead(ayah.page, ayah.key);
    if (readPages.add(ayah.page)) await prefs.setReadPages(readPages);
    notifyListeners();
  }

  Future<void> setLastPosition(int page, String key) async {
    await prefs.setLastRead(page, key);
    notifyListeners();
  }

  Future<void> markPageRead(int page, {String? lastKey}) async {
    final ayahs = quran.ayahsForPage(page);
    final key = lastKey ?? ayahs.last.key;
    await prefs.setLastRead(page, key);
    if (readPages.add(page)) await prefs.setReadPages(readPages);
    notifyListeners();
  }

  Future<void> toggleBookmark(String key) async {
    if (!bookmarks.add(key)) bookmarks.remove(key);
    await prefs.setBookmarks(bookmarks);
    notifyListeners();
  }

  Future<void> saveNote(String key, String value) async {
    if (value.trim().isEmpty) {
      notes.remove(key);
    } else {
      notes[key] = value.trim();
    }
    await prefs.setNotes(notes);
    notifyListeners();
  }

  Future<void> toggleMastered(String key) async {
    if (!mastered.add(key)) mastered.remove(key);
    await prefs.setMastered(mastered);
    notifyListeners();
  }

  Future<void> setTheme(String mode) async {
    themeMode = mode;
    await prefs.setThemeMode(mode);
    notifyListeners();
  }

  Future<void> setFontScale(double value) async {
    fontScale = value.clamp(.8, 1.6).toDouble();
    await prefs.setFontScale(fontScale);
    notifyListeners();
  }

  Future<void> setReciter(String value) async {
    reciter = value;
    audio.setReciter(value);
    await prefs.setReciter(value);
    notifyListeners();
  }

  Future<void> setKhatmaDaily(int pages) async {
    khatmaDaily = pages.clamp(1, 40).toInt();
    await prefs.setKhatmaDaily(khatmaDaily);
    notifyListeners();
  }

  Future<void> setReminder(bool enabled, TimeOfDay time) async {
    reminderTime = time;
    reminderEnabled = enabled;
    try {
      if (enabled) {
        await reminders.init();
        final allowed = await reminders.requestPermission();
        if (!allowed) {
          reminderEnabled = false;
        } else {
          await reminders.scheduleDaily(time.hour, time.minute);
        }
      } else {
        await reminders.cancelDaily();
      }
    } catch (_) {
      reminderEnabled = false;
    }
    await prefs.setReminder(
      enabled: reminderEnabled,
      hour: time.hour,
      minute: time.minute,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(audio.dispose());
    super.dispose();
  }
}
