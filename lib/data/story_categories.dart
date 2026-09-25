import 'package:flutter/material.dart';

import '../core/app_theme.dart';

/// یک دسته‌ی استوری/بازی — هر دسته به یکی از فایل‌های JSON موجود وصل است
class StoryCategory {
  final String id;
  final String title;
  final String file;
  final IconData icon;
  final Color color;
  final String emoji;

  const StoryCategory({
    required this.id,
    required this.title,
    required this.file,
    required this.icon,
    required this.color,
    required this.emoji,
  });
}

/// همان فایل‌های JSON پروژه — بدون هیچ تغییری در ساختار آن‌ها
const List<StoryCategory> kStoryCategories = [
  StoryCategory(
      id: 'vocabulary',
      title: 'معنی واژه‌ها',
      file: 'vocabulary.json',
      icon: Icons.menu_book_rounded,
      color: AppTheme.primary,
      emoji: '📘'),
  StoryCategory(
      id: 'antonyms',
      title: 'متضادها',
      file: 'antonyms.json',
      icon: Icons.compare_arrows_rounded,
      color: Color(0xFF0EA5E9),
      emoji: '↔️'),
  StoryCategory(
      id: 'synonyms',
      title: 'هم‌خانواده و ریشه',
      file: 'synonyms_roots.json',
      icon: Icons.account_tree_rounded,
      color: Color(0xFF10B981),
      emoji: '🌱'),
  StoryCategory(
      id: 'spelling_challenges',
      title: 'غلط‌یاب املا',
      file: 'spelling_challenges.json',
      icon: Icons.rule_rounded,
      color: Color(0xFFEF4444),
      emoji: '🔎'),
  StoryCategory(
      id: 'spelling',
      title: 'حرف گم‌شده',
      file: 'spelling.json',
      icon: Icons.abc_rounded,
      color: Color(0xFFF59E0B),
      emoji: '✏️'),
  StoryCategory(
      id: 'grammar',
      title: 'دستور و زبان',
      file: 'grammar_language.json',
      icon: Icons.school_rounded,
      color: Color(0xFF6366F1),
      emoji: '🧮'),
  StoryCategory(
      id: 'literature_arts',
      title: 'آرایه‌های ادبی',
      file: 'literature_arts.json',
      icon: Icons.palette_rounded,
      color: Color(0xFFEC4899),
      emoji: '🎨'),
  StoryCategory(
      id: 'proverbs',
      title: 'ضرب‌المثل‌ها',
      file: 'proverbs_wisdom.json',
      icon: Icons.format_quote_rounded,
      color: Color(0xFF0D9488),
      emoji: '🧠'),
  StoryCategory(
      id: 'poetry_verses',
      title: 'تکمیل بیت',
      file: 'poetry_verses.json',
      icon: Icons.auto_awesome_rounded,
      color: Color(0xFF8B5CF6),
      emoji: '🖋️'),
  StoryCategory(
      id: 'poetry',
      title: 'شعر و شاعران',
      file: 'poetry.json',
      icon: Icons.music_note_rounded,
      color: Color(0xFFD946EF),
      emoji: '🎵'),
  StoryCategory(
      id: 'comprehension',
      title: 'درک مطلب',
      file: 'comprehension.json',
      icon: Icons.psychology_rounded,
      color: Color(0xFF2563EB),
      emoji: '🧐'),
  StoryCategory(
      id: 'stories_master',
      title: 'آزمون جامع',
      file: 'stories_master.json',
      icon: Icons.emoji_events_rounded,
      color: Color(0xFFB45309),
      emoji: '🏆'),
];
