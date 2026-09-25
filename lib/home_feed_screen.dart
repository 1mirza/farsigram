import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models_and_state.dart';
import 'story_challenge_screen.dart';

class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen> {
  int _navIndex = 0;
  List<dynamic> posts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    final loaded =
        await AssetDataLoader.loadJsonList('assets/data/posts_feed.json');
    if (mounted) {
      setState(() {
        posts = loaded;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: IndexedStack(
          index: _navIndex,
          children: [
            _buildMainFeedTab(),
            const DirectInboxScreen(),
            const LeaderboardTabScreen(),
            _buildProfileTab(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
        selectedItemColor: const Color(0xFF7C3AED),
        unselectedItemColor: const Color(0xFF94A3B8),
        showSelectedLabels: true,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded), label: "خانه"),
          BottomNavigationBarItem(
              icon: Icon(Icons.mark_chat_unread_rounded),
              label: "دایرکت مفاخر"),
          BottomNavigationBarItem(
              icon: Icon(Icons.leaderboard_rounded), label: "لیگ برتر"),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded), label: "پروفایل من"),
        ],
      ),
    );
  }

  Widget _buildMainFeedTab() {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    final filteredPosts = posts.where((p) {
      final lessonId = p['lesson_id'] as int? ?? 1;
      return lessonId <= GameState.activeLessonLimit.value;
    }).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // کارت کنترل کاربر، سکه و انتخاب درس
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // نام کاربر با قابلیت کلیک برای تغییر
                    InkWell(
                      onTap: _showEditNameDialog,
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 18,
                            backgroundColor: Color(0xFF7C3AED),
                            child: Icon(Icons.person,
                                color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 8),
                          ValueListenableBuilder<String>(
                            valueListenable: GameState.userName,
                            builder: (context, name, _) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 14)),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.edit,
                                        size: 14, color: Colors.grey),
                                  ],
                                ),
                                const Text("دانش‌آموز ششم",
                                    style: TextStyle(
                                        fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // نمایش سکه‌ها
                    ValueListenableBuilder<int>(
                      valueListenable: GameState.coins,
                      builder: (context, coins, _) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFF59E0B)),
                        ),
                        child: Row(
                          children: [
                            Text("$coins",
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFFB45309))),
                            const SizedBox(width: 4),
                            const Icon(Icons.monetization_on_rounded,
                                color: Color(0xFFF59E0B), size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),

                // دکمه بزرگ و صریح انتخاب درس فعال
                InkWell(
                  onTap: _showLessonFilterDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.menu_book_rounded,
                                color: Color(0xFF7C3AED)),
                            const SizedBox(width: 8),
                            ValueListenableBuilder<int>(
                              valueListenable: GameState.activeLessonLimit,
                              builder: (context, limit, _) => Text(
                                "محدوده آزمون: تا درس $limit کتاب",
                                style: const TextStyle(
                                    color: Color(0xFF6D28D9),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C3AED),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text("تغییر درس",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ردیف استوری‌ها با اسکرول نرم
          _buildStorySection(),

          // فید پست‌ها
          if (filteredPosts.isEmpty)
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: const Text(
                "پستی در محدوده این درس‌ها یافت نشد.\nاز دکمه بالا «تغییر درس» را بزنید و عدد بالاتری انتخاب کنید.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF64748B), height: 1.6),
              ),
            )
          else
            ...filteredPosts
                .map((p) => PostCardItem(post: p as Map<String, dynamic>)),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStorySection() {
    final stories = [
      {
        "title": "معنی واژگان",
        "file": "vocabulary.json",
        "icon": Icons.translate_rounded,
        "color": const Color(0xFF06B6D4)
      },
      {
        "title": "متضادها",
        "file": "antonyms.json",
        "icon": Icons.swap_horiz_rounded,
        "color": const Color(0xFFEC4899)
      },
      {
        "title": "هم‌خانواده",
        "file": "synonyms_roots.json",
        "icon": Icons.hub_rounded,
        "color": const Color(0xFF10B981)
      },
      {
        "title": "املای کلمات",
        "file": "spelling_challenges.json",
        "icon": Icons.spellcheck_rounded,
        "color": const Color(0xFF7C3AED)
      },
      {
        "title": "دستور زبان",
        "file": "grammar_language.json",
        "icon": Icons.rule_rounded,
        "color": const Color(0xFFF59E0B)
      },
      {
        "title": "دانش ادبی",
        "file": "literature_arts.json",
        "icon": Icons.auto_awesome_rounded,
        "color": const Color(0xFF8B5CF6)
      },
      {
        "title": "ضرب‌المثل",
        "file": "proverbs_wisdom.json",
        "icon": Icons.lightbulb_rounded,
        "color": const Color(0xFFEF4444)
      },
      {
        "title": "حفظ شعر",
        "file": "poetry_verses.json",
        "icon": Icons.format_quote_rounded,
        "color": const Color(0xFF14B8A6)
      },
    ];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: stories.length,
        itemBuilder: (context, i) {
          final s = stories[i];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StoryChallengeScreen(
                    categoryTitle: s['title'] as String,
                    jsonFileName: s['file'] as String,
                    accentColor: s['color'] as Color,
                  ),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        (s['color'] as Color),
                        (s['color'] as Color).withOpacity(0.4)
                      ]),
                      shape: BoxShape.circle,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle),
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor:
                            (s['color'] as Color).withOpacity(0.12),
                        child: Icon(s['icon'] as IconData,
                            color: s['color'] as Color, size: 26),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(s['title'] as String,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B))),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showLessonFilterDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("انتخاب درس فعال (۱ تا ۱۷):",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            const Text("تنها سوالات دروسی که خوانده‌اید نمایش داده می‌شود.",
                style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 14),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2.2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: 17,
                itemBuilder: (context, idx) {
                  final lNum = idx + 1;
                  final isSel = GameState.activeLessonLimit.value == lNum;
                  return InkWell(
                    onTap: () {
                      GameState.setActiveLessonLimit(lNum);
                      setState(() {});
                      Navigator.pop(context);
                    },
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSel
                            ? const Color(0xFF7C3AED)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "درس $lNum",
                        style: TextStyle(
                            color:
                                isSel ? Colors.white : const Color(0xFF334155),
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditNameDialog() {
    final c = TextEditingController(text: GameState.userName.value);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("تغییر نام کاربری"),
        content: TextField(
            controller: c,
            decoration: const InputDecoration(labelText: "نام شما")),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("انصراف")),
          ElevatedButton(
            onPressed: () {
              if (c.text.trim().isNotEmpty) {
                GameState.setUserName(c.text.trim());
              }
              Navigator.pop(context);
            },
            child: const Text("ذخیره"),
          )
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFFEC4899)]),
                ),
                child: const CircleAvatar(
                  radius: 46,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.school_rounded,
                      size: 50, color: Color(0xFF7C3AED)),
                ),
              ),
              const SizedBox(height: 12),
              ValueListenableBuilder<String>(
                valueListenable: GameState.userName,
                builder: (context, name, _) => Text(name,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w900)),
              ),
              const Text("دانش‌آموز پایه ششم ابتدایی",
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.edit, size: 16),
                label: const Text("ویرایش نام کاربری"),
                onPressed: _showEditNameDialog,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ValueListenableBuilder<Set<int>>(
              valueListenable: GameState.savedPosts,
              builder: (context, s, _) =>
                  _profileStatBox("پست نشان‌شده", "${s.length}"),
            ),
            ValueListenableBuilder<int>(
              valueListenable: GameState.coins,
              builder: (context, c, _) => _profileStatBox("سکه طلایی", "$c 🪙"),
            ),
          ],
        ),
        const SizedBox(height: 24),
        ListTile(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          tileColor: Colors.white,
          leading: const Icon(Icons.bookmark_rounded, color: Color(0xFF7C3AED)),
          title: const Text("مشاهده پست‌های نشان‌شده (شب امتحان)",
              style: TextStyle(fontWeight: FontWeight.bold)),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => SavedPostsScreen(allPosts: posts)),
            );
          },
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("شناسنامه طراح اپلیکیشن",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Divider(height: 20),
              Text("طراح و توسعه‌دهنده: حمیدرضا علی میرزائی",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7C3AED),
                      fontSize: 14)),
              SizedBox(height: 6),
              Text("اپلیکیشن آموزشی دوکتابه (فارسی و نگارش پایه ششم)",
                  style: TextStyle(fontSize: 12, color: Color(0xFF475569))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _profileStatBox(String title, String val) {
    return Container(
      width: 140,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Text(val,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF7C3AED))),
          const SizedBox(height: 4),
          Text(title,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        ],
      ),
    );
  }
}

class SavedPostsScreen extends StatelessWidget {
  final List<dynamic> allPosts;
  const SavedPostsScreen({super.key, required this.allPosts});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
          title: const Text("پست‌های نشان‌شده"), backgroundColor: Colors.white),
      body: ValueListenableBuilder<Set<int>>(
        valueListenable: GameState.savedPosts,
        builder: (context, saved, _) {
          final savedList =
              allPosts.where((p) => saved.contains(p['id'])).toList();
          if (savedList.isEmpty) {
            return const Center(child: Text("هیچ پستی نشان نشده است!"));
          }
          return ListView.builder(
            itemCount: savedList.length,
            itemBuilder: (context, i) =>
                PostCardItem(post: savedList[i] as Map<String, dynamic>),
          );
        },
      ),
    );
  }
}

class PostCardItem extends StatelessWidget {
  final Map<String, dynamic> post;
  const PostCardItem({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final banner = post['banner'] as Map<String, dynamic>;
    final postId = post['id'] as int;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      Color(post['avatar_color'] as int? ?? 0xFF7C3AED),
                  child: const Icon(Icons.bolt_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 8),
                Text(post['author_name'] as String,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                const Spacer(),
                Text(post['lesson_title'] as String,
                    style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF7C3AED),
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: (banner['gradient'] as List<dynamic>)
                    .map((c) => Color(c as int))
                    .toList(),
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(banner['title'] as String,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 8),
                Text(
                  banner['quote'] as String,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post['caption'] as String,
                    style: const TextStyle(fontSize: 13, height: 1.5)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10)),
                  child: Text(post['educational_tip'] as String,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF334155))),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Row(
              children: [
                ValueListenableBuilder<Set<int>>(
                  valueListenable: GameState.likedPosts,
                  builder: (context, likes, _) {
                    final isLiked = likes.contains(postId);
                    return Row(
                      children: [
                        IconButton(
                          icon: Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: isLiked ? Colors.red : Colors.grey),
                          onPressed: () => GameState.toggleLike(postId),
                        ),
                        Text("${post['likes_base'] + (isLiked ? 1 : 0)}",
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.share_outlined, color: Colors.grey),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(
                        text:
                            "${post['author_name']}:\n${post['caption']}\n\nنکته: ${post['educational_tip']}"));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text(
                            "متن پست کپی شد! می‌توانید در شاد یا ایتا ارسال کنید.")));
                  },
                ),
                const Spacer(),
                ValueListenableBuilder<Set<int>>(
                  valueListenable: GameState.savedPosts,
                  builder: (context, saved, _) {
                    final isSaved = saved.contains(postId);
                    return IconButton(
                      icon: Icon(
                          isSaved ? Icons.bookmark : Icons.bookmark_border,
                          color:
                              isSaved ? const Color(0xFF7C3AED) : Colors.grey),
                      onPressed: () => GameState.toggleSave(postId),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DirectInboxScreen extends StatefulWidget {
  const DirectInboxScreen({super.key});

  @override
  State<DirectInboxScreen> createState() => _DirectInboxScreenState();
}

class _DirectInboxScreenState extends State<DirectInboxScreen> {
  List<dynamic> characters = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadBios();
  }

  Future<void> _loadBios() async {
    final list =
        await AssetDataLoader.loadJsonList('assets/data/biographies.json');
    if (mounted) {
      setState(() {
        characters = list;
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: characters.length,
      itemBuilder: (context, i) {
        final c = characters[i];
        return Card(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Color(c['avatar_color'] as int? ?? 0xFF7C3AED),
              child: const Icon(Icons.person, color: Colors.white),
            ),
            title: Text(c['name'] as String,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(c['title'] as String,
                style: const TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.chat_bubble_outline_rounded,
                color: Color(0xFF7C3AED)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SingleChatRoom(character: c)),
              );
            },
          ),
        );
      },
    );
  }
}

class SingleChatRoom extends StatefulWidget {
  final Map<String, dynamic> character;
  const SingleChatRoom({super.key, required this.character});

  @override
  State<SingleChatRoom> createState() => _SingleChatRoomState();
}

class _SingleChatRoomState extends State<SingleChatRoom> {
  final List<Map<String, String>> chatHistory = [];

  @override
  void initState() {
    super.initState();
    final tree = widget.character['dialogue_tree'] as List<dynamic>?;
    if (tree != null && tree.isNotEmpty) {
      chatHistory.add({
        "sender": widget.character['name'],
        "text": tree[0]['character_msg']
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tree = widget.character['dialogue_tree'] as List<dynamic>?;
    final replies = tree != null && tree.isNotEmpty
        ? (tree[0]['quick_replies'] as List<dynamic>)
        : [];

    return Scaffold(
      appBar: AppBar(
          title: Text("گفت‌وگو با ${widget.character['name']}"),
          backgroundColor: Colors.white),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: chatHistory.length,
              itemBuilder: (context, idx) {
                final isMe = chatHistory[idx]['sender'] == "شما";
                return Align(
                  alignment:
                      isMe ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMe ? const Color(0xFF7C3AED) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      chatHistory[idx]['text']!,
                      style: TextStyle(
                          color: isMe ? Colors.white : Colors.black,
                          height: 1.5),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Wrap(
              spacing: 8,
              children: replies.map((r) {
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF1F5F9),
                    foregroundColor: const Color(0xFF1E293B),
                  ),
                  onPressed: () {
                    setState(() {
                      chatHistory.add({"sender": "شما", "text": r['text']});
                      chatHistory.add({
                        "sender": widget.character['name'],
                        "text": r['reply']
                      });
                    });
                    if (r['reward'] != null) {
                      GameState.addCoins(r['reward'] as int);
                    }
                  },
                  child: Text(r['text']),
                );
              }).toList(),
            ),
          )
        ],
      ),
    );
  }
}

class LeaderboardTabScreen extends StatelessWidget {
  const LeaderboardTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> students = List.generate(100, (i) {
      final cities = [
        "تهران",
        "مشهد",
        "شیراز",
        "اصفهان",
        "تبریز",
        "اهواز",
        "رشت",
        "کرمان"
      ];
      final names = [
        "امیرعلی",
        "فاطمه",
        "محمدحسین",
        "زهرا",
        "یاسین",
        "مائده",
        "علی‌رضا",
        "هلیا",
        "پارسا",
        "نازنین"
      ];
      final rank = i + 1;
      final score = 3200 - (i * 25);
      return {
        "rank": rank,
        "name": "${names[i % names.length]} (${cities[i % cities.length]})",
        "score": score,
      };
    });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: students.length,
      itemBuilder: (context, idx) {
        final s = students[idx];
        String medal = "${s['rank']}";
        if (s['rank'] == 1) medal = "🥇";
        if (s['rank'] == 2) medal = "🥈";
        if (s['rank'] == 3) medal = "🥉";

        return Card(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: SizedBox(
                width: 36,
                child: Text(medal,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold))),
            title: Text(s['name'] as String,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            trailing: Text("${s['score']} امتیاز",
                style: const TextStyle(
                    fontWeight: FontWeight.w900, color: Color(0xFF7C3AED))),
          ),
        );
      },
    );
  }
}
