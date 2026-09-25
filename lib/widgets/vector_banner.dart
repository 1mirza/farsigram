import 'dart:math';

import 'package:flutter/material.dart';

import '../core/color_utils.dart';
import '../core/data_loader.dart';

/// بنر تصویری پست که فقط با کد کشیده می‌شود (بدون فایل عکس)
class VectorCodeBanner extends StatelessWidget {
  final Map<String, dynamic> banner;
  final double height;
  final bool forPoster;

  const VectorCodeBanner({
    super.key,
    required this.banner,
    this.height = 220,
    this.forPoster = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = parseGradient(banner['gradient']);
    final icon = AppIcons.byName(banner['icon']);
    final title = TextClean.clean(banner['title']);
    final quote = TextClean.clean(banner['quote']);
    final pattern = TextClean.clean(banner['pattern']).toLowerCase();

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
            ),
          ),
          CustomPaint(painter: ProceduralPatternPainter(pattern: pattern)),
          Padding(
            padding: EdgeInsets.all(forPoster ? 18 : 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 1.4),
                  ),
                  child: Icon(icon,
                      color: Colors.white, size: forPoster ? 26 : 30),
                ),
                const SizedBox(height: 12),
                if (title.isNotEmpty)
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: forPoster ? 16 : 17.5,
                      height: 1.9,
                      fontWeight: FontWeight.w900,
                      shadows: const [
                        Shadow(color: Color(0x66000000), blurRadius: 8)
                      ],
                    ),
                  ),
                if (quote.isNotEmpty) ...[
                  const SizedBox(height: 9),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      quote,
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        fontSize: forPoster ? 11.5 : 12.5,
                        height: 2,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// طرح‌های پس‌زمینه‌ی بنر (از فیلد pattern در JSON خوانده می‌شود)
class ProceduralPatternPainter extends CustomPainter {
  final String pattern;
  const ProceduralPatternPainter({required this.pattern});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.13)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final fill = Paint()..color = Colors.white.withOpacity(0.10);

    if (pattern.contains('line') || pattern.contains('stripe')) {
      for (var x = -size.height; x < size.width; x += 22) {
        canvas.drawLine(
            Offset(x, size.height), Offset(x + size.height, 0), paint);
      }
      return;
    }

    if (pattern.contains('dot') || pattern.contains('bubble')) {
      for (var y = 14.0; y < size.height; y += 26) {
        for (var x = 14.0; x < size.width; x += 26) {
          canvas.drawCircle(Offset(x, y), 3.2, fill);
        }
      }
      return;
    }

    if (pattern.contains('wave')) {
      for (var i = 0; i < 5; i++) {
        final path = Path();
        final base = size.height * (0.2 + i * 0.17);
        path.moveTo(0, base);
        for (var x = 0.0; x <= size.width; x += 12) {
          path.lineTo(x, base + sin(x / 26 + i) * 9);
        }
        canvas.drawPath(path, paint);
      }
      return;
    }

    if (pattern.contains('grid') || pattern.contains('square')) {
      for (var x = 0.0; x < size.width; x += 30) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      }
      for (var y = 0.0; y < size.height; y += 30) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
      return;
    }

    if (pattern.contains('star')) {
      final rnd = Random(7);
      for (var i = 0; i < 46; i++) {
        final dx = rnd.nextDouble() * size.width;
        final dy = rnd.nextDouble() * size.height;
        canvas.drawCircle(Offset(dx, dy), rnd.nextDouble() * 2.2 + 0.8, fill);
      }
      return;
    }

    // پیش‌فرض: کمان‌های اسلیمی
    for (var i = 1; i <= 5; i++) {
      canvas.drawCircle(
        Offset(size.width * 0.86, size.height * 0.18),
        i * 26.0,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ProceduralPatternPainter oldDelegate) =>
      oldDelegate.pattern != pattern;
}
