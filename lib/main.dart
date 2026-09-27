import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  PaintingBinding.instance.imageCache.maximumSizeBytes = 120 << 20;

  final prefs = await SharedPreferences.getInstance();
  final initialPage = (prefs.getInt('last_mushaf_page') ?? 1).clamp(1, 604);

  runApp(QuranKareemApp(initialPage: initialPage));
}

String arabicNumber(int value) {
  const western = '0123456789';
  const eastern = '٠١٢٣٤٥٦٧٨٩';
  return value
      .toString()
      .split('')
      .map((c) => eastern[western.indexOf(c)])
      .join();
}

class QuranKareemApp extends StatelessWidget {
  const QuranKareemApp({super.key, required this.initialPage});

  final int initialPage;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'القرآن الكريم',
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF5EEDC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5D513B),
          brightness: Brightness.light,
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
        ),
      ),
      home: QuranHome(initialPage: initialPage),
    );
  }
}

class QuranHome extends StatefulWidget {
  const QuranHome({super.key, required this.initialPage});

  final int initialPage;

  @override
  State<QuranHome> createState() => _QuranHomeState();
}

class _QuranHomeState extends State<QuranHome> {
  late int _lastPage;

  @override
  void initState() {
    super.initState();
    _lastPage = widget.initialPage;
  }

  Future<void> _reloadLastPage() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _lastPage = (prefs.getInt('last_mushaf_page') ?? 1).clamp(1, 604);
    });
  }

  Future<void> _openMushaf(int page) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MushafReader(initialPage: page)),
    );
    await _reloadLastPage();
  }

  Future<void> _showPagePicker() async {
    final controller = TextEditingController(text: '$_lastPage');
    final page = await showDialog<int>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('الانتقال إلى صفحة'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              hintText: 'من ١ إلى ٦٠٤',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (value) =>
                Navigator.pop(dialogContext, int.tryParse(value)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, int.tryParse(controller.text)),
              child: const Text('فتح'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();

    if (page != null && page >= 1 && page <= 604) {
      await _openMushaf(page);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'القرآن الكريم',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'مصحف المدينة',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE8DEC4),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFD3C5A5)),
              ),
              padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
              child: Column(
                children: [
                  const Icon(
                    Icons.auto_stories_rounded,
                    size: 48,
                    color: Color(0xFF5D513B),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'وَرَتِّلِ الْقُرْآنَ تَرْتِيلًا',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1.7,
                        ),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'آخر قراءة',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'صفحة ${arabicNumber(_lastPage)}',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () => _openMushaf(_lastPage),
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: Text(
                              _lastPage == 1 ? 'ابدأ القراءة' : 'متابعة القراءة',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'الوصول السريع',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _HomeAction(
                    icon: Icons.first_page_rounded,
                    title: 'أول المصحف',
                    subtitle: 'صفحة ١',
                    onTap: () => _openMushaf(1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _HomeAction(
                    icon: Icons.pin_drop_outlined,
                    title: 'صفحة محددة',
                    subtitle: '١ – ٦٠٤',
                    onTap: _showPagePicker,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Card(
              color: scheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'القراءة داخل التطبيق تعرض صفحات المصحف كاملة كما هي، بدون إعادة تنسيق النص.',
                        style: TextStyle(height: 1.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeAction extends StatelessWidget {
  const _HomeAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
          child: Column(
            children: [
              Icon(icon, size: 30),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MushafReader extends StatefulWidget {
  const MushafReader({super.key, required this.initialPage});

  final int initialPage;

  @override
  State<MushafReader> createState() => _MushafReaderState();
}

class _MushafReaderState extends State<MushafReader> {
  late final PageController _pageController;
  late int _currentPage;
  bool _controlsVisible = false;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage.clamp(1, 604);
    _pageController = PageController(initialPage: _currentPage - 1);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _precacheAround(_currentPage);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  String _assetForPage(int page) =>
      'assets/mushaf_pages/page_${page.toString().padLeft(3, '0')}.webp';

  Future<void> _rememberPage(int page) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_mushaf_page', page);
  }

  void _precacheAround(int page) {
    for (final candidate in [page - 1, page, page + 1]) {
      if (candidate < 1 || candidate > 604) continue;
      precacheImage(AssetImage(_assetForPage(candidate)), context);
    }
  }

  Future<void> _onPageChanged(int index) async {
    final page = index + 1;
    if (!mounted) return;
    setState(() => _currentPage = page);
    _precacheAround(page);
    await _rememberPage(page);
  }

  void _goTo(int page) {
    if (page < 1 || page > 604) return;
    _pageController.animateToPage(
      page - 1,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _showPagePicker() async {
    final controller = TextEditingController(text: '$_currentPage');
    final page = await showDialog<int>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('الانتقال إلى صفحة'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              hintText: 'من ١ إلى ٦٠٤',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (value) =>
                Navigator.pop(dialogContext, int.tryParse(value)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, int.tryParse(controller.text)),
              child: const Text('انتقال'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();

    if (page != null && page >= 1 && page <= 604) _goTo(page);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ColoredBox(
        color: const Color(0xFFF5EEDC),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Directionality(
              textDirection: TextDirection.ltr,
              child: PageView.builder(
                controller: _pageController,
                itemCount: 604,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  final page = index + 1;
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(
                      () => _controlsVisible = !_controlsVisible,
                    ),
                    child: SafeArea(
                      minimum: const EdgeInsets.all(2),
                      child: Center(
                        child: Image.asset(
                          _assetForPage(page),
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                          gaplessPlayback: true,
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Text(
                              'تعذر تحميل صفحة ${arabicNumber(page)}',
                              textDirection: TextDirection.rtl,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            IgnorePointer(
              ignoring: !_controlsVisible,
              child: AnimatedOpacity(
                opacity: _controlsVisible ? 1 : 0,
                duration: const Duration(milliseconds: 150),
                child: _ReaderControls(
                  page: _currentPage,
                  onHome: () => Navigator.of(context).maybePop(),
                  onPrevious:
                      _currentPage > 1 ? () => _goTo(_currentPage - 1) : null,
                  onNext: _currentPage < 604
                      ? () => _goTo(_currentPage + 1)
                      : null,
                  onPickPage: _showPagePicker,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReaderControls extends StatelessWidget {
  const _ReaderControls({
    required this.page,
    required this.onHome,
    required this.onPrevious,
    required this.onNext,
    required this.onPickPage,
  });

  final int page;
  final VoidCallback onHome;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onPickPage;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  _GlassButton(
                    tooltip: 'الرئيسية',
                    icon: Icons.home_rounded,
                    onPressed: onHome,
                  ),
                  const Spacer(),
                  _GlassButton(
                    tooltip: 'الانتقال إلى صفحة',
                    icon: Icons.menu_book_rounded,
                    label: 'صفحة ${arabicNumber(page)}',
                    onPressed: onPickPage,
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 10,
          right: 10,
          bottom: 10,
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _GlassButton(
                  tooltip: 'الصفحة التالية',
                  icon: Icons.chevron_left_rounded,
                  onPressed: onNext,
                ),
                _GlassButton(
                  tooltip: 'الصفحة السابقة',
                  icon: Icons.chevron_right_rounded,
                  onPressed: onPrevious,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.label,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Material(
      color: const Color(0xDD2E2A22),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onPressed,
        child: Tooltip(
          message: tooltip,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (label != null) ...[
                  Text(
                    label!,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      color: enabled ? Colors.white : Colors.white38,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Icon(
                  icon,
                  color: enabled ? Colors.white : Colors.white38,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
