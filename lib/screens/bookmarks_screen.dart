import 'package:flutter/material.dart';

import '../core/app_scope.dart';
import '../core/models.dart';
import 'reader_screen.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final ayahs = app.bookmarks.map(app.quran.ayahByKey).whereType<Ayah>().toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    return Scaffold(
      appBar: AppBar(title: const Text('علاماتي')),
      body: ayahs.isEmpty
          ? const Center(child: Text('لا توجد علامات بعد. اضغط مطولًا على أي آية لإضافتها.'))
          : ListView.separated(
              itemCount: ayahs.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final a = ayahs[i];
                final note = app.notes[a.key];
                return ListTile(
                  title: Text(a.text, maxLines: 2, overflow: TextOverflow.ellipsis, textDirection: TextDirection.rtl),
                  subtitle: Text('سورة ${app.surahName(a.surah)} • ${a.ayah}${note == null ? '' : '\n$note'}'),
                  isThreeLine: note != null,
                  trailing: IconButton(icon: const Icon(Icons.bookmark_remove_outlined), onPressed: () => app.toggleBookmark(a.key)),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ReaderScreen(initialPage: a.page))),
                );
              },
            ),
    );
  }
}
