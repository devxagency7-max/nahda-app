import 'package:drift/drift.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/sync/sync_operation.dart';
import '../../../core/sync/sync_queue.dart';
import 'notifications_api.dart';

/// معرّف طابور ثابت لعملية "قراءة الكل" — لا `caseId` حقيقي يصلح هنا؛ طابور
/// المزامنة يُجمِّع دائمًا حسب عمود واحد (راجع [SyncQueueDao]) فنُعيد
/// استخدامه بقيمة ثابتة مميَّزة بدل تمديد الجدول لعمود جديد لحالة واحدة.
const _markAllReadGroupKey = '_notifications_mark_all_';

/// مستودع الإشعارات — يقرأ من Drift دائمًا؛ الشبكة تُحدِّث الكاش فتتحدّث
/// الشاشة (نفس مبدأ [CachedCases] في `cases_repository.dart`).
class NotificationsRepository {
  NotificationsRepository({
    required NotificationsApi api,
    required AppDatabase db,
    required SyncQueueDao queue,
  }) : _api = api,
       _db = db,
       _queue = queue;

  final NotificationsApi _api;
  final AppDatabase _db;
  final SyncQueueDao _queue;

  Stream<List<CachedNotificationRow>> watchAll() =>
      (_db.select(_db.cachedNotifications)
            ..orderBy([(t) => OrderingTerm.desc(t.createdAtUtc)]))
          .watch();

  Stream<int> watchUnreadCount() {
    final query = _db.selectOnly(_db.cachedNotifications)
      ..addColumns([_db.cachedNotifications.id.count()])
      ..where(_db.cachedNotifications.isRead.equals(false));
    return query
        .watchSingle()
        .map((row) => row.read(_db.cachedNotifications.id.count()) ?? 0);
  }

  /// يجلب أحدث الإشعارات من الخادم ويكتبها محليًا.
  ///
  /// **لا يرمي أبدًا** — فشل الشبكة يعني الشاشة تبقى تعرض الكاش بهدوء، بلا
  /// رسالة خطأ مزعجة (نفس نمط [RefreshOutcome] في بقية المستودعات، بشكل
  /// أبسط هنا: لا حاجة لتمييز نوع الفشل لأن الإشعارات ليست حرجة بنفس درجة
  /// طابور عمل الحالات).
  Future<bool> refresh({int limit = 50}) async {
    try {
      final response = await _api.list(limit: limit);
      final page = response['page'] as Map<String, dynamic>? ?? const {};
      final items = (page['items'] as List? ?? const [])
          .whereType<Map<String, dynamic>>();
      if (items.isEmpty) return true;

      await _db.batch((batch) {
        for (final item in items) {
          final id = item['id'] as String?;
          final createdAt = DateTime.tryParse(
            item['createdAtUtc'] as String? ?? '',
          );
          if (id == null || createdAt == null) continue;

          final companion = CachedNotificationsCompanion.insert(
            id: id,
            title: item['title'] as String? ?? '',
            subtitle: Value(item['subtitle'] as String?),
            icon: Value(item['icon'] as String?),
            isRead: Value(item['isRead'] as bool? ?? false),
            caseId: Value(item['caseId'] as String?),
            createdAtUtc: createdAt,
          );

          batch.insert(
            _db.cachedNotifications,
            companion,
            onConflict: DoUpdate(
              (_) => CachedNotificationsCompanion(
                title: companion.title,
                subtitle: companion.subtitle,
                icon: companion.icon,
                isRead: companion.isRead,
                caseId: companion.caseId,
              ),
            ),
          );
        }
      });
      return true;
    } on ApiException {
      return false;
    }
  }

  /// يعلّم إشعارًا واحدًا مقروءًا — تفاؤليًا محليًا، ثم عبر الطابور.
  ///
  /// يُستخدَم معرّف الإشعار نفسه كمفتاح تجميع الطابور (`caseId` في
  /// [SyncQueueDao] عمود عام لأي نوع عملية، لا حالات فقط) — كل إشعار
  /// مستقل تمامًا عن غيره فلا داعي لتجميع مشترك.
  Future<void> markRead(String id) async {
    await (_db.update(_db.cachedNotifications)..where((t) => t.id.equals(id)))
        .write(const CachedNotificationsCompanion(isRead: Value(true)));

    await _queue.enqueue(
      type: SyncOperationType.markNotificationRead,
      caseId: id,
      payload: const {},
    );
  }

  /// يعلّم كل الإشعارات مقروءة — تفاؤليًا محليًا، ثم عبر الطابور.
  Future<void> markAllRead() async {
    await _db
        .update(_db.cachedNotifications)
        .write(const CachedNotificationsCompanion(isRead: Value(true)));

    await _queue.enqueue(
      type: SyncOperationType.markAllNotificationsRead,
      caseId: _markAllReadGroupKey,
      payload: const {},
    );
  }
}
