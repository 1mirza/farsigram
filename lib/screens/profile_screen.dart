import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/game_state.dart';
import '../data/avatar_catalog.dart';
import 'avatar_shop_screen.dart';
import 'onboarding_screen.dart';
import 'saved_posts_screen.dart';

/// پروفایل: سطح، نشان‌ها، آمار واقعی، فروشگاه آواتار و تنطیمات
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  double _lesson = GameState.activeLessonLimit.value.toDouble();

  Future<void> _editName() async {
    final controller = TextEditingController(text: GameState.userName.value);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تغییر نام',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        content: TextField(
          controller: controller,
          maxLength: 20,
          decoration: const InputDecoration(hintText: 'نام جدید'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('انصراف')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('ذخیره'),
          ),
        ],
      ),
    );
    if (name != null && name.length >= 2) {
      await GameState.setUserName(name);
      if (mounted) setState(() {});
    }
  }

  Future<void> _reset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('پاک کردن همه‌ی داده‌ها؟',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        content: const Text(
            'نام، سکه، امتیاز، آواتارها و پست‌های ذخیره‌شده حذف می‌شوند.',
            style: TextStyle(fontSize: 13, height: 2)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('انصراف')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('پاک کن'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await GameState.resetAll();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const OnboardingScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            _header(),
            _statsRow(),
            _shopCards(),
            _lessonCard(),
            _badges(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: OutlinedButton.icon(
                onPressed: _reset,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.red,
                  side: BorderSide(color: AppTheme.red.withOpacity(0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('پاک کردن داده‌ها و شروع مجدد'),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 18, 16, 0),
              child: Text(
                  'پارسی‌گرام ششم · نسخه‌ی ۲\nساخته‌ی حمیدرضا علی میرزائی',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 11, height: 2, color: AppTheme.textMuted)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppTheme.nightGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 104,
                height: 104,
                child: CircularProgressIndicator(
                  value: GameState.levelProgress,
                  strokeWidth: 5,
                  backgroundColor: Colors.white12,
                  color: AppTheme.amber,
                ),
              ),
              const AvatarCircle(size: 78),
              Positioned(
                bottom: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: AppTheme.goldGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('سطح ${faNum(GameState.level)}',
                      style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF3F2D00))),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ValueListenableBuilder<String>(
            valueListenable: GameState.userName,
            builder: (context, name, _) => GestureDetector(
              onTap: _editName,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(name.isEmpty ? 'کاربر مهمان' : name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(width: 6),
                  const Icon(Icons.edit_rounded,
                      size: 15, color: Colors.white54),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(GameState.rankTitle,
              style: const TextStyle(color: Colors.white60, fontSize: 12)),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: GameState.levelProgress,
              minHeight: 8,
              backgroundColor: Colors.white12,
              color: AppTheme.amber,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            '${faNum(GameState.xpInLevel)} از ${faNum(GameState.xpPerLevel)} امتیاز تا سطح ${faNum(GameState.level + 1)}',
            style: const TextStyle(color: Colors.white54, fontSize: 10.5),
          ),
        ],
      ),
    );
  }

  Widget _statsRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
      child: Row(
        children: [
          Expanded(
            child: ValueListenableBuilder<int>(
              valueListenable: GameState.coins,
              builder: (context, coins, _) =>
                  _stat('🪙', 'سکه', faGroup(coins)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ValueListenableBuilder<int>(
              valueListenable: GameState.xp,
              builder: (context, xp, _) => _stat('⭐', 'امتیاز', faGroup(xp)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _stat('🎯', 'دقت', '${faNum(GameState.accuracy)}٪'),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ValueListenableBuilder<int>(
              valueListenable: GameState.streak,
              builder: (context, streak, _) =>
                  _stat('🔥', 'روز پیاپی', faNum(streak)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String emoji, String label, String value) => Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.soft,
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 5),
            Text(value,
                style:
                    const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
            const SizedBox(height: 2),
            Text(label,
                style:
                    const TextStyle(fontSize: 9.5, color: AppTheme.textMuted)),
          ],
        ),
      );

  Widget _shopCards() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Row(
        children: [
          Expanded(
            child: _actionCard(
              emoji: '🛒',
              title: 'فروشگاه آواتار',
              subtitle: ValueListenableBuilder<Set<String>>(
                valueListenable: GameState.ownedAvatars,
                builder: (context, owned, _) => Text(
                  '${faNum(owned.length)} از ${faNum(kAvatars.length)} آواتار',
                  style: const TextStyle(
                      fontSize: 10.5, color: AppTheme.textMuted),
                ),
              ),
              color: AppTheme.secondary,
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                      builder: (_) => const AvatarShopScreen()),
                );
                if (mounted) setState(() {});
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _actionCard(
              emoji: '🔖',
              title: 'پست‌های ذخیره‌شده',
              subtitle: ValueListenableBuilder<Set<int>>(
                valueListenable: GameState.savedPosts,
                builder: (context, saved, _) => Text(
                  '${faNum(saved.length)} پست برای مرور',
                  style: const TextStyle(
                      fontSize: 10.5, color: AppTheme.textMuted),
                ),
              ),
              color: AppTheme.primary,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                    builder: (_) => const SavedPostsScreen()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionCard({
    required String emoji,
    required String title,
    required Widget subtitle,
    required Color color,
    required VoidCallback onTap,
  }) =>
      InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: AppTheme.soft,
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 19)),
              const SizedBox(height: 8),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 12.5)),
              const SizedBox(height: 3),
              subtitle,
            ],
          ),
        ),
      );

  Widget _lessonCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('تا کدام درس خوانده‌ای؟',
                    style:
                        TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5)),
              ),
              Text('درس ${faNum(_lesson.round())}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13.5,
                      color: AppTheme.primary)),
            ],
          ),
          const Text('محتوای فید و بازی‌ها تا همین درس نشان داده می‌شود.',
              style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          Slider(
            value: _lesson,
            min: 1,
            max: 17,
            divisions: 16,
            label: faNum(_lesson.round()),
            onChanged: (v) => setState(() => _lesson = v),
            onChangeEnd: (v) => GameState.setActiveLessonLimit(v.round()),
          ),
        ],
      ),
    );
  }

  Widget _badges() {
    final badges = GameState.badges;
    final unlocked = badges.where((b) => b.unlocked).length;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('نشان‌های من',
                    style:
                        TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5)),
              ),
              Text('${faNum(unlocked)} از ${faNum(badges.length)}',
                  style: const TextStyle(
                      fontSize: 11.5, color: AppTheme.textMuted)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: badges
                .map((badge) => _badgeTile(
                      emoji: badge.emoji,
                      title: badge.title,
                      description: badge.description,
                      unlocked: badge.unlocked,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _badgeTile({
    required String emoji,
    required String title,
    required String description,
    required bool unlocked,
  }) =>
      Tooltip(
        message: description,
        child: Container(
          width: 92,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            color: unlocked
                ? AppTheme.amber.withOpacity(0.12)
                : AppTheme.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: unlocked ? AppTheme.amber : AppTheme.border,
            ),
          ),
          child: Column(
            children: [
              Opacity(
                opacity: unlocked ? 1 : 0.35,
                child: Text(emoji, style: const TextStyle(fontSize: 20)),
              ),
              const SizedBox(height: 6),
              Text(title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    height: 1.5,
                    fontWeight: FontWeight.w900,
                    color: unlocked ? AppTheme.textDark : AppTheme.textMuted,
                  )),
            ],
          ),
        ),
      );
}
