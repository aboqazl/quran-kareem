import 'package:flutter_test/flutter_test.dart';
import 'package:quran_kareem/core/quran_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Quran dataset passes structural integrity checks', () async {
    final repo = QuranRepository();
    await repo.load();
    expect(repo.ayahs.length, 6236);
    expect(repo.surahs.length, 114);
    expect(repo.pageCount, 604);
    expect(repo.juzCount, 30);
    expect(repo.hizbCount, 60);
    expect(repo.ayahs.first.key, '1:1');
    expect(repo.ayahs.last.key, '114:6');
  });

  test('Arabic normalization supports unvocalized search', () {
    expect(QuranRepository.normalizeArabic('إِنَّا أَعْطَيْنَاكَ'), 'انا اعطيناك');
  });
}
