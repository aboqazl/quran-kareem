import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_scope.dart';
import '../core/models.dart';

Future<void> showAyahActions(BuildContext context, Ayah ayah) async {
  final app = AppScope.of(context);
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            title: Text('سورة ${app.surahName(ayah.surah)} • الآية ${ayah.ayah}'),
            subtitle: Text(ayah.text, maxLines: 3, overflow: TextOverflow.ellipsis, textDirection: TextDirection.rtl),
          ),
          Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
            _Action(icon: Icons.play_arrow, label: 'استماع', onTap: () async { Navigator.pop(sheetContext); await app.audio.playAyah(ayah, app.surahName(ayah.surah)); }),
            _Action(icon: app.bookmarks.contains(ayah.key) ? Icons.bookmark : Icons.bookmark_border, label: 'علامة', onTap: () async { await app.toggleBookmark(ayah.key); if (sheetContext.mounted) Navigator.pop(sheetContext); }),
            _Action(icon: Icons.edit_note, label: 'ملاحظة', onTap: () { Navigator.pop(sheetContext); _editNote(context, ayah); }),
            _Action(icon: Icons.menu_book_outlined, label: 'تفسير', onTap: () async { Navigator.pop(sheetContext); await _openTafsir(ayah); }),
            _Action(icon: Icons.translate, label: 'ترجمة', onTap: () async { Navigator.pop(sheetContext); await _openTranslation(ayah); }),
            _Action(icon: Icons.share_outlined, label: 'مشاركة', onTap: () async { Navigator.pop(sheetContext); await SharePlus.instance.share(ShareParams(text: '${ayah.text}\n[${app.surahName(ayah.surah)}: ${ayah.ayah}]')); }),
            _Action(icon: app.mastered.contains(ayah.key) ? Icons.task_alt : Icons.check_circle_outline, label: 'حفظتها', onTap: () async { await app.toggleMastered(ayah.key); if (sheetContext.mounted) Navigator.pop(sheetContext); }),
          ]),
          if (ayah.sajdah != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text('موضع سجدة • ${ayah.sajdah == 'obligatory' ? 'واجبة بحسب تصنيف البيانات' : 'مستحبة بحسب تصنيف البيانات'}', style: Theme.of(context).textTheme.labelMedium),
            ),
        ]),
      ),
    ),
  );
}

Future<void> _openTafsir(Ayah ayah) async {
  final uri = Uri.parse('https://quran.com/ar/${ayah.surah}%3A${ayah.ayah}/tafsirs/ar-tafsir-muyassar');
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}


Future<void> _openTranslation(Ayah ayah) async {
  final surah = ayah.surah.toString().padLeft(2, '0');
  final uri = Uri.parse('https://legacy.quran.com/$surah/${ayah.ayah}');
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

Future<void> _editNote(BuildContext context, Ayah ayah) async {
  final app = AppScope.of(context);
  final controller = TextEditingController(text: app.notes[ayah.key] ?? '');
  final value = await showDialog<String>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text('ملاحظة على ${ayah.key}'),
      content: TextField(controller: controller, autofocus: true, minLines: 3, maxLines: 7, decoration: const InputDecoration(hintText: 'اكتب ملاحظتك الشخصية…')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('حفظ')),
      ],
    ),
  );
  if (value != null) await app.saveNote(ayah.key, value);
}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: 96,
        child: OutlinedButton(onPressed: onTap, style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8)), child: Column(children: [Icon(icon), const SizedBox(height: 4), Text(label)])),
      );
}
