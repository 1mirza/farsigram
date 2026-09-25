import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/color_utils.dart';
import '../core/data_loader.dart';
import '../core/game_state.dart';
import '../share/post_share.dart';
import 'vector_banner.dart';

/// کارت پست فید: لایک (دابل‌تپ)، ذخیره‌ی واقعی، کامنت و اشتراک عکسی
class PostCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final VoidCallback? onChanged;

  const PostCard({super.key, required this.post, this.onChanged});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _heart = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );
  bool _expanded = false;

  @override
  void dispose() {
    _heart.dispose();
    super.dispose();
  }

  int get _id => PostShareService.postId(widget.post);

  Future<void> _like({bool fromDoubleTap = false}) async {
    final wasLiked = GameState.likedPosts.value.contains(_id);
    if (fromDoubleTap && wasLiked) {
      _heart.forward(from: 0);
      return;
    }
    await GameState.toggleLike(_id);
    if (!wasLiked) _heart.forward(from: 0);
    widget.onChanged?.call();
  }

  Future<void> _save() async {
    await GameState.toggleSave(_id);
    if (!mounted) return;
    final saved = GameState.savedPosts.value.contains(_id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            saved ? 'در ذخیره‌شده‌ها ذخیره شد 🔖' : 'از ذخیره‌شده‌ها حذف شد'),
        duration: const Duration(milliseconds: 1400),
      ),
    );
    widget.onChanged?.call();
  }

  void _openComments() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _CommentsSheet(post: widget.post, onChanged: () => setState(() {})),
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final banner = (post['banner'] is Map)
        ? Map<String, dynamic>.from(post['banner'] as Map)
        : <String, dynamic>{};
    final authorColor = parseColor(post['avatar_color']);
    final caption = TextClean.clean(post['caption']);
    final tip = TextClean.clean(post['educational_tip']);
    final comments = PostShareService.mergedComments(post);
    final likesBase = (post['likes_base'] as num?)?.toInt() ?? 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppTheme.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // سربرگ نویسنده
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [authorColor, authorColor.withOpacity(0.6)],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                  ),
                  child: Icon(AppIcons.byName(post['avatar_icon']),
                      color: Colors.white, size: 21),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              TextClean.clean(post['author_name']),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900, fontSize: 13.5),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.verified_rounded,
                              size: 14, color: AppTheme.blue),
                        ],
                      ),
                      Text(
                        '${TextClean.clean(post['author_handle'])} · ${TextClean.clean(post['lesson_title'])}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                if (TextClean.clean(post['badge']).isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: AppTheme.goldGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      TextClean.clean(post['badge']),
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF92400E)),
                    ),
                  ),
              ],
            ),
          ),

          // بنر با دابل‌تپ لایک
          GestureDetector(
            onDoubleTap: () => _like(fromDoubleTap: true),
            child: Stack(
              alignment: Alignment.center,
              children: [
                VectorCodeBanner(banner: banner),
                AnimatedBuilder(
                  animation: _heart,
                  builder: (context, _) {
                    final t = _heart.value;
                    if (t == 0) return const SizedBox.shrink();
                    final scale = 0.6 + (t < 0.5 ? t * 1.4 : (1 - t) * 1.4);
                    return Opacity(
                      opacity: (1 - t).clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: scale,
                        child: const Icon(Icons.favorite_rounded,
                            color: Colors.white, size: 92),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // دکمه‌ها
          ValueListenableBuilder<Set<int>>(
            valueListenable: GameState.likedPosts,
            builder: (context, liked, _) {
              final isLiked = liked.contains(_id);
              return Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _like,
                      icon: Icon(
                        isLiked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: isLiked ? AppTheme.red : AppTheme.textDark,
                      ),
                    ),
                    Text(faGroup(likesBase + (isLiked ? 1 : 0)),
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700)),
                    IconButton(
                        onPressed: _openComments,
                        icon: const Icon(Icons.mode_comment_outlined)),
                    Text(faNum(comments.length),
                        style: const TextStyle(fontSize: 12)),
                    IconButton(
                      onPressed: () =>
                          PostShareService.sharePost(context, widget.post),
                      icon: const Icon(Icons.ios_share_rounded),
                      tooltip: 'اشتراک به صورت عکس',
                    ),
                    const Spacer(),
                    ValueListenableBuilder<Set<int>>(
                      valueListenable: GameState.savedPosts,
                      builder: (context, saved, _) => IconButton(
                        onPressed: _save,
                        icon: Icon(
                          saved.contains(_id)
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          color: saved.contains(_id)
                              ? AppTheme.primary
                              : AppTheme.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // متن پست
          if (caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 2, 14, 0),
              child: GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Text(
                  caption,
                  maxLines: _expanded ? null : 3,
                  overflow:
                      _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, height: 2.1),
                ),
              ),
            ),

          // نکته‌ی آموزشی
          if (tip.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.amber.withOpacity(0.10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.amber.withOpacity(0.35)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡', style: TextStyle(fontSize: 15)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(tip,
                        style: const TextStyle(
                            fontSize: 12, height: 2, color: Color(0xFF7C4A03))),
                  ),
                ],
              ),
            ),

          // دو کامنت اول
          if (comments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Column(
                children: comments
                    .take(2)
                    .map((c) => _CommentRow(comment: c))
                    .toList(),
              ),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
            child: GestureDetector(
              onTap: _openComments,
              child: Text(
                comments.isEmpty
                    ? 'اولین نفری باش که کامنت می‌گذارد…'
                    : 'دیدن همه‌ی ${faNum(comments.length)} کامنت',
                style:
                    const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentRow extends StatelessWidget {
  final Map<String, dynamic> comment;
  const _CommentRow({required this.comment});

  @override
  Widget build(BuildContext context) {
    final isPinned = comment['is_pinned'] == true;
    final color = parseColor(comment['avatar_color'], fallback: AppTheme.blue);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: color.withOpacity(0.18),
            child: Text(
              TextClean.clean(comment['name']).characters.take(1).toString(),
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(TextClean.clean(comment['name']),
                        style: const TextStyle(
                            fontSize: 11.5, fontWeight: FontWeight.w900)),
                    if (isPinned) ...[
                      const SizedBox(width: 5),
                      const Icon(Icons.push_pin_rounded,
                          size: 11, color: AppTheme.primary),
                    ],
                  ],
                ),
                Text(TextClean.clean(comment['text']),
                    style: const TextStyle(fontSize: 12, height: 1.95)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// شیت کامنت‌ها — کامنت خود کاربر روی گوشی ذخیره می‌شود
class _CommentsSheet extends StatefulWidget {
  final Map<String, dynamic> post;
  final VoidCallback onChanged;
  const _CommentsSheet({required this.post, required this.onChanged});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final TextEditingController _input = TextEditingController();
  late List<Map<String, dynamic>> _comments =
      PostShareService.mergedComments(widget.post);

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;

    final id = PostShareService.postId(widget.post);
    final key = 'my_comments_$id';
    final mine = GameState.prefs.getStringList(key) ?? <String>[];
    mine.add(text);
    await GameState.prefs.setStringList(key, mine);
    await GameState.addCoins(3);

    _input.clear();
    setState(() => _comments = PostShareService.mergedComments(widget.post));
    widget.onChanged();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('کامنتت ثبت شد · ۳ سکه گرفتی 🪙')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
            Text('کامنت‌ها (${faNum(_comments.length)})',
                style:
                    const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.45,
              ),
              child: SingleChildScrollView(
                child: Column(
                  children:
                      _comments.map((c) => _CommentRow(comment: c)).toList(),
                ),
              ),
            ),
            const Divider(height: 22),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: const InputDecoration(
                      hintText: 'نظرت را بنویس…',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                    onPressed: _send,
                    icon: const Icon(Icons.send_rounded, size: 18)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
