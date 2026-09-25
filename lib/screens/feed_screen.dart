import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/data_loader.dart';
import '../core/game_state.dart';
import '../data/story_categories.dart';
import '../widgets/post_card.dart';
import 'story_challenge_screen.dart';

/// فید اصلی: نوار استوری بازی‌ها + چالش روزانه + پست‌های آموزشی
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _posts = [];
  final Map<String, int> _counts = {};

  @override
  void initState() {
    super.initState();
    _load();
    GameState.activeLessonLimit.addListener(_load);
  }

  @override
  void dispose() {
    GameState.activeLessonLimit.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final limit = GameState.activeLessonLimit.value;

    final rawPosts = await AssetDataLoader.loadJsonList('posts_feed.json');
    final posts = rawPosts
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .where((post) {
      final lesson = post['lesson_id'];
      if (lesson == null) return true;
      final id = lesson is num ? lesson.toInt() : int.tryParse('$lesson') ?? 0;
      return id <= limit;
    }).toList();

    // شمارش سؤال‌های قابل‌استفاده‌ی هر دسته (دسته‌ی خالی نمایش داده نمی‌شود)
    for (final category in kStoryCategories) {
      final raw = await AssetDataLoader.loadJsonList(category.file);
      _counts[category.id] =
          QuestionFactory.build(raw, lessonLimit: limit).length;
    }

    if (!mounted) return;
    setState(() {
      _posts = posts;
      _loading = false;
    });
  }

  List<StoryCategory> get _available => kStoryCategories
      .where((category) => (_counts[category.id] ?? 0) >= 3)
      .toList();

  Future<void> _openChallenge(
    StoryCategory category, {
    bool doubleReward = false,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StoryChallengeScreen(
          categoryId: category.id,
          title: category.title,
          fileName: category.file,
          color: category.color,
          icon: category.icon,
          doubleReward: doubleReward,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openReview() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const StoryChallengeScreen(
          categoryId: 'review',
          title: 'مرور اشتباه‌ها',
          fileName: '',
          color: AppTheme.red,
          icon: Icons.refresh_rounded,
          reviewMistakes: true,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primary));
    }

    final categories = _available;
    final daily = categories.isEmpty
        ? null
        : categories[DateTime.now().day % categories.length];

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.only(top: 10, bottom: 20),
        children: [
          _storyTray(categories),
          const SizedBox(height: 14),
          if (daily != null) _dailyCard(daily),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text('پست‌های درسی',
                    style:
                        TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                const Spacer(),
                ValueListenableBuilder<int>(
                  valueListenable: GameState.activeLessonLimit,
                  builder: (context, limit, _) => Text(
                    'تا درس ${faNum(limit)}',
                    style: const TextStyle(
                        fontSize: 11.5, color: AppTheme.textMuted),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (_posts.isEmpty)
            const Padding(
              padding: EdgeInsets.all(30),
              child: Text('پستی برای این درس‌ها پیدا نشد.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textMuted)),
            )
          else
            ..._posts.map((post) => PostCard(
                  post: post,
                  onChanged: () => setState(() {}),
                )),
        ],
      ),
    );
  }

  Widget _storyTray(List<StoryCategory> categories) {
    final mistakes = LeitnerEngine.mistakeCount;

    return SizedBox(
      height: 118,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _storyBubble(
            emoji: mistakes > 0 ? '🔁' : '✅',
            title: 'مرور اشتباه‌ها',
            color: AppTheme.red,
            badge: mistakes > 0 ? faNum(mistakes) : null,
            dimmed: mistakes == 0,
            onTap: mistakes == 0
                ? () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'عالی! الان هیچ اشتباه مرورنشده‌ای نداری 🎉')),
                    )
                : _openReview,
          ),
          ...categories.map((category) {
            final best = GameState.bestOf(category.id);
            return _storyBubble(
              emoji: category.emoji,
              title: category.title,
              color: category.color,
              badge: best > 0 ? '⭐${faNum(best)}' : null,
              onTap: () => _openChallenge(category),
            );
          }),
        ],
      ),
    );
  }

  Widget _storyBubble({
    required String emoji,
    required String title,
    required Color color,
    required VoidCallback onTap,
    String? badge,
    bool dimmed = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 84,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: dimmed
                          ? [AppTheme.border, AppTheme.border]
                          : [color, color.withOpacity(0.45)],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                  ),
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.surface,
                    ),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 26)),
                    ),
                  ),
                ),
                if (badge != null)
                  Positioned(
                    bottom: -2,
                    left: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white, width: 1.6),
                      ),
                      child: Text(badge,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              title,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10.5, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dailyCard(StoryCategory category) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.brandGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppTheme.glow(AppTheme.primary),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text('🎯', style: TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('چالش روزانه · جایزه‌ی دوبرابر',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14)),
                const SizedBox(height: 4),
                Text('امروز: ${category.title}',
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _openChallenge(category, doubleReward: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('شروع',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
