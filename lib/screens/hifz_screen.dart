import 'package:flutter/material.dart';

import '../core/app_scope.dart';
import '../core/models.dart';
import '../widgets/common.dart';

class HifzScreen extends StatefulWidget {
  const HifzScreen({super.key});
  @override
  State<HifzScreen> createState() => _HifzScreenState();
}

class _HifzScreenState extends State<HifzScreen> with AutomaticKeepAliveClientMixin {
  int surah = 1;
  int from = 1;
  int to = 7;
  int repeat = 3;
  @override bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final app = AppScope.of(context);
    final meta = app.quran.surah(surah);
    from = from.clamp(1, meta.ayahCount).toInt();
    to = to.clamp(from, meta.ayahCount).toInt();
    final verses = app.quran.ayahsForSurah(surah).where((a) => a.ayah >= from && a.ayah <= to).toList();
    final mastered = verses.where((a) => app.mastered.contains(a.key)).length;
    return Scaffold(
      appBar: AppBar(title: const Text('مساعد الحفظ')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        InputDecorator(
          decoration: const InputDecoration(labelText: 'السورة', border: OutlineInputBorder()),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              isExpanded: true,
              value: surah,
              items: app.quran.surahs.map((s) => DropdownMenuItem(value: s.number, child: Text('${s.number}. ${s.nameAr}'))).toList(),
              onChanged: (value) => setState(() { surah = value ?? 1; from = 1; to = app.quran.surah(surah).ayahCount.clamp(1, 7).toInt(); }),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _NumberField(label: 'من آية', value: from, max: meta.ayahCount, onChanged: (v) => setState(() { from = v; if (to < from) to = from; }))),
          const SizedBox(width: 10),
          Expanded(child: _NumberField(label: 'إلى آية', value: to, max: meta.ayahCount, onChanged: (v) => setState(() => to = v.clamp(from, meta.ayahCount).toInt()))),
        ]),
        const SizedBox(height: 12),
        SegmentedButton<int>(
          segments: const [ButtonSegment(value: 1, label: Text('مرة')), ButtonSegment(value: 3, label: Text('٣')), ButtonSegment(value: 5, label: Text('٥')), ButtonSegment(value: 10, label: Text('١٠'))],
          selected: {repeat},
          onSelectionChanged: (v) => setState(() => repeat = v.first),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(onPressed: verses.isEmpty ? null : () => app.audio.playSequence(verses, app.surahName, repeat: repeat), icon: const Icon(Icons.repeat), label: const Text('ابدأ التكرار')),
        const SizedBox(height: 18),
        Row(children: [Expanded(child: Text('تقدم هذا النطاق', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))), Text('${arabicNumber(mastered)} / ${arabicNumber(verses.length)}')]),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: verses.isEmpty ? 0 : mastered / verses.length),
        const SizedBox(height: 12),
        ...verses.map((a) => CheckboxListTile(
          value: app.mastered.contains(a.key),
          onChanged: (_) => app.toggleMastered(a.key),
          title: Text(a.text, textDirection: TextDirection.rtl, style: TextStyle(fontSize: 18 * app.fontScale, height: 1.6)),
          subtitle: Text('الآية ${arabicNumber(a.ayah)}'),
          controlAffinity: ListTileControlAffinity.leading,
        )),
      ]),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({required this.label, required this.value, required this.max, required this.onChanged});
  final String label;
  final int value;
  final int max;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => InputDecorator(
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            isExpanded: true,
            value: value,
            items: List.generate(max, (i) => i + 1).map((n) => DropdownMenuItem(value: n, child: Text(arabicNumber(n)))).toList(),
            onChanged: (v) { if (v != null) onChanged(v); },
          ),
        ),
      );
}
