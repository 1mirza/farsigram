import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_theme.dart';
import '../core/data_loader.dart';
import '../core/game_state.dart';
import '../data/story_categories.dart';

const int kCount = 7; // تعداد سؤال هر بازی
const int kSeconds = 25; // زمان هر سؤال
const int kFiftyCost = 20; // هزینه‌ی ۵۰٪۵۰
const int kHintCost = 15; // هزینه‌ی راهنما

/// بازی استوری‌مانند با تایمر، کمبو، کمک‌خریدنی و جعبه‌ی لایتنر
class StoryChallengeScreen extends StatefulWidget {
  final String categoryId;
  final String title;
  final String fileName;
  final Color color;
  final IconData icon;
  final bool reviewMistakes;
  final bool doubleReward;

  const StoryChallengeScreen({
    super.key,
    required this.categoryId,
    required this.title,
    required this.fileName,
    required this.color,
    required this.icon,
    this.reviewMistakes = false,
    this.doubleReward = false,
  });

  @override
  State<StoryChallengeScreen> createState() => _StoryChallengeScreenState();
}

class _StoryChallengeScreenState extends State<StoryChallengeScreen> {
  bool _loading = true;
  List<QuizQuestion> _questions = [];
  int _index = 0;
  int _score = 0;
  int _combo = 0;
  int _bestCombo = 0;
  int _left = kSeconds;
  Timer? _timer;
  String? _picked;
  bool _answered = false;
  bool _showHint = false;
  Set<String> _hidden = {};
  bool _finished = false;
  int _coinsEarned = 0;
  int _xpEarned = 0;

  QuizQuestion get _q => _questions[_index];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final limit = GameState.activeLessonLimit.value;
    final all = <QuizQuestion>[];

    if (widget.reviewMistakes) {
      final mistakes = LeitnerEngine.getMistakes().toSet();
      for (final category in kStoryCategories) {
        final raw = await AssetDataLoader.loadJsonList(category.file);
        all.addAll(QuestionFactory.build(raw, lessonLimit: limit)
            .where((q) => mistakes.contains(q.id)));
      }
    } else {
      final raw = await AssetDataLoader.loadJsonList(widget.fileName);
      all.addAll(QuestionFactory.build(raw, lessonLimit: limit));
    }

    all.shuffle(Random());
    if (!mounted) return;
    setState(() {
      _questions = all.take(kCount).toList();
      _loading = false;
    });
    if (_questions.isNotEmpty) _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _left = kSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_left <= 1) {
        timer.cancel();
        _answer(null, timeout: true);
      } else {
        setState(() => _left--);
      }
    });
  }

  Future<void> _answer(String? option, {bool timeout = false}) async {
    if (_answered) return;
    _timer?.cancel();

    final correct = !timeout && option == _q.correct;
    setState(() {
      _answered = true;
      _picked = option;
      if (correct) {
        _score++;
        _combo++;
        _bestCombo = max(_bestCombo, _combo);
      } else {
        _combo = 0;
      }
    });

    correct ? HapticFeedback.lightImpact() : HapticFeedback.heavyImpact();
    await GameState.registerAnswer(correct);
    await LeitnerEngine.recordAnswer(_q.id, correct);

    await Future<void>.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;

    if (_index + 1 >= _questions.length) {
      await _finish();
    } else {
      setState(() {
        _index++;
        _answered = false;
        _picked = null;
        _showHint = false;
        _hidden = {};
      });
      _startTimer();
    }
  }

  Future<void> _finish() async {
    final multiplier = widget.doubleReward ? 2 : 1;
    final coins = (_score * 8 + _bestCombo * 4) * multiplier;
    final xp = (_score * 12 + _bestCombo * 3) * multiplier;

    await GameState.finishChallenge(
      categoryId: widget.categoryId,
      score: _score,
      total: _questions.length,
      coinsEarned: coins,
      xpEarned: xp,
    );

    if (!mounted) return;
    setState(() {
      _finished = true;
      _coinsEarned = coins;
      _xpEarned = xp;
    });
  }

  Future<void> _useFifty() async {
    if (_answered || _hidden.isNotEmpty) return;
    if (!await GameState.spendCoins(kFiftyCost)) {
      _notEnough();
      return;
    }
    final wrong = _q.options.where((o) => o != _q.correct).toList()..shuffle();
    setState(() => _hidden = wrong.take(max(0, _q.options.length - 2)).toSet());
  }

  Future<void> _useHint() async {
    if (_answered || _showHint) return;
    if (_q.hint.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('برای این سؤال راهنمایی ثبت نشده')),
      );
      return;
    }
    if (!await GameState.spendCoins(kHintCost)) {
      _notEnough();
      return;
    }
    setState(() => _showHint = true);
  }

  void _notEnough() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('سکه‌ات کافی نیست 🪙 اول چند بازی دیگر ببر!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppTheme.night,
        body: Center(child: CircularProgressIndicator(color: widget.color)),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(28),
            child: Text(
              'برای این بخش سؤالی قابل ساخت نبود.\n(شاید فایل JSON آن در assets/data نیست)',
              textAlign: TextAlign.center,
              style: TextStyle(height: 2, color: AppTheme.textMuted),
            ),
          ),
        ),
      );
    }

    if (_finished) return _resultView();

    return Scaffold(
      backgroundColor: AppTheme.night,
      body: SafeArea(
        child: Column(
          children: [
            // نوارهای پیشرفت به سبک استوری
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: Row(
                children: List.generate(_questions.length, (i) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: i < _index
                            ? Colors.white
                            : i == _index
                                ? Colors.white70
                                : Colors.white24,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // هدر
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(widget.icon, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 14.5),
                    ),
                  ),
                  if (widget.doubleReward)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('×۲ جایزه',
                          style: TextStyle(
                              color: AppTheme.amber,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900)),
                    ),
                  const SizedBox(width: 6),
                  _TimerRing(left: _left, total: kSeconds),
                ],
              ),
            ),

            // کمبو و امتیاز
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Text(
                      'سؤال ${faNum(_index + 1)} از ${faNum(_questions.length)}',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 11.5)),
                  const Spacer(),
                  if (_combo >= 2)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: AppTheme.goldGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('🔥 کمبو ${faNum(_combo)}',
                          style: const TextStyle(
                              color: Color(0xFF3F2D00),
                              fontSize: 11,
                              fontWeight: FontWeight.w900)),
                    ),
                ],
              ),
            ),

            // متن سؤال
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        children: [
                          Text(_kindLabel(_q.kind),
                              style: TextStyle(
                                  color: widget.color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900)),
                          const SizedBox(height: 12),
                          Text(
                            _q.prompt,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: _q.kind == QuizKind.letter ? 25 : 16.5,
                              height: 2.1,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (_q.subtitle.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(_q.subtitle,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 12.5,
                                    height: 2)),
                          ],
                          if (_showHint && _q.hint.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.all(11),
                              decoration: BoxDecoration(
                                color: AppTheme.amber.withOpacity(0.16),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text('💡 ${_q.hint}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      height: 1.9)),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    ..._q.options.map(_optionTile),
                  ],
                ),
              ),
            ),

            // کمک‌ها
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Row(
                children: [
                  Expanded(
                    child: _HelperButton(
                      icon: Icons.content_cut_rounded,
                      label: '۵۰٪۵۰ (${faNum(kFiftyCost)})',
                      onTap: _useFifty,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _HelperButton(
                      icon: Icons.lightbulb_rounded,
                      label: 'راهنما (${faNum(kHintCost)})',
                      onTap: _useHint,
                    ),
                  ),
                  const SizedBox(width: 10),
                  ValueListenableBuilder<int>(
                    valueListenable: GameState.coins,
                    builder: (context, coins, _) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.amber.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text('🪙 ${faGroup(coins)}',
                          style: const TextStyle(
                              color: AppTheme.amber,
                              fontWeight: FontWeight.w900,
                              fontSize: 12.5)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _kindLabel(QuizKind kind) {
    switch (kind) {
      case QuizKind.meaning:
        return 'معنی واژه';
      case QuizKind.verse:
        return 'تکمیل بیت';
      case QuizKind.letter:
        return 'حرف گم‌شده';
      case QuizKind.correction:
        return 'غلط‌یابی املا';
      case QuizKind.choice:
        return 'چهارگزینه‌ای';
    }
  }

  Widget _optionTile(String option) {
    if (_hidden.contains(option)) {
      return const SizedBox.shrink();
    }

    final isCorrect = option == _q.correct;
    final isPicked = option == _picked;

    Color background = Colors.white.withOpacity(0.07);
    Color borderColor = Colors.white24;
    Widget? trailing;

    if (_answered) {
      if (isCorrect) {
        background = AppTheme.green.withOpacity(0.25);
        borderColor = AppTheme.green;
        trailing = const Icon(Icons.check_circle_rounded,
            color: AppTheme.green, size: 20);
      } else if (isPicked) {
        background = AppTheme.red.withOpacity(0.22);
        borderColor = AppTheme.red;
        trailing =
            const Icon(Icons.cancel_rounded, color: AppTheme.red, size: 20);
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: _answered ? null : () => _answer(option),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor, width: 1.4),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(option,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 14, height: 1.9)),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }

  Widget _resultView() {
    final total = _questions.length;
    final ratio = total == 0 ? 0.0 : _score / total;
    final stars =
        ratio >= 0.9 ? 3 : (ratio >= 0.6 ? 2 : (ratio >= 0.3 ? 1 : 0));

    return Scaffold(
      backgroundColor: AppTheme.night,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 168,
                height: 168,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 168,
                      height: 168,
                      child: CircularProgressIndicator(
                        value: ratio,
                        strokeWidth: 12,
                        backgroundColor: Colors.white12,
                        color: widget.color,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${faNum(_score)}/${faNum(total)}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.w900)),
                        Text('${faNum((ratio * 100).round())}٪ درست',
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Icon(
                      i < stars
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: i < stars ? AppTheme.amber : Colors.white24,
                      size: 38,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                ratio >= 0.9
                    ? 'عالی بود! استاد شدی 🎉'
                    : ratio >= 0.6
                        ? 'خوب بود، می‌توانی بهتر شوی 💪'
                        : 'اشکالی ندارد، دوباره تمرین کن 🌱',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _ResultStat(
                        emoji: '🪙',
                        label: 'سکه',
                        value: '+${faNum(_coinsEarned)}'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ResultStat(
                        emoji: '⭐',
                        label: 'امتیاز',
                        value: '+${faNum(_xpEarned)}'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ResultStat(
                        emoji: '🔥',
                        label: 'بهترین کمبو',
                        value: faNum(_bestCombo)),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _loading = true;
                      _finished = false;
                      _index = 0;
                      _score = 0;
                      _combo = 0;
                      _bestCombo = 0;
                      _answered = false;
                      _picked = null;
                      _showHint = false;
                      _hidden = {};
                    });
                    _load();
                  },
                  icon: const Icon(Icons.replay_rounded, size: 19),
                  label: const Text('بازی دوباره',
                      style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                  ),
                  child: const Text('بازگشت به فید'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimerRing extends StatelessWidget {
  final int left;
  final int total;
  const _TimerRing({required this.left, required this.total});

  @override
  Widget build(BuildContext context) {
    final ratio = left / total;
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              value: ratio,
              strokeWidth: 3.4,
              backgroundColor: Colors.white12,
              color: ratio > 0.4
                  ? AppTheme.green
                  : (ratio > 0.2 ? AppTheme.amber : AppTheme.red),
            ),
          ),
          Text(faNum(left),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _HelperButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _HelperButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(color: Colors.white, fontSize: 11.5)),
            ],
          ),
        ),
      );
}

class _ResultStat extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  const _ResultStat(
      {required this.emoji, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 5),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(color: Colors.white54, fontSize: 10)),
          ],
        ),
      );
}
