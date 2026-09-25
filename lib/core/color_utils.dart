import 'package:flutter/material.dart';

import 'app_theme.dart';

/// تبدیل مقدار رنگ در JSON (عدد، 0xFF… یا #…) به Color
Color parseColor(Object? value, {Color fallback = AppTheme.primary}) {
  if (value == null) return fallback;
  if (value is Color) return value;
  if (value is num) return Color(value.toInt() | 0xFF000000);

  var text = value.toString().trim();
  if (text.isEmpty) return fallback;
  text = text.replaceAll('#', '').replaceAll('0x', '').replaceAll('0X', '');

  if (text.length == 6) text = 'FF$text';
  final parsed = int.tryParse(text, radix: 16);
  if (parsed != null) return Color(parsed | 0xFF000000);

  final decimal = int.tryParse(text);
  if (decimal != null) return Color(decimal | 0xFF000000);

  return fallback;
}

/// گرادیان بنر پست
List<Color> parseGradient(Object? value) {
  if (value is List && value.isNotEmpty) {
    final colors = value.map((e) => parseColor(e)).toList();
    if (colors.length == 1) return [colors.first, _shade(colors.first)];
    return colors;
  }

  if (value is String && value.contains(',')) {
    final colors = value
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .map((e) => parseColor(e))
        .toList();
    if (colors.length >= 2) return colors;
    if (colors.length == 1) return [colors.first, _shade(colors.first)];
  }

  if (value != null) {
    final single = parseColor(value, fallback: AppTheme.primary);
    return [single, _shade(single)];
  }

  return const [AppTheme.primary, AppTheme.secondary];
}

Color _shade(Color color) {
  final hsl = HSLColor.fromColor(color);
  return hsl.withLightness((hsl.lightness * 0.72).clamp(0.0, 1.0)).toColor();
}
