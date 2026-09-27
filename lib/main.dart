import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Keep the reading experience close to a physical Mushaf.
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  PaintingBinding.instance.imageCache.maximumSizeBytes = 120 << 20;

  final prefs = await SharedPreferences.getInstance();
  final initialPage = (prefs.getInt('last_mushaf_page') ?? 1).clamp(1, 604);

  runApp(QuranKareemApp(initialPage: initialPage));
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
          seedColor: const Color(0xFF6C5B3E),
          brightness: Brightness.light,
        ),
      ),
      home: MushafReader(initialPage: initialPage),
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
    _currentPage = widget.initialPage;
    _pageController = PageController(initialPage: _currentPage - 1);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _precacheAround(_currentPage);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _assetForPage(int page) =>
      'assets/mushaf_pages/page_${page.toString().padLeft(3, '0')}.webp';

  String _arabicNumber(int value) {
    const western = '0123456789';
    const eastern = '٠١٢٣٤٥٦٧٨٩';
    return value
        .toString()
        .split('')
        .map((c) => eastern[western.indexOf(c)])
        .join();
  }

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

    if (page != null) _goTo(page);
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
                              'تعذر تحميل صفحة ${_arabicNumber(page)}',
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
                  arabicNumber: _arabicNumber,
                  onClose: () => setState(() => _controlsVisible = false),
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
    required this.arabicNumber,
    required this.onClose,
    required this.onPrevious,
    required this.onNext,
    required this.onPickPage,
  });

  final int page;
  final String Function(int) arabicNumber;
  final VoidCallback onClose;
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
                    tooltip: 'إخفاء',
                    icon: Icons.close,
                    onPressed: onClose,
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
