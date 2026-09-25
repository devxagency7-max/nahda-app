import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nahda/core/network/api_error_code.dart';
import 'package:nahda/core/network/api_exception.dart';
import 'package:nahda/core/storage/app_database.dart';
import 'package:nahda/core/sync/sync_operation.dart';
import 'package:nahda/core/sync/sync_queue.dart';

/// اختبارات طابور المزامنة — أهم اختبارات المشروع.
///
/// خطأ هنا يعني فقد عمل أخصائي في الميدان أو تكرار بيانات في سجل رسمي.
void main() {
  late AppDatabase db;
  late SyncQueueDao queue;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    queue = SyncQueueDao(db);
  });

  tearDown(() => db.close());

  group('الإضافة للطابور', () {
    test('تُضيف عملية بحالة pending', () async {
      final id = await queue.enqueue(
        type: SyncOperationType.updateHousing,
        caseId: 'case-1',
        payload: {'ownership': 'ملك'},
        rowVersion: 3,
      );

      final ops = await queue.operationsForCase('case-1');
      expect(ops, hasLength(1));
      expect(ops.first.id, id);
      expect(ops.first.status, 'pending');
      expect(ops.first.rowVersion, 3);
    });

    test('تُولّد Idempotency-Key لعمليات سير العمل فقط', () async {
      await queue.enqueue(
        type: SyncOperationType.submitWorkerOpinion,
        caseId: 'case-1',
        payload: {'decision': 'accepted'},
      );
      await queue.enqueue(
        type: SyncOperationType.updateHousing,
        caseId: 'case-2',
        payload: {'ownership': 'ملك'},
      );

      final opinion = (await queue.operationsForCase('case-1')).single;
      final housing = (await queue.operationsForCase('case-2')).single;

      expect(opinion.idempotencyKey, isNotNull);
      expect(opinion.idempotencyKey, isNotEmpty);
      expect(housing.idempotencyKey, isNull);
    });

    test('تُولّد dedupId للزيارة الميدانية — لا حماية من الخادم (§14.2)', () async {
      await queue.enqueue(
        type: SyncOperationType.createFieldVisit,
        caseId: 'case-1',
        payload: {'visitDate': '2026-09-18'},
      );

      final op = (await queue.operationsForCase('case-1')).single;
      expect(op.dedupId, isNotNull);
    });

    test('dedupId مكرّر لا يُنشئ عملية ثانية', () async {
      final first = await queue.enqueue(
        type: SyncOperationType.createFieldVisit,
        caseId: 'case-1',
        payload: {'visitDate': '2026-09-18'},
        dedupId: 'visit-abc',
      );
      final second = await queue.enqueue(
        type: SyncOperationType.createFieldVisit,
        caseId: 'case-1',
        payload: {'visitDate': '2026-09-18'},
        dedupId: 'visit-abc',
      );

      expect(second, first);
      expect(await queue.operationsForCase('case-1'), hasLength(1));
    });
  });

  group('دمج تعديلات الأقسام', () {
    test('تعديلان على نفس القسم يُدمجان — يمنع تعارض rowVersion حتميًا', () async {
      final first = await queue.enqueue(
        type: SyncOperationType.updateHousing,
        caseId: 'case-1',
        payload: {'ownership': 'ملك', 'roomsCount': '3'},
        rowVersion: 5,
      );
      final second = await queue.enqueue(
        type: SyncOperationType.updateHousing,
        caseId: 'case-1',
        payload: {'ownership': 'إيجار', 'roomsCount': '4'},
        rowVersion: 5,
      );

      expect(second, first, reason: 'نفس العملية، لا عملية جديدة');

      final ops = await queue.operationsForCase('case-1');
      expect(ops, hasLength(1));

      final payload = jsonDecode(ops.single.payload) as Map<String, dynamic>;
      expect(payload['ownership'], 'إيجار', reason: 'آخر قيمة تفوز');
      expect(payload['roomsCount'], '4');
    });

    test('يحتفظ بأقدم rowVersion عند الدمج', () async {
      await queue.enqueue(
        type: SyncOperationType.updateHousing,
        caseId: 'case-1',
        payload: {'ownership': 'ملك'},
        rowVersion: 5,
      );
      await queue.enqueue(
        type: SyncOperationType.updateHousing,
        caseId: 'case-1',
        payload: {'ownership': 'إيجار'},
        rowVersion: 9,
      );

      final op = (await queue.operationsForCase('case-1')).single;
      expect(op.rowVersion, 5);
    });

    test('أقسام مختلفة لا تُدمج', () async {
      await queue.enqueue(
        type: SyncOperationType.updateHousing,
        caseId: 'case-1',
        payload: {'ownership': 'ملك'},
      );
      await queue.enqueue(
        type: SyncOperationType.updateAgriculture,
        caseId: 'case-1',
        payload: {'hasLand': 'yes'},
      );

      expect(await queue.operationsForCase('case-1'), hasLength(2));
    });

    test('حالات مختلفة لا تُدمج', () async {
      await queue.enqueue(
        type: SyncOperationType.updateHousing,
        caseId: 'case-1',
        payload: {'ownership': 'ملك'},
      );
      await queue.enqueue(
        type: SyncOperationType.updateHousing,
        caseId: 'case-2',
        payload: {'ownership': 'إيجار'},
      );

      expect(await queue.operationsForCase('case-1'), hasLength(1));
      expect(await queue.operationsForCase('case-2'), hasLength(1));
    });

    test('عملية قيد الإرسال لا تُدمَج — نتيجتها مجهولة', () async {
      final first = await queue.enqueue(
        type: SyncOperationType.updateHousing,
        caseId: 'case-1',
        payload: {'ownership': 'ملك'},
      );
      await queue.markInFlight(first);

      final second = await queue.enqueue(
        type: SyncOperationType.updateHousing,
        caseId: 'case-1',
        payload: {'ownership': 'إيجار'},
      );

      expect(second, isNot(first));
      expect(await queue.operationsForCase('case-1'), hasLength(2));
    });

    test('سير العمل لا يُدمَج أبدًا — كل ضغطة إجراء مستقلة', () async {
      await queue.enqueue(
        type: SyncOperationType.submitWorkerOpinion,
        caseId: 'case-1',
        payload: {'decision': 'accepted'},
      );
      await queue.enqueue(
        type: SyncOperationType.submitWorkerOpinion,
        caseId: 'case-1',
        payload: {'decision': 'rejected'},
      );

      expect(await queue.operationsForCase('case-1'), hasLength(2));
    });
  });

  group('معالجة الفشل', () {
    test('تعارض ← conflict بلا إعادة محاولة تلقائية', () async {
      final id = await queue.enqueue(
        type: SyncOperationType.updateHousing,
        caseId: 'case-1',
        payload: {},
      );

      final status = await queue.markFailed(
        id,
        const ApiException(
          code: ApiErrorCode.concurrencyConflict,
          message: 'تم تعديل الحالة',
        ),
      );

      expect(status, SyncOperationStatus.conflict);
      final op = (await queue.operationsForCase('case-1')).single;
      expect(op.status, 'conflict');
      expect(op.nextAttemptAt, isNull, reason: 'لا إعادة محاولة تلقائية');
      expect(op.lastErrorMessage, 'تم تعديل الحالة');
    });

    test('خطأ تحقق ← dead_lettered، لن ينجح مهما تكرّر', () async {
      final id = await queue.enqueue(
        type: SyncOperationType.updateHousing,
        caseId: 'case-1',
        payload: {},
      );

      final status = await queue.markFailed(
        id,
        const ApiException(
          code: ApiErrorCode.validationError,
          message: 'بيانات غير صحيحة',
        ),
      );

      expect(status, SyncOperationStatus.deadLettered);
    });

    test('خطأ شبكة ← failed بتباعد أسّي متزايد', () async {
      final id = await queue.enqueue(
        type: SyncOperationType.updateHousing,
        caseId: 'case-1',
        payload: {},
      );

      const offline = ApiException(code: ApiErrorCode.offline, message: '');

      await queue.markFailed(id, offline);
      var op = (await queue.operationsForCase('case-1')).single;
      expect(op.status, 'failed');
      expect(op.attempts, 1);
      final firstRetry = op.nextAttemptAt!;

      await queue.markFailed(id, offline);
      op = (await queue.operationsForCase('case-1')).single;
      expect(op.attempts, 2);
      expect(
        op.nextAttemptAt!.isAfter(firstRetry),
        isTrue,
        reason: 'التباعد يتزايد',
      );
    });

    test('عملية فاشلة لا تُحذَف تلقائيًا — حماية من فقد العمل', () async {
      final id = await queue.enqueue(
        type: SyncOperationType.createFieldVisit,
        caseId: 'case-1',
        payload: {'visitDate': '2026-09-18'},
      );

      await queue.markFailed(
        id,
        const ApiException(code: ApiErrorCode.validationError, message: ''),
      );

      expect(await queue.operationsForCase('case-1'), hasLength(1));
    });
  });

  group('عزل التعارضات', () {
    test('تعارض في حالة لا يوقف حالة أخرى', () async {
      final blocked = await queue.enqueue(
        type: SyncOperationType.updateHousing,
        caseId: 'case-1',
        payload: {},
      );
      await queue.enqueue(
        type: SyncOperationType.updateHousing,
        caseId: 'case-2',
        payload: {},
      );

      await queue.markFailed(
        blocked,
        const ApiException(
          code: ApiErrorCode.concurrencyConflict,
          message: '',
        ),
      );

      expect(await queue.hasBlockingOperation('case-1'), isTrue);
      expect(await queue.hasBlockingOperation('case-2'), isFalse);
    });

    test('403 يُعامَل كتعارض — الحالة لم تعد مُسنَدة إليك', () async {
      final id = await queue.enqueue(
        type: SyncOperationType.updateHousing,
        caseId: 'case-1',
        payload: {},
      );

      final status = await queue.markFailed(
        id,
        const ApiException(
          code: ApiErrorCode.forbidden,
          message: 'لا يمكن تعديل بيانات حالة غير مسندة إليك',
        ),
      );

      expect(status, SyncOperationStatus.conflict);
    });
  });

  group('ترتيب التفريغ', () {
    test('المرفقات قبل الزيارة قبل الأقسام قبل الرأي', () {
      expect(
        SyncOperationType.uploadAttachment.flushPriority,
        lessThan(SyncOperationType.createFieldVisit.flushPriority),
      );
      expect(
        SyncOperationType.createFieldVisit.flushPriority,
        lessThan(SyncOperationType.updateHousing.flushPriority),
      );
      expect(
        SyncOperationType.updateHousing.flushPriority,
        lessThan(SyncOperationType.submitWorkerOpinion.flushPriority),
      );
    });

    test('العمليات المؤجّلة لا تظهر ضمن الجاهزة', () async {
      final id = await queue.enqueue(
        type: SyncOperationType.updateHousing,
        caseId: 'case-1',
        payload: {},
      );
      await queue.markFailed(
        id,
        const ApiException(code: ApiErrorCode.offline, message: ''),
      );

      expect(await queue.readyOperations(), isEmpty);
    });

    test('المتعارضة لا تظهر ضمن الجاهزة', () async {
      final id = await queue.enqueue(
        type: SyncOperationType.updateHousing,
        caseId: 'case-1',
        payload: {},
      );
      await queue.markFailed(
        id,
        const ApiException(
          code: ApiErrorCode.concurrencyConflict,
          message: '',
        ),
      );

      expect(await queue.readyOperations(), isEmpty);
    });
  });

  group('العمليات العالقة', () {
    test('عملية inFlight حديثة ليست عالقة', () async {
      final id = await queue.enqueue(
        type: SyncOperationType.createFieldVisit,
        caseId: 'case-1',
        payload: {},
      );
      await queue.markInFlight(id);

      expect(await queue.stuckInFlight(), isEmpty);
    });
  });

  group('حلّ التعارض', () {
    test('إعادة المحاولة تُعيد العملية للطابور بنسخة جديدة', () async {
      final id = await queue.enqueue(
        type: SyncOperationType.updateHousing,
        caseId: 'case-1',
        payload: {},
        rowVersion: 3,
      );
      await queue.markFailed(
        id,
        const ApiException(
          code: ApiErrorCode.concurrencyConflict,
          message: '',
        ),
      );

      await queue.retryAfterResolution(id, newRowVersion: 7);

      final op = (await queue.operationsForCase('case-1')).single;
      expect(op.status, 'pending');
      expect(op.rowVersion, 7);
      expect(op.attempts, 0);
      expect(op.lastErrorMessage, isNull);
      expect(await queue.readyOperations(), hasLength(1));
    });

    test('التخلّي يحذف العملية — بقرار المستخدم وحده', () async {
      final id = await queue.enqueue(
        type: SyncOperationType.updateHousing,
        caseId: 'case-1',
        payload: {},
      );

      await queue.discard(id);

      expect(await queue.operationsForCase('case-1'), isEmpty);
    });

    test(
      'operationById يجد العملية بمعرّفها وحده — لا يحتاج caseId مسبقًا '
      '(شاشة التعارض تُفتح بمعرّف العملية فقط)',
      () async {
        final id = await queue.enqueue(
          type: SyncOperationType.updateHousing,
          caseId: 'case-unknown-at-open-time',
          payload: {'ownership': 'خاص'},
          rowVersion: 2,
        );

        final found = await queue.operationById(id);

        expect(found, isNotNull);
        expect(found!.caseId, 'case-unknown-at-open-time');
      },
    );

    test('operationById يرجع null لعملية غير موجودة (رُبما حُلّت بالفعل)', () async {
      expect(await queue.operationById('غير-موجود'), isNull);
    });

    test(
      'إعادة المحاولة بنسخة قديمة (نفس التي سبّبت التعارض) تفشل ثانيةً — '
      'إثبات أن الإصلاح (تمرير rowVersion طازج) ضروري لا اختياري',
      () async {
        final id = await queue.enqueue(
          type: SyncOperationType.updateHousing,
          caseId: 'case-1',
          payload: {},
          rowVersion: 3,
        );
        await queue.markFailed(
          id,
          const ApiException(
            code: ApiErrorCode.concurrencyConflict,
            message: '',
          ),
        );

        // محاكاة الزر القديم في SyncStatusScreen: إعادة محاولة بلا rowVersion
        // جديد — العملية تعود pending لكن بنفس النسخة القديمة (null هنا لأن
        // retryAfterResolution بلا newRowVersion يمسح القيمة، فتصبح "أول
        // حفظ" منطقيًا خاطئ لقسم موجود أصلًا).
        await queue.retryAfterResolution(id);
        final blind = (await queue.operationsForCase('case-1')).single;

        // بعكسها: تمرير rowVersion طازج (كما تفعل ConflictResolutionScreen
        // بعد GET) يضمن نسخة صحيحة لمحاولة الإرسال التالية.
        await queue.retryAfterResolution(id, newRowVersion: 9);
        final fixed = (await queue.operationsForCase('case-1')).single;

        expect(blind.rowVersion, isNull);
        expect(fixed.rowVersion, 9);
      },
    );
  });

  group('عدّاد المعلّق', () {
    test('يحصي كل العمليات غير المكتملة', () async {
      await queue.enqueue(
        type: SyncOperationType.updateHousing,
        caseId: 'case-1',
        payload: {},
      );
      final conflicted = await queue.enqueue(
        type: SyncOperationType.updateAgriculture,
        caseId: 'case-1',
        payload: {},
      );
      await queue.markFailed(
        conflicted,
        const ApiException(
          code: ApiErrorCode.concurrencyConflict,
          message: '',
        ),
      );

      expect(await db.pendingOperationCount(), 2);
    });

    test('النجاح يزيل العملية من العدّاد', () async {
      final id = await queue.enqueue(
        type: SyncOperationType.updateHousing,
        caseId: 'case-1',
        payload: {},
      );
      await queue.markSucceeded(id);

      expect(await db.pendingOperationCount(), 0);
    });
  });
}
