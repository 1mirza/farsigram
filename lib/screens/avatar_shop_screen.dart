import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/game_state.dart';
import '../data/avatar_catalog.dart';

/// فروشگاه آواتار: خرید با سکه، فروش با ۵۰٪ قیمت، انتخاب آواتار فعال
class AvatarShopScreen extends StatefulWidget {
  const AvatarShopScreen({super.key});

  @override
  State<AvatarShopScreen> createState() => _AvatarShopScreenState();
}

class _AvatarShopScreenState extends State<AvatarShopScreen> {
  static const List<String> _filters = [
    'همه',
    'عادی',
    'کمیاب',
    'حماسی',
    'افسانه‌ای'
  ];
  String _filter = 'همه';

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message), duration: const Duration(milliseconds: 1600)),
    );
  }

  Future<void> _buy(AvatarItem item) async {
    if (GameState.level < item.minLevel) {
      _toast('باید اول به سطح ${faNum(item.minLevel)} برسی 🔒');
      return;
    }
    final ok = await GameState.buyAvatar(item.id, item.price);
    if (!ok) {
      _toast('سکه‌ات کافی نیست — بازی کن تا سکه بگیری 🪙');
      return;
    }
    await GameState.equipAvatar(item.id);
    _toast('آواتار «${item.name}» خریده و فعال شد 🎉');
  }

  Future<void> _sell(AvatarItem item) async {
    final refund = (item.price * 0.5).round();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('فروش آواتار',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        content: Text(
            '«${item.name}» را بفروشی؟ ${faNum(refund)} سکه (۵۰٪ قیمت) به تو برمی‌گردد.',
            style: const TextStyle(fontSize: 13, height: 2)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('انصراف')),
          ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('بفروش')),
        ],
      ),
    );
    if (ok != true) return;

    final done = await GameState.sellAvatar(item.id, item.price);
    _toast(done
        ? 'فروخته شد · ${faNum(refund)} سکه گرفتی'
        : 'این آواتار قابل فروش نیست');
  }

  @override
  Widget build(BuildContext context) {
    final items = _filter == 'همه'
        ? kAvatars
        : kAvatars.where((a) => a.rarity == _filter).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('فروشگاه آواتار',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16.5)),
        actions: [
          ValueListenableBuilder<int>(
            valueListenable: GameState.coins,
            builder: (context, coins, _) => Container(
              margin: const EdgeInsets.only(left: 12, top: 12, bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTheme.amber.withOpacity(0.14),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('🪙 ${faGroup(coins)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12.5,
                      color: Color(0xFF92400E))),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 54,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              children: _filters
                  .map((filter) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: ChoiceChip(
                          label: Text(filter,
                              style: const TextStyle(fontSize: 11.5)),
                          selected: _filter == filter,
                          onSelected: (_) => setState(() => _filter = filter),
                        ),
                      ))
                  .toList(),
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<Set<String>>(
              valueListenable: GameState.ownedAvatars,
              builder: (context, owned, _) => ValueListenableBuilder<String>(
                valueListenable: GameState.avatarId,
                builder: (context, active, _) => GridView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.78,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) => _tile(
                    items[index],
                    owned: owned.contains(items[index].id),
                    active: active == items[index].id,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(AvatarItem item, {required bool owned, required bool active}) {
    final locked = GameState.level < item.minLevel;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.soft,
        border: Border.all(
          color: active ? AppTheme.primary : AppTheme.border,
          width: active ? 1.8 : 1,
        ),
      ),
      child: Column(
        children: [
          Opacity(
            opacity: owned || !locked ? 1 : 0.45,
            child: AvatarCircle(avatarId: item.id, size: 58),
          ),
          const SizedBox(height: 9),
          Text(item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
          const SizedBox(height: 2),
          Text(item.subtitle,
              maxLines: 1,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
          const SizedBox(height: 7),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: item.rarityColor.withOpacity(0.14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(item.rarity,
                style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: item.rarityColor)),
          ),
          const Spacer(),
          if (active)
            const Text('آواتار فعال ✅',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primary))
          else if (owned)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => GameState.equipAvatar(item.id),
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8)),
                    child:
                        const Text('انتخاب', style: TextStyle(fontSize: 11.5)),
                  ),
                ),
                if (item.price > 0) ...[
                  const SizedBox(width: 6),
                  IconButton(
                    tooltip: 'فروش',
                    onPressed: () => _sell(item),
                    icon: const Icon(Icons.sell_outlined,
                        size: 18, color: AppTheme.textMuted),
                  ),
                ],
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _buy(item),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  backgroundColor:
                      locked ? AppTheme.textMuted : AppTheme.primary,
                ),
                child: Text(
                  locked
                      ? 'قفل · سطح ${faNum(item.minLevel)}'
                      : '🪙 ${faGroup(item.price)}',
                  style: const TextStyle(
                      fontSize: 11.5, fontWeight: FontWeight.w900),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
