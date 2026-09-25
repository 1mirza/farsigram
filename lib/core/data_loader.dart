import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

/// خواننده‌ی فایل‌های JSON در assets/data (ساختار فایل‌ها دست‌نخورده می‌ماند)
class AssetDataLoader {
  AssetDataLoader._();

  static final Map<String, List<dynamic>> _cache = {};

  static Future<List<dynamic>> loadJsonList(String fileName) async {
    final path =
        fileName.startsWith('assets/') ? fileName : 'assets/data/$fileName';
    if (_cache.containsKey(path)) return _cache[path]!;
    try {
      final raw = await rootBundle.loadString(path);
      final decoded = jsonDecode(raw);
      final list = decoded is List
          ? decoded
          : (decoded is Map &&
                  decoded.values.isNotEmpty &&
                  decoded.values.first is List)
              ? decoded.values.first as List
              : <dynamic>[];
      _cache[path] = list;
      return list;
    } catch (_) {
      _cache[path] = <dynamic>[];
      return <dynamic>[];
    }
  }
}

/// پاکسازی متن از نشانه‌های ارجاع
class TextClean {
  TextClean._();

  static final RegExp _cite = RegExp(r'\[\s*cite[^\]]*\]');
  static final RegExp _spaces = RegExp(r'[ \t]+');

  static String clean(Object? value) {
    if (value == null) return '';
    return value
        .toString()
        .replaceAll(_cite, '')
        .replaceAll(_spaces, ' ')
        .trim();
  }
}

/// تبدیل نام آیکون در JSON به IconData
class AppIcons {
  AppIcons._();

  static const Map<String, IconData> _map = {
    'book': Icons.book_rounded,
    'menu_book': Icons.menu_book_rounded,
    'auto_stories': Icons.auto_stories_rounded,
    'library_books': Icons.library_books_rounded,
    'edit': Icons.edit_rounded,
    'create': Icons.create_rounded,
    'brush': Icons.brush_rounded,
    'palette': Icons.palette_rounded,
    'school': Icons.school_rounded,
    'star': Icons.star_rounded,
    'lightbulb': Icons.lightbulb_rounded,
    'format_quote': Icons.format_quote_rounded,
    'history_edu': Icons.history_edu_rounded,
    'emoji_events': Icons.emoji_events_rounded,
    'language': Icons.language_rounded,
    'translate': Icons.translate_rounded,
    'spellcheck': Icons.spellcheck_rounded,
    'music_note': Icons.music_note_rounded,
    'theater_comedy': Icons.theater_comedy_rounded,
    'psychology': Icons.psychology_rounded,
    'science': Icons.science_rounded,
    'public': Icons.public_rounded,
    'mosque': Icons.mosque_rounded,
    'nature': Icons.nature_rounded,
    'local_florist': Icons.local_florist_rounded,
    'water_drop': Icons.water_drop_rounded,
    'wb_sunny': Icons.wb_sunny_rounded,
    'nightlight': Icons.nightlight_round,
    'favorite': Icons.favorite_rounded,
    'person': Icons.person_rounded,
    'groups': Icons.groups_rounded,
    'flag': Icons.flag_rounded,
    'shield': Icons.shield_rounded,
    'castle': Icons.castle_rounded,
    'map': Icons.map_rounded,
    'explore': Icons.explore_rounded,
    'rule': Icons.rule_rounded,
    'abc': Icons.abc_rounded,
    'auto_awesome': Icons.auto_awesome_rounded,
    'workspace_premium': Icons.workspace_premium_rounded,
    'bolt': Icons.bolt_rounded,
    'forum': Icons.forum_rounded,
  };

  static IconData byName(Object? name) {
    var key = TextClean.clean(name).toLowerCase();
    if (key.startsWith('icons.')) key = key.substring(6);
    key = key.replaceAll('_rounded', '').replaceAll('_outlined', '').trim();
    return _map[key] ?? Icons.auto_stories_rounded;
  }
}

enum QuizKind { choice, meaning, verse, letter, correction }

class QuizQuestion {
  final String id;
  final String prompt;
  final String subtitle;
  final List<String> options;
  final String correct;
  final String hint;
  final QuizKind kind;

  const QuizQuestion({
    required this.id,
    required this.prompt,
    required this.options,
    required this.correct,
    this.subtitle = '',
    this.hint = '',
    this.kind = QuizKind.choice,
  });
}

/// سازنده‌ی سؤال از همان ساختار JSON موجود — بدون هیچ تغییری در فایل‌ها
class QuestionFactory {
  QuestionFactory._();

  static final Random _rnd = Random();

  static List<QuizQuestion> build(List<dynamic> raw, {int lessonLimit = 17}) {
    final items = raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .where((m) {
      final lesson = m['lesson_id'] ?? m['lesson'];
      if (lesson == null) return true;
      final id = _asInt(lesson);
      return id == 0 || id <= lessonLimit;
    }).toList();

    final meaningPool = _pool(items, 'meaning');
    final answerPool = _pool(items, 'answer');
    final artPool = _pool(items, 'art_type');
    final wordPool = _pool(items, 'word');

    final out = <QuizQuestion>[];
    for (var i = 0; i < items.length; i++) {
      out.addAll(
          _fromItem(items[i], i, meaningPool, answerPool, artPool, wordPool));
    }
    return out;
  }

  static List<String> _pool(List<Map<String, dynamic>> items, String key) =>
      items
          .map((m) => TextClean.clean(m[key]))
          .where((s) => s.isNotEmpty)
          .toSet()
          .toList();

  static List<QuizQuestion> _fromItem(
    Map<String, dynamic> m,
    int index,
    List<String> meaningPool,
    List<String> answerPool,
    List<String> artPool,
    List<String> wordPool,
  ) {
    final type = TextClean.clean(m['type']).toLowerCase();
    final hint =
        TextClean.clean(m['hint'] ?? m['rule_hint'] ?? m['explanation']);
    final baseOptions = (m['options'] is List)
        ? (m['options'] as List).map((e) => TextClean.clean(e)).toList()
        : <String>[];

    // ۱) جای خالی حرف — spelling_challenges.json (fill_in)
    if (type == 'fill_in' || m['correct_letter'] != null) {
      final prefix = TextClean.clean(m['word_prefix']);
      final suffix = TextClean.clean(m['word_suffix']);
      final correct = TextClean.clean(m['correct_letter']);
      final distractors = (m['distractors'] is List)
          ? (m['distractors'] as List).map((e) => TextClean.clean(e)).toList()
          : baseOptions;
      final q = _finalize(
        id: 'fill-$index-$prefix$suffix',
        prompt: '$prefix ▫ $suffix'.trim(),
        subtitle: TextClean.clean(m['meaning']),
        hint: hint,
        correct: correct,
        options: distractors,
        kind: QuizKind.letter,
      );
      return q == null ? [] : [q];
    }

    // ۲) غلط‌یابی جمله — spelling_challenges.json (correction)
    if (type == 'correction' || m['errors'] is List) {
      final sentence = TextClean.clean(m['sentence']);
      final errors = (m['errors'] is List) ? m['errors'] as List : const [];
      final result = <QuizQuestion>[];
      for (var e = 0; e < errors.length; e++) {
        final err = errors[e];
        if (err is! Map) continue;
        final wrong = TextClean.clean(err['wrong']);
        final correct = TextClean.clean(err['correct']);
        if (wrong.isEmpty || correct.isEmpty) continue;
        final q = _finalize(
          id: 'corr-$index-$e-$wrong',
          prompt: 'در این جمله، شکل درست واژه‌ی «$wrong» کدام است؟',
          subtitle: sentence,
          hint: hint,
          correct: correct,
          options: [
            wrong,
            ..._sample(wordPool, {correct, wrong}, 2)
          ],
          kind: QuizKind.correction,
        );
        if (q != null) result.add(q);
      }
      return result;
    }

    // ۳) حرف گم‌شده — spelling.json
    if (m['word_part1'] != null && m['word_part2'] != null) {
      final p1 = TextClean.clean(m['word_part1']);
      final p2 = TextClean.clean(m['word_part2']);
      final q = _finalize(
        id: 'sp-$index-$p1$p2',
        prompt: '$p1 ▫ $p2',
        subtitle: TextClean.clean(m['meaning']),
        hint: hint,
        correct: TextClean.clean(m['correct']),
        options: baseOptions,
        kind: QuizKind.letter,
      );
      return q == null ? [] : [q];
    }

    // ۴) تکمیل بیت — poetry_verses.json
    if (m['verse_part2_gap'] != null || m['verse_part1'] != null) {
      final p1 = TextClean.clean(m['verse_part1']);
      final gap = TextClean.clean(m['verse_part2_gap']);
      final poet = TextClean.clean(m['poet']);
      final poem = TextClean.clean(m['poem_title']);
      final q = _finalize(
        id: 'verse-$index-$p1',
        prompt: gap.isEmpty ? p1 : '$p1\n$gap',
        subtitle: [poem, poet].where((e) => e.isNotEmpty).join(' · '),
        hint: hint,
        correct: TextClean.clean(m['correct']),
        options: baseOptions,
        kind: QuizKind.verse,
      );
      return q == null ? [] : [q];
    }

    // ۵) معنی واژه — vocabulary.json / synonyms_roots.json
    if (m['word'] != null && m['meaning'] != null) {
      final word = TextClean.clean(m['word']);
      final meaning = TextClean.clean(m['meaning']);
      final q = _finalize(
        id: 'voc-$index-$word',
        prompt: 'معنی واژه‌ی «$word» کدام است؟',
        subtitle: TextClean.clean(m['example_verse']),
        hint: hint,
        correct: meaning,
        options: baseOptions.isNotEmpty
            ? baseOptions
            : _sample(meaningPool, {meaning}, 3),
        kind: QuizKind.meaning,
      );
      return q == null ? [] : [q];
    }

    // ۶) ضرب‌المثل — proverbs_wisdom.json
    if (m['proverb'] != null) {
      final proverb = TextClean.clean(m['proverb']);
      final meaning = TextClean.clean(m['meaning']);
      final q = _finalize(
        id: 'prov-$index-$proverb',
        prompt: '«$proverb» چه معنایی دارد؟',
        hint: hint,
        correct: meaning,
        options: baseOptions.isNotEmpty
            ? baseOptions
            : _sample(meaningPool, {meaning}, 3),
        kind: QuizKind.meaning,
      );
      return q == null ? [] : [q];
    }

    // ۷) سؤال عمومی — grammar_language / comprehension / stories_master / poetry
    final prompt = TextClean.clean(m['question'] ?? m['prompt'] ?? m['topic']);
    if (prompt.isNotEmpty) {
      final correct = TextClean.clean(m['correct'] ?? m['answer']);
      final q = _finalize(
        id: 'gen-$index-$prompt',
        prompt: prompt,
        subtitle: TextClean.clean(
            m['topic'] != null && m['question'] != null ? m['topic'] : ''),
        hint: hint,
        correct: correct,
        options: baseOptions.isNotEmpty
            ? baseOptions
            : _sample(answerPool, {correct}, 3),
        kind: QuizKind.choice,
      );
      return q == null ? [] : [q];
    }

    // ۸) آرایه‌های ادبی — literature_arts.json
    if (m['art_type'] != null && m['explanation'] != null) {
      final art = TextClean.clean(m['art_type']);
      final explanation = TextClean.clean(m['explanation']);
      final q = _finalize(
        id: 'art-$index-$art',
        prompt: 'این توضیح مربوط به کدام آرایه‌ی ادبی است؟',
        subtitle: explanation,
        correct: art,
        options:
            baseOptions.isNotEmpty ? baseOptions : _sample(artPool, {art}, 3),
        kind: QuizKind.choice,
      );
      return q == null ? [] : [q];
    }

    return const [];
  }

  static QuizQuestion? _finalize({
    required String id,
    required String prompt,
    required String correct,
    required List<String> options,
    String subtitle = '',
    String hint = '',
    QuizKind kind = QuizKind.choice,
  }) {
    final cleanPrompt = TextClean.clean(prompt);
    final cleanCorrect = TextClean.clean(correct);
    if (cleanPrompt.isEmpty || cleanCorrect.isEmpty) return null;

    final set = <String>{cleanCorrect};
    for (final option in options) {
      final value = TextClean.clean(option);
      if (value.isNotEmpty) set.add(value);
    }
    if (set.length < 2) return null;

    var list = set.toList();
    if (list.length > 4) {
      final others = list.where((e) => e != cleanCorrect).toList()
        ..shuffle(_rnd);
      list = [cleanCorrect, ...others.take(3)];
    }
    list.shuffle(_rnd);

    return QuizQuestion(
      id: id,
      prompt: cleanPrompt,
      subtitle: TextClean.clean(subtitle),
      hint: TextClean.clean(hint),
      correct: cleanCorrect,
      options: list,
      kind: kind,
    );
  }

  static List<String> _sample(
      List<String> pool, Set<String> exclude, int count) {
    final candidates = pool.where((e) => !exclude.contains(e)).toList()
      ..shuffle(_rnd);
    return candidates.take(count).toList();
  }

  static int _asInt(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(TextClean.clean(value)) ?? 0;
  }
}
