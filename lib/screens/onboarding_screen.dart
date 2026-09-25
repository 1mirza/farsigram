import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/game_state.dart';
import '../data/avatar_catalog.dart';
import 'home_shell.dart';

/// گرفتن نام کاربری و آواتار اولیه (فقط بار اول)
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pager = PageController();
  final TextEditingController _name = TextEditingController();

  String _avatar = GameState.defaultAvatar;
  double _lessonLimit = 17;
  String? _error;
  int _page = 0;

  @override
  void dispose() {
    _pager.dispose();
    _name.dispose();
    super.dispose();
  }

  void _next() {
    if (_page == 1 && _name.text.trim().length < 2) {
      setState(() => _error = 'نام باید حداقل ۲ حرف باشد');
      return;
    }
    setState(() => _error = null);
    if (_page == 2) {
      _finish();
    } else {
      _pager.nextPage(
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutCubic);
    }
  }

  Future<void> _finish() async {
    await GameState.createProfile(
      name: _name.text.trim(),
      avatar: _avatar,
      lessonLimit: _lessonLimit.round(),
    );
    await GameState.addCoins(100); // هدیه‌ی خوش‌آمد
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const HomeShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final freeAvatars = kAvatars.where((a) => a.price == 0).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: List.generate(
                  3,
                  (i) => Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      height: 5,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: i <= _page ? AppTheme.primary : AppTheme.border,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pager,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  // ۱) خوش‌آمدگویی
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 104,
                          height: 104,
                          decoration: BoxDecoration(
                            gradient: AppTheme.brandGradient,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: AppTheme.glow(AppTheme.primary),
                          ),
                          child: const Icon(Icons.waving_hand_rounded,
                              color: Colors.white, size: 48),
                        ),
                        const SizedBox(height: 22),
                        const Text('به پارسی‌گرام خوش آمدی!',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 10),
                        const Text(
                          'اینجا فارسی پایه‌ی ششم را با پست، استوری و بازی یاد می‌گیری، سکه جمع می‌کنی و آواتار می‌خری.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 13,
                              height: 2.2,
                              color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 22),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: const [
                            _Pill(emoji: '🎮', label: '۱۲ بازی آموزشی'),
                            _Pill(emoji: '🗣', label: 'گفت‌وگو با بزرگان'),
                            _Pill(emoji: '🏆', label: 'جدول ۱۰۰ نفره'),
                            _Pill(emoji: '🖼', label: 'اشتراک عکسی پست'),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ۲) نام و آواتار
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('اسمت چیه؟',
                            style: TextStyle(
                                fontSize: 19, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 6),
                        const Text(
                            'این نام در پروفایل و جدول رتبه‌بندی نمایش داده می‌شود.',
                            style: TextStyle(
                                fontSize: 12, color: AppTheme.textMuted)),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _name,
                          maxLength: 20,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            hintText: 'مثلاً علی محمدی',
                            errorText: _error,
                            prefixIcon: const Icon(Icons.person_rounded),
                          ),
                          onChanged: (_) => setState(() => _error = null),
                        ),
                        const SizedBox(height: 10),
                        const Text('یک آواتار رایگان انتخاب کن:',
                            style: TextStyle(
                                fontWeight: FontWeight.w900, fontSize: 13.5)),
                        const SizedBox(height: 12),
                        Row(
                          children: freeAvatars
                              .map(
                                (item) => Expanded(
                                  child: GestureDetector(
                                    onTap: () =>
                                        setState(() => _avatar = item.id),
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 5),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      decoration: BoxDecoration(
                                        color: _avatar == item.id
                                            ? AppTheme.primary.withOpacity(0.08)
                                            : AppTheme.surface,
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: _avatar == item.id
                                              ? AppTheme.primary
                                              : AppTheme.border,
                                          width: _avatar == item.id ? 1.8 : 1,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          AvatarCircle(
                                              avatarId: item.id, size: 46),
                                          const SizedBox(height: 8),
                                          Text(item.name,
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w900)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),

                  // ۳) تا کدام درس خوانده‌ای؟
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('تا کدام درس خوانده‌ای؟',
                            style: TextStyle(
                                fontSize: 19, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 6),
                        const Text(
                            'فقط محتوای همین درس‌ها به تو نشان داده می‌شود (هر وقت بخواهی در پروفایل عوضش کن).',
                            style: TextStyle(
                                fontSize: 12,
                                height: 2,
                                color: AppTheme.textMuted)),
                        const SizedBox(height: 26),
                        Center(
                          child: Text('درس ${faNum(_lessonLimit.round())}',
                              style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.primary)),
                        ),
                        Slider(
                          value: _lessonLimit,
                          min: 1,
                          max: 17,
                          divisions: 16,
                          label: faNum(_lessonLimit.round()),
                          onChanged: (v) => setState(() => _lessonLimit = v),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _next,
                  child: Text(_page == 2 ? 'شروع کنیم! 🎉' : 'ادامه',
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 15)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String emoji;
  final String label;
  const _Pill({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.07),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text('$emoji  $label', style: const TextStyle(fontSize: 11.5)),
      );
}
