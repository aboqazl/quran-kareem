import 'package:flutter/material.dart';

import '../core/app_scope.dart';
import '../core/models.dart';
import '../widgets/common.dart';
import 'reader_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with AutomaticKeepAliveClientMixin {
  final controller = TextEditingController();
  List<Ayah> results = const [];
  @override bool get wantKeepAlive => true;

  @override
  void dispose() { controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final app = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('البحث في القرآن')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: SearchBar(
            controller: controller,
            hintText: 'اكتب كلمة أو 2:255…',
            leading: const Icon(Icons.search),
            trailing: [if (controller.text.isNotEmpty) IconButton(onPressed: () { controller.clear(); setState(() => results = const []); }, icon: const Icon(Icons.clear))],
            onChanged: (q) => setState(() => results = q.trim().length < 2 && !q.contains(':') ? const [] : app.quran.search(q)),
          ),
        ),
        if (controller.text.trim().isNotEmpty)
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Align(alignment: Alignment.centerRight, child: Text('النتائج: ${arabicNumber(results.length)}${results.length == 120 ? '+' : ''}'))),
        Expanded(
          child: results.isEmpty
              ? const Center(child: Text('ابحث بكلمة من الآية أو برقم السورة والآية'))
              : ListView.separated(
                  itemCount: results.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final a = results[i];
                    return ListTile(
                      title: Text(a.text, textDirection: TextDirection.rtl, maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 18 * app.fontScale, height: 1.7)),
                      subtitle: Text('سورة ${app.surahName(a.surah)} • ${arabicNumber(a.ayah)} • صفحة ${arabicNumber(a.page)}'),
                      leading: app.bookmarks.contains(a.key) ? const Icon(Icons.bookmark) : null,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ReaderScreen(initialPage: a.page))),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}
