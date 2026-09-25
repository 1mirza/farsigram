import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/game_state.dart';
import '../data/avatar_catalog.dart';
import 'chat_screens.dart';
import 'feed_screen.dart';
import 'leaderboard_screen.dart';
import 'profile_screen.dart';
import 'saved_posts_screen.dart';

class _TabSpec {
  final String label;
  final IconData icon;
  final IconData outline;
  const _TabSpec(this.label, this.icon, this.outline);
}

/// پوسته‌ی اصلی اپ با ۴ تب
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const List<_TabSpec> _tabs = [
    _TabSpec('خانه', Icons.home_rounded, Icons.home_outlined),
    _TabSpec('مفاخر', Icons.forum_rounded, Icons.forum_outlined),
    _TabSpec('لیگ', Icons.emoji_events_rounded, Icons.emoji_events_outlined),
    _TabSpec('پروفایل', Icons.person_rounded, Icons.person_outline_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _index == 3
          ? null
          : AppBar(
              titleSpacing: 14,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      gradient: AppTheme.brandGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.auto_stories_rounded,
                        color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 9),
                  const Text('پارسی‌گرام ششم',
                      style: TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 15.5)),
                ],
              ),
              actions: [
                ValueListenableBuilder<int>(
                  valueListenable: GameState.streak,
                  builder: (context, streak, _) => _Pill(
                      emoji: '🔥', text: faNum(streak), color: AppTheme.red),
                ),
                const SizedBox(width: 6),
                ValueListenableBuilder<int>(
                  valueListenable: GameState.coins,
                  builder: (context, coins, _) => _Pill(
                      emoji: '🪙', text: faGroup(coins), color: AppTheme.amber),
                ),
                IconButton(
                  tooltip: 'ذخیره‌شده‌ها',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                        builder: (_) => const SavedPostsScreen()),
                  ),
                  icon: const Icon(Icons.bookmark_border_rounded),
                ),
                GestureDetector(
                  onTap: () => setState(() => _index = 3),
                  child: const Padding(
                    padding: EdgeInsets.only(left: 12, right: 4),
                    child: AvatarCircle(size: 30),
                  ),
                ),
              ],
            ),
      body: IndexedStack(
        index: _index,
        children: const [
          FeedScreen(),
          ChatListScreen(),
          LeaderboardScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          border: Border(top: BorderSide(color: AppTheme.border)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 62,
            child: Row(
              children: List.generate(_tabs.length, (i) {
                final tab = _tabs[i];
                final active = i == _index;
                return Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _index = i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 5),
                          decoration: BoxDecoration(
                            color: active
                                ? AppTheme.primary.withOpacity(0.10)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(
                            active ? tab.icon : tab.outline,
                            size: 21,
                            color:
                                active ? AppTheme.primary : AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          tab.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight:
                                active ? FontWeight.w900 : FontWeight.w400,
                            color:
                                active ? AppTheme.primary : AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String emoji;
  final String text;
  final Color color;
  const _Pill({required this.emoji, required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Text(text,
                style: TextStyle(
                    fontSize: 11.5, fontWeight: FontWeight.w900, color: color)),
          ],
        ),
      );
}
