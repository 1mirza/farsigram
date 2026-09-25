import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/game_state.dart';
import '../data/avatar_catalog.dart';
import '../data/leaderboard_service.dart';

/// جدول رتبه‌بندی ۱۰۰ نفره با امتیاز واقعی کاربر
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  bool _loading = true;
  List<LeaderRow> _rows = [];

  @override
  void initState() {
    super.initState();
    _load();
    GameState.xp.addListener(_load);
    GameState.avatarId.addListener(_load);
  }

  @override
  void dispose() {
    GameState.xp.removeListener(_load);
    GameState.avatarId.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final rows = await LeaderboardService.table();
    if (!mounted) return;
    setState(() {
      _rows = rows;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primary));
    }

    final me = LeaderboardService.myRow(_rows);
    final gap = LeaderboardService.gapToNext(_rows);
    final top = _rows.take(3).toList();
    final rest = _rows.skip(3).toList();

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 16),
            children: [
              _podium(top),
              if (me != null)
                Container(
                  margin: const EdgeInsets.fromLTRB(12, 14, 12, 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: AppTheme.brandGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppTheme.glow(AppTheme.primary),
                  ),
                  child: Row(
                    children: [
                      const Text('📊', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                'رتبه‌ی تو: ${faNum(me.rank)} از ${faNum(_rows.length)}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14)),
                            const SizedBox(height: 4),
                            Text(
                              gap > 0
                                  ? 'با ${faNum(gap)} امتیاز دیگر یک پله بالا می‌روی!'
                                  : 'تو نفر اول جدولی! 👑',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 11.5),
                            ),
                          ],
                        ),
                      ),
                      Text('⭐ ${faGroup(me.score)}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 13.5)),
                    ],
                  ),
                ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 6, 16, 8),
                child: Text('جدول کامل — ۱۰۰ رقیب + خودت',
                    style:
                        TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              ),
              ...rest.map(_row),
            ],
          ),
        ),
        if (me != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              border: Border(top: BorderSide(color: AppTheme.border)),
            ),
            child: _row(me, compact: true),
          ),
      ],
    );
  }

  Widget _podium(List<LeaderRow> top) {
    if (top.length < 3) return const SizedBox.shrink();
    final order = [top[1], top[0], top[2]];
    final heights = [74.0, 96.0, 60.0];
    final medals = ['🥈', '🥇', '🥉'];

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
      decoration: BoxDecoration(
        gradient: AppTheme.nightGradient,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          const Text('قهرمانان امروز',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14.5)),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(3, (i) {
              final row = order[i];
              return Expanded(
                child: Column(
                  children: [
                    Text(medals[i], style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 6),
                    AvatarCircle(
                        avatarId: row.avatarId, size: i == 1 ? 52 : 42),
                    const SizedBox(height: 6),
                    Text(row.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: row.isMe ? AppTheme.amber : Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900)),
                    Text('⭐ ${faGroup(row.score)}',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 10)),
                    const SizedBox(height: 7),
                    Container(
                      height: heights[i],
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        gradient: i == 1
                            ? AppTheme.goldGradient
                            : LinearGradient(colors: [
                                Colors.white.withOpacity(0.22),
                                Colors.white.withOpacity(0.08),
                              ]),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12)),
                      ),
                      alignment: Alignment.topCenter,
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(faNum(row.rank),
                          style: TextStyle(
                              color: i == 1
                                  ? const Color(0xFF3F2D00)
                                  : Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 15)),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _row(LeaderRow row, {bool compact = false}) {
    return Container(
      margin: EdgeInsets.fromLTRB(12, 0, 12, compact ? 0 : 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: row.isMe ? AppTheme.primary.withOpacity(0.10) : AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: row.isMe ? AppTheme.primary : AppTheme.border,
          width: row.isMe ? 1.6 : 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(faNum(row.rank),
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12.5,
                    color: row.isMe ? AppTheme.primary : AppTheme.textMuted)),
          ),
          const SizedBox(width: 6),
          AvatarCircle(avatarId: row.avatarId, size: 34, showRing: false),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(row.isMe ? '${row.name} (خودت)' : row.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 12.5)),
                Text(row.city,
                    style: const TextStyle(
                        fontSize: 10.5, color: AppTheme.textMuted)),
              ],
            ),
          ),
          Text('⭐ ${faGroup(row.score)}',
              style:
                  const TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5)),
        ],
      ),
    );
  }
}
