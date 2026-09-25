import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routing/app_root.dart';
import 'core/sync/background_sync.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // لا تحجب أول رسم للواجهة بانتظار تسجيل مهمة الخلفية — فشلها (منصّة غير
  // مدعومة، إلخ) لا يجوز أن يمنع فتح التطبيق أصلًا.
  unawaited(registerBackgroundSync());
  runApp(const ProviderScope(child: NahdaApp()));
}

class NahdaApp extends StatelessWidget {
  const NahdaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تطبيق الأخصائي الاجتماعي — النهضة',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return Directionality(textDirection: TextDirection.rtl, child: child!);
      },
      home: const AppRoot(),
    );
  }
}
