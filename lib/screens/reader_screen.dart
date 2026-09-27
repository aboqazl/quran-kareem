import 'package:flutter/material.dart';

import '../core/app_scope.dart';
import '../core/models.dart';
import '../widgets/common.dart';
import 'ayah_actions_sheet.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key, required this.initialPage, this.focusMode = false});
  final int initialPage;
  final bool focusMode;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late final PageController pageController;
  late int currentPage;
  var controlsVisible = true;

  @override
  void initState() {
    super.initState();
    currentPage = widget.initialPage.clamp(1, 604).toInt();
    pageController = PageController(initialPage: currentPage - 1);
    if (widget.focusMode) controlsVisible = false;
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final pageAyahs = app.quran.ayahsForPage(currentPage);
    final first = pageAyahs.first;
    return Scaffold(
      appBar: controlsVisible
          ? AppBar(
              title: Text('صفحة ${arabicNumber(currentPage)}'),
              actions: [
                IconButton(
                  tooltip: 'تشغيل الصفحة',
                  onPressed: () => app.audio.playSequence(pageAyahs, app.surahName),
                  icon: const Icon(Icons.play_circle_outline),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'read') await app.markPageRead(currentPage);
                    if (value == 'go') _goToPageDialog(context);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'read', child: Text('تحديد الصفحة كمقروءة')),
                    PopupMenuItem(value: 'go', child: Text('الانتقال إلى صفحة')),
                  ],
                ),
              ],
            )
          : null,
      body: GestureDetector(
        onTap: () => setState(() => controlsVisible = !controlsVisible),
        child: Column(children: [
          if (controlsVisible)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              child: Wrap(spacing: 8, runSpacing: 6, alignment: WrapAlignment.center, children: [
                InfoPill(icon: Icons.menu_book_outlined, label: 'الجزء ${arabicNumber(first.juz)}'),
                InfoPill(icon: Icons.view_agenda_outlined, label: 'الحزب ${arabicNumber(first.hizb)}'),
                InfoPill(icon: Icons.book_outlined, label: 'سورة ${app.surahName(first.surah)}'),
              ]),
            ),
          Expanded(
            child: PageView.builder(
              controller: pageController,
              itemCount: 604,
              onPageChanged: (i) async {
                final page = i + 1;
                setState(() => currentPage = page);
                await app.setLastPosition(page, app.quran.ayahsForPage(page).first.key);
              },
              itemBuilder: (_, i) => _MushafPage(page: i + 1),
            ),
          ),
          if (controlsVisible)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
                child: Row(children: [
                  IconButton(onPressed: currentPage > 1 ? () => pageController.previousPage(duration: const Duration(milliseconds: 220), curve: Curves.easeOut) : null, icon: const Icon(Icons.arrow_forward_ios)),
                  Expanded(
                    child: Slider(
                      value: currentPage.toDouble(), min: 1, max: 604, divisions: 603,
                      label: '${arabicNumber(currentPage)}',
                      onChanged: (v) => pageController.jumpToPage(v.round() - 1),
                    ),
                  ),
                  IconButton(onPressed: currentPage < 604 ? () => pageController.nextPage(duration: const Duration(milliseconds: 220), curve: Curves.easeOut) : null, icon: const Icon(Icons.arrow_back_ios)),
                ]),
              ),
            ),
        ]),
      ),
    );
  }

  Future<void> _goToPageDialog(BuildContext context) async {
    final controller = TextEditingController(text: '$currentPage');
    final page = await showDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('الانتقال إلى صفحة'),
        content: TextField(controller: controller, keyboardType: TextInputType.number, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, int.tryParse(controller.text)), child: const Text('انتقال')),
        ],
      ),
    );
    if (page != null && page >= 1 && page <= 604) pageController.jumpToPage(page - 1);
  }
}

class _MushafPage extends StatelessWidget {
  const _MushafPage({required this.page});
  final int page;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final ayahs = app.quran.ayahsForPage(page);
    final groups = <int, List<Ayah>>{};
    for (final ayah in ayahs) {
      groups.putIfAbsent(ayah.surah, () => []).add(ayah);
    }
    return ColoredBox(
      color: Theme.of(context).brightness == Brightness.light ? const Color(0xFFFFFCF3) : Theme.of(context).scaffoldBackgroundColor,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        children: [
          for (final entry in groups.entries) ...[
            if (entry.value.first.ayah == 1) _SurahHeader(name: app.surahName(entry.key), showBasmala: entry.key != 1 && entry.key != 9),
            Wrap(
              textDirection: TextDirection.rtl,
              alignment: WrapAlignment.start,
              runAlignment: WrapAlignment.start,
              spacing: 2,
              runSpacing: 4,
              children: [for (final ayah in entry.value) _AyahToken(ayah: ayah)],
            ),
            const SizedBox(height: 10),
          ],
          Center(child: Text('— ${arabicNumber(page)} —', style: Theme.of(context).textTheme.labelMedium)),
        ],
      ),
    );
  }
}

class _SurahHeader extends StatelessWidget {
  const _SurahHeader({required this.name, required this.showBasmala});
  final String name;
  final bool showBasmala;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border.symmetric(horizontal: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
            ),
            child: Text('سُورَةُ $name', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          ),
          if (showBasmala) const Padding(padding: EdgeInsets.only(top: 10), child: Text('بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ', textAlign: TextAlign.center, style: TextStyle(fontSize: 20))),
        ]),
      );
}

class _AyahToken extends StatelessWidget {
  const _AyahToken({required this.ayah});
  final Ayah ayah;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final bookmarked = app.bookmarks.contains(ayah.key);
    return Semantics(
      label: 'سورة ${app.surahName(ayah.surah)} الآية ${ayah.ayah}',
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () async {
          await app.markRead(ayah);
          if (context.mounted) await showAyahActions(context, ayah);
        },
        onLongPress: () => app.toggleBookmark(ayah.key),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
          child: Text.rich(
            TextSpan(children: [
              TextSpan(text: '${ayah.text} ', style: TextStyle(fontSize: 23 * app.fontScale, height: 2.0, fontWeight: FontWeight.w500)),
              WidgetSpan(alignment: PlaceholderAlignment.middle, child: _VerseNumber(number: ayah.ayah, active: bookmarked)),
            ]),
            textDirection: TextDirection.rtl,
          ),
        ),
      ),
    );
  }
}

class _VerseNumber extends StatelessWidget {
  const _VerseNumber({required this.number, required this.active});
  final int number;
  final bool active;
  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minWidth: 31, minHeight: 31),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: active ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outlineVariant),
          color: active ? Theme.of(context).colorScheme.primaryContainer : Colors.transparent,
        ),
        child: Text(arabicNumber(number), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      );
}
