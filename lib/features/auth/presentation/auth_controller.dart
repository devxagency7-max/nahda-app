import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/data_providers.dart';
import '../data/auth_api.dart';
import '../data/auth_repository.dart';
import '../domain/auth_user.dart';

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.watch(apiClientProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    api: ref.watch(authApiProvider),
    tokenStore: ref.watch(tokenStoreProvider),
    database: ref.watch(appDatabaseProvider),
    session: ref.watch(sessionRegistryProvider),
    // `data_providers.dart` يستورد هذا الملف لـ `authRepositoryProvider`
    // نفسه (`ensureFreshSession` في `syncEngineProvider`) — الاتجاه المعاكس
    // هنا (`ref.watch` مباشر لمزوّد من ذاك الملف) كان سيُنشئ اعتمادًا
    // دائريًا وقت البناء. `syncEngineIdleWaiterProvider` كسر بمقصود بدل ذلك:
    // دالة تُقرأ (`ref.read`) عند الاستدعاء الفعلي لا عند بناء هذا الـ Provider.
    awaitSyncIdle: () => ref.read(syncEngineIdleWaiterProvider)(),
  );
});

/// حالة المصادقة.
sealed class AuthState {
  const AuthState();
}

/// جارٍ استعادة الجلسة عند الإقلاع.
class AuthRestoring extends AuthState {
  const AuthRestoring();
}

class AuthSignedOut extends AuthState {
  const AuthSignedOut({this.reason});

  /// سبب الخروج — يُعرَض في شاشة الدخول (مثل "انتهت الجلسة").
  final String? reason;
}

class AuthSignedIn extends AuthState {
  const AuthSignedIn(this.user);

  final AuthUser user;
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(AuthRepository? repository)
    : _repository = repository,
      super(const AuthRestoring());

  /// `null` في الاختبارات التي تتجاوز كل الدوالّ الملامسة للشبكة.
  final AuthRepository? _repository;

  AuthRepository get _repo =>
      _repository ?? (throw StateError('AuthRepository غير مُهيّأ'));

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  /// يُستدعى مرة عند إقلاع التطبيق.
  Future<void> restore() async {
    final user = await _repo.restoreSession();
    if (!mounted) return;
    state = user == null ? const AuthSignedOut() : AuthSignedIn(user);
  }

  /// يرجع `null` عند النجاح، أو الخطأ لعرضه في الشاشة.
  Future<ApiException?> login({
    required String email,
    required String password,
  }) async {
    if (_isSubmitting) return null;
    _isSubmitting = true;

    try {
      final user = await _repo.login(
        email: email.trim(),
        password: password,
      );
      if (mounted) state = AuthSignedIn(user);
      return null;
    } on ApiException catch (e) {
      return e;
    } finally {
      _isSubmitting = false;
    }
  }

  /// [force]: مرّرها `true` فقط بعد أن راجع المستخدم فعليًا تحذير العمل
  /// المعلّق (كما يفعل `home_drawer.dart`) — بدونها، `endSession` ترفض مسح
  /// القاعدة المحلية (لكنها تُنهي الجلسة نفسها دومًا) لو بقيت عمليات لم
  /// تُرفَع بعد.
  Future<void> logout({bool force = false}) async {
    await _repo.endSession(
      reason: SessionEndReason.userInitiated,
      force: force,
    );
    if (mounted) state = const AuthSignedOut();
  }

  /// يُستدعى حين يرفض الخادم التوكن أثناء العمل، أو حين يفشل تجديده.
  ///
  /// **يمرّ عبر نفس `endSession` الموحَّدة** — قبل هذا التعديل كان هذا
  /// المسار يكتفي بتغيير حالة الواجهة بلا مسح فعلي لقاعدة البيانات
  /// المحلية، فتبقى بيانات المستخدم السابق كاملة أمام أي حساب يدخل بعده
  /// على نفس الجهاز (AUTH_SESSION_AUDIT.md §3، مشكلة #3 CRITICAL).
  ///
  /// `force: true` دومًا — مسار تلقائي بلا واجهة تعرض تحذيرًا أو تنتظر قرار
  /// المستخدم؛ حجب المسح هنا يعني تعليق الجلسة بلا خروج فعلي.
  Future<void> onSessionExpired() async {
    if (!mounted) return;
    if (state is! AuthSignedIn) return;
    await _repo.endSession(reason: SessionEndReason.expired, force: true);
    if (!mounted) return;
    state = const AuthSignedOut(
      reason: 'انتهت الجلسة. يرجى تسجيل الدخول مرة أخرى.',
    );
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
      final controller = AuthController(ref.watch(authRepositoryProvider));

      // ربط إشارة انتهاء الجلسة القادمة من طبقة الشبكة.
      ref.listen<int>(sessionExpiredProvider, (previous, next) {
        if (previous != null && next > previous) {
          controller.onSessionExpired();
        }
      });

      return controller;
    });

/// المستخدم الحالي — `null` حين لا توجد جلسة.
final currentUserProvider = Provider<AuthUser?>((ref) {
  final state = ref.watch(authControllerProvider);
  return state is AuthSignedIn ? state.user : null;
});

/// تحذير قرب انتهاء صلاحية الجلسة — مهم قبل الخروج للميدان.
final reauthSoonProvider = FutureProvider<bool>((ref) {
  ref.watch(authControllerProvider);
  return ref.watch(authRepositoryProvider).isReauthSoon();
});
