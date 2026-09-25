import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/color_utils.dart';
import '../core/data_loader.dart';
import '../core/game_state.dart';

/// فهرست بزرگان ادب فارسی — از biographies.json
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _people = [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final raw = await AssetDataLoader.loadJsonList('biographies.json');
    if (!mounted) return;
    setState(() {
      _people = raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      _loading = false;
    });
  }

  static String idOf(Map<String, dynamic> person) {
    final id = TextClean.clean(person['id']);
    if (id.isNotEmpty) return id;
    final handle = TextClean.clean(person['handle']);
    return handle.isNotEmpty ? handle : TextClean.clean(person['name']);
  }

  static List<Map<String, dynamic>> treeOf(Map<String, dynamic> person) {
    final raw = person['dialogue_tree'];
    if (raw is! List) return <Map<String, dynamic>>[];
    final list =
        raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    list.sort((a, b) {
      final as = (a['step'] as num?)?.toInt() ?? 0;
      final bs = (b['step'] as num?)?.toInt() ?? 0;
      return as.compareTo(bs);
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primary));
    }

    final people = _people.where((person) {
      if (_query.isEmpty) return true;
      final haystack =
          '${TextClean.clean(person['name'])} ${TextClean.clean(person['title'])} ${TextClean.clean(person['handle'])}';
      return haystack.contains(_query);
    }).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 20),
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(12, 12, 12, 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppTheme.nightGradient,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🗿', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('گفت‌وگو با بزرگان ادب فارسی',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 15)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'هر گفت‌وگو یک ماموریت است: پاسخ درست بده تا سکه و امتیاز بگیری و داستان ادامه پیدا کند.',
                style:
                    TextStyle(color: Colors.white60, fontSize: 11.5, height: 2),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'جستجوی نام شاعر یا نویسنده…',
              prefixIcon: Icon(Icons.search_rounded),
              isDense: true,
            ),
            onChanged: (value) => setState(() => _query = value.trim()),
          ),
        ),
        ...people.map(_personTile),
        if (people.isEmpty)
          const Padding(
            padding: EdgeInsets.all(30),
            child: Text('چنین شخصیتی پیدا نشد.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textMuted)),
          ),
      ],
    );
  }

  Widget _personTile(Map<String, dynamic> person) {
    final id = idOf(person);
    final tree = treeOf(person);
    final step = GameState.prefs.getInt('chat_step_$id') ?? 0;
    final done = tree.isNotEmpty && step >= tree.length;
    final progress = tree.isEmpty ? 0.0 : (step / tree.length).clamp(0.0, 1.0);
    final color = parseColor(person['avatar_color']);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.soft,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => ChatScreen(person: person)),
          );
          if (mounted) setState(() {});
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 3,
                      backgroundColor: AppTheme.border,
                      color: done ? AppTheme.green : color,
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [color, color.withOpacity(0.6)],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                    ),
                    child: Icon(AppIcons.byName(person['avatar_icon']),
                        color: Colors.white, size: 20),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(TextClean.clean(person['name']),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900, fontSize: 14)),
                        ),
                        if (done) ...[
                          const SizedBox(width: 5),
                          const Icon(Icons.verified_rounded,
                              size: 14, color: AppTheme.green),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(TextClean.clean(person['title']),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11.5, color: AppTheme.textMuted)),
                    const SizedBox(height: 5),
                    Text(
                      tree.isEmpty
                          ? 'گفت‌وگو برای این شخصیت ثبت نشده'
                          : done
                              ? 'گفت‌وگو کامل شد ✨'
                              : '${faNum(step)} از ${faNum(tree.length)} مرحله',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: done ? AppTheme.green : color,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left_rounded, color: AppTheme.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

/// گفت‌وگوی داستانی با یک شخصیت — تاریخچه روی گوشی ذخیره می‌شود
class ChatScreen extends StatefulWidget {
  final Map<String, dynamic> person;
  const ChatScreen({super.key, required this.person});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scroll = ScrollController();

  late final String _id = _ChatListScreenState.idOf(widget.person);
  late final List<Map<String, dynamic>> _tree =
      _ChatListScreenState.treeOf(widget.person);
  late final Color _color = parseColor(widget.person['avatar_color']);

  List<Map<String, dynamic>> _messages = [];
  int _step = 0;
  bool _typing = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _messages = GameState.loadChatHistory(_id);
    _step = GameState.prefs.getInt('chat_step_$_id') ?? 0;
    if (_messages.isEmpty && _tree.isNotEmpty) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _pushCharacterMessage());
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _pushCharacterMessage() async {
    if (_step >= _tree.length) return;
    setState(() => _typing = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() {
      _typing = false;
      _messages.add({
        'role': 'them',
        'text': TextClean.clean(_tree[_step]['character_msg']),
      });
    });
    await GameState.saveChatHistory(_id, _messages);
    _scrollToEnd();
  }

  List<Map<String, dynamic>> get _replies {
    if (_step >= _tree.length) return const [];
    final raw = _tree[_step]['quick_replies'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> _answer(Map<String, dynamic> reply) async {
    if (_busy || _typing) return;
    _busy = true;

    final correct = reply['is_correct'] == true;
    final coins = (reply['reward'] as num?)?.toInt() ?? (correct ? 12 : 0);
    final xp = correct ? 15 : 4;

    setState(() {
      _messages.add({
        'role': 'me',
        'text': TextClean.clean(reply['text']),
        'correct': correct,
      });
    });
    _scrollToEnd();

    if (coins > 0) await GameState.addCoins(coins);
    await GameState.addXp(xp);
    await GameState.registerAnswer(correct);

    setState(() => _typing = true);
    await Future<void>.delayed(const Duration(milliseconds: 750));
    if (!mounted) return;

    setState(() {
      _typing = false;
      _messages.add({
        'role': 'them',
        'text': TextClean.clean(reply['reply']),
        'reward': coins,
      });
      _step++;
    });
    await GameState.prefs.setInt('chat_step_$_id', _step);
    await GameState.saveChatHistory(_id, _messages);
    _scrollToEnd();

    if (mounted && coins > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('جایزه: ${faNum(coins)} سکه 🪙 و ${faNum(xp)} امتیاز ⭐'),
          duration: const Duration(milliseconds: 1500),
        ),
      );
    }

    if (_step >= _tree.length) {
      await GameState.markDialogueDone('$_id-completed');
      await GameState.addCoins(40);
      await GameState.addXp(60);
      if (mounted) setState(() {});
    } else {
      await _pushCharacterMessage();
    }

    _busy = false;
  }

  Future<void> _reset() async {
    await GameState.prefs.remove('chat_$_id');
    await GameState.prefs.setInt('chat_step_$_id', 0);
    setState(() {
      _messages = [];
      _step = 0;
    });
    await _pushCharacterMessage();
  }

  @override
  Widget build(BuildContext context) {
    final finished = _tree.isNotEmpty && _step >= _tree.length;
    final progress =
        _tree.isEmpty ? 0.0 : (_step / _tree.length).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 6,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [_color, _color.withOpacity(0.6)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),
              child: Icon(AppIcons.byName(widget.person['avatar_icon']),
                  color: Colors.white, size: 17),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(TextClean.clean(widget.person['name']),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 14.5)),
                  Text(
                    _typing
                        ? 'در حال نوشتن…'
                        : TextClean.clean(widget.person['title']),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 10.5,
                        color: _typing ? AppTheme.green : AppTheme.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'شروع از اول',
            onPressed: _reset,
            icon: const Icon(Icons.restart_alt_rounded),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 3,
            backgroundColor: AppTheme.border,
            color: finished ? AppTheme.green : _color,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              children: [
                ..._messages.map(_bubble),
                if (_typing) _typingBubble(),
                if (finished) _finishedCard(),
              ],
            ),
          ),
          if (!finished && _tree.isNotEmpty) _replyBar(),
        ],
      ),
    );
  }

  Widget _bubble(Map<String, dynamic> message) {
    final mine = message['role'] == 'me';
    final reward = (message['reward'] as num?)?.toInt() ?? 0;

    return Align(
      alignment: mine ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: mine ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(mine ? 4 : 18),
            bottomRight: Radius.circular(mine ? 18 : 4),
          ),
          boxShadow: AppTheme.soft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${message['text']}',
              style: TextStyle(
                fontSize: 13,
                height: 2.05,
                color: mine ? Colors.white : AppTheme.textDark,
              ),
            ),
            if (reward > 0) ...[
              const SizedBox(height: 7),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.amber.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('🪙 +${faNum(reward)} سکه',
                    style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF92400E))),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _typingBubble() => Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: AppTheme.soft,
          ),
          child: Row(
            children: List.generate(
              3,
              (i) => Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.textMuted.withOpacity(0.35 + i * 0.2),
                ),
              ),
            ),
          ),
        ),
      );

  Widget _finishedCard() => Container(
        margin: const EdgeInsets.only(top: 6, bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppTheme.goldGradient,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            const Text('🏅', style: TextStyle(fontSize: 26)),
            const SizedBox(height: 8),
            const Text('گفت‌وگو کامل شد!',
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: Color(0xFF3F2D00))),
            const SizedBox(height: 6),
            const Text('پاداش پایانی: ۴۰ سکه و ۶۰ امتیاز',
                style: TextStyle(fontSize: 11.5, color: Color(0xFF5B4300))),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _reset,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF3F2D00),
                side: const BorderSide(color: Color(0x553F2D00)),
              ),
              icon: const Icon(Icons.restart_alt_rounded, size: 17),
              label: const Text('دوباره گفت‌وگو کن'),
            ),
          ],
        ),
      );

  Widget _replyBar() {
    final replies = _replies;
    if (replies.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(right: 4, bottom: 8),
              child: Text('پاسخت را انتخاب کن:',
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textMuted)),
            ),
            ...replies.map(
              (reply) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _typing || _busy ? null : () => _answer(reply),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 13),
                      alignment: Alignment.centerRight,
                      side: BorderSide(color: _color.withOpacity(0.45)),
                      foregroundColor: AppTheme.textDark,
                    ),
                    child: Text(TextClean.clean(reply['text']),
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 12.5, height: 1.9)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
