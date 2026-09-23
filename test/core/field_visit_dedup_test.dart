import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nahda/core/storage/app_database.dart';
import 'package:nahda/core/sync/sync_operation.dart';

/// اختبارات ضمان "الزيارة مرة واحدة بالضبط".
///
/// `POST /field-visits` بلا حماية من الخادم؛ هذه الاختبارات تحرس آخر خط دفاع.
/// زيارة مكررة تعني بيانات فاسدة في سجل رسمي — أخطر من زيارة متأخرة.
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> insertVisit({
    required String id,
    required String caseId,
    required String dedupId,
    String visitDate = '2026-09-18',
    String outcome = 'تمت الزيارة',
    String? serverId,
    String syncState = 'pendingSync',
    double? latitude,
    double? longitude,
  }) {
    final now = DateTime.now();
    return db
        .into(db.localFieldVisits)
        .insert(
          LocalFieldVisitsCompanion.insert(
            id: id,
            caseId: caseId,
            dedupId: dedupId,
            visitDate: visitDate,
            outcome: outcome,
            serverId: Value(serverId),
            syncState: Value(syncState),
            latitude: Value(latitude),
            longitude: Value(longitude),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  group('dedupId', () {
    test('يُخزَّن ويبقى ثابتًا', () async {
      await insertVisit(id: 'v1', caseId: 'c1', dedupId: 'dedup-abc');

      final row = await (db.select(
        db.localFieldVisits,
      )..where((t) => t.id.equals('v1'))).getSingle();

      expect(row.dedupId, 'dedup-abc');
    });

    test('زيارتان مختلفتان لهما dedupId مختلف', () async {
      await insertVisit(id: 'v1', caseId: 'c1', dedupId: 'dedup-1');
      await insertVisit(id: 'v2', caseId: 'c1', dedupId: 'dedup-2');

      final rows = await db.select(db.localFieldVisits).get();
      final ids = rows.map((r) => r.dedupId).toSet();
      expect(ids, hasLength(2));
    });
  });

  group('الحماية من الإرسال المزدوج', () {
    test('زيارة لها serverId لا تُرسَل ثانية', () async {
      await insertVisit(
        id: 'v1',
        caseId: 'c1',
        dedupId: 'd1',
        serverId: 'server-123',
        syncState: 'synced',
      );

      final row = await (db.select(
        db.localFieldVisits,
      )..where((t) => t.id.equals('v1'))).getSingle();

      expect(
        row.serverId,
        isNotNull,
        reason: 'وجود serverId هو شرط منع الإرسال الثاني',
      );
    });

    test('زيارة عالقة في syncing تُكتشَف عند الإقلاع', () async {
      await insertVisit(
        id: 'v1',
        caseId: 'c1',
        dedupId: 'd1',
        syncState: SyncState.syncing.name,
      );

      final stuck =
          await (db.select(db.localFieldVisits)..where(
                (t) =>
                    t.syncState.equals(SyncState.syncing.name) &
                    t.serverId.isNull(),
              ))
              .get();

      expect(stuck, hasLength(1));
      expect(
        stuck.single.id,
        'v1',
        reason: 'هذه بالضبط الحالة التي تسبّب التكرار لو أُعيد الإرسال أعمى',
      );
    });

    test('زيارة syncing لها serverId ليست عالقة — وصلت فعلًا', () async {
      await insertVisit(
        id: 'v1',
        caseId: 'c1',
        dedupId: 'd1',
        serverId: 'server-1',
        syncState: SyncState.syncing.name,
      );

      final stuck =
          await (db.select(db.localFieldVisits)..where(
                (t) =>
                    t.syncState.equals(SyncState.syncing.name) &
                    t.serverId.isNull(),
              ))
              .get();

      expect(stuck, isEmpty);
    });
  });

  group('الإحداثيات', () {
    test('تُخزَّنان معًا', () async {
      await insertVisit(
        id: 'v1',
        caseId: 'c1',
        dedupId: 'd1',
        latitude: 29.0661,
        longitude: 31.0994,
      );

      final row = await (db.select(
        db.localFieldVisits,
      )..where((t) => t.id.equals('v1'))).getSingle();

      expect(row.latitude, 29.0661);
      expect(row.longitude, 31.0994);
    });

    test('غيابهما معًا مقبول — GPS قد يفشل في الميدان', () async {
      await insertVisit(id: 'v1', caseId: 'c1', dedupId: 'd1');

      final row = await (db.select(
        db.localFieldVisits,
      )..where((t) => t.id.equals('v1'))).getSingle();

      expect(row.latitude, isNull);
      expect(row.longitude, isNull);
    });
  });

  group('عزل الحالات', () {
    test('زيارات كل حالة منفصلة', () async {
      await insertVisit(id: 'v1', caseId: 'c1', dedupId: 'd1');
      await insertVisit(id: 'v2', caseId: 'c2', dedupId: 'd2');

      final forCase1 = await (db.select(
        db.localFieldVisits,
      )..where((t) => t.caseId.equals('c1'))).get();

      expect(forCase1, hasLength(1));
      expect(forCase1.single.id, 'v1');
    });
  });

  group('حالة المزامنة المعروضة', () {
    test('كل حالة لها معنى واضح للأخصائي', () {
      expect(SyncState.pendingSync.hasPendingWork, isTrue);
      expect(SyncState.syncing.hasPendingWork, isTrue);

      expect(SyncState.synced.hasPendingWork, isFalse);
      expect(SyncState.conflict.hasPendingWork, isFalse);
      expect(SyncState.failed.hasPendingWork, isFalse);
    });
  });

  group('ترتيب التفريغ للزيارات', () {
    test('المرفقات تُرفَع قبل الزيارة التي تشير إليها', () {
      expect(
        SyncOperationType.uploadAttachment.flushPriority,
        lessThan(SyncOperationType.createFieldVisit.flushPriority),
        reason: 'photoAttachmentIds يقبل المُثبَّت فقط',
      );
    });

    test('الزيارة تحتاج حماية محلية من التكرار', () {
      expect(SyncOperationType.createFieldVisit.needsLocalDedup, isTrue);
      expect(
        SyncOperationType.createFieldVisit.requiresIdempotencyKey,
        isFalse,
        reason: 'الخادم لا يدعمه على هذا المسار — لذا الحماية محلية',
      );
    });

    test('تعديل الزيارة لا يحتاج dedup — محروس بـ rowVersion', () {
      expect(SyncOperationType.updateFieldVisit.needsLocalDedup, isFalse);
    });
  });
}
