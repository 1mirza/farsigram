import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/data_loader.dart';
import '../core/game_state.dart';
import '../widgets/post_card.dart';

/// پست‌های ذخیره‌شده — از حافظه‌ی گوشی خوانده می‌شوند و قابل مطالعه‌ی مجدد هستند
class SavedPostsScreen extends StatefulWidget {
  const SavedPostsScreen({super.key});

  @override
  State<SavedPostsScreen> createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends State<SavedPostsScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _all = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final raw = await AssetDataLoader.loadJsonList('posts_feed.json');
    if (!mounted) return;
    setState(() {
      _all = raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      _loading = false;
    });
  }

  int _idOf(Map<String, dynamic> post) {
    final id = post['id'];
    return id is num ? id.toInt() : int.tryParse('$id') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('پست‌های ذخیره‌شده',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16.5)),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : ValueListenableBuilder<Set<int>>(
              valueListenable: GameState.savedPosts,
              builder: (context, saved, _) {
                final posts =
                    _all.where((post) => saved.contains(_idOf(post))).toList();

                if (posts.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(30),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.bookmark_border_rounded,
                                size: 40, color: AppTheme.primary),
                          ),
                          const SizedBox(height: 16),
                          const Text('هنوز پستی ذخیره نکرده‌ای',
                              style: TextStyle(
                                  fontWeight: FontWeight.w900, fontSize: 15)),
                          const SizedBox(height: 8),
                          const Text(
                            'در فید، روی آیکون 🔖 هر پست بزن تا برای شب امتحان اینجا بماند.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 12.5,
                                height: 2),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.only(top: 12, bottom: 20),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Text(
                        '${faNum(posts.length)} پست ذخیره‌شده · برای مرور شب امتحان عالی است',
                        style: const TextStyle(
                            color: AppTheme.textMuted, fontSize: 12),
                      ),
                    ),
                    ...posts.map((post) => PostCard(
                          post: post,
                          onChanged: () => setState(() {}),
                        )),
                  ],
                );
              },
            ),
    );
  }
}
