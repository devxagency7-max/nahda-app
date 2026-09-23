import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/sync_tables.dart';

part 'app_database.g.dart';

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
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
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
  /// **تحذير:** يجب التأكد من فراغ طابور المزامنة أولًا — استدعاء هذه الدالة
  /// وفيه عمليات معلّقة يعني فقد عمل الأخصائي نهائيًا.
  Future<void> clearAll() async {
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
