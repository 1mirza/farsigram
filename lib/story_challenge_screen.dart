import 'package:flutter/material.dart';
import 'models_and_state.dart';

class StoryChallengeScreen extends StatefulWidget {
  final String categoryTitle;
  final String jsonFileName;
  final Color accentColor;

  const StoryChallengeScreen({
    super.key,
    required this.categoryTitle,
    required this.jsonFileName,
    required this.accentColor,
  });

  @override
  State<StoryChallengeScreen> createState() => _StoryChallengeScreenState();
}

class _StoryChallengeScreenState extends State<StoryChallengeScreen> {
  List<Map<String, dynamic>> questions = [];
  bool isLoading = true;
  int currentStep = 0;
  int correctAnswersCount = 0;

  String _cleanText(String text) {
    return text.replaceAll(RegExp(r'\]+\]'), '').trim();
  }

  @override
  void initState() {
    super.initState();
    _loadCategoryQuestions();
  }

  Future<void> _loadCategoryQuestions() async {
    final rawData = await AssetDataLoader.loadJsonList(
        'assets/data/${widget.jsonFileName}');
    final mistakes = await LeitnerEngine.getMistakes();

    List<Map<String, dynamic>> normalized = [];

    for (var item in rawData) {
      final lessonId = item['lesson_id'] as int? ?? 1;
      if (lessonId <= GameState.activeLessonLimit.value) {
        String qText = "";
        String correct = "";
        List<String> options = [];
        String hint = "";

        if (item.containsKey('question')) {
          qText = _cleanText(item['question']);
          correct = _cleanText(item['correct']?.toString() ?? "");
          if (item['options'] != null) {
            options = (item['options'] as List)
                .map((e) => _cleanText(e.toString()))
                .toList();
          }
          hint = _cleanText(item['rule_hint'] ?? item['page_source'] ?? "");
        } else if (item.containsKey('word') && item.containsKey('meaning')) {
          qText = "معنی واژه «${_cleanText(item['word'])}» چیست؟";
          correct = _cleanText(item['meaning']);
          if (item['options'] != null) {
            options = (item['options'] as List)
                .map((e) => _cleanText(e.toString()))
                .toList();
          }
          hint = _cleanText(item['example_verse'] ?? item['page_source'] ?? "");
        } else if (item.containsKey('verse_part2_gap')) {
          qText =
              "${_cleanText(item['verse_part1'])}\n${_cleanText(item['verse_part2_gap'])}";
          correct = _cleanText(item['correct']?.toString() ?? "");
          if (item['options'] != null) {
            options = (item['options'] as List)
                .map((e) => _cleanText(e.toString()))
                .toList();
          }
          hint =
              "شاعر: ${_cleanText(item['poet'])} (${_cleanText(item['page_source'])})";
        } else if (item.containsKey('proverb')) {
          qText =
              "مفهوم و پیام ضرب‌المثل «${_cleanText(item['proverb'])}» چیست؟";
          correct = _cleanText(item['meaning']);
          options = [
            _cleanText(item['meaning']),
            "تلاش بیهوده و بدون برنامه‌ریزی",
            "عجله کردن در کارهای بزرگ",
            "بی‌توجهی به دوستان صمیمی"
          ];
          options.shuffle();
          hint = _cleanText(item['source_page'] ?? "");
        } else if (item.containsKey('prompt')) {
          qText = _cleanText(item['prompt']);
          correct = _cleanText(item['correct']?.toString() ?? "");
          if (item['options'] != null) {
            options = (item['options'] as List)
                .map((e) => _cleanText(e.toString()))
                .toList();
          }
          hint = _cleanText(item['rule_hint'] ?? item['explanation'] ?? "");
        }

        if (qText.isNotEmpty && correct.isNotEmpty) {
          normalized.add({
            "id": item['id']?.toString() ?? UniqueKey().toString(),
            "question": qText,
            "correct": correct,
            "options": options.isNotEmpty ? options : [correct],
            "hint": hint,
          });
        }
      }
    }

    normalized.sort((a, b) {
      bool aMistake = mistakes.contains(a['id']);
      bool bMistake = mistakes.contains(b['id']);
      if (aMistake && !bMistake) return -1;
      if (!aMistake && bMistake) return 1;
      return 0;
    });

    normalized.shuffle();
    if (normalized.length > 5) {
      normalized = normalized.take(5).toList();
    }

    setState(() {
      questions = normalized;
      isLoading = false;
    });
  }

  void _onOptionSelected(String option) {
    final currentQ = questions[currentStep];
    final isCorrect = (option.trim() == currentQ['correct'].toString().trim());

    LeitnerEngine.recordAnswer(currentQ['id'], isCorrect);

    if (isCorrect) {
      correctAnswersCount++;
    }

    if (currentStep < questions.length - 1) {
      setState(() {
        currentStep++;
      });
    } else {
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    final earnedCoins = correctAnswersCount * 10;
    GameState.addCoins(earnedCoins);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.stars_rounded, color: Colors.amber, size: 80),
            const SizedBox(height: 10),
            Text("کارنامه چالش ${widget.categoryTitle}",
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            const SizedBox(height: 12),
            Text("امتیاز شما: $correctAnswersCount از ${questions.length}",
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 6),
            Text("پاداش دریافتی: $earnedCoins سکه 🪙",
                style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.accentColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text("تأیید و برگشت به خانه",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (questions.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.menu_book_rounded,
                    size: 60, color: Colors.white54),
                const SizedBox(height: 16),
                const Text(
                  "در محدوده درس‌های انتخابی شما هنوز سؤالی برای این بخش وجود ندارد!\nلطفاً محدوده درس را در صفحه اصلی افزایش دهید[cite: 10].",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white70, fontSize: 15, height: 1.5),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("بازگشت")),
              ],
            ),
          ),
        ),
      );
    }

    final currentQuestion = questions[currentStep];

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: List.generate(questions.length, (index) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: index <= currentStep
                            ? widget.accentColor
                            : Colors.white24,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${widget.categoryTitle} (${currentStep + 1}/${questions.length})",
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            const Spacer(),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                children: [
                  Text(
                    currentQuestion['question'],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1.6),
                  ),
                  if (currentQuestion['hint'].toString().isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      currentQuestion['hint'],
                      textAlign: TextAlign.center,
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ]
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children:
                    (currentQuestion['options'] as List<String>).map((opt) {
                  return SizedBox(
                    width: MediaQuery.of(context).size.width * 0.43,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF0F172A),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () => _onOptionSelected(opt),
                      child: Text(opt,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 35),
          ],
        ),
      ),
    );
  }
}
