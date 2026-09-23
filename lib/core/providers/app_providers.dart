import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';
import '../storage/app_database.dart';
import '../storage/secure_token_store.dart';
import '../sync/connectivity_monitor.dart';
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

final connectivityProvider = Provider<ConnectivityMonitor>((ref) {
  final monitor = ConnectivityMonitor();
  ref.onDispose(monitor.dispose);
  return monitor;
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

/// حالة الاتصال الحالية — تُستخدم لعرض شارة "بدون اتصال".
final connectionKindProvider = StreamProvider<ConnectionKind>((ref) async* {
  final monitor = ref.watch(connectivityProvider);
  await monitor.start();
  yield monitor.current;
  yield* monitor.changes;
});

/// عدد العمليات المعلّقة — يغذّي شارة المزامنة وتحذير الخروج.
final pendingSyncCountProvider = StreamProvider<int>((ref) {
  return ref.watch(syncQueueProvider).watchPendingCount();
});
