import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';
import '../network/network_status_service.dart';
import '../storage/app_database.dart';
import '../storage/secure_token_store.dart';
import '../sync/sync_queue.dart';

/// مزوّدات البنية التحتية المشتركة.

final tokenStoreProvider = Provider<SecureTokenStore>((ref) {
  return SecureTokenStore();
});

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final syncQueueProvider = Provider<SyncQueueDao>((ref) {
  return SyncQueueDao(ref.watch(appDatabaseProvider));
});

/// المراقب المركزي الوحيد لحالة الاتصال (Internet + Backend reachability) —
/// يحلّ محل `ConnectivityMonitor` القديم عبر كل مزوّدات/مستودعات التطبيق.
final networkStatusServiceProvider = Provider<NetworkStatusService>((ref) {
  final service = NetworkStatusService();
  ref.onDispose(service.dispose);
  return service;
});

/// حالة الاتصال المركزية — `StreamProvider` يبدأ المراقبة عند أول قراءة.
final networkStatusProvider = StreamProvider<NetworkStatus>((ref) async* {
  final service = ref.watch(networkStatusServiceProvider);
  await service.start();
  yield service.current;
  yield* service.statusStream;
});

/// إشارة انتهاء الجلسة — يرفعها `AuthInterceptor` حين يرفض الخادم التوكن.
///
/// منفصلة عن مزوّد المصادقة تجنّبًا لاعتماد دائري: العميل يحتاج ردّ فعل عند
/// انتهاء الجلسة، وطبقة المصادقة تحتاج العميل.
final sessionExpiredProvider = StateProvider<int>((ref) => 0);

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient.create(
    tokenStore: ref.watch(tokenStoreProvider),
    onSessionExpired: () async {
      ref.read(sessionExpiredProvider.notifier).state++;
    },
  );
});

/// عدد العمليات المعلّقة — يغذّي شارة المزامنة وتحذير الخروج.
final pendingSyncCountProvider = StreamProvider<int>((ref) {
  return ref.watch(syncQueueProvider).watchPendingCount();
});

/// عمليات رفضها الخادم أو تعارضت — تحتاج قرار المستخدم في شاشة المزامنة.
final syncNeedsAttentionCountProvider = StreamProvider<int>((ref) {
  return ref.watch(syncQueueProvider).watchNeedingAttentionCount();
});
