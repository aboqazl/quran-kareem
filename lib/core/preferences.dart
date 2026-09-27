import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  static const _lastPage = 'last_page';
  static const _lastAyah = 'last_ayah';
  static const _bookmarks = 'bookmarks';
  static const _notes = 'notes';
  static const _readPages = 'read_pages';
  static const _mastered = 'mastered';
  static const _theme = 'theme_mode';
  static const _fontScale = 'font_scale';
  static const _reciter = 'reciter';
  static const _khatmaDaily = 'khatma_daily';
  static const _reminderEnabled = 'reminder_enabled';
  static const _reminderHour = 'reminder_hour';
  static const _reminderMinute = 'reminder_minute';

  late SharedPreferences _prefs;

  Future<void> init() async => _prefs = await SharedPreferences.getInstance();

  int get lastPage => _prefs.getInt(_lastPage) ?? 1;
  String? get lastAyah => _prefs.getString(_lastAyah);
  Future<void> setLastRead(int page, String key) async {
    await _prefs.setInt(_lastPage, page);
    await _prefs.setString(_lastAyah, key);
  }

  Set<String> get bookmarks => (_prefs.getStringList(_bookmarks) ?? const []).toSet();
  Future<void> setBookmarks(Set<String> values) => _prefs.setStringList(_bookmarks, values.toList()..sort());

  Map<String, String> get notes {
    final raw = _prefs.getString(_notes);
    if (raw == null || raw.isEmpty) return {};
    return Map<String, String>.from(jsonDecode(raw) as Map<String, dynamic>);
  }
  Future<void> setNotes(Map<String, String> values) => _prefs.setString(_notes, jsonEncode(values));

  Set<int> get readPages => (_prefs.getStringList(_readPages) ?? const []).map(int.parse).toSet();
  Future<void> setReadPages(Set<int> pages) => _prefs.setStringList(_readPages, pages.map((e) => '$e').toList()..sort());

  Set<String> get mastered => (_prefs.getStringList(_mastered) ?? const []).toSet();
  Future<void> setMastered(Set<String> keys) => _prefs.setStringList(_mastered, keys.toList()..sort());

  String get themeMode => _prefs.getString(_theme) ?? 'system';
  Future<void> setThemeMode(String value) => _prefs.setString(_theme, value);

  double get fontScale => _prefs.getDouble(_fontScale) ?? 1.0;
  Future<void> setFontScale(double value) => _prefs.setDouble(_fontScale, value);

  String get reciter => _prefs.getString(_reciter) ?? 'Alafasy';
  Future<void> setReciter(String value) => _prefs.setString(_reciter, value);

  int get khatmaDaily => _prefs.getInt(_khatmaDaily) ?? 4;
  Future<void> setKhatmaDaily(int value) => _prefs.setInt(_khatmaDaily, value);

  bool get reminderEnabled => _prefs.getBool(_reminderEnabled) ?? false;
  int get reminderHour => _prefs.getInt(_reminderHour) ?? 20;
  int get reminderMinute => _prefs.getInt(_reminderMinute) ?? 0;
  Future<void> setReminder({required bool enabled, required int hour, required int minute}) async {
    await _prefs.setBool(_reminderEnabled, enabled);
    await _prefs.setInt(_reminderHour, hour);
    await _prefs.setInt(_reminderMinute, minute);
  }
}
