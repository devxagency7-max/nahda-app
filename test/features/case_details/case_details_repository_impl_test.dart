import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nahda/core/network/api_client.dart';
import 'package:nahda/core/network/network_status_service.dart';
import 'package:nahda/core/storage/app_database.dart';
import 'package:nahda/core/storage/secure_token_store.dart';
import 'package:nahda/core/sync/sync_engine.dart';
import 'package:nahda/core/sync/sync_operation.dart';
import 'package:nahda/core/sync/sync_queue.dart';
import 'package:nahda/features/case_details/data/case_details_repository_impl.dart';
import 'package:nahda/features/case_details/data/mappers/family_members_mapper.dart';
import 'package:nahda/features/case_details/data/mappers/housing_mapper.dart';
import 'package:nahda/features/case_details/domain/sections/basic_info_family_form.dart';
import 'package:nahda/features/case_details/domain/sections/housing_form.dart';
import 'package:nahda/features/cases/data/cases_api.dart';
import 'package:nahda/features/cases/data/cases_repository.dart';

/// اختبارات ترطيب [CaseDetailsRepositoryImpl] من `CachedSections` — يتأكد
/// أن قسمًا حُفظ محليًا سابقًا يُقرأ **حرفيًا** عند إعادة فتح الشاشة، وأن
/// حالة بلا أي بيانات محلية ترجع قيمًا فاضية صادقة، لا بيانات Mock مطلقًا.
void main() {
  late AppDatabase db;
  late CasesRepository casesRepo;
  late CaseDetailsRepositoryImpl repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final queue = SyncQueueDao(db);
    casesRepo = CasesRepository(
      api: CasesApi(
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
    repo = CaseDetailsRepositoryImpl(casesRepository: casesRepo);
  });

  tearDown(() => db.close());

  test('حالة بلا أي بيانات محلية ترجع قيمًا فاضية، لا بيانات Mock', () async {
    final details = await repo.getCaseDetails('case-never-seen');

    expect(details.basicInfo.caseNumber, isEmpty);
    expect(details.basicInfo.fullName.value, isEmpty);
    expect(details.family.members, isEmpty);
    expect(details.housing, isNotNull);
    expect(details.attachments, isEmpty);
    expect(details.fieldVisit, isNull);
    expect(details.financialSummary, isNull);
    expect(details.socialWorkerOpinion, isNull);
  });

  test('أفراد الأسرة المحفوظون محليًا يُقرأون حرفيًا، لا من Mock', () async {
    final form = FamilyMembersFormData(
      members: [
        FamilyMemberFormData(
          name: 'فرد اختباري',
          relation: 'ابن',
          age: 10,
          gender: 'ذكر',
          isStudent: true,
          educationStage: 'ابتدائي',
        ),
      ],
    );

    await casesRepo.saveSection(
      caseId: 'case-unknown',
      sectionKey: 'family_members',
      dataJson: FamilyMembersMapper.toCacheJson(form),
    );

    final details = await repo.getCaseDetails('case-unknown');

    expect(details.family.members, hasLength(1));
    expect(details.family.members.single.name, 'فرد اختباري');
    expect(details.family.members.single.relationship, 'ابن');
    expect(details.family.familyMembersCount, 1);
  });

  test('السكن المحفوظ محليًا يُقرأ حرفيًا بعد enqueue', () async {
    final form = HousingFormData(housingDescription: 'وصف اختباري');
    form.walls.selected.add('طوب احمر');

    await casesRepo.saveSection(
      caseId: 'case-unknown',
      sectionKey: 'housing',
      dataJson: HousingMapper.toCacheJson(form),
      apiPayload: HousingMapper.toApiPayload(form, rowVersion: null),
      syncType: SyncOperationType.updateHousing,
    );

    final details = await repo.getCaseDetails('case-unknown');

    expect(details.housing, isNotNull);
    expect(details.housing!.description, 'وصف اختباري');
    expect(details.housing!.wallsCondition, 'طوب احمر');
  });
}
