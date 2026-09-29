import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/case_search/domain/case_search_filter.dart';
import '../../features/case_search/presentation/case_search_providers.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/profile/presentation/user_profile_provider.dart';
import '../providers/data_providers.dart';
import '../theme/app_colors.dart';
import '../widgets/app_background.dart';

/// جذر التطبيق — يقرّر الشاشة حسب حالة المصادقة.
///
/// الشاشات لا تتنقّل يدويًا بعد تسجيل الدخول أو الخروج؛ تغيير الحالة وحده
/// يحرّك الواجهة. هذا يضمن أن انتهاء الجلسة في أي لحظة يعيد المستخدم لشاشة
/// الدخول دون أن تعرف كل شاشة كيف تتصرّف.
class AppRoot extends ConsumerStatefulWidget {
  const AppRoot({super.key});

  @override
  ConsumerState<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends ConsumerState<AppRoot> with WidgetsBindingObserver {
  /// يمنع تشغيل تهيئة بدء التشغيل مرتين لنفس الجلسة.
  bool _startupRan = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // استعادة الجلسة بعد أول إطار حتى لا نعدّل الحالة أثناء البناء.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authControllerProvider.notifier).restore();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // عودة التطبيق للمقدّمة: نتعافى من أي زيارة عالقة ونحدّث الكاش.
    if (state == AppLifecycleState.resumed && _startupRan) {
      ref.read(startupServiceProvider).onResume();
    }
  }

  /// يُشغَّل بعد تسجيل الدخول أو استعادة الجلسة.
  ///
  /// يبدأ بالتعافي من الزيارات العالقة **قبل أي شيء آخر** — إرسال زيارة
  /// وصلت أصلًا يُنشئ تكرارًا في سجل رسمي.
  void _runStartup() {
    if (_startupRan) return;
    _startupRan = true;
    ref.read(startupServiceProvider).run();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);

    if (state is AuthSignedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _runStartup());
      // يبدأ الاستماع لعودة الاتصال طوال مدة الجلسة — أول قراءة تُنشئ
      // الاشتراك؛ `ref.onDispose` في المزوّد نفسه يُلغيه عند الخروج.
      ref.watch(autoSyncOnReconnectProvider);
    } else if (state is AuthSignedOut) {
      _startupRan = false;
    }

    final child = switch (state) {
      AuthRestoring() => const _SplashScreen(),
      AuthSignedOut() => const LoginScreen(),
      // مزوّدات الشاشات التي تحتفظ بحالة محلية بين المستخدمين تُعاد تهيئتها
      // هنا صراحةً بمفتاح مرتبط بهوية المستخدم، حتى لا يرى مستخدم جديد
      // بحثًا أو نتيجة مزامنة تخص مستخدم سابق:
      // - `caseSearchQueryProvider`/`caseSearchFilterProvider`: نص البحث
      //   والفلتر. `caseSearchResultsProvider` نفسه (نتائج البحث، رغم
      //   `keepAlive` الذي يمنع تنظيفه التلقائي المعتاد كـ `autoDispose`)
      //   **لا يحتاج override منفصل** — يعتمد عليهما بـ `ref.watch`، فيُبنى
      //   تلقائيًا داخل نفس هذا الـ scope الفرعي (قاعدة Riverpod: provider
      //   يعتمد transitively على override يُعامَل معاملته).
      // - `lastSyncResultProvider`: نتيجة آخر دورة مزامنة — لا يعتمد على
      //   أي شيء آخر، فيحتاج override صريحًا مستقلًا.
      //
      // مزوّدات غير مذكورة هنا ولا تعتمد على أي منها (مثل `currentUserProvider`)
      // تبقى موروثة من الجذر كالمعتاد — `ProviderScope` المتداخل بلا override
      // صريح (مباشر أو transitive) لا يعزلها (توثيق Riverpod: "non-overridden
      // providers are mounted in the root container").
      AuthSignedIn(:final user) => ProviderScope(
        key: ValueKey('signed-in-${user.id}'),
        overrides: [
          caseSearchQueryProvider.overrideWith((ref) => ''),
          caseSearchFilterProvider.overrideWith((ref) => const CaseSearchFilter()),
          lastSyncResultProvider.overrideWith((ref) => null),
          // `ref.watch(currentUserProvider)` داخل `UserProfileNotifier.build`
          // وحده لا يكفي لعزله: `currentUserProvider` نفسه غير overridden
          // هنا، فالاعتماد transitive عليه لا يُدخل `userProfileProvider` في
          // هذا الـ scope الفرعي (قاعدة Riverpod تشترط أن يكون المُعتمَد
          // عليه نفسه overridden). override صريح هو الضمان الوحيد.
          userProfileProvider.overrideWith(UserProfileNotifier.new),
        ],
        child: const HomeScreen(),
      ),
    };

    // إشعار سبب الخروج القسري (انتهاء الجلسة) بعد رسم شاشة الدخول.
    if (state is AuthSignedOut && state.reason != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final messenger = ScaffoldMessenger.maybeOf(context);
        messenger?.showSnackBar(SnackBar(content: Text(state.reason!)));
      });
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: KeyedSubtree(
        key: ValueKey(state.runtimeType),
        child: child,
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
    );
  }
}
