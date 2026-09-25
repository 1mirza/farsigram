import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/app_theme.dart';
import 'core/game_state.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GameState.init(); // خواندن همه‌ی داده‌های ذخیره‌شده روی گوشی
  runApp(const ParsigramApp());
}

class ParsigramApp extends StatelessWidget {
  const ParsigramApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'پارسی‌گرام ششم',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      locale: const Locale('fa'),
      supportedLocales: const [Locale('fa'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: MediaQuery.withNoTextScaling(
          child: child ?? const SizedBox.shrink(),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
