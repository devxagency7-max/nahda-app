import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nahda/core/network/api_error_code.dart';
import 'package:nahda/core/network/api_exception.dart';
import 'package:nahda/core/storage/app_database.dart';
import 'package:nahda/core/sync/sync_engine.dart';
import 'package:nahda/core/sync/sync_operation.dart';
import 'package:nahda/core/sync/sync_queue.dart';
import 'package:nahda/features/cases/data/cases_api.dart';
import 'package:nahda/features/cases/data/workflow_api.dart';

/// نسخة مزيّفة من [CasesApi] — لا تلمس الشبكة، تُسجّل الاستدعاءات وتحاكي
/// نجاحًا أو فشلًا بحسب ما يُعِدُّه الاختبار سلفًا.
///
/// `CasesApi` ليست `final`، فطرقها قابلة للتجاوز — لا حاجة لمحاكاة `Dio`
/// كاملًا لاختبار توجيه [SyncEngine] وحده.
class FakeCasesApi implements CasesApi {
  final List<String> bookmarked = [];
  final List<String> unbookmarked = [];
  final Map<String, Map<String, dynamic>> updatedHousing = {};
  ApiException? failBookmarkWith;

  @override
  Future<void> addBookmark(String caseId) async {
    if (failBookmarkWith != null) throw failBookmarkWith!;
    bookmarked.add(caseId);
  }

  @override
  Future<void> removeBookmark(String caseId) async {
    unbookmarked.add(caseId);
  }

  @override
  Future<Map<String, dynamic>> updateHousing(
    String caseId,
    Map<String, dynamic> payload,
  ) async {
    updatedHousing[caseId] = payload;
    return {...payload, 'rowVersion': (payload['rowVersion'] as int? ?? 0) + 1};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('CasesApi.${invocation.memberName} غير مموَّه في هذا الاختبار');
}

/// نسخة مزيّفة من [WorkflowApi] لاختبار توجيه سير العمل بلا شبكة حقيقية.
class FakeWorkflowApi implements WorkflowApi {
  final List<String> acceptedCaseIds = [];
  final List<String> acceptedIdempotencyKeys = [];

  @override
  Future<Map<String, dynamic>> accept(
    String caseId,
    Map<String, dynamic> payload, {
    required String idempotencyKey,
  }) async {
    acceptedCaseIds.add(caseId);
    acceptedIdempotencyKeys.add(idempotencyKey);
    return {'status': 'in_research', 'caseRowVersion': 5};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
    'WorkflowApi.${invocation.memberName} غير مموَّه في هذا الاختبار',
  );
}

void main() {
  late AppDatabase db;
  late SyncQueueDao queue;
  late FakeCasesApi casesApi;
  late FakeWorkflowApi workflowApi;
  late SyncEngine engine;
  var sessionValid = true;
  final uploadedForCase = <String>[];
  final submittedForCase = <String>[];

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    queue = SyncQueueDao(db);
    casesApi = FakeCasesApi();
    workflowApi = FakeWorkflowApi();
    sessionValid = true;
    uploadedForCase.clear();
    submittedForCase.clear();

    engine = SyncEngine(
      queue: queue,
      casesApi: casesApi,
      workflowApi: workflowApi,
      ensureFreshSession: () async => sessionValid,
      uploadAttachmentsForCase: (caseId) async {
        uploadedForCase.add(caseId);
      },
      submitPendingVisitsForCase: (caseId) async {
        submittedForCase.add(caseId);
      },
    );
  });

  tearDown(() => db.close());

  group('بوابة الجلسة', () {
    test('جلسة منتهية توقف التفريغ بالكامل قبل أي عملية', () async {
      sessionValid = false;
      await queue.enqueue(
        type: SyncOperationType.bookmarkCase,
        caseId: 'case-1',
        payload: const {},
      );

      final result = await engine.flush();

      expect(result.stoppedForAuth, isTrue);
      expect(result.succeeded, 0);
      expect(casesApi.bookmarked, isEmpty, reason: 'لا نداء شبكة قبل التحقق من الجلسة');
      expect(await queue.operationsForCase('case-1'), hasLength(1),
          reason: 'العملية تبقى pending، لا تُفقَد ولا تُعامَل كفشل');
    });
  });

  group('التنفيذ الناجح', () {
    test('يفرّغ عملية bookmark وتُحذف من الطابور', () async {
      await queue.enqueue(
        type: SyncOperationType.bookmarkCase,
        caseId: 'case-1',
        payload: const {},
      );

      final result = await engine.flush();

      expect(result.succeeded, 1);
      expect(casesApi.bookmarked, ['case-1']);
      expect(await queue.operationsForCase('case-1'), isEmpty);
    });

    test('يستدعي رفع المرفقات وإرسال الزيارات لكل حالة بها عمل معلّق', () async {
      await queue.enqueue(
        type: SyncOperationType.bookmarkCase,
        caseId: 'case-1',
        payload: const {},
      );

      await engine.flush();

      expect(uploadedForCase, contains('case-1'));
      expect(submittedForCase, contains('case-1'));
    });
  });

  group('التعارض يوقف حالته فقط', () {
    test('تعارض في حالة لا يمنع تفريغ حالة أخرى', () async {
      casesApi.failBookmarkWith = const ApiException(
        code: ApiErrorCode.concurrencyConflict,
        message: 'تعارض',
      );

      await queue.enqueue(
        type: SyncOperationType.bookmarkCase,
        caseId: 'case-1',
        payload: const {},
      );
      await queue.enqueue(
        type: SyncOperationType.unbookmarkCase,
        caseId: 'case-2',
        payload: const {},
      );

      final result = await engine.flush();

      expect(result.conflicted, 1);
      expect(result.succeeded, 1);
      expect(casesApi.unbookmarked, ['case-2']);

      final case1Ops = await queue.operationsForCase('case-1');
      expect(case1Ops.single.status, 'conflict');
    });

    test('عملية بها تعارض متبقٍّ من قبل تمنع تفريغ باقي طابور نفس الحالة', () async {
      casesApi.failBookmarkWith = const ApiException(
        code: ApiErrorCode.concurrencyConflict,
        message: '',
      );
      final first = await queue.enqueue(
        type: SyncOperationType.bookmarkCase,
        caseId: 'case-1',
        payload: const {},
      );
      await engine.flush();
      expect((await queue.operationsForCase('case-1')).single.status, 'conflict');

      // عملية ثانية على نفس الحالة تُضاف بعد التعارض — يجب ألّا تُفرَّغ.
      await queue.enqueue(
        type: SyncOperationType.unbookmarkCase,
        caseId: 'case-1',
        payload: const {},
      );

      casesApi.failBookmarkWith = null;
      final result = await engine.flush();

      expect(result.succeeded, 0);
      expect(await queue.hasBlockingOperation('case-1'), isTrue);
      // العملية الأولى (المتعارضة) لم تُحذَف — بانتظار قرار المستخدم.
      final ops = await queue.operationsForCase('case-1');
      expect(ops.map((o) => o.id), contains(first));
    });
  });

  group('المرحلة ٢ — مسارات الكتابة', () {
    test('تعديل قسم (housing) يُرسَل ويُحذَف من الطابور عند النجاح', () async {
      await queue.enqueue(
        type: SyncOperationType.updateHousing,
        caseId: 'case-1',
        payload: {'ownership': 'ملك'},
        rowVersion: null,
      );

      final result = await engine.flush();

      expect(result.succeeded, 1);
      expect(casesApi.updatedHousing['case-1']?['ownership'], 'ملك');
      expect(await queue.operationsForCase('case-1'), isEmpty);
    });

    test('قبول حالة (accept) يُرسل نفس Idempotency-Key المولَّد عند الإضافة', () async {
      final id = await queue.enqueue(
        type: SyncOperationType.acceptCase,
        caseId: 'case-1',
        payload: {'caseRowVersion': 4},
      );
      final op = (await queue.operationsForCase('case-1')).single;
      expect(op.id, id);
      final generatedKey = op.idempotencyKey;
      expect(generatedKey, isNotNull, reason: 'يُولَّد تلقائيًا عند enqueue لأنواع سير العمل');

      final result = await engine.flush();

      expect(result.succeeded, 1);
      expect(workflowApi.acceptedCaseIds, ['case-1']);
      expect(workflowApi.acceptedIdempotencyKeys, [generatedKey]);
    });
  });

  group('لا قفل متزامن', () {
    test('استدعاءان متزامنان لا يُنفّذان العملية مرتين', () async {
      await queue.enqueue(
        type: SyncOperationType.bookmarkCase,
        caseId: 'case-1',
        payload: const {},
      );

      final results = await Future.wait([engine.flush(), engine.flush()]);

      // واحدة فقط نفّذت العمل؛ الأخرى رجعت فارغة لأن القفل كان مأخوذًا.
      final totalSucceeded = results.fold<int>(0, (a, r) => a + r.succeeded);
      expect(totalSucceeded, 1);
      expect(casesApi.bookmarked, ['case-1']);
    });
  });

  group('أنواع غير مُنفَّذة بعد (المرحلة ٢)', () {
    // `updateSupportRecommendations` وحده يبقى بلا دالة API فعلية بعد
    // المرحلة ٢ (تسع أقسام الحالة + سير العمل الثلاثي مُوجَّهة الآن) — نستخدمه
    // هنا خصّيصًا لاختبار سلوك "نوع غير موجَّه" دون أن يصطدم بتوجيه حقيقي.
    test('قسم لم يُنفَّذ مسار كتابته بعد يبقى pending بلا أي أثر', () async {
      await queue.enqueue(
        type: SyncOperationType.updateSupportRecommendations,
        caseId: 'case-1',
        payload: {'ownership': 'ملك'},
        rowVersion: 3,
      );

      final result = await engine.flush();

      expect(result.succeeded, 0);
      expect(result.failed, 0);
      expect(result.conflicted, 0);

      final ops = await queue.operationsForCase('case-1');
      // **لا** dead_lettered ولا failed: هذا غياب كود تنفيذ، لا خطأ من
      // الخادم. العملية تبقى كما أُنشئت تمامًا حتى يُضاف مسار الكتابة.
      expect(ops.single.status, 'pending');
      expect(ops.single.attempts, 0);
    });

    test('نوع غير موجَّه في مقدّمة طابور حالة يوقف باقي طابورها', () async {
      // القسم أولًا (غير موجّه) ثم المفضّلة (موجّهة) — الترتيب بالأولوية
      // يضع القسم قبل المفضّلة في هذه الحالة الافتراضية لو كانتا من نفس
      // النوع؛ هنا نتحقق تحديدًا أن عدم توجيه الأولى يمنع تنفيذ الثانية،
      // حفاظًا على ترتيب الإرسال حتى لو كانت الثانية قابلة للتنفيذ فعليًا.
      await queue.enqueue(
        type: SyncOperationType.updateSupportRecommendations,
        caseId: 'case-1',
        payload: {'ownership': 'ملك'},
      );
      await queue.enqueue(
        type: SyncOperationType.bookmarkCase,
        caseId: 'case-1',
        payload: const {},
      );

      final result = await engine.flush();

      expect(result.succeeded, 0);
      expect(casesApi.bookmarked, isEmpty,
          reason: 'لا يجوز تجاوز عملية أقدم غير مُنفَّذة لتنفيذ الأحدث');
    });

    test('لا حلقة لا نهائية عند وجود عملية غير موجَّهة فقط', () async {
      await queue.enqueue(
        type: SyncOperationType.updateSupportRecommendations,
        caseId: 'case-1',
        payload: {},
      );

      // ينتهي `flush` فعليًا بدل الدوران للأبد على نفس العملية.
      final result = await engine.flush().timeout(const Duration(seconds: 5));

      expect(result.succeeded, 0);
    });
  });
}
