import 'package:flutter/material.dart';

import '../core/app_scope.dart';
import '../widgets/common.dart';
import 'reader_screen.dart';

class QuranIndexScreen extends StatefulWidget {
  const QuranIndexScreen({super.key});
  @override
  State<QuranIndexScreen> createState() => _QuranIndexScreenState();
}

class _QuranIndexScreenState extends State<QuranIndexScreen> with AutomaticKeepAliveClientMixin {
  var tab = 0;
  @override bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final app = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('فهرس المصحف')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('السور')),
              ButtonSegment(value: 1, label: Text('الأجزاء')),
              ButtonSegment(value: 2, label: Text('الصفحات')),
            ],
            selected: {tab},
            onSelectionChanged: (v) => setState(() => tab = v.first),
          ),
        ),
        Expanded(
          child: switch (tab) {
            0 => ListView.separated(
                itemCount: app.quran.surahs.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final s = app.quran.surahs[i];
                  return ListTile(
                    leading: CircleAvatar(child: Text(arabicNumber(s.number))),
                    title: Text('سورة ${s.nameAr}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('${arabicNumber(s.ayahCount)} آية • صفحة ${arabicNumber(s.startPage)}'),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ReaderScreen(initialPage: s.startPage))),
                  );
                },
              ),
            1 => ListView.separated(
                itemCount: 30,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final juz = i + 1;
                  final page = app.quran.pageForJuz(juz);
                  return ListTile(
                    leading: CircleAvatar(child: Text(arabicNumber(juz))),
                    title: Text('الجزء ${arabicNumber(juz)}'),
                    subtitle: Text('يبدأ من الصفحة ${arabicNumber(page)}'),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ReaderScreen(initialPage: page))),
                  );
                },
              ),
            _ => GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 1.2),
                itemCount: 604,
                itemBuilder: (_, i) {
                  final page = i + 1;
                  return OutlinedButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ReaderScreen(initialPage: page))), child: Text(arabicNumber(page)));
                },
              ),
          },
        ),
      ]),
    );
  }
}
