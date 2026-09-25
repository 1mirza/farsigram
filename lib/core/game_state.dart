import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// وضعیت کامل کاربر. همه‌ی مقدارها روی گوشی (SharedPreferences) ذخیره می‌شوند.
class GameState {
  GameState._();

  static late SharedPreferences prefs;

  static const int xpPerLevel = 250;
  static const String defaultAvatar = 'student';

  static final ValueNotifier<int> coins = ValueNotifier<int>(150);
  static final ValueNotifier<int> xp = ValueNotifier<int>(0);
  static final ValueNotifier<String> userName = ValueNotifier<String>('');
  static final ValueNotifier<String> avatarId =
      ValueNotifier<String>(defaultAvatar);
  static final ValueNotifier<Set<String>> ownedAvatars =
      ValueNotifier<Set<String>>(<String>{defaultAvatar});
  static final ValueNotifier<int> activeLessonLimit = ValueNotifier<int>(17);
  static final ValueNotifier<Set<int>> likedPosts =
      ValueNotifier<Set<int>>(<int>{});
  static final ValueNotifier<Set<int>> savedPosts =
      ValueNotifier<Set<int>>(<int>{});
  static final ValueNotifier<int> streak = ValueNotifier<int>(0);
  static final ValueNotifier<int> correctAnswers = ValueNotifier<int>(0);
  static final ValueNotifier<int> wrongAnswers = ValueNotifier<int>(0);
  static final ValueNotifier<int> challengesDone = ValueNotifier<int>(0);
  static final ValueNotifier<Map<String, int>> categoryBest =
      ValueNotifier<Map<String, int>>(<String, int>{});
  static final ValueNotifier<Set<String>> finishedDialogues =
      ValueNotifier<Set<String>>(<String>{});

  static Future<void> init() async {
    prefs = await SharedPreferences.getInstance();

    coins.value = prefs.getInt('coins') ?? 150;
    xp.value = prefs.getInt('xp') ?? 0;
    userName.value = prefs.getString('userName') ?? '';
    avatarId.value = prefs.getString('avatarId') ?? defaultAvatar;
    ownedAvatars.value =
        (prefs.getStringList('ownedAvatars') ?? <String>[defaultAvatar])
            .toSet();
    activeLessonLimit.value = prefs.getInt('activeLessonLimit') ?? 17;
    likedPosts.value = _toIntSet(prefs.getStringList('liked_posts'));
    savedPosts.value = _toIntSet(prefs.getStringList('saved_posts'));
    correctAnswers.value = prefs.getInt('correctAnswers') ?? 0;
    wrongAnswers.value = prefs.getInt('wrongAnswers') ?? 0;
    challengesDone.value = prefs.getInt('challengesDone') ?? 0;
    streak.value = prefs.getInt('streak') ?? 0;
    finishedDialogues.value =
        (prefs.getStringList('finishedDialogues') ?? <String>[]).toSet();

    final bestRaw = prefs.getString('categoryBest');
    if (bestRaw != null && bestRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(bestRaw);
        if (decoded is Map) {
          categoryBest.value = decoded.map(
            (key, value) => MapEntry('$key', value is num ? value.toInt() : 0),
          );
        }
      } catch (_) {}
    }

    await _touchStreak();
  }

  static Set<int> _toIntSet(List<String>? raw) {
    if (raw == null) return <int>{};
    return raw.map((e) => int.tryParse(e) ?? -1).where((e) => e >= 0).toSet();
  }

  static String _dayKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static Future<void> _touchStreak() async {
    final today = DateTime.now();
    final todayKey = _dayKey(today);
    final last = prefs.getString('lastActiveDate');

    if (last == todayKey) return;
    if (last == _dayKey(today.subtract(const Duration(days: 1)))) {
      streak.value = streak.value + 1;
    } else {
      streak.value = 1;
    }
    await prefs.setInt('streak', streak.value);
    await prefs.setString('lastActiveDate', todayKey);
  }

  static bool get hasProfile => userName.value.trim().length >= 2;
  static bool get onboarded =>
      (prefs.getBool('onboarded') ?? false) && hasProfile;

  static int get level => (xp.value ~/ xpPerLevel) + 1;
  static int get xpInLevel => xp.value % xpPerLevel;
  static double get levelProgress => xpInLevel / xpPerLevel;

  static int get answeredTotal => correctAnswers.value + wrongAnswers.value;
  static int get accuracy => answeredTotal == 0
      ? 0
      : ((correctAnswers.value / answeredTotal) * 100).round();

  static String get rankTitle {
    final lvl = level;
    if (lvl >= 20) return 'سخن‌سرای افسانه‌ای';
    if (lvl >= 14) return 'استاد ادبیات';
    if (lvl >= 8) return 'پهلوان واژه‌ها';
    if (lvl >= 4) return 'دانش‌آموز کوشا';
    return 'نوآموز پارسی';
  }

  static Future<void> createProfile({
    required String name,
    String avatar = defaultAvatar,
    int? lessonLimit,
  }) async {
    userName.value = name.trim();
    avatarId.value = avatar;
    ownedAvatars.value = {...ownedAvatars.value, avatar};
    if (lessonLimit != null) activeLessonLimit.value = lessonLimit;

    await prefs.setString('userName', userName.value);
    await prefs.setString('avatarId', avatarId.value);
    await prefs.setStringList('ownedAvatars', ownedAvatars.value.toList());
    await prefs.setInt('activeLessonLimit', activeLessonLimit.value);
    await prefs.setBool('onboarded', true);
  }

  static Future<void> setUserName(String name) async {
    userName.value = name.trim();
    await prefs.setString('userName', userName.value);
  }

  static Future<void> setActiveLessonLimit(int limit) async {
    activeLessonLimit.value = limit.clamp(1, 17);
    await prefs.setInt('activeLessonLimit', activeLessonLimit.value);
  }

  static Future<void> addCoins(int amount) async {
    coins.value = coins.value + amount;
    await prefs.setInt('coins', coins.value);
  }

  static Future<bool> spendCoins(int amount) async {
    if (coins.value < amount) return false;
    coins.value = coins.value - amount;
    await prefs.setInt('coins', coins.value);
    return true;
  }

  static Future<void> addXp(int amount) async {
    xp.value = xp.value + amount;
    await prefs.setInt('xp', xp.value);
  }

  static bool owns(String id) => ownedAvatars.value.contains(id);

  static Future<bool> buyAvatar(String id, int price) async {
    if (owns(id)) return true;
    if (price > 0 && !await spendCoins(price)) return false;
    ownedAvatars.value = {...ownedAvatars.value, id};
    await prefs.setStringList('ownedAvatars', ownedAvatars.value.toList());
    return true;
  }

  /// فروش آواتار با ۵۰٪ قیمت
  static Future<bool> sellAvatar(String id, int price) async {
    if (!owns(id) || price <= 0 || id == defaultAvatar) return false;
    final next = {...ownedAvatars.value}..remove(id);
    ownedAvatars.value = next;
    await prefs.setStringList('ownedAvatars', next.toList());
    if (avatarId.value == id) await equipAvatar(defaultAvatar);
    await addCoins((price * 0.5).round());
    return true;
  }

  static Future<void> equipAvatar(String id) async {
    if (!owns(id)) return;
    avatarId.value = id;
    await prefs.setString('avatarId', id);
  }

  static Future<void> toggleLike(int postId) async {
    final next = {...likedPosts.value};
    if (next.contains(postId)) {
      next.remove(postId);
    } else {
      next.add(postId);
      final rewarded =
          (prefs.getStringList('rewarded_likes') ?? <String>[]).toSet();
      if (!rewarded.contains('$postId')) {
        rewarded.add('$postId');
        await prefs.setStringList('rewarded_likes', rewarded.toList());
        await addCoins(5);
        await addXp(2);
      }
    }
    likedPosts.value = next;
    await prefs.setStringList('liked_posts', next.map((e) => '$e').toList());
  }

  static Future<void> toggleSave(int postId) async {
    final next = {...savedPosts.value};
    next.contains(postId) ? next.remove(postId) : next.add(postId);
    savedPosts.value = next;
    await prefs.setStringList('saved_posts', next.map((e) => '$e').toList());
  }

  static Future<void> registerAnswer(bool correct) async {
    if (correct) {
      correctAnswers.value = correctAnswers.value + 1;
      await prefs.setInt('correctAnswers', correctAnswers.value);
    } else {
      wrongAnswers.value = wrongAnswers.value + 1;
      await prefs.setInt('wrongAnswers', wrongAnswers.value);
    }
  }

  static Future<void> finishChallenge({
    required String categoryId,
    required int score,
    required int total,
    required int coinsEarned,
    required int xpEarned,
  }) async {
    challengesDone.value = challengesDone.value + 1;
    await prefs.setInt('challengesDone', challengesDone.value);

    if (coinsEarned > 0) await addCoins(coinsEarned);
    if (xpEarned > 0) await addXp(xpEarned);

    final best = {...categoryBest.value};
    if ((best[categoryId] ?? 0) < score) {
      best[categoryId] = score;
      categoryBest.value = best;
      await prefs.setString('categoryBest', jsonEncode(best));
    }
  }

  static int bestOf(String categoryId) => categoryBest.value[categoryId] ?? 0;

  static Future<void> markDialogueDone(String key) async {
    finishedDialogues.value = {...finishedDialogues.value, key};
    await prefs.setStringList(
        'finishedDialogues', finishedDialogues.value.toList());
  }

  static bool dialogueDone(String key) => finishedDialogues.value.contains(key);

  static Future<void> saveChatHistory(
      String characterId, List<Map<String, dynamic>> messages) async {
    await prefs.setString('chat_$characterId', jsonEncode(messages));
  }

  static List<Map<String, dynamic>> loadChatHistory(String characterId) {
    final raw = prefs.getString('chat_$characterId');
    if (raw == null || raw.isEmpty) return <Map<String, dynamic>>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (_) {}
    return <Map<String, dynamic>>[];
  }

  static List<Badge> get badges => [
        Badge(
            emoji: '🌱',
            title: 'اولین قدم',
            description: 'اولین بازی را تمام کن',
            unlocked: challengesDone.value >= 1),
        Badge(
            emoji: '🔥',
            title: '۳ روز پیاپی',
            description: 'سه روز پشت سر هم تمرین کن',
            unlocked: streak.value >= 3),
        Badge(
            emoji: '💪',
            title: '۱۰ بازی',
            description: '۱۰ بازی را کامل کن',
            unlocked: challengesDone.value >= 10),
        Badge(
            emoji: '🎯',
            title: 'دقیق',
            description: 'دقت بالای ۸۰٪ با ۳۰ پاسخ',
            unlocked: answeredTotal >= 30 && accuracy >= 80),
        Badge(
            emoji: '⭐',
            title: 'هزار امتیاز',
            description: '۱۰۰۰ امتیاز جمع کن',
            unlocked: xp.value >= 1000),
        Badge(
            emoji: '📚',
            title: 'کتابخوان',
            description: '۵ پست را ذخیره کن',
            unlocked: savedPosts.value.length >= 5),
        Badge(
            emoji: '🗣',
            title: 'هم‌سخن بزرگان',
            description: 'یک گفت‌وگو را کامل کن',
            unlocked:
                finishedDialogues.value.any((e) => e.endsWith('-completed'))),
        Badge(
            emoji: '👑',
            title: 'مجموعه‌دار',
            description: '۵ آواتار داشته باش',
            unlocked: ownedAvatars.value.length >= 5),
      ];

  static Future<void> resetAll() async {
    await prefs.clear();
    coins.value = 150;
    xp.value = 0;
    userName.value = '';
    avatarId.value = defaultAvatar;
    ownedAvatars.value = <String>{defaultAvatar};
    activeLessonLimit.value = 17;
    likedPosts.value = <int>{};
    savedPosts.value = <int>{};
    streak.value = 0;
    correctAnswers.value = 0;
    wrongAnswers.value = 0;
    challengesDone.value = 0;
    categoryBest.value = <String, int>{};
    finishedDialogues.value = <String>{};
    await _touchStreak();
  }
}

class Badge {
  final String emoji;
  final String title;
  final String description;
  final bool unlocked;

  const Badge({
    required this.emoji,
    required this.title,
    required this.description,
    required this.unlocked,
  });
}

/// جعبه‌ی لایتنر: سؤال‌های غلط دوباره پرسیده می‌شوند
class LeitnerEngine {
  LeitnerEngine._();

  static const String _key = 'leitner_mistakes';

  static List<String> getMistakes() =>
      GameState.prefs.getStringList(_key) ?? <String>[];

  static int get mistakeCount => getMistakes().length;

  static Future<void> recordAnswer(String questionId, bool correct) async {
    final list = getMistakes().toSet();
    if (correct) {
      list.remove(questionId);
    } else {
      list.add(questionId);
    }
    await GameState.prefs.setStringList(_key, list.toList());
  }
}
