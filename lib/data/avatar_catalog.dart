import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/game_state.dart';

/// یک آواتار قابل خرید در فروشگاه
class AvatarItem {
  final String id;
  final String name;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  final int price;
  final String rarity;
  final int minLevel;

  const AvatarItem({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.colors,
    required this.price,
    required this.rarity,
    this.minLevel = 1,
  });

  Color get rarityColor {
    switch (rarity) {
      case 'کمیاب':
        return AppTheme.blue;
      case 'حماسی':
        return AppTheme.secondary;
      case 'افسانه‌ای':
        return AppTheme.amber;
      default:
        return AppTheme.textMuted;
    }
  }

  LinearGradient get gradient => LinearGradient(
        colors: colors,
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      );
}

const List<AvatarItem> kAvatars = [
  AvatarItem(
      id: 'student',
      name: 'دانش‌آموز',
      subtitle: 'شروع راه',
      icon: Icons.school_rounded,
      colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
      price: 0,
      rarity: 'عادی'),
  AvatarItem(
      id: 'book_lover',
      name: 'کتاب‌دوست',
      subtitle: 'همیشه در حال خواندن',
      icon: Icons.menu_book_rounded,
      colors: [Color(0xFF0EA5E9), Color(0xFF0369A1)],
      price: 0,
      rarity: 'عادی'),
  AvatarItem(
      id: 'pen_master',
      name: 'قلم‌به‌دست',
      subtitle: 'نویسنده‌ی جوان',
      icon: Icons.create_rounded,
      colors: [Color(0xFF10B981), Color(0xFF047857)],
      price: 120,
      rarity: 'عادی'),
  AvatarItem(
      id: 'owl',
      name: 'جغد دانا',
      subtitle: 'شب‌ها درس می‌خواند',
      icon: Icons.nightlight_round,
      colors: [Color(0xFF6366F1), Color(0xFF312E81)],
      price: 180,
      rarity: 'عادی'),
  AvatarItem(
      id: 'star_writer',
      name: 'ستاره‌ی انشا',
      subtitle: 'بهترین انشای کلاس',
      icon: Icons.star_rounded,
      colors: [Color(0xFFF59E0B), Color(0xFFB45309)],
      price: 250,
      rarity: 'کمیاب',
      minLevel: 2),
  AvatarItem(
      id: 'rakhsh',
      name: 'رخش',
      subtitle: 'اسب رستم',
      icon: Icons.bolt_rounded,
      colors: [Color(0xFFEF4444), Color(0xFF991B1B)],
      price: 320,
      rarity: 'کمیاب',
      minLevel: 2),
  AvatarItem(
      id: 'falcon',
      name: 'شاهین',
      subtitle: 'تیزبین و سریع',
      icon: Icons.flight_rounded,
      colors: [Color(0xFF0EA5E9), Color(0xFF164E63)],
      price: 380,
      rarity: 'کمیاب',
      minLevel: 3),
  AvatarItem(
      id: 'poet',
      name: 'شاعر',
      subtitle: 'هم‌سخن حافظ',
      icon: Icons.format_quote_rounded,
      colors: [Color(0xFFEC4899), Color(0xFF9D174D)],
      price: 450,
      rarity: 'کمیاب',
      minLevel: 3),
  AvatarItem(
      id: 'explorer',
      name: 'جهانگرد',
      subtitle: 'کاشف واژه‌ها',
      icon: Icons.explore_rounded,
      colors: [Color(0xFF14B8A6), Color(0xFF115E59)],
      price: 520,
      rarity: 'کمیاب',
      minLevel: 4),
  AvatarItem(
      id: 'shield',
      name: 'سپردار',
      subtitle: 'نگهبان زبان فارسی',
      icon: Icons.shield_rounded,
      colors: [Color(0xFF64748B), Color(0xFF1E293B)],
      price: 650,
      rarity: 'حماسی',
      minLevel: 5),
  AvatarItem(
      id: 'lion',
      name: 'شیر دلیر',
      subtitle: 'بی‌ترس در آزمون',
      icon: Icons.pets_rounded,
      colors: [Color(0xFFF97316), Color(0xFF9A3412)],
      price: 750,
      rarity: 'حماسی',
      minLevel: 5),
  AvatarItem(
      id: 'simorgh',
      name: 'سیمرغ',
      subtitle: 'پرنده‌ی افسانه‌ای',
      icon: Icons.auto_awesome_rounded,
      colors: [Color(0xFF8B5CF6), Color(0xFF4C1D95)],
      price: 900,
      rarity: 'حماسی',
      minLevel: 6),
  AvatarItem(
      id: 'astronomer',
      name: 'ستاره‌شناس',
      subtitle: 'مثل خیام',
      icon: Icons.nights_stay_rounded,
      colors: [Color(0xFF1D4ED8), Color(0xFF0B1120)],
      price: 1000,
      rarity: 'حماسی',
      minLevel: 7),
  AvatarItem(
      id: 'calligrapher',
      name: 'خوشنویس',
      subtitle: 'استاد نستعلیق',
      icon: Icons.brush_rounded,
      colors: [Color(0xFF0D9488), Color(0xFF134E4A)],
      price: 1200,
      rarity: 'حماسی',
      minLevel: 8),
  AvatarItem(
      id: 'dictionary',
      name: 'لغت‌نامه',
      subtitle: 'گنجینه‌ی واژه‌ها',
      icon: Icons.library_books_rounded,
      colors: [Color(0xFFB45309), Color(0xFF78350F)],
      price: 1400,
      rarity: 'افسانه‌ای',
      minLevel: 9),
  AvatarItem(
      id: 'crown',
      name: 'تاج ادب',
      subtitle: 'برترین کلاس',
      icon: Icons.workspace_premium_rounded,
      colors: [Color(0xFFFBBF24), Color(0xFFB45309)],
      price: 1800,
      rarity: 'افسانه‌ای',
      minLevel: 10),
  AvatarItem(
      id: 'phoenix',
      name: 'ققنوس',
      subtitle: 'از خاکستر برمی‌خیزد',
      icon: Icons.local_fire_department_rounded,
      colors: [Color(0xFFF43F5E), Color(0xFF7F1D1D)],
      price: 2200,
      rarity: 'افسانه‌ای',
      minLevel: 12),
  AvatarItem(
      id: 'galaxy',
      name: 'کهکشان',
      subtitle: 'نادرترین آواتار بازی',
      icon: Icons.blur_on_rounded,
      colors: [Color(0xFF7C3AED), Color(0xFF0B1120)],
      price: 3000,
      rarity: 'افسانه‌ای',
      minLevel: 15),
];

AvatarItem avatarById(String id) =>
    kAvatars.firstWhere((a) => a.id == id, orElse: () => kAvatars.first);

/// دایره‌ی آواتار. اگر avatarId ندهی، آواتار فعلی کاربر را زنده نشان می‌دهد.
class AvatarCircle extends StatelessWidget {
  final String? avatarId;
  final double size;
  final bool showRing;

  const AvatarCircle(
      {super.key, this.avatarId, this.size = 48, this.showRing = true});

  @override
  Widget build(BuildContext context) {
    if (avatarId == null) {
      return ValueListenableBuilder<String>(
        valueListenable: GameState.avatarId,
        builder: (context, id, _) => _circle(avatarById(id)),
      );
    }
    return _circle(avatarById(avatarId!));
  }

  Widget _circle(AvatarItem item) {
    final inner = Container(
      width: size,
      height: size,
      decoration:
          BoxDecoration(shape: BoxShape.circle, gradient: item.gradient),
      child: Icon(item.icon, color: Colors.white, size: size * 0.5),
    );

    if (!showRing) return inner;

    return Container(
      padding: const EdgeInsets.all(2.4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [item.rarityColor, item.rarityColor.withOpacity(0.35)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration:
            const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
        child: inner,
      ),
    );
  }
}
