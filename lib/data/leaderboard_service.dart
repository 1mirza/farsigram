import 'dart:convert';
import 'dart:math';

import '../core/game_state.dart';

class LeaderRow {
  final String name;
  final String city;
  final int score;
  final bool isMe;
  final String avatarId;
  int rank;

  LeaderRow({
    required this.name,
    required this.city,
    required this.score,
    this.isMe = false,
    this.avatarId = 'student',
    this.rank = 0,
  });
}

/// جدول رتبه‌بندی ۱۰۰ نفره. رقیب‌ها یک‌بار ساخته و روی گوشی ذخیره می‌شوند
/// و هر روز کمی رشد می‌کنند. امتیاز خود کاربر واقعی است (XP ذخیره‌شده).
class LeaderboardService {
  LeaderboardService._();

  static const String _botsKey = 'leaderboard_bots_v2';
  static const String _growKey = 'leaderboard_last_grow';

  static const List<String> _firstNames = [
    'علی',
    'محمد',
    'زهرا',
    'فاطمه',
    'امیر',
    'سارا',
    'رضا',
    'نرگس',
    'حسین',
    'مریم',
    'مهدی',
    'یلدا',
    'طاها',
    'حنانه',
    'ابوالفضل',
    'بهار',
    'یوسف',
    'رومینا',
    'احمد',
    'دیانا',
    'ماهان',
    'آیدا',
    'سامیار',
    'نازنین',
    'ارشیا',
    'رونیکا',
    'پرهام',
    'ملیکا',
    'کیان',
    'آوا',
    'بنیامین',
    'ستایش',
    'امیرعلی',
    'باران',
    'محمدطاه',
    'هلیا',
    'سجاد',
    'ریحانه',
    'مانی',
    'پریا',
  ];

  static const List<String> _families = [
    'محمدی',
    'رضایی',
    'کریمی',
    'احمدی',
    'موسوی',
    'حسینی',
    'صادقی',
    'علوی',
    'نوری',
    'امینی',
    'کاظمی',
    'قاسمی',
    'نجفی',
    'مرادی',
    'بهرامی',
    'اسدی',
  ];

  static const List<String> _cities = [
    'تهران',
    'مشهد',
    'اصفهان',
    'شیراز',
    'تبریز',
    'کرج',
    'اهواز',
    'قم',
    'کرمان',
    'رشت',
    'یزد',
    'ارومیه',
    'زاهدان',
    'همدان',
    'ساری',
    'بوشهر',
    'اردبیل',
    'گرگان',
    'بیرجند',
    'سنندج',
  ];

  static const List<String> _botAvatars = [
    'student',
    'book_lover',
    'pen_master',
    'owl',
    'star_writer',
    'rakhsh',
    'falcon',
    'poet',
    'explorer',
    'shield',
    'lion',
    'simorgh',
  ];

  static List<Map<String, dynamic>> _generate() {
    final rnd = Random(20250916); // بذر ثابت: لیست همیشه یکسان می‌ماند
    final out = <Map<String, dynamic>>[];
    for (var i = 0; i < 100; i++) {
      final name =
          '${_firstNames[rnd.nextInt(_firstNames.length)]} ${_families[rnd.nextInt(_families.length)]}';
      out.add({
        'name': name,
        'city': _cities[rnd.nextInt(_cities.length)],
        'avatar': _botAvatars[rnd.nextInt(_botAvatars.length)],
        'score': max(40, 3600 - i * 33 - rnd.nextInt(20)),
      });
    }
    return out;
  }

  static List<Map<String, dynamic>> _bots() {
    final raw = GameState.prefs.getString(_botsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List && decoded.length == 100) {
          return decoded
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      } catch (_) {}
    }
    final generated = _generate();
    GameState.prefs.setString(_botsKey, jsonEncode(generated));
    return generated;
  }

  /// هر روز رقیب‌ها کمی امتیاز می‌گیرند تا جدول زنده باشد
  static Future<List<Map<String, dynamic>>> _growIfNewDay() async {
    final bots = _bots();
    final today = DateTime.now();
    final key = '${today.year}-${today.month}-${today.day}';
    if (GameState.prefs.getString(_growKey) == key) return bots;

    final rnd = Random();
    for (final bot in bots) {
      final current = (bot['score'] as num?)?.toInt() ?? 0;
      bot['score'] = current + rnd.nextInt(55);
    }
    await GameState.prefs.setString(_botsKey, jsonEncode(bots));
    await GameState.prefs.setString(_growKey, key);
    return bots;
  }

  /// جدول کامل (۱۰۰ رقیب + خود کاربر) مرتب‌شده بر اساس امتیاز
  static Future<List<LeaderRow>> table() async {
    final bots = await _growIfNewDay();

    final rows = bots
        .map((bot) => LeaderRow(
              name: '${bot['name']}',
              city: '${bot['city']}',
              score: (bot['score'] as num?)?.toInt() ?? 0,
              avatarId: '${bot['avatar']}',
            ))
        .toList();

    rows.add(LeaderRow(
      name: GameState.userName.value.isEmpty ? 'من' : GameState.userName.value,
      city: 'کلاس من',
      score: GameState.xp.value,
      isMe: true,
      avatarId: GameState.avatarId.value,
    ));

    rows.sort((a, b) => b.score.compareTo(a.score));
    for (var i = 0; i < rows.length; i++) {
      rows[i].rank = i + 1;
    }
    return rows;
  }

  static LeaderRow? myRow(List<LeaderRow> rows) {
    for (final row in rows) {
      if (row.isMe) return row;
    }
    return null;
  }

  /// فاصله‌ی امتیازی تا نفر بالای جدول
  static int gapToNext(List<LeaderRow> rows) {
    final me = myRow(rows);
    if (me == null || me.rank <= 1) return 0;
    return rows[me.rank - 2].score - me.score + 1;
  }
}
