import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';

// =============================================================================
// 1. DATA & UTILS
// =============================================================================

class GameUtils {
  static String cleanAnswer(dynamic answer) {
    if (answer == null) return "";
    return answer
        .toString()
        .replaceAll(' ', '')
        .replaceAll('\u200c', '')
        .replaceAll('آ', 'ا')
        .trim();
  }

  static String safeString(dynamic value, [String fallback = ""]) {
    return value?.toString() ?? fallback;
  }
}

class AssetLoader {
  static Future<List<dynamic>> loadJson(String path) async {
    try {
      final String response = await rootBundle.loadString(path);
      final data = json.decode(response);
      return (data is List) ? data : [];
    } catch (e) {
      debugPrint("Error loading asset $path: $e");
      return [];
    }
  }
}

class GameState {
  static ValueNotifier<int> coins = ValueNotifier<int>(500);
  static ValueNotifier<String> userName = ValueNotifier<String>("");
  static Map<String, int> levels = {};

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    coins.value = prefs.getInt('coins') ?? 500;
    userName.value = prefs.getString('userName') ?? "";

    levels['grid'] = prefs.getInt('level_grid') ?? 0;
    levels['spelling'] = prefs.getInt('level_spelling') ?? 0;
    levels['poetry'] = prefs.getInt('level_poetry') ?? 0;
  }

  static Future<void> updateCoins(int value) async {
    coins.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('coins', value);
  }

  static Future<void> setUserName(String name) async {
    userName.value = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', name);
  }

  static Future<void> saveLevel(String type, int levelIndex) async {
    levels[type] = levelIndex;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('level_$type', levelIndex);
  }

  static int getLevel(String type) {
    return levels[type] ?? 0;
  }
}

// =============================================================================
// 2. THEME
// =============================================================================

class AppTheme {
  static const Color background = Color(0xFFF5F5F5);
  static const Color textDark = Color(0xFF212121);
  static const Color textGrey = Color(0xFF757575);
  static const String fontName = 'Vazir';
}

class PersianPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF6200EA).withOpacity(0.03)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = const Color(0xFF6200EA).withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    double step = 80;
    for (double y = 0; y < size.height; y += step) {
      for (double x = 0; x < size.width; x += step) {
        _drawShamseh(
            canvas, x + step / 2, y + step / 2, step / 3, paint, strokePaint);
      }
    }
  }

  void _drawShamseh(
      Canvas canvas, double cx, double cy, double r, Paint fill, Paint stroke) {
    Path path = Path();
    for (int i = 0; i < 8; i++) {
      double angle = (i * 45) * (math.pi / 180);
      double x = cx + r * math.cos(angle);
      double y = cy + r * math.sin(angle);
      if (i == 0)
        path.moveTo(x, y);
      else
        path.lineTo(x, y);

      double angleInner = ((i * 45) + 22.5) * (math.pi / 180);
      double xIn = cx + (r * 0.6) * math.cos(angleInner);
      double yIn = cy + (r * 0.6) * math.sin(angleInner);
      path.lineTo(xIn, yIn);
    }
    path.close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GlassBox extends StatelessWidget {
  final Widget child;
  final double opacity;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final double borderRadius;
  final Color color;
  final BoxBorder? border;
  final List<BoxShadow>? shadows;

  const GlassBox({
    super.key,
    required this.child,
    this.opacity = 0.7,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.borderRadius = 24,
    this.color = Colors.white,
    this.border,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: color.withOpacity(opacity),
              borderRadius: BorderRadius.circular(borderRadius),
              border: border ??
                  Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
              boxShadow: shadows ??
                  [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      spreadRadius: 0,
                      offset: const Offset(0, 8),
                    )
                  ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// 3. MAIN APP
// =============================================================================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GameState.init();
  runApp(const ShahrzadGameApp());
}

class ShahrzadGameApp extends StatelessWidget {
  const ShahrzadGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'بازی شهرزاد',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fa', 'IR')],
      locale: const Locale('fa', 'IR'),
      theme: ThemeData(
        fontFamily: AppTheme.fontName,
        useMaterial3: true,
        scaffoldBackgroundColor: AppTheme.background,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6200EA)),
      ),
      home: const SplashScreen(),
    );
  }
}

// =============================================================================
// 4. COMMON WIDGETS
// =============================================================================

class GameBackground extends StatelessWidget {
  final Widget child;
  const GameBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: AppTheme.background),
        Positioned.fill(child: CustomPaint(painter: PersianPatternPainter())),
        SafeArea(child: child),
      ],
    );
  }
}

class SafeLottie extends StatelessWidget {
  final String url;
  final double height;
  final IconData fallbackIcon;

  const SafeLottie(
      {super.key,
      required this.url,
      this.height = 200,
      this.fallbackIcon = Icons.image});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Lottie.network(
        url,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            alignment: Alignment.center,
            child: Icon(fallbackIcon,
                size: height / 2, color: Colors.purple.withOpacity(0.3)),
          );
        },
        frameBuilder: (context, child, composition) {
          if (composition == null) {
            return Center(
                child: CircularProgressIndicator(
                    color: Colors.purple.withOpacity(0.3)));
          }
          return child;
        },
      ),
    );
  }
}

// =============================================================================
// 5. SCREENS
// =============================================================================

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        if (GameState.userName.value.isEmpty) {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const NameInputScreen()));
        } else {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const MainMenuScreen()));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GlassBox(
                borderRadius: 100,
                padding: const EdgeInsets.all(30),
                child: const Icon(Icons.auto_stories_rounded,
                    size: 80, color: Color(0xFF6200EA)),
              ),
              const SizedBox(height: 40),
              const Text(
                "بازی با کلمات فارسی ششم",
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF6200EA)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6200EA).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "منبع: کتاب فارسی و نگارش ششم دبستان",
                  style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textDark,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NameInputScreen extends StatefulWidget {
  const NameInputScreen({super.key});
  @override
  State<NameInputScreen> createState() => _NameInputScreenState();
}

class _NameInputScreenState extends State<NameInputScreen> {
  final TextEditingController _controller = TextEditingController();

  void _submit() {
    if (_controller.text.trim().isNotEmpty) {
      GameState.setUserName(_controller.text.trim());
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const MainMenuScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("لطفاً نام خود را وارد کنید")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: GlassBox(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("سلام قهرمان!",
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark)),
                  const SizedBox(height: 10),
                  const Text("برای شروع ماجراجویی، نامت را بگو:",
                      style: TextStyle(fontSize: 16, color: AppTheme.textGrey)),
                  const SizedBox(height: 30),
                  TextField(
                    controller: _controller,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[50],
                      hintText: "نام شما",
                      contentPadding: const EdgeInsets.symmetric(vertical: 18),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF6200EA), Color(0xFF7E57C2)]),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                            color: const Color(0xFF6200EA).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5))
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                      ),
                      child: const Text("شروع بازی",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});
  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  // لیست بازی‌ها با رنگ‌های گرادینت
  final List<Map<String, dynamic>> menuItems = [
    {
      "title": "معنی کلمات",
      "icon": Icons.menu_book_rounded,
      "gradient": [const Color(0xFFFF9800), const Color(0xFFFF5722)], // نارنجی
      "path": "assets/data/meanings.json",
      "type": "grid"
    },
    {
      "title": "متضاد",
      "icon": Icons.swap_horiz_rounded,
      "gradient": [
        const Color(0xFF00BFA5),
        const Color(0xFF009688)
      ], // سبز کله غازی
      "path": "assets/data/antonyms.json",
      "type": "grid"
    },
    {
      "title": "هم‌خانواده",
      "icon": Icons.hub_rounded,
      "gradient": [const Color(0xFF2196F3), const Color(0xFF1976D2)], // آبی
      "path": "assets/data/synonyms.json",
      "type": "grid"
    },
    {
      "title": "املای کلمات",
      "icon": Icons.spellcheck_rounded,
      "gradient": [const Color(0xFF9C27B0), const Color(0xFF7B1FA2)], // بنفش
      "path": "assets/data/spelling.json",
      "type": "spelling"
    },
    {
      "title": "حفظ شعر",
      "icon": Icons.mic_rounded,
      "gradient": [const Color(0xFFE91E63), const Color(0xFFC2185B)], // سرخابی
      "path": "assets/data/poetry.json",
      "type": "poetry"
    },
    // دکمه تنظیمات به عنوان آیتم آخر
    {
      "title": "تنظیمات",
      "icon": Icons.settings_rounded,
      "gradient": [const Color(0xFF607D8B), const Color(0xFF455A64)], // خاکستری
      "type": "settings"
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFirstTime();
    });
  }

  void _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    bool seen = prefs.getBool('seen_tutorial') ?? false;
    if (!seen) {
      _showTutorial();
      await prefs.setBool('seen_tutorial', true);
    }
  }

  void _showTutorial() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("راهنمای بازی",
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          "به بازی شهرزاد خوش اومدی!\n\n"
          "🔹 از منو یکی از بازی‌ها رو انتخاب کن.\n"
          "🔹 با پاسخ درست سکه بگیر.\n"
          "🔹 اگر جایی گیر کردی از راهنما استفاده کن.\n"
          "🔹 مراحل به صورت خودکار ذخیره میشن.",
          style: TextStyle(height: 1.8),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("متوجه شدم"))
        ],
      ),
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            const Icon(Icons.info_outline_rounded,
                size: 60, color: Color(0xFF6200EA)),
            const SizedBox(height: 15),
            const Text("درباره اپلیکیشن",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text(
              "این برنامه جهت تقویت مهارت‌های فارسی دانش‌آموزان پایه ششم طراحی شده است.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textGrey, height: 1.5),
            ),
            const Divider(height: 40),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("طراح و توسعه‌دهنده: ",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text("حمیدرضا علی میرزائی",
                    style: TextStyle(
                        color: Color(0xFF6200EA), fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            const Text("لطفاً نظرات خود را برای بهبود برنامه ارسال کنید.",
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameBackground(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("منوی اصلی",
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark)),
                      ValueListenableBuilder<String>(
                        valueListenable: GameState.userName,
                        builder: (context, name, _) => Text(
                            "سلام $name، خوش اومدی!",
                            style: const TextStyle(
                                fontSize: 14, color: AppTheme.textGrey)),
                      ),
                    ],
                  ),
                  ValueListenableBuilder<int>(
                    valueListenable: GameState.coins,
                    builder: (context, val, _) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFFFD740)),
                          boxShadow: [
                            BoxShadow(
                                color: const Color(0xFFFFD740).withOpacity(0.2),
                                blurRadius: 10)
                          ],
                        ),
                        child: Row(children: [
                          Text("$val",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber,
                                  fontSize: 16)),
                          const SizedBox(width: 4),
                          const Icon(Icons.monetization_on,
                              color: Colors.amber, size: 20),
                        ]),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Grid List
            Expanded(
              child: GridView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 0.9,
                ),
                itemCount: menuItems.length,
                itemBuilder: (context, index) {
                  final item = menuItems[index];
                  return GestureDetector(
                    onTap: () {
                      if (item['type'] == 'settings') {
                        _showSettings();
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GameScreen(
                              title: item['title'],
                              jsonPath: item['path'],
                              type: item['type'],
                              gradient: item['gradient'],
                            ),
                          ),
                        );
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: item['gradient'],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                              color: (item['gradient'][0] as Color)
                                  .withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 6)),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(item['icon'],
                                size: 36, color: Colors.white),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            item['title'],
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 6. GAME CONTAINER
// =============================================================================

class GameScreen extends StatefulWidget {
  final String title, jsonPath, type;
  final List<Color> gradient;

  const GameScreen(
      {super.key,
      required this.title,
      required this.jsonPath,
      required this.type,
      required this.gradient});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  List<dynamic> questions = [];
  bool isLoading = true;
  int currentLevelIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await AssetLoader.loadJson(widget.jsonPath);
    final savedIndex = GameState.getLevel(widget.type);

    if (mounted) {
      setState(() {
        questions = data;
        currentLevelIndex = (savedIndex < data.length) ? savedIndex : 0;
        isLoading = false;
      });
    }
  }

  void _onLevelComplete() {
    setState(() {
      if (currentLevelIndex < questions.length - 1) {
        currentLevelIndex++;
        GameState.saveLevel(widget.type, currentLevelIndex);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: Colors.black),
        body: const Center(child: Text("داده‌ای یافت نشد!")),
      );
    }

    if (currentLevelIndex >= questions.length) {
      return Scaffold(
        appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: Colors.black),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.emoji_events, size: 80, color: Colors.amber),
              const SizedBox(height: 20),
              const Text("تبریک! تمام مراحل تمام شد.",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 20),
              ElevatedButton(
                  onPressed: () {
                    GameState.saveLevel(widget.type, 0);
                    setState(() => currentLevelIndex = 0);
                  },
                  child: const Text("شروع مجدد"))
            ],
          ),
        ),
      );
    }

    Widget engine;
    if (widget.type == 'grid') {
      engine = GridGameEngine(
          key: ValueKey(currentLevelIndex),
          question: questions[currentLevelIndex],
          color: widget.gradient[0],
          onNext: _onLevelComplete);
    } else if (widget.type == 'poetry') {
      engine = GridGameEngine(
          key: ValueKey(currentLevelIndex),
          question: questions[currentLevelIndex],
          color: widget.gradient[0],
          isPoetry: true,
          onNext: _onLevelComplete);
    } else if (widget.type == 'spelling') {
      engine = SpellingGameEngine(
          key: ValueKey(currentLevelIndex),
          question: questions[currentLevelIndex],
          color: widget.gradient[0],
          onNext: _onLevelComplete);
    } else {
      engine = const Center(child: Text("بازی نامعتبر"));
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(widget.title,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: AppTheme.textDark)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_ios, color: AppTheme.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: ValueListenableBuilder<int>(
              valueListenable: GameState.coins,
              builder: (context, val, _) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.amber),
                ),
                child: Row(children: [
                  Text("$val",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.amber)),
                  const SizedBox(width: 5),
                  const Icon(Icons.monetization_on,
                      size: 16, color: Colors.amber)
                ]),
              ),
            ),
          )
        ],
      ),
      body: GameBackground(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Expanded(child: engine),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 7. GAME ENGINE: GRID
// =============================================================================

class GridGameEngine extends StatefulWidget {
  final dynamic question;
  final Color color;
  final bool isPoetry;
  final VoidCallback onNext;

  const GridGameEngine(
      {super.key,
      required this.question,
      required this.color,
      required this.onNext,
      this.isPoetry = false});

  @override
  State<GridGameEngine> createState() => _GridGameEngineState();
}

class _GridGameEngineState extends State<GridGameEngine> {
  String userAnswer = "";

  void _keyPress(String char) {
    final cleanTarget = GameUtils.cleanAnswer(widget.question['answer']);
    if (userAnswer.length < cleanTarget.length) {
      setState(() => userAnswer += char);

      if (userAnswer.length == cleanTarget.length) {
        if (userAnswer == cleanTarget) {
          _showFeedback(true, cleanTarget);
        } else {
          _showFeedback(false, cleanTarget);
          Future.delayed(const Duration(milliseconds: 1000),
              () => setState(() => userAnswer = ""));
        }
      }
    }
  }

  void _showFeedback(bool isCorrect, String correctAnswer) {
    if (isCorrect) GameState.updateCoins(GameState.coins.value + 20);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isCorrect ? Icons.check_circle : Icons.error,
                size: 80, color: isCorrect ? Colors.green : Colors.red),
            const SizedBox(height: 10),
            Text(isCorrect ? "آفرین! درست بود" : "اشتباه بود!",
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isCorrect ? Colors.green : Colors.red)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10)),
              child: Column(
                children: [
                  const Text("پاسخ صحیح:",
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 5),
                  Text(correctAnswer,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: isCorrect ? Colors.green : Colors.orange,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              onPressed: () {
                Navigator.pop(context);
                if (isCorrect) {
                  widget.onNext();
                }
              },
              child: Text(isCorrect ? "مرحله بعد" : "تلاش مجدد"),
            )
          ],
        ),
      ),
    );
  }

  void _useHint(String type) {
    final cleanTarget = GameUtils.cleanAnswer(widget.question['answer']);
    int cost = (type == 'full')
        ? 30
        : (type == 'half')
            ? 15
            : 5;

    if (GameState.coins.value < cost) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("سکه کافی نیست!"), backgroundColor: Colors.red));
      return;
    }

    GameState.updateCoins(GameState.coins.value - cost);

    setState(() {
      if (type == 'single' && userAnswer.length < cleanTarget.length) {
        userAnswer += cleanTarget[userAnswer.length];
      } else if (type == 'half') {
        int len = (cleanTarget.length / 2).ceil();
        if (userAnswer.length < len) userAnswer = cleanTarget.substring(0, len);
      } else if (type == 'full') {
        userAnswer = cleanTarget;
      }
      if (userAnswer == cleanTarget) _showFeedback(true, cleanTarget);
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final cleanTarget = GameUtils.cleanAnswer(q['answer']);
    final questionText = GameUtils.safeString(q['question']);

    return Column(
      children: [
        GlassBox(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          color: Colors.white,
          child: Column(
            children: [
              Text(widget.isPoetry ? "شعر را کامل کنید" : "سوال",
                  style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 10),
              Text(questionText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark)),
            ],
          ),
        ),
        const Spacer(),
        Directionality(
          textDirection: TextDirection.rtl,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: List.generate(cleanTarget.length, (i) {
              String char = i < userAnswer.length ? userAnswer[i] : "";
              return Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                    color: char.isNotEmpty
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: widget.color, width: 2),
                    boxShadow: [
                      BoxShadow(
                          color: widget.color.withOpacity(0.2),
                          blurRadius: 5,
                          offset: const Offset(0, 3))
                    ]),
                alignment: Alignment.center,
                child: Text(char,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: widget.color)),
              );
            }),
          ),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _hintBtn("۱ حرف", "5", () => _useHint('single')),
              _hintBtn("نصف", "15", () => _useHint('half')),
              _hintBtn("کل جواب", "30", () => _useHint('full')),
            ],
          ),
        ),
        const SizedBox(height: 20),
        GlassBox(
          margin: EdgeInsets.zero,
          borderRadius: 0,
          opacity: 0.98,
          color: const Color(0xFFF9F9F9),
          child: Column(children: [
            _keyRow(
                ['ض', 'ص', 'ث', 'ق', 'ف', 'غ', 'ع', 'ه', 'خ', 'ح', 'ج', 'چ']),
            _keyRow(['ش', 'س', 'ی', 'ب', 'ل', 'ا', 'ت', 'ن', 'م', 'ک', 'گ']),
            _keyRow(['ظ', 'ط', 'ز', 'ر', 'ذ', 'د', 'پ', 'و', 'آ'],
                hasBack: true),
          ]),
        ),
      ],
    );
  }

  Widget _hintBtn(String title, String cost, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Container(
          width: 55,
          height: 55,
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [Colors.white, widget.color.withOpacity(0.1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)
              ],
              border: Border.all(color: Colors.white, width: 2)),
          child: Icon(Icons.lightbulb_rounded, color: widget.color),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Text(cost,
                style: TextStyle(
                    color: widget.color, fontWeight: FontWeight.bold)),
            Icon(Icons.monetization_on, size: 14, color: widget.color)
          ],
        )
      ]),
    );
  }

  Widget _keyRow(List<String> chars, {bool hasBack = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ...chars.map((c) => Expanded(
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: _keyBtn(c, () => _keyPress(c))))),
          if (hasBack)
            Expanded(
                flex: 2,
                child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: _keyBtn(null, () {
                      if (userAnswer.isNotEmpty)
                        setState(() => userAnswer =
                            userAnswer.substring(0, userAnswer.length - 1));
                    }, isBack: true))),
        ],
      ),
    );
  }

  Widget _keyBtn(String? text, VoidCallback onTap, {bool isBack = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
            color: isBack ? Colors.red.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  offset: const Offset(0, 3),
                  blurRadius: 0)
            ],
            border: Border.all(color: Colors.grey.shade200)),
        alignment: Alignment.center,
        child: isBack
            ? const Icon(Icons.backspace_rounded, color: Colors.red)
            : Text(text!,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark)),
      ),
    );
  }
}

// =============================================================================
// 8. GAME ENGINE: SPELLING
// =============================================================================

class SpellingGameEngine extends StatefulWidget {
  final dynamic question;
  final Color color;
  final VoidCallback onNext;

  const SpellingGameEngine(
      {super.key,
      required this.question,
      required this.color,
      required this.onNext});

  @override
  State<SpellingGameEngine> createState() => _SpellingGameEngineState();
}

class _SpellingGameEngineState extends State<SpellingGameEngine> {
  void _check(String selected) {
    final q = widget.question;
    bool isCorrect = (selected == q['correct']);

    String p1 = GameUtils.safeString(q['word_part1']);
    String p2 = GameUtils.safeString(q['word_part2']);
    // نمایش درست کلمه در بازخورد
    String fullWord = "$p1${q['correct']}$p2";

    _showFeedback(isCorrect, fullWord);
  }

  void _showFeedback(bool isCorrect, String fullWord) {
    if (isCorrect) GameState.updateCoins(GameState.coins.value + 20);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isCorrect ? Icons.check_circle : Icons.cancel,
                size: 80, color: isCorrect ? Colors.green : Colors.red),
            const SizedBox(height: 10),
            Text(isCorrect ? "درست بود!" : "غلط بود!",
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isCorrect ? Colors.green : Colors.red)),
            const SizedBox(height: 15),
            const Text("املای صحیح:",
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text(fullWord,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark)),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: isCorrect ? Colors.green : Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              onPressed: () {
                Navigator.pop(context);
                if (isCorrect) widget.onNext();
              },
              child: Text(isCorrect ? "بعدی" : "تلاش مجدد"),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final p1 = GameUtils.safeString(q['word_part1']);
    final p2 = GameUtils.safeString(q['word_part2']);
    final meaning = GameUtils.safeString(q['meaning']);
    final options = (q['options'] as List).map((e) => e.toString()).toList();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GlassBox(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            color: Colors.white,
            child: Column(
              children: [
                const Text("کلمه را کامل کنید",
                    style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 30),
                // نمایش درست کلمه (راست چین)
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // بخش اول (سمت راست)
                      if (p1.isNotEmpty)
                        Text(p1,
                            style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark)),
                      // جای خالی
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: widget.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: widget.color, width: 2),
                        ),
                        alignment: Alignment.center,
                        child: const Text("؟",
                            style: TextStyle(fontSize: 28, color: Colors.grey)),
                      ),
                      // بخش دوم (سمت چپ)
                      if (p2.isNotEmpty)
                        Text(p2,
                            style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text("معنی: $meaning",
                      style: TextStyle(
                          color: widget.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 50),
          // گزینه‌ها
          Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: options.map((opt) {
              return GestureDetector(
                onTap: () => _check(opt),
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [Colors.white, widget.color.withOpacity(0.1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5))
                      ],
                      border: Border.all(color: Colors.white, width: 2)),
                  alignment: Alignment.center,
                  child: Text(opt,
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark)),
                ),
              );
            }).toList(),
          )
        ],
      ),
    );
  }
}
