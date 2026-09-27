class Ayah {
  const Ayah({
    required this.index,
    required this.surah,
    required this.ayah,
    required this.key,
    required this.text,
    required this.simple,
    required this.page,
    required this.juz,
    required this.hizb,
    required this.rub,
    required this.search,
    this.sajdah,
  });

  final int index;
  final int surah;
  final int ayah;
  final String key;
  final String text;
  final String simple;
  final int page;
  final int juz;
  final int hizb;
  final int rub;
  final String search;
  final String? sajdah;

  factory Ayah.fromJson(Map<String, dynamic> json) => Ayah(
        index: json['index'] as int,
        surah: json['surah'] as int,
        ayah: json['ayah'] as int,
        key: json['key'] as String,
        text: json['text'] as String,
        simple: json['simple'] as String,
        page: json['page'] as int,
        juz: json['juz'] as int,
        hizb: json['hizb'] as int,
        rub: json['rub'] as int,
        search: json['search'] as String,
        sajdah: json['sajdah'] as String?,
      );
}

class SurahMeta {
  const SurahMeta({
    required this.number,
    required this.nameAr,
    required this.ayahCount,
    required this.startIndex,
    required this.endIndex,
    required this.startPage,
    required this.endPage,
  });

  final int number;
  final String nameAr;
  final int ayahCount;
  final int startIndex;
  final int endIndex;
  final int startPage;
  final int endPage;

  factory SurahMeta.fromJson(Map<String, dynamic> json) => SurahMeta(
        number: json['number'] as int,
        nameAr: json['name_ar'] as String,
        ayahCount: json['ayah_count'] as int,
        startIndex: json['start_index'] as int,
        endIndex: json['end_index'] as int,
        startPage: json['start_page'] as int,
        endPage: json['end_page'] as int,
      );
}

class QuranRange {
  const QuranRange({
    required this.number,
    required this.startIndex,
    required this.endIndex,
    required this.startKey,
    required this.endKey,
  });

  final int number;
  final int startIndex;
  final int endIndex;
  final String startKey;
  final String endKey;
}

class Reciter {
  const Reciter(this.id, this.nameAr);
  final String id;
  final String nameAr;
}

const reciters = <Reciter>[
  Reciter('Alafasy', 'مشاري العفاسي'),
  Reciter('AbdulBaset/Mujawwad', 'عبدالباسط عبدالصمد - مجود'),
];
