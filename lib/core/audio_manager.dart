import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import 'models.dart';

class QuranAudioManager {
  final AudioPlayer player = AudioPlayer();
  String _reciter = 'Alafasy';

  String get reciter => _reciter;
  void setReciter(String id) => _reciter = id;

  String remoteUrl(Ayah ayah) {
    final surah = ayah.surah.toString().padLeft(3, '0');
    final verse = ayah.ayah.toString().padLeft(3, '0');
    return 'https://verses.quran.foundation/$_reciter/mp3/$surah$verse.mp3';
  }

  Future<Directory> _audioRoot() async {
    final root = await getApplicationSupportDirectory();
    final dir = Directory('${root.path}/quran_audio/$_reciter');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<File> _localFile(Ayah ayah) async {
    final root = await _audioRoot();
    return File('${root.path}/${ayah.surah.toString().padLeft(3, '0')}${ayah.ayah.toString().padLeft(3, '0')}.mp3');
  }

  Future<Uri> uriFor(Ayah ayah) async {
    final local = await _localFile(ayah);
    if (await local.exists() && await local.length() > 1024) return local.uri;
    return Uri.parse(remoteUrl(ayah));
  }

  Future<void> playAyah(Ayah ayah, String surahName) async {
    final uri = await uriFor(ayah);
    await player.setAudioSource(AudioSource.uri(
      uri,
      tag: MediaItem(
        id: ayah.key,
        album: 'القرآن الكريم',
        title: 'سورة $surahName • الآية ${ayah.ayah}',
        artist: reciters.firstWhere((r) => r.id == _reciter, orElse: () => reciters.first).nameAr,
      ),
    ));
    await player.play();
  }

  Future<void> playSequence(List<Ayah> ayahs, String Function(int) surahName, {int repeat = 1}) async {
    final sources = <AudioSource>[];
    for (var round = 0; round < repeat; round++) {
      for (final ayah in ayahs) {
        final uri = await uriFor(ayah);
        sources.add(AudioSource.uri(
          uri,
          tag: MediaItem(
            id: '${ayah.key}-$round',
            album: 'القرآن الكريم',
            title: 'سورة ${surahName(ayah.surah)} • الآية ${ayah.ayah}',
            artist: reciters.firstWhere((r) => r.id == _reciter, orElse: () => reciters.first).nameAr,
          ),
        ));
      }
    }
    await player.setAudioSources(sources);
    await player.play();
  }

  Future<void> stop() => player.stop();

  Future<bool> isDownloaded(Ayah ayah) async {
    final file = await _localFile(ayah);
    return file.exists();
  }

  Future<void> downloadAyah(Ayah ayah) async {
    final target = await _localFile(ayah);
    if (await target.exists() && await target.length() > 1024) return;
    final temp = File('${target.path}.part');
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
    try {
      final request = await client.getUrl(Uri.parse(remoteUrl(ayah)));
      final response = await request.close();
      if (response.statusCode != 200) throw HttpException('HTTP ${response.statusCode}');
      final sink = temp.openWrite();
      await response.pipe(sink);
      if (await temp.length() <= 1024) throw const FormatException('ملف صوت غير صالح');
      if (await target.exists()) await target.delete();
      await temp.rename(target.path);
    } finally {
      client.close(force: true);
      if (await temp.exists()) await temp.delete();
    }
  }

  Future<void> downloadAyahs(List<Ayah> ayahs, void Function(int done, int total) progress) async {
    var done = 0;
    for (final ayah in ayahs) {
      await downloadAyah(ayah);
      done++;
      progress(done, ayahs.length);
    }
  }

  Future<int> downloadedCount() async {
    final dir = await _audioRoot();
    if (!await dir.exists()) return 0;
    return dir.list().where((e) => e.path.endsWith('.mp3')).length;
  }

  Future<void> clearDownloads() async {
    final dir = await _audioRoot();
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  Future<void> dispose() => player.dispose();
}
