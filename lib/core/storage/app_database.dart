import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/sync_tables.dart';

part 'app_database.g.dart';

/// [AppDatabase.clearAll] رُفض لوجود عمليات لم تُرفَع بعد — راجع توثيقها.
class PendingSyncOperationsException implements Exception {
  const PendingSyncOperationsException(this.pendingCount);

  final int pendingCount;

  @override
  String toString() =>
      'PendingSyncOperationsException: $pendingCount عملية معلّقة لم تُرفَع بعد';
}

/// قاعدة البيانات المحلية — **مصدر الحقيقة للواجهة**.
///
/// الشاشات تقرأ من هنا عبر `Stream`، والشبكة تحدّث هذه الجداول.
/// لا شاشة تنتظر الشبكة، ولا زرّ حفظ يفشل بسبب انقطاعها.
///
/// راجع §2.1 من `INTEGRATION_PLAN.md`.
@DriftDatabase(
  tables: [
    SyncQueue,
    CachedCases,
    CachedSections,
    LocalFieldVisits,
    PendingAttachments,
    DropdownCache,
    CachedNotifications,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_open());

  /// للاختبارات — قاعدة في الذاكرة.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      // v1 → v2: عمود `userId` في `SyncQueue` (AUTH_SESSION_AUDIT.md، مشكلة
      // #4/#6). الصفوف الموجودة تُترَك بـ `userId = null` — عمليات أُنشئت
      // قبل وجود هذا العمود، فلا معرفة فعلية بصاحبها. `SyncEngine`/
      // `background_sync.dart` يعاملان `null` كـ "غير قابلة للتنفيذ الآن"
      // (راجع `SyncQueueDao.readyOperations`)، لا كـ "تخص أي مستخدم حالي"،
      // فلا خطر تسريب منها رغم عدم حذفها هنا صراحة.
      if (from < 2) {
        await m.addColumn(syncQueue, syncQueue.userId);
      }
    },
    beforeOpen: (details) async {
      // المفاتيح الأجنبية معطّلة افتراضيًا في SQLite.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  static QueryExecutor _open() =>
      driftDatabase(name: 'nahda_local');

  /// مسح كل البيانات عند تسجيل الخروج.
  ///
  /// **حارس فعلي، لا تعليق توثيقي فقط** (AUTH_SESSION_AUDIT.md §2، مشكلة
  /// #9): يرفض المسح افتراضيًا لو وُجدت عمليات معلّقة في [SyncQueue]، لأن
  /// المسح حينها يعني فقدًا نهائيًا لعمل الأخصائي غير المرفوع. المتصل الذي
  /// يريد تجاوز هذا (مثل زر تسجيل الخروج بعد تحذير صريح واعٍ للمستخدم في
  /// `home_drawer.dart`) يمرّر [force] بوضوح — قرار مقروء في نقطة الاستدعاء،
  /// لا حذف صامت بلا أثر.
  ///
  /// يرمي [PendingSyncOperationsException] لو رُفض المسح.
  Future<void> clearAll({bool force = false}) async {
    if (!force) {
      final pending = await pendingOperationCount();
      if (pending > 0) {
        throw PendingSyncOperationsException(pending);
      }
    }

    await transaction(() async {
      for (final table in allTables) {
        await delete(table).go();
      }
    });
  }

  /// عدد العمليات التي لم تُرفَع بعد — لتحذير المستخدم قبل الخروج.
  Future<int> pendingOperationCount() async {
    final query = selectOnly(syncQueue)
      ..addColumns([syncQueue.id.count()])
      ..where(
        syncQueue.status.isIn([
          'pending',
          'in_flight',
          'failed',
          'conflict',
          'dead_lettered',
        ]),
      );
    final row = await query.getSingleOrNull();
    return row?.read(syncQueue.id.count()) ?? 0;
  }
}
