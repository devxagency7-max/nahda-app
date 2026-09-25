import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nahda/core/storage/app_database.dart';
import 'package:nahda/core/sync/sync_engine.dart';
import 'package:nahda/core/sync/sync_operation.dart';
import 'package:nahda/core/sync/sync_queue.dart';
import 'package:nahda/core/network/api_client.dart';
import 'package:nahda/core/network/network_status_service.dart';
import 'package:nahda/core/storage/secure_token_store.dart';
import 'package:nahda/features/cases/data/cases_api.dart';
import 'package:nahda/features/cases/data/cases_repository.dart';
import 'package:nahda/features/cases/data/dto/case_details_dto.dart';
import 'package:nahda/features/cases/data/dto/case_list_item_dto.dart';
import 'package:nahda/features/cases/domain/case_status.dart';

/// اختبارات طبقة الحالات: تحويل الاستجابات + سلوك الكاش.
///
/// التركيز على الفخاخ المؤكَّدة من العقد لا على المسار السعيد.
void main() {
  group('CaseListItemDto', () {
    test('يقرأ عنصر قائمة كاملًا', () {
      final item = CaseListItemDto.fromJson({
        'id': '5b1e2a3c',
        'caseNumber': 'C-2026-000123',
        'displayId': '123',
        'status': 'assigned',
        'priority': 'urgent',
        'beneficiaryFullName': 'أحمد محمود علي',
        'nationalId': '29805142200015',
        'charityId': null,
        'registrationDate': '2026-09-18',
        'completionPercentage': 33.33,
        'createdAtUtc': '2026-09-18T09:00:00Z',
        'nextVisitDate': '2026-09-18',
        'nextVisitStartTimeUtc': '2026-09-18T08:00:00Z',
        'nextVisitLocation': 'قرية بني عدي',
        'isBookmarked': true,
      });

      expect(item.id, '5b1e2a3c');
      expect(item.status, CaseStatus.assigned);
      expect(item.priority, CasePriorityWire.urgent);
      expect(item.completionPercentage, 33.33);
      expect(item.isBookmarked, isTrue);
      expect(item.hasScheduledVisit, isTrue);
    });

    test('"زيارة مجدولة" مشتقّة لا حالة على الشبكة', () {
      final withVisit = CaseListItemDto.fromJson({
        'status': 'in_research',
        'nextVisitDate': '2026-09-20',
      });
      final without = CaseListItemDto.fromJson({'status': 'in_research'});

      expect(withVisit.hasScheduledVisit, isTrue);
      expect(without.hasScheduledVisit, isFalse);
      // كلتاهما نفس الحالة على الشبكة.
      expect(withVisit.status, without.status);
    });

    test('حالة غير معروفة لا تُسقِط التطبيق', () {
      final item = CaseListItemDto.fromJson({'status': 'brand_new_status'});
      expect(item.status, CaseStatus.unknown);
    });

    test('returnedBy يُقرأ حين يضيفه الباك إند، ويبقى null قبل ذلك', () {
      final before = CaseListItemDto.fromJson({'status': 'returned_to_worker'});
      final after = CaseListItemDto.fromJson({
        'status': 'returned_to_worker',
        'returnedBy': 'manager',
      });

      expect(before.returnedBy, isNull);
      expect(after.returnedBy, ReturnSource.manager);
    });
  });

  group('CaseDetailsDto', () {
    final sample = {
      'id': '5b1e2a3c',
      'caseNumber': 'C-2026-000123',
      'displayId': '123',
      'status': 'assigned',
      'priority': 'urgent',
      'rowVersion': 4,
      'beneficiary': {
        'fullName': 'أحمد محمود علي',
        'nationalId': '29805142200015',
        'age': 28,
        'gender': 'male',
        'birthGovernorate': 'بني سويف',
        'rowVersion': 2,
      },
      'completion': {'percentage': 33.33, 'isReady': false},
      'workflow': {
        'currentStage': 'assigned',
        'availableActions': ['accept_assignment', 'reject_assignment'],
      },
    };

    test('يفصل rowVersion الحالة عن rowVersion المستفيد', () {
      final details = CaseDetailsDto.fromJson(sample);

      expect(details.rowVersion, 4, reason: 'نسخة صفّ الحالة');
      expect(details.beneficiary.rowVersion, 2, reason: 'نسخة صفّ المستفيد');
      expect(
        details.rowVersion,
        isNot(details.beneficiary.rowVersion),
        reason: 'عدّادان مستقلان — خلطهما يسبب 409 متكرّرًا',
      );
    });

    test('يقرأ availableActions ويتجاهل المجهول منها', () {
      final details = CaseDetailsDto.fromJson({
        ...sample,
        'workflow': {
          'availableActions': ['accept_assignment', 'future_action_x'],
        },
      });

      expect(details.availableActions, [WorkflowAction.acceptAssignment]);
      expect(details.canPerform(WorkflowAction.acceptAssignment), isTrue);
      expect(details.canPerform(WorkflowAction.submitWorkerOpinion), isFalse);
    });

    test('الحقول المشتقّة من الرقم القومي للقراءة فقط', () {
      final details = CaseDetailsDto.fromJson(sample);
      expect(details.beneficiary.age, 28);
      expect(details.beneficiary.gender, 'male');
      expect(details.beneficiary.birthGovernorate, 'بني سويف');
    });

    test('يتحمّل استجابة ناقصة', () {
      final details = CaseDetailsDto.fromJson(const <String, dynamic>{});
      expect(details.status, CaseStatus.unknown);
      expect(details.rowVersion, isNull);
      expect(details.availableActions, isEmpty);
      expect(details.isReady, isFalse);
    });
  });

  group('CaseCompletionDto', () {
    test('يحصي الأقسام الناقصة بأسمائها العربية', () {
      final completion = CaseCompletionDto.fromJson({
        'sections': [
          {'key': 'beneficiary', 'percentage': 100.0},
          {'key': 'family_members', 'percentage': 0.0},
          {'key': 'housing', 'percentage': 100.0},
          {'key': 'utilities', 'percentage': 0.0},
          {'key': 'agriculture', 'percentage': 0.0},
          {'key': 'financial', 'percentage': 0.0},
          {'key': 'initial_needs', 'percentage': 0.0},
          {'key': 'classification', 'percentage': 0.0},
          {'key': 'assessed_needs', 'percentage': 0.0},
        ],
        'overallPercentage': 22.22,
        'isReady': false,
      });

      expect(completion.overallPercentage, 22.22);
      expect(completion.isReady, isFalse);
      expect(completion.incompleteSections, contains('أفراد الأسرة'));
      expect(completion.incompleteSections, isNot(contains('السكن')));
      expect(completion.incompleteSections, hasLength(7));
    });

    test('الأقسام التسعة المحسوبة فقط — لا مرفقات ولا دعم ولا رأي', () {
      expect(CaseCompletionDto.sectionKeys, hasLength(9));
      expect(CaseCompletionDto.sectionKeys, isNot(contains('attachments')));
      expect(CaseCompletionDto.sectionKeys, isNot(contains('support')));
      expect(CaseCompletionDto.sectionKeys, isNot(contains('opinion')));
    });
  });

  group('CaseStatus', () {
    test('نافذة العمل الميداني محصورة في حالتين', () {
      expect(CaseStatus.inResearch.allowsFieldWork, isTrue);
      expect(CaseStatus.returnedToWorker.allowsFieldWork, isTrue);

      expect(CaseStatus.assigned.allowsFieldWork, isFalse);
      expect(CaseStatus.pendingReview.allowsFieldWork, isFalse);
      expect(CaseStatus.approved.allowsFieldWork, isFalse);
    });

    test('الحالات النهائية لا تقبل إجراءً', () {
      expect(CaseStatus.approved.isTerminal, isTrue);
      expect(CaseStatus.rejected.isTerminal, isTrue);
      expect(CaseStatus.inResearch.isTerminal, isFalse);
    });

    test('القيم العشر كلها معرّفة', () {
      const wire = [
        'draft',
        'pending_assignment',
        'assigned',
        'accepted',
        'in_research',
        'pending_review',
        'returned_to_worker',
        'pending_approval',
        'approved',
        'rejected',
      ];
      for (final value in wire) {
        expect(
          CaseStatus.fromWire(value),
          isNot(CaseStatus.unknown),
          reason: 'الحالة $value غير معرّفة',
        );
      }
    });
  });

  group('كاش الحالات', () {
    late AppDatabase db;

    setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('الشاشة تقرأ من الكاش فورًا دون شبكة', () async {
      await db
          .into(db.cachedCases)
          .insert(
            CachedCasesCompanion.insert(
              id: 'case-1',
              caseNumber: 'C-2026-000123',
              displayId: '123',
              status: 'in_research',
              priority: 'urgent',
              beneficiaryFullName: 'أحمد محمود',
              fetchedAt: DateTime.now(),
            ),
          );

      final rows = await db.select(db.cachedCases).get();
      expect(rows, hasLength(1));
      expect(rows.single.beneficiaryFullName, 'أحمد محمود');
    });

    test('تحذير الخروج يحصي العمليات المعلّقة', () async {
      final queue = SyncQueueDao(db);
      expect(await db.pendingOperationCount(), 0);

      await queue.enqueue(
        type: SyncOperationType.updateHousing,
        caseId: 'case-1',
        payload: const {},
      );

      expect(await db.pendingOperationCount(), 1);
    });
  });

  group('CasesRepository.saveSection', () {
    late AppDatabase db;
    late SyncQueueDao queue;
    late CasesRepository repo;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      queue = SyncQueueDao(db);
      // `CasesApi` غير مُستخدَم فعليًا في هذه الاختبارات (saveSection لا
      // يستدعي الشبكة مباشرة) — عميل بلا استدعاءات حقيقية كافٍ.
      repo = CasesRepository(
        api: CasesApi(
          ApiClient.create(
            tokenStore: SecureTokenStore(),
            onSessionExpired: () async {},
          ),
        ),
        db: db,
        queue: queue,
        // أوفلاين عمدًا (لا `start()`): `trySendImmediately` يرتدّ فورًا
        // لمسار `enqueue` — بالضبط سلوك ما قبل الإرسال الفوري. بلا هذا
        // الفحص كان `SyncEngine` يعامل غياب الـ APIs الحقيقية كخطأ شبكة
        // أونلاين قابل لإعادة المحاولة، لا أوفلاين، فيرمي بدل أن يُدرج
        // في الطابور.
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

    test('يكتب القسم في CachedSections دائمًا، حتى بلا apiPayload', () async {
      await repo.saveSection(
        caseId: 'case-1',
        sectionKey: 'social_assessment',
        dataJson: {'familySituation': 'أسرة من 5 أفراد'},
      );

      final saved = await repo.readSection('case-1', 'social_assessment');
      expect(saved, {'familySituation': 'أسرة من 5 أفراد'});

      // بلا apiPayload = بلا enqueue — القسم بلا endpoint في العقد.
      expect(await db.pendingOperationCount(), 0);
    });

    test('apiPayload موجود يضيف عملية للطابور بالنوع الصحيح', () async {
      await repo.saveSection(
        caseId: 'case-1',
        sectionKey: 'housing',
        dataJson: {'housingType': ['خاص']},
        apiPayload: {'ownership': 'خاص', 'rowVersion': null},
        syncType: SyncOperationType.updateHousing,
      );

      final ops = await queue.operationsForCase('case-1');
      expect(ops, hasLength(1));
      expect(ops.single.type, SyncOperationType.updateHousing.wireValue);

      final decoded = queue.decodePayload(ops.single);
      expect(decoded['ownership'], 'خاص');
    });

    test('حفظ ثانٍ لنفس القسم يحدّث الصف بدل تكراره', () async {
      await repo.saveSection(
        caseId: 'case-1',
        sectionKey: 'housing',
        dataJson: {'housingDescription': 'وصف أول'},
      );
      await repo.saveSection(
        caseId: 'case-1',
        sectionKey: 'housing',
        dataJson: {'housingDescription': 'وصف محدَّث'},
      );

      final rows = await (db.select(
        db.cachedSections,
      )..where((t) => t.caseId.equals('case-1'))).get();
      expect(rows, hasLength(1));
      expect(await repo.readSection('case-1', 'housing'), {
        'housingDescription': 'وصف محدَّث',
      });
    });

    test('readAllSections يرجع كل الأقسام المحفوظة لحالة واحدة', () async {
      await repo.saveSection(
        caseId: 'case-1',
        sectionKey: 'housing',
        dataJson: {'a': 1},
      );
      await repo.saveSection(
        caseId: 'case-1',
        sectionKey: 'utilities',
        dataJson: {'b': 2},
      );
      await repo.saveSection(
        caseId: 'case-2',
        sectionKey: 'housing',
        dataJson: {'c': 3},
      );

      final sections = await repo.readAllSections('case-1');
      expect(sections.keys, containsAll(['housing', 'utilities']));
      expect(sections, isNot(contains('case-2')));
      expect(sections.length, 2);
    });
  });

  group('CasesRepository.submitWorkerOpinion', () {
    late AppDatabase db;
    late SyncQueueDao queue;
    late CasesRepository repo;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      queue = SyncQueueDao(db);
      repo = CasesRepository(
        api: CasesApi(
          ApiClient.create(
            tokenStore: SecureTokenStore(),
            onSessionExpired: () async {},
          ),
        ),
        db: db,
        queue: queue,
        // أوفلاين عمدًا — راجع تعليق المجموعة أعلاه.
        syncEngine: SyncEngine(
          queue: queue,
          networkStatus: NetworkStatusService(),
          ensureFreshSession: () async => true,
          uploadAttachmentsForCase: (_) async {},
          submitPendingVisitsForCase: (_) async {},
        ),
      );

      await db
          .into(db.cachedCases)
          .insert(
            CachedCasesCompanion.insert(
              id: 'case-1',
              caseNumber: 'C-1',
              displayId: '1',
              status: CaseStatus.inResearch.wireValue,
              priority: 'medium',
              beneficiaryFullName: 'فلانة الفلانية',
              rowVersion: const Value(6),
              fetchedAt: DateTime.now(),
            ),
          );
    });

    tearDown(() => db.close());

    test('يحوّل الحالة محليًا لـ pending_review ويضيف عملية بالنوع والحمولة الصحيحة', () async {
      await repo.submitWorkerOpinion(
        caseId: 'case-1',
        decision: 'accepted',
        notes: 'تمت الزيارة الميدانية',
      );

      final cached = await repo.readCase('case-1');
      expect(cached!.status, CaseStatus.pendingReview.wireValue);
      expect(cached.syncState, 'pendingSync');

      final ops = await queue.operationsForCase('case-1');
      expect(ops, hasLength(1));
      expect(ops.single.type, SyncOperationType.submitWorkerOpinion.wireValue);
      // §6/§15.3: مسارات سير العمل تتطلب Idempotency-Key يُولَّد وقت enqueue.
      expect(ops.single.idempotencyKey, isNotNull);

      final decoded = queue.decodePayload(ops.single);
      expect(decoded['decision'], 'accepted');
      expect(decoded['notes'], 'تمت الزيارة الميدانية');
      expect(decoded['caseRowVersion'], 6);
    });

    test('حالة غير موجودة محليًا لا تكتب شيئًا ولا تضيف للطابور', () async {
      await repo.submitWorkerOpinion(caseId: 'case-unknown', decision: 'accepted');

      expect(await db.pendingOperationCount(), 0);
    });
  });
}

