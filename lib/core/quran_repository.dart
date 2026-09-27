import 'dart:convert';

import 'package:flutter/services.dart';

import 'models.dart';

class QuranRepository {
  List<Ayah> _ayahs = const [];
  List<SurahMeta> _surahs = const [];
  List<Map<String, dynamic>> _pages = const [];
  List<Map<String, dynamic>> _juzs = const [];
  List<Map<String, dynamic>> _hizbs = const [];

  List<Ayah> get ayahs => _ayahs;
  List<SurahMeta> get surahs => _surahs;
  int get pageCount => _pages.length;
  int get juzCount => _juzs.length;
  int get hizbCount => _hizbs.length;

  Future<void> load() async {
    final results = await Future.wait<String>([
      rootBundle.loadString('assets/data/ayahs.json'),
      rootBundle.loadString('assets/data/surahs.json'),
      rootBundle.loadString('assets/data/pages.json'),
      rootBundle.loadString('assets/data/juzs.json'),
      rootBundle.loadString('assets/data/hizbs.json'),
    ]);

    _ayahs = (jsonDecode(results[0]) as List<dynamic>)
        .map((e) => Ayah.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    _surahs = (jsonDecode(results[1]) as List<dynamic>)
        .map((e) => SurahMeta.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    _pages = (jsonDecode(results[2]) as List<dynamic>)
        .cast<Map<String, dynamic>>();
    _juzs = (jsonDecode(results[3]) as List<dynamic>)
        .cast<Map<String, dynamic>>();
    _hizbs = (jsonDecode(results[4]) as List<dynamic>)
        .cast<Map<String, dynamic>>();

    _assertIntegrity();
  }

  void _assertIntegrity() {
    if (_ayahs.length != 6236 || _surahs.length != 114 || _pages.length != 604 || _juzs.length != 30) {
      throw StateError('بيانات القرآن غير مكتملة. تم إيقاف التطبيق لحماية سلامة النص.');
    }
    if (_ayahs.first.key != '1:1' || _ayahs.last.key != '114:6') {
      throw StateError('فشل التحقق من حدود بيانات القرآن.');
    }
    for (final surah in _surahs) {
      final count = _ayahs.where((a) => a.surah == surah.number).length;
      if (count != surah.ayahCount) {
        throw StateError('فشل التحقق من سورة ${surah.nameAr}.');
      }
    }
  }

  Ayah ayahByIndex(int oneBasedIndex) => _ayahs[oneBasedIndex - 1];

  Ayah? ayahByKey(String key) {
    final parts = key.split(':');
    if (parts.length != 2) return null;
    final surah = int.tryParse(parts[0]);
    final ayah = int.tryParse(parts[1]);
    if (surah == null || ayah == null || surah < 1 || surah > 114) return null;
    final meta = _surahs[surah - 1];
    if (ayah < 1 || ayah > meta.ayahCount) return null;
    return _ayahs[meta.startIndex + ayah - 2];
  }

  SurahMeta surah(int number) => _surahs[number - 1];

  List<Ayah> ayahsForPage(int page) {
    final row = _pages[page - 1];
    final start = row['start_index'] as int;
    final end = row['end_index'] as int;
    return _ayahs.sublist(start - 1, end);
  }

  List<Ayah> ayahsForSurah(int surahNumber) {
    final meta = surah(surahNumber);
    return _ayahs.sublist(meta.startIndex - 1, meta.endIndex);
  }

  int pageForJuz(int juz) => ayahByIndex(_juzs[juz - 1]['start_index'] as int).page;
  int pageForHizb(int hizb) => ayahByIndex(_hizbs[hizb - 1]['start_index'] as int).page;

  List<Ayah> search(String rawQuery, {int limit = 120}) {
    final query = normalizeArabic(rawQuery);
    if (query.isEmpty) return const [];
    final out = <Ayah>[];
    for (final ayah in _ayahs) {
      if (ayah.search.contains(query) || ayah.key == rawQuery.trim()) {
        out.add(ayah);
        if (out.length >= limit) break;
      }
    }
    return out;
  }

  static String normalizeArabic(String input) {
    return input
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED]'), '')
        .replaceAll('ٱ', 'ا')
        .replaceAll(RegExp('[إأآ]'), 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي')
        .replaceAll(RegExp(r'[^\u0621-\u063A\u0641-\u064A0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
