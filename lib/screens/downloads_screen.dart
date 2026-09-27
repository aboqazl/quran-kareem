import 'package:flutter/material.dart';

import '../core/app_scope.dart';
import '../widgets/common.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});
  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  int? downloadingSurah;
  int done = 0;
  int total = 0;
  int downloaded = 0;
  Object? error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refresh();
  }

  Future<void> _refresh() async {
    final count = await AppScope.of(context).audio.downloadedCount();
    if (mounted) setState(() => downloaded = count);
  }

  Future<void> _download(int surah) async {
    final app = AppScope.of(context);
    setState(() { downloadingSurah = surah; done = 0; total = app.quran.surah(surah).ayahCount; error = null; });
    try {
      await app.audio.downloadAyahs(app.quran.ayahsForSurah(surah), (d, t) {
        if (mounted) setState(() { done = d; total = t; });
      });
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => downloadingSurah = null);
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('الاستماع دون إنترنت')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('القارئ: ${reciterLabel(app.reciter)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('المقاطع المحملة: ${arabicNumber(downloaded)} آية'),
                if (downloadingSurah != null) ...[
                  const SizedBox(height: 12),
                  LinearProgressIndicator(value: total == 0 ? null : done / total),
                  const SizedBox(height: 6),
                  Text('جاري التحميل ${arabicNumber(done)} / ${arabicNumber(total)}'),
                ],
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text('تعذر إكمال التحميل: $error', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: downloaded == 0 || downloadingSurah != null ? null : () async {
                    final confirm = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('حذف التلاوات المحملة؟'), content: const Text('يمكنك إعادة تحميلها لاحقًا.'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف'))]));
                    if (confirm == true) { await app.audio.clearDownloads(); await _refresh(); }
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('حذف تحميلات القارئ الحالي'),
                ),
              ]),
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: 114,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final s = app.quran.surahs[i];
              final busy = downloadingSurah != null;
              return ListTile(
                leading: CircleAvatar(child: Text(arabicNumber(s.number))),
                title: Text('سورة ${s.nameAr}'),
                subtitle: Text('${arabicNumber(s.ayahCount)} آية'),
                trailing: downloadingSurah == s.number ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2)) : IconButton(onPressed: busy ? null : () => _download(s.number), icon: const Icon(Icons.download_outlined)),
              );
            },
          ),
        ),
      ]),
    );
  }

  String reciterLabel(String id) => id == 'Alafasy' ? 'مشاري العفاسي' : 'عبدالباسط عبدالصمد - مجود';
}
