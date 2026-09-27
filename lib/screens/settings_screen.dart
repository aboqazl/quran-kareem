import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_scope.dart';
import '../core/models.dart';
import '../widgets/common.dart';
import 'bookmarks_screen.dart';
import 'downloads_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text('المظهر والقراءة', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Card(child: Column(children: [
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: const Text('المظهر'),
            trailing: DropdownButton<String>(
              value: app.themeMode,
              items: const [DropdownMenuItem(value: 'system', child: Text('تلقائي')), DropdownMenuItem(value: 'light', child: Text('فاتح')), DropdownMenuItem(value: 'dark', child: Text('داكن'))],
              onChanged: (v) { if (v != null) app.setTheme(v); },
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.format_size),
            title: const Text('حجم نص الآيات'),
            subtitle: Slider(value: app.fontScale, min: .8, max: 1.6, divisions: 8, label: '${(app.fontScale * 100).round()}٪', onChanged: app.setFontScale),
          ),
        ])),
        const SizedBox(height: 18),
        Text('التلاوة', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Card(child: Column(children: [
          ListTile(
            leading: const Icon(Icons.record_voice_over_outlined),
            title: const Text('القارئ'),
            subtitle: DropdownButton<String>(
              isExpanded: true,
              value: app.reciter,
              items: reciters.map((r) => DropdownMenuItem(value: r.id, child: Text(r.nameAr))).toList(),
              onChanged: (v) { if (v != null) app.setReciter(v); },
            ),
          ),
          const Divider(height: 1),
          ListTile(leading: const Icon(Icons.download_for_offline_outlined), title: const Text('التلاوات دون إنترنت'), subtitle: const Text('تحميل سورة أو حذف الملفات الصوتية'), trailing: const Icon(Icons.chevron_left), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DownloadsScreen()))),
        ])),
        const SizedBox(height: 18),
        Text('الختمة والتذكير', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Card(child: Column(children: [
          ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: const Text('الهدف اليومي'),
            subtitle: Text('${arabicNumber(app.khatmaDaily)} صفحات يوميًا'),
            trailing: DropdownButton<int>(value: app.khatmaDaily, items: const [1,2,4,5,10,20].map((n) => DropdownMenuItem(value: n, child: Text(arabicNumber(n)))).toList(), onChanged: (v) { if (v != null) app.setKhatmaDaily(v); }),
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('تذكير الورد اليومي'),
            subtitle: Text('الوقت ${app.reminderTime.format(context)}'),
            value: app.reminderEnabled,
            onChanged: (enabled) async {
              var time = app.reminderTime;
              if (enabled) {
                final picked = await showTimePicker(context: context, initialTime: time);
                if (picked == null) return;
                time = picked;
              }
              await app.setReminder(enabled, time);
            },
          ),
          if (app.reminderEnabled)
            ListTile(leading: const Icon(Icons.schedule), title: const Text('تغيير وقت التذكير'), trailing: const Icon(Icons.chevron_left), onTap: () async { final picked = await showTimePicker(context: context, initialTime: app.reminderTime); if (picked != null) await app.setReminder(true, picked); }),
        ])),
        const SizedBox(height: 18),
        Text('البيانات والمصادر', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Card(child: Column(children: [
          ListTile(leading: const Icon(Icons.bookmark_outline), title: const Text('العلامات والملاحظات'), subtitle: Text('${arabicNumber(app.bookmarks.length)} علامة • ${arabicNumber(app.notes.length)} ملاحظة'), trailing: const Icon(Icons.chevron_left), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BookmarksScreen()))),
          const Divider(height: 1),
          ListTile(leading: const Icon(Icons.verified_outlined), title: const Text('سلامة بيانات القرآن'), subtitle: const Text('6236 آية • 114 سورة • 604 صفحات • تحقق داخلي عند التشغيل'), onTap: () => _showIntegrity(context)),
          const Divider(height: 1),
          ListTile(leading: const Icon(Icons.info_outline), title: const Text('عن التطبيق والمصادر'), trailing: const Icon(Icons.chevron_left), onTap: () => _showAbout(context)),
        ])),
      ]),
    );
  }

  void _showIntegrity(BuildContext context) => showDialog<void>(context: context, builder: (_) => AlertDialog(title: const Text('سلامة البيانات'), content: const Text('يحتوي التطبيق على فحص عند التشغيل لعدد الآيات والسور والصفحات وحدود البيانات. كما يتضمن المشروع أداة تحقق مستقلة وملف بصمات SHA-256.'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('حسنًا'))]));

  Future<void> _showAbout(BuildContext context) async {
    await showModalBottomSheet<void>(context: context, showDragHandle: true, isScrollControlled: true, builder: (sheet) => SafeArea(child: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('القرآن الكريم', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      const Text('نسخة 1.0.0 • القراءة الأساسية تعمل دون اتصال. لا يتطلب التطبيق إنشاء حساب.'),
      const SizedBox(height: 12),
      const Text('بيانات النص والبنية مولدة من حزمة quran لـ LaTeX الإصدار 2.3 (2024-09-07) وفق LPPL 1.3c+. التلاوات تُجلب عند الاتصال من Quran Foundation. زر التفسير يفتح التفسير الميسر على Quran.com.'),
      const SizedBox(height: 16),
      Wrap(spacing: 8, children: [
        OutlinedButton(onPressed: () => launchUrl(Uri.parse('https://ctan.org/pkg/quran'), mode: LaunchMode.externalApplication), child: const Text('مصدر النص')),
        OutlinedButton(onPressed: () => launchUrl(Uri.parse('https://quran.foundation/'), mode: LaunchMode.externalApplication), child: const Text('Quran Foundation')),
        OutlinedButton(onPressed: () => launchUrl(Uri.parse('https://quran.com/'), mode: LaunchMode.externalApplication), child: const Text('Quran.com')),
      ]),
    ]))));
  }
}
