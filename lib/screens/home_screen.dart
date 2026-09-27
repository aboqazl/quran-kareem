import 'package:flutter/material.dart';

import '../core/app_scope.dart';
import '../widgets/common.dart';
import 'bookmarks_screen.dart';
import 'reader_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final last = app.lastAyah == null ? null : app.quran.ayahByKey(app.lastAyah!);
    final remaining = (604 - app.readPages.length).clamp(0, 604);
    final days = app.khatmaDaily <= 0 ? 0 : (remaining / app.khatmaDaily).ceil();
    return Scaffold(
      appBar: AppBar(title: const Text('القرآن الكريم')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('آخر قراءة', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 6),
                  Text(
                    last == null ? 'ابدأ رحلتك من الفاتحة' : 'سورة ${app.surahName(last.surah)} • الآية ${arabicNumber(last.ayah)}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ReaderScreen(initialPage: app.lastPage))),
                    icon: const Icon(Icons.auto_stories),
                    label: Text(last == null ? 'ابدأ القراءة' : 'متابعة القراءة'),
                  ),
                ]),
              ),
            ),
            const SectionTitle('ورد الختمة'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  Row(children: [
                    Expanded(child: Text('أنجزت ${arabicNumber(app.readPages.length)} من ${arabicNumber(604)} صفحة')),
                    Text('${(app.completion * 100).toStringAsFixed(0)}٪', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(value: app.completion),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: Text('الهدف اليومي: ${arabicNumber(app.khatmaDaily)} صفحات')),
                    Text(days == 0 ? 'مكتملة' : 'حوالي ${arabicNumber(days)} يوم'),
                  ]),
                ]),
              ),
            ),
            const SectionTitle('اختصارات'),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.8,
              children: [
                _Shortcut(icon: Icons.bookmark_outline, title: 'علاماتي', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BookmarksScreen()))),
                _Shortcut(icon: Icons.menu_book, title: 'الصفحة الأولى', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReaderScreen(initialPage: 1)))),
                _Shortcut(icon: Icons.nights_stay_outlined, title: 'قراءة هادئة', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ReaderScreen(initialPage: app.lastPage, focusMode: true)))),
                _Shortcut(icon: Icons.check_circle_outline, title: 'صفحات مقروءة', onTap: () => _showReadPages(context, app.readPages.length)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showReadPages(BuildContext context, int count) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تقدم القراءة'),
        content: Text('تم تسجيل ${arabicNumber(count)} صفحة كمقروءة على هذا الجهاز.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('حسنًا'))],
      ),
    );
  }
}

class _Shortcut extends StatelessWidget {
  const _Shortcut({required this.icon, required this.title, required this.onTap});
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [Icon(icon), const SizedBox(width: 10), Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)))]),
          ),
        ),
      );
}
