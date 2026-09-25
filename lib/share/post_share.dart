import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../core/app_theme.dart';
import '../core/color_utils.dart';
import '../core/data_loader.dart';
import '../core/game_state.dart';
import '../widgets/vector_banner.dart';

/// تبدیل پست به یک عکس (بنر + متن + کامنت‌ها + واترمارک) و ارسال به شبکه‌های اجتماعی
class PostShareService {
  PostShareService._();

  static const String appName = 'پارسی‌گرام ششم';
  static const String creator = 'حمیدرضا علی میرزائی';

  static int postId(Map<String, dynamic> post) {
    final id = post['id'];
    if (id is num) return id.toInt();
    return int.tryParse('$id') ?? 0;
  }

  /// کامنت‌های فایل JSON + کامنت‌های خود کاربر (ذخیره‌شده روی گوشی)
  static List<Map<String, dynamic>> mergedComments(Map<String, dynamic> post) {
    final out = <Map<String, dynamic>>[];

    if (post['comments'] is List) {
      for (final c in post['comments'] as List) {
        if (c is Map) out.add(Map<String, dynamic>.from(c));
      }
    }
    out.sort((a, b) {
      final ap = a['is_pinned'] == true ? 0 : 1;
      final bp = b['is_pinned'] == true ? 0 : 1;
      return ap.compareTo(bp);
    });

    final mine = GameState.prefs.getStringList('my_comments_${postId(post)}') ??
        <String>[];
    for (final text in mine) {
      out.add({
        'user_handle': '@${GameState.userName.value}',
        'name':
            GameState.userName.value.isEmpty ? 'من' : GameState.userName.value,
        'avatar_color': '0xFF7C3AED',
        'is_pinned': false,
        'text': text,
      });
    }
    return out;
  }

  static String captionFor(Map<String, dynamic> post) {
    final lesson = TextClean.clean(post['lesson_title']);
    return '$lesson\nاز اپ $appName · ساخته‌ی $creator';
  }

  /// باز کردن پیش‌نمایش عکس پیش از ارسال
  static Future<void> sharePost(
      BuildContext context, Map<String, dynamic> post) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SharePreviewSheet(post: post),
    );
  }

  /// رندر کردن کارت پست به عکس PNG
  static Future<Uint8List> renderPoster({
    required BuildContext context,
    required Map<String, dynamic> post,
  }) {
    final controller = ScreenshotController();
    return controller.captureFromWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: Theme(
          data: AppTheme.light(),
          child: Material(
            color: Colors.white,
            child: SharePosterCard(post: post, comments: mergedComments(post)),
          ),
        ),
      ),
      context: context,
      pixelRatio: 3,
      delay: const Duration(milliseconds: 140),
    );
  }

  /// ذخیره‌ی موقت عکس و باز کردن منوی اشتراک‌گذاری گوشی
  static Future<void> shareBytes(Uint8List bytes, {String text = ''}) async {
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/parsigram_${DateTime.now().millisecondsSinceEpoch}.png';
    final file = File(path);
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(path, mimeType: 'image/png')],
      text: text,
      subject: appName,
    );
  }
}

class _SharePreviewSheet extends StatefulWidget {
  final Map<String, dynamic> post;
  const _SharePreviewSheet({required this.post});

  @override
  State<_SharePreviewSheet> createState() => _SharePreviewSheetState();
}

class _SharePreviewSheetState extends State<_SharePreviewSheet> {
  bool _busy = false;

  Future<void> _share() async {
    setState(() => _busy = true);
    try {
      final bytes = await PostShareService.renderPoster(
          context: context, post: widget.post);
      await PostShareService.shareBytes(bytes,
          text: PostShareService.captionFor(widget.post));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ارسال عکس انجام نشد: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.border,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 12),
          const Text('اشتراک پست به صورت عکس',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
          const SizedBox(height: 4),
          const Text('بنر، متن پست و کامنت‌ها در یک تصویر با نشان اپ',
              style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted)),
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5),
            child: SingleChildScrollView(
              child: FittedBox(
                child: SharePosterCard(
                  post: widget.post,
                  comments: PostShareService.mergedComments(widget.post),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _busy ? null : _share,
              icon: _busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.ios_share_rounded, size: 18),
              label: Text(_busy ? 'در حال ساخت عکس…' : 'ارسال عکس',
                  style: const TextStyle(fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }
}

/// کارتی که به عکس تبدیل می‌شود (عرض ثابت ۴۰۰)
class SharePosterCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final List<Map<String, dynamic>> comments;

  const SharePosterCard(
      {super.key, required this.post, required this.comments});

  @override
  Widget build(BuildContext context) {
    final banner = (post['banner'] is Map)
        ? Map<String, dynamic>.from(post['banner'] as Map)
        : <String, dynamic>{};
    final authorColor = parseColor(post['avatar_color']);
    final caption = TextClean.clean(post['caption']);
    final tip = TextClean.clean(post['educational_tip']);
    final likes = (post['likes_base'] as num?)?.toInt() ?? 0;
    final shown = comments.take(4).toList();

    return Container(
      width: 400,
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // هدر برند
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(gradient: AppTheme.brandGradient),
            child: Row(
              children: [
                const Icon(Icons.auto_stories_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 8),
                const Text(
                  PostShareService.appName,
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13.5),
                ),
                const Spacer(),
                Text(
                  TextClean.clean(post['lesson_title']),
                  style: const TextStyle(color: Colors.white70, fontSize: 10.5),
                ),
              ],
            ),
          ),

          // نویسنده
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [authorColor, authorColor.withOpacity(0.6)],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                  ),
                  child: Icon(AppIcons.byName(post['avatar_icon']),
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(TextClean.clean(post['author_name']),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 12.5)),
                      Text(TextClean.clean(post['author_handle']),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 10.5, color: AppTheme.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          VectorCodeBanner(banner: banner, height: 210, forPoster: true),

          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Row(
              children: [
                const Icon(Icons.favorite_rounded,
                    size: 15, color: AppTheme.red),
                const SizedBox(width: 4),
                Text(faGroup(likes), style: const TextStyle(fontSize: 11.5)),
                const SizedBox(width: 12),
                const Icon(Icons.mode_comment_rounded,
                    size: 14, color: AppTheme.textMuted),
                const SizedBox(width: 4),
                Text(faNum(comments.length),
                    style: const TextStyle(fontSize: 11.5)),
              ],
            ),
          ),

          if (caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: Text(caption,
                  style: const TextStyle(fontSize: 11.8, height: 2.05)),
            ),

          if (tip.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.amber.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('💡 $tip',
                  style: const TextStyle(
                      fontSize: 10.8, height: 1.95, color: Color(0xFF7C4A03))),
            ),

          if (shown.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(14, 12, 14, 4),
              child: Text('کامنت‌ها',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textMuted)),
            ),
            ...shown.map(
              (c) => Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: parseColor(c['avatar_color'],
                                fallback: AppTheme.blue)
                            .withOpacity(0.18),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        TextClean.clean(c['name'])
                            .characters
                            .take(1)
                            .toString(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: parseColor(c['avatar_color'],
                              fallback: AppTheme.blue),
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                              fontSize: 10.8,
                              height: 1.9,
                              color: AppTheme.textDark,
                              fontFamily: 'Vazir'),
                          children: [
                            TextSpan(
                                text: '${TextClean.clean(c['name'])}: ',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900)),
                            TextSpan(text: TextClean.clean(c['text'])),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),

          // واترمارک و نام سازنده
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(gradient: AppTheme.nightGradient),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.school_rounded,
                      color: Colors.white, size: 15),
                ),
                const SizedBox(width: 9),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(PostShareService.appName,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900)),
                    Text('سازنده: ${PostShareService.creator}',
                        style: TextStyle(color: Colors.white60, fontSize: 9.5)),
                  ],
                ),
                const Spacer(),
                const Text('فارسی ششم ابتدایی',
                    style: TextStyle(color: Colors.white38, fontSize: 9.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
