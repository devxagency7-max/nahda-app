import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nahda/core/network/api_client.dart';
import 'package:nahda/core/network/network_status_service.dart';
import 'package:nahda/core/storage/app_database.dart';
import 'package:nahda/core/storage/secure_token_store.dart';
import 'package:nahda/core/sync/sync_engine.dart';
import 'package:nahda/core/sync/sync_operation.dart';
import 'package:nahda/core/sync/sync_queue.dart';
import 'package:nahda/features/notifications/data/notifications_api.dart';
import 'package:nahda/features/notifications/data/notifications_repository.dart';

/// اختبارات مستودع الإشعارات — الجزء المحلي (بلا شبكة). `refresh()` يحتاج
/// خادمًا حقيقيًا فلا يُختبَر هنا، بنفس حدود اختبارات المستودعات الأخرى في
/// هذا المشروع لمسارات القراءة من الشبكة.
void main() {
  late AppDatabase db;
  late SyncQueueDao queue;
  late NotificationsRepository repo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    queue = SyncQueueDao(db);
    repo = NotificationsRepository(
      api: NotificationsApi(
        ApiClient.create(
          tokenStore: SecureTokenStore(),
          onSessionExpired: () async {},
        ),
      ),
      db: db,
      queue: queue,
      // أوفلاين عمدًا (لا `start()`): `trySendImmediately` يرتدّ فورًا
      // لمسار `enqueue` بدل أن يعامل غياب اتصال معروف كأونلاين فيرمي
      // الخطأ بدل التأجيل للطابور.
      syncEngine: SyncEngine(
        queue: queue,
        networkStatus: NetworkStatusService(),
        ensureFreshSession: () async => true,
        uploadAttachmentsForCase: (_) async {},
        submitPendingVisitsForCase: (_) async {},
      ),
    );
  });

  tearDown(() => db.close());

  Future<void> insertNotification({
    required String id,
    bool isRead = false,
    DateTime? createdAtUtc,
  }) {
    return db
        .into(db.cachedNotifications)
        .insert(
          CachedNotificationsCompanion.insert(
            id: id,
            title: 'عنوان $id',
            isRead: Value(isRead),
            createdAtUtc: createdAtUtc ?? DateTime.now(),
          ),
        );
  }

  group('markRead', () {
    test('يحدّث isRead محليًا فورًا ويضيف عملية للطابور بمعرّف الإشعار', () async {
      await insertNotification(id: 'n1');

      await repo.markRead('n1');

      final row = await (db.select(
        db.cachedNotifications,
      )..where((t) => t.id.equals('n1'))).getSingle();
      expect(row.isRead, isTrue);

      final ops = await queue.operationsForCase('n1');
      expect(ops, hasLength(1));
      expect(ops.single.type, SyncOperationType.markNotificationRead.wireValue);
    });
  });

  group('markAllRead', () {
    test('يحدّث كل الإشعارات محليًا ويضيف عملية واحدة للطابور', () async {
      await insertNotification(id: 'n1');
      await insertNotification(id: 'n2', isRead: true);
      await insertNotification(id: 'n3');

      await repo.markAllRead();

      final rows = await db.select(db.cachedNotifications).get();
      expect(rows.every((r) => r.isRead), isTrue);

      final ops = await queue.operationsForCase('_notifications_mark_all_');
      expect(ops, hasLength(1));
      expect(
        ops.single.type,
        SyncOperationType.markAllNotificationsRead.wireValue,
      );
    });
  });

  group('watchUnreadCount', () {
    test('يعكس عدد الإشعارات غير المقروءة فقط', () async {
      await insertNotification(id: 'n1');
      await insertNotification(id: 'n2', isRead: true);
      await insertNotification(id: 'n3');

      final count = await repo.watchUnreadCount().first;
      expect(count, 2);
    });
  });

  group('watchAll', () {
    test('يرتّب الأحدث أولًا', () async {
      final old = DateTime(2026, 1, 1);
      final recent = DateTime(2026, 9, 1);
      await insertNotification(id: 'old', createdAtUtc: old);
      await insertNotification(id: 'recent', createdAtUtc: recent);

      final items = await repo.watchAll().first;
      expect(items.map((n) => n.id), ['recent', 'old']);
    });
  });
}
