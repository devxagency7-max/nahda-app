import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/sync/sync_operation.dart';
import '../../../core/sync/sync_queue.dart';
import '../domain/case_status.dart';
import 'cases_api.dart';
import 'dto/case_details_dto.dart';
import 'dto/case_list_item_dto.dart';

/// نتيجة عملية تحديث من الشبكة.
class RefreshOutcome {
  const RefreshOutcome({this.error});

  /// `null` عند النجاح.
  final ApiException? error;

  bool get isSuccess => error == null;

  /// هل الفشل بسبب انقطاع الشبكة (لا خطأ حقيقي)؟
  ///
  /// نميّزه لأن الواجهة تعرض بيانات الكاش بهدوء بدل رسالة خطأ مزعجة.
  bool get isOfflineFailure => error?.isRetryable ?? false;
}

/// مستودع الحالات — **يقرأ من Drift دائمًا، لا من الشبكة**.
///
/// المبدأ الحاكم (§2.1 من خطة الربط): قاعدة البيانات المحلية هي مصدر الحقيقة
/// للواجهة. الشاشة تشترك في `Stream` من Drift؛ [refreshWorkQueue] و
/// [refreshCaseDetails] تجلبان من الشبكة وتكتبان في Drift فتتحدّث الشاشة.
///
/// لا شاشة تنتظر الشبكة، ولا شاشة تفشل لانقطاعها.
class CasesRepository {
  CasesRepository({
    required CasesApi api,
    required AppDatabase db,
    required SyncQueueDao queue,
  }) : _api = api,
       _db = db,
       _queue = queue;

  final CasesApi _api;
  final AppDatabase _db;
  final SyncQueueDao _queue;

  // ───────────────────────── القراءة من الكاش ─────────────────────────

  /// طابور عمل الأخصائي من الكاش.
  ///
  /// يظهر فورًا عند فتح التطبيق حتى بلا اتصال.
  Stream<List<CachedCaseRow>> watchWorkQueue() {
    return (_db.select(_db.cachedCases)
          ..where(
            (t) => t.status.isIn([
              'assigned',
              'in_research',
              'returned_to_worker',
            ]),
          )
          ..orderBy([
            // العاجل أولًا، ثم الأقدم تحديثًا.
            (t) => OrderingTerm.desc(t.nextVisitDate),
            (t) => OrderingTerm.desc(t.fetchedAt),
          ]))
        .watch();
  }

  Stream<List<CachedCaseRow>> watchBookmarked() =>
      (_db.select(_db.cachedCases)
            ..where((t) => t.isBookmarked.equals(true))
            ..orderBy([(t) => OrderingTerm.desc(t.fetchedAt)]))
          .watch();

  Stream<List<CachedCaseRow>> watchReturned() =>
      (_db.select(_db.cachedCases)
            ..where((t) => t.status.equals('returned_to_worker'))
            ..orderBy([(t) => OrderingTerm.desc(t.serverUpdatedAt)]))
          .watch();

  Stream<CachedCaseRow?> watchCase(String caseId) =>
      (_db.select(_db.cachedCases)..where((t) => t.id.equals(caseId)))
          .watchSingleOrNull();

  Future<CachedCaseRow?> readCase(String caseId) =>
      (_db.select(_db.cachedCases)..where((t) => t.id.equals(caseId)))
          .getSingleOrNull();

  /// تفاصيل الحالة من الكاش، مُفكوكة من JSON المخزَّن.
  Future<CaseDetailsDto?> cachedDetails(String caseId) async {
    final row = await readCase(caseId);
    final raw = row?.detailsJson;
    if (raw == null) return null;
    try {
      return CaseDetailsDto.fromJson(jsonDecode(raw));
    } on FormatException {
      return null;
    }
  }

  // ───────────────────────── بحث حيّ (بلا كاش) ─────────────────────────

  /// `GET /search/cases` — نتيجة حيّة من الشبكة مباشرة، لا تُكتب في Drift ولا
  /// تُقرأ منه: نتيجة بحث قديمة مضلِّلة أكثر من عدم وجود نتيجة (على عكس
  /// [refreshWorkQueue]، اللي الكاش فيه هو مصدر الحقيقة للواجهة). يُستخدم من
  /// شريط البحث والتحقق من تكرار الحالة عند التسجيل. يرمي [ApiException] عند
  /// فشل الشبكة — على المستدعي التعامل معه (الشاشات الحالية بالفعل عندها
  /// حالة خطأ لذلك).
  Future<List<CaseListItemDto>> search({
    String? q,
    String? name,
    String? nationalId,
    String? charity,
    String? region,
    String? phone,
    String? date,
    int page = 1,
    int limit = 20,
  }) async {
    final paged = await _api.search(
      q: q,
      name: name,
      nationalId: nationalId,
      charity: charity,
      region: region,
      phone: phone,
      date: date,
      page: page,
      limit: limit,
    );
    return paged.items;
  }

  // ───────────────────────── التحديث من الشبكة ─────────────────────────

  /// يجلب طابور العمل ويكتبه في Drift.
  ///
  /// الفشل **لا يرمي** — يرجع [RefreshOutcome] لأن الواجهة تظلّ تعرض الكاش.
  /// رمي استثناء هنا يعني شاشة خطأ لأخصائي بياناته موجودة أصلًا على الجهاز.
  Future<RefreshOutcome> refreshWorkQueue() async {
    try {
      final paged = await _api.workQueue(page: 1, limit: 100);
      await _upsertListItems(paged.items);
      return const RefreshOutcome();
    } on ApiException catch (e) {
      return RefreshOutcome(error: e);
    }
  }

  /// يجلب تفاصيل حالة كاملة ويكتبها في Drift.
  ///
  /// **يجب استدعاؤها قبل أي كتابة** للحصول على `rowVersion` طازج — تعديل قسم
  /// آخر (أو مستخدم آخر) قد يكون رفع نسخة الحالة بينما نحن أوفلاين (§19).
  Future<RefreshOutcome> refreshCaseDetails(String caseId) async {
    try {
      final details = await _api.details(caseId);
      await _upsertDetails(details);
      return const RefreshOutcome();
    } on ApiException catch (e) {
      return RefreshOutcome(error: e);
    }
  }

  /// يجلب أفراد الأسرة التابعين من الخادم (`GET /cases/{id}/family-members`)
  /// ويخزّنهم في `CachedSections['family_members']` بنفس الشكل الذي يكتبه
  /// `FamilyMembersMapper.toCacheJson` — فيقرأهما `CaseDetailsRepositoryImpl`
  /// كأي قسم محفوظ محليًا. لا يمس `isDirty`/الطابور: هذه قراءة، لا كتابة
  /// معلّقة للمزامنة.
  ///
  /// أسماء حقول الفرد في الاستجابة (`relation`, `nationalId`, `age`,
  /// `gender`, `isStudent`, `educationStage`, `grade`, `university`,
  /// `education`, `job`, `monthlyIncome`, `takafulBeneficiary`,
  /// `takafulAmount`, `notes`) مطابقة لشكل جسم الـ `PUT` المقابل (§19) —
  /// نقرأ بديلًا احتياطيًا (`relationship`) فقط تحسبًا لاختلاف تسمية من
  /// طرف الخادم لم يُوثَّق بعد.
  Future<RefreshOutcome> refreshFamilyMembers(String caseId) async {
    try {
      final response = await _api.familyMembers(caseId);
      final rawMembers = response['members'] as List? ?? const [];

      final members = [
        for (final m in rawMembers.whereType<Map<String, dynamic>>())
          {
            'name': m['name'] as String? ?? '',
            'relation': (m['relation'] ?? m['relationship']) as String? ?? '',
            'nationalId': m['nationalId'] as String?,
            'age': m['age'] as int?,
            'gender': m['gender'] as String?,
            'isStudent': m['isStudent'] as bool? ?? false,
            'educationStage': m['educationStage'] as String?,
            'educationGrade': m['grade'] as String?,
            'universityName': m['university'] as String?,
            'nonStudentEducation': m['education'] as String?,
            'job': m['job'] as String?,
            'monthlyIncome': (m['monthlyIncome'] as num?)?.toDouble(),
            'takafulKarama': m['takafulBeneficiary'] as bool? ?? false,
            'takafulKaramaAmount': (m['takafulAmount'] as num?)?.toDouble(),
            'notes': m['notes'] as String?,
          },
      ];

      await _db
          .into(_db.cachedSections)
          .insertOnConflictUpdate(
            CachedSectionsCompanion.insert(
              caseId: caseId,
              sectionKey: 'family_members',
              dataJson: jsonEncode({'members': members}),
              rowVersion: const Value(null),
              isDirty: const Value(false),
              updatedAt: DateTime.now(),
            ),
          );

      return const RefreshOutcome();
    } on ApiException catch (e) {
      return RefreshOutcome(error: e);
    }
  }

  /// ينشئ حالة جديدة على الخادم (`POST /cases`) — **مباشر لا عبر الطابور**.
  ///
  /// خلافًا لكل الكتابات الأخرى في هذا الملف، لا يمرّ عبر `sync_queue`: نتيجة
  /// الإنشاء (`id`, `caseNumber`) لازمة للانتقال لشاشة الحالة فورًا، وتأجيلها
  /// بلا معنى. **يتطلب اتصالًا فعليًا** — يرمي [ApiException] مباشرة (لا
  /// [RefreshOutcome]) لأن الشاشة تحتاج تمييز أخطاء التحقق (`422`) وتكرار
  /// الرقم القومي (`409 DUPLICATE_NATIONAL_ID`) حقلًا حقلًا، لا مجرد "فشل".
  ///
  /// **لا يكتب في الكاش المحلي** — الحالة الناتجة `unassigned` (لحين تنفيذ
  /// `BACKEND_CHANGE_REQUEST_4.md`)، فلن تظهر في `watchWorkQueue` على أي حال
  /// (يشترط `assigned`+). الشاشة المستدعية تعرض رقم الحالة من الاستجابة
  /// مباشرة، ولا تعتمد على ظهورها في أي قائمة محلية.
  Future<Map<String, dynamic>> createCase(Map<String, dynamic> payload) =>
      _api.create(payload);

  /// تحميل مسبق لكل حالات طابور العمل — استعدادًا للخروج للميدان.
  ///
  /// يجلب **التفاصيل الكاملة** لا العناوين فقط، فالأخصائي قد يقضي اليوم بلا
  /// تغطية. [onProgress] لعرض التقدّم.
  Future<RefreshOutcome> prefetchForFieldWork({
    void Function(int done, int total)? onProgress,
  }) async {
    final queueResult = await refreshWorkQueue();
    if (!queueResult.isSuccess) return queueResult;

    final cases = await (_db.select(
      _db.cachedCases,
    )..where(
          (t) => t.status.isIn(['assigned', 'in_research', 'returned_to_worker']),
        ))
        .get();

    ApiException? firstError;
    var done = 0;

    for (final row in cases) {
      final result = await refreshCaseDetails(row.id);
      if (!result.isSuccess) {
        firstError ??= result.error;
        // انقطاع الشبكة يوقف الباقي؛ خطأ حالة واحدة لا يوقف الباقي.
        if (result.isOfflineFailure) break;
      }
      onProgress?.call(++done, cases.length);
    }

    return RefreshOutcome(error: firstError);
  }

  // ───────────────────────── الكتابة ─────────────────────────

  /// حفظ قسم واحد من أقسام شاشة تفاصيل الحالة — **الجهة الوحيدة** التي تكتب
  /// في `CachedSections` (§3 من خطة المرحلة ٣).
  ///
  /// يكتب محليًا **دائمًا** (`isDirty: true`) بصرف النظر عن وجود مسار شبكة —
  /// الأخصائي لا يجب أن يفقد عمله لمجرد أن القسم لا يملك `PUT` في العقد بعد.
  ///
  /// [apiPayload]/[syncType] معًا أو لا شيء: قسم بلا `apiPayload` يُحفَظ محليًا
  /// فقط بلا `enqueue` — هذه بالضبط الأقسام الموثّقة في `BACKEND_CHANGE_REQUEST.md`
  /// كفجوة (`SocialAssessmentSection`, تفاصيل رأي الأخصائي الحرة...).
  Future<void> saveSection({
    required String caseId,
    required String sectionKey,
    required Map<String, dynamic> dataJson,
    Map<String, dynamic>? apiPayload,
    SyncOperationType? syncType,
    int? rowVersion,
  }) async {
    assert(
      (apiPayload == null) == (syncType == null),
      'apiPayload و syncType يجب أن يُمرَّرا معًا أو لا شيء — قسم بلا مسار '
      'شبكة لا يحمل نوع مزامنة، وقسم له مسار لا يجوز أن يُهمَل نوعه.',
    );

    final now = DateTime.now();

    await _db
        .into(_db.cachedSections)
        .insertOnConflictUpdate(
          CachedSectionsCompanion.insert(
            caseId: caseId,
            sectionKey: sectionKey,
            dataJson: jsonEncode(dataJson),
            rowVersion: Value(rowVersion),
            isDirty: const Value(true),
            updatedAt: now,
          ),
        );

    if (apiPayload != null && syncType != null) {
      await _queue.enqueue(
        type: syncType,
        caseId: caseId,
        payload: apiPayload,
        rowVersion: rowVersion,
      );
    }
  }

  /// يقرأ قسمًا محفوظًا محليًا لهذه الحالة، أو `null` إن لم يُحفَظ بعد.
  Future<Map<String, dynamic>?> readSection(
    String caseId,
    String sectionKey,
  ) async {
    final row =
        await (_db.select(_db.cachedSections)..where(
              (t) => t.caseId.equals(caseId) & t.sectionKey.equals(sectionKey),
            ))
            .getSingleOrNull();
    if (row == null) return null;
    try {
      final decoded = jsonDecode(row.dataJson);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  /// كل الأقسام المحفوظة محليًا لحالة واحدة — لبناء `CaseFullDetails` كاملة
  /// دفعة واحدة بدل استعلام منفصل لكل قسم.
  Future<Map<String, Map<String, dynamic>>> readAllSections(
    String caseId,
  ) async {
    final rows = await (_db.select(
      _db.cachedSections,
    )..where((t) => t.caseId.equals(caseId))).get();

    final result = <String, Map<String, dynamic>>{};
    for (final row in rows) {
      try {
        final decoded = jsonDecode(row.dataJson);
        if (decoded is Map<String, dynamic>) result[row.sectionKey] = decoded;
      } on FormatException {
        continue;
      }
    }
    return result;
  }

  /// قبول تكليف/استلام حالة — `POST /cases/{id}/accept` عبر طابور المزامنة.
  ///
  /// يغطّي كلا مساري الخادم بلا تفريق من هنا (§2.2 من عقد الموبايل):
  /// **AcceptAssignment** (الحالة `assigned` لك فعلًا) و **SelfAcceptCase**
  /// (الحالة `pending_assignment` غير مُسندة لأحد — أي أخصائي يقبلها). القرار
  /// كله خادمي.
  ///
  /// يكتب محليًا **فورًا** (حالة الصفّ تتحول إلى `in_research` تفاؤليًا،
  /// فتختفي الحالة من شاشة "قبول الحالات" وتظهر في "كل حالاتي" فورًا) ثم
  /// يضع العملية في الطابور بنوع [SyncOperationType.acceptCase] — يتطلب
  /// `Idempotency-Key` (يُولَّد مرة واحدة هنا في `enqueue` ولا يتغيّر بعدها،
  /// §6/§15.3)، ويحمل `caseRowVersion` الحالي كحارس تزامن (§5).
  ///
  /// لو فشل الإرسال لاحقًا بتعارض (409) أو انتقال غير صالح (422) — العملية
  /// تبقى في الطابور بحالة `conflict`/`dead_lettered` وتظهر في شاشة حالة
  /// المزامنة؛ لا نتراجع محليًا عن الكتابة التفاؤلية هنا تلقائيًا، لأن ذلك
  /// قرار يحتاج عرضًا صريحًا للمستخدم لا انقلابًا صامتًا للحالة.
  Future<void> acceptAssignment(String caseId) async {
    final row = await readCase(caseId);
    if (row == null) return;

    await (_db.update(_db.cachedCases)..where((t) => t.id.equals(caseId)))
        .write(
          CachedCasesCompanion(
            status: Value(CaseStatus.inResearch.wireValue),
            syncState: const Value('pendingSync'),
          ),
        );

    await _queue.enqueue(
      type: SyncOperationType.acceptCase,
      caseId: caseId,
      payload: {'caseRowVersion': row.rowVersion},
      rowVersion: row.rowVersion,
    );
  }

  /// إرسال رأي الأخصائي — `POST /cases/{id}/opinions/worker` عبر طابور
  /// المزامنة. ينقل الحالة لـ `pending_review` ويُخرجها من نافذة تعديل
  /// الأخصائي.
  ///
  /// [decision] القيمة السلكية فقط: `'accepted'` أو `'rejected'` — المتصل
  /// (شاشة التفاصيل) مسؤول عن تحويل اختيار الأخصائي لها قبل النداء هنا.
  ///
  /// بوابة الإكمال 100% **يفرضها الخادم دائمًا** ولا تُقلَّد هنا (§20) —
  /// لو رفضها لاحقًا أثناء التفريغ، العملية تدخل `dead_lettered` (خطأ
  /// `VALIDATION_ERROR` غير قابل لإعادة المحاولة) وتظهر برسالة الخادم
  /// نفسها في شاشة حالة المزامنة؛ **لا نتراجع محليًا عن الكتابة التفاؤلية
  /// هنا تلقائيًا**، بنفس منطق [acceptAssignment] أعلاه — انقلاب صامت للحالة
  /// أسوأ من عرض صريح للمستخدم.
  Future<void> submitWorkerOpinion({
    required String caseId,
    required String decision,
    String? notes,
  }) async {
    final row = await readCase(caseId);
    if (row == null) return;

    await (_db.update(_db.cachedCases)..where((t) => t.id.equals(caseId)))
        .write(
          CachedCasesCompanion(
            status: Value(CaseStatus.pendingReview.wireValue),
            syncState: const Value('pendingSync'),
          ),
        );

    await _queue.enqueue(
      type: SyncOperationType.submitWorkerOpinion,
      caseId: caseId,
      payload: {
        'decision': decision,
        'notes': notes,
        'caseRowVersion': row.rowVersion,
      },
      rowVersion: row.rowVersion,
    );
  }

  /// تبديل الحفظ — يكتب محليًا **فورًا** ويضع العملية في الطابور.
  ///
  /// الواجهة تستجيب لحظيًا؛ الرفع يحدث حين تسمح الشبكة.
  Future<void> toggleBookmark(String caseId) async {
    final row = await readCase(caseId);
    if (row == null) return;

    final next = !row.isBookmarked;

    await (_db.update(_db.cachedCases)..where((t) => t.id.equals(caseId)))
        .write(CachedCasesCompanion(isBookmarked: Value(next)));

    await _queue.enqueue(
      type: next
          ? SyncOperationType.bookmarkCase
          : SyncOperationType.unbookmarkCase,
      caseId: caseId,
      payload: const {},
    );
  }

  // ───────────────────────── الكتابة في الكاش ─────────────────────────

  Future<void> _upsertListItems(List<CaseListItemDto> items) async {
    if (items.isEmpty) return;
    final now = DateTime.now();

    await _db.batch((batch) {
      for (final item in items) {
        batch.insert(
          _db.cachedCases,
          CachedCasesCompanion.insert(
            id: item.id,
            caseNumber: item.caseNumber,
            displayId: item.displayId,
            status: item.status.wireValue,
            priority: item.priority.wireValue,
            beneficiaryFullName: item.beneficiaryFullName,
            nationalId: Value(item.nationalId),
            charityId: Value(item.charityId),
            registrationDate: Value(item.registrationDate),
            completionPercentage: Value(item.completionPercentage),
            nextVisitDate: Value(item.nextVisitDate),
            nextVisitStartTimeUtc: Value(item.nextVisitStartTimeUtc),
            nextVisitLocation: Value(item.nextVisitLocation),
            isBookmarked: Value(item.isBookmarked),
            fetchedAt: now,
          ),
          // القائمة لا تحمل التفاصيل — نحدّث حقول العنوان فقط ونُبقي
          // `detailsJson` و `rowVersion` كما هما حتى لا نمحو تفاصيل مُحمَّلة.
          onConflict: DoUpdate(
            (_) => CachedCasesCompanion(
              caseNumber: Value(item.caseNumber),
              displayId: Value(item.displayId),
              status: Value(item.status.wireValue),
              priority: Value(item.priority.wireValue),
              beneficiaryFullName: Value(item.beneficiaryFullName),
              nationalId: Value(item.nationalId),
              charityId: Value(item.charityId),
              registrationDate: Value(item.registrationDate),
              completionPercentage: Value(item.completionPercentage),
              nextVisitDate: Value(item.nextVisitDate),
              nextVisitStartTimeUtc: Value(item.nextVisitStartTimeUtc),
              nextVisitLocation: Value(item.nextVisitLocation),
              isBookmarked: Value(item.isBookmarked),
              fetchedAt: Value(now),
            ),
          ),
        );
      }
    });
  }

  Future<void> _upsertDetails(CaseDetailsDto details) async {
    final now = DateTime.now();
    final json = jsonEncode(_detailsToJson(details));

    await _db
        .into(_db.cachedCases)
        .insertOnConflictUpdate(
          CachedCasesCompanion.insert(
            id: details.id,
            caseNumber: details.caseNumber,
            displayId: details.displayId,
            status: details.status.wireValue,
            priority: details.priority.wireValue,
            beneficiaryFullName: details.beneficiary.fullName,
            nationalId: Value(details.beneficiary.nationalId),
            charityId: Value(details.charityId),
            registrationDate: Value(details.registrationDate),
            completionPercentage: Value(details.completionPercentage),
            rowVersion: Value(details.rowVersion),
            beneficiaryRowVersion: Value(details.beneficiary.rowVersion),
            availableActionsJson: Value(
              jsonEncode(
                details.availableActions
                    .map((a) => a.wireValue)
                    .toList(growable: false),
              ),
            ),
            detailsJson: Value(json),
            hasFullDetails: const Value(true),
            serverUpdatedAt: Value(details.updatedAtUtc),
            fetchedAt: now,
          ),
        );
  }

  /// يحفظ استجابة التفاصيل كما وصلت تقريبًا، لإعادة بنائها أوفلاين.
  Map<String, dynamic> _detailsToJson(CaseDetailsDto d) => {
    'id': d.id,
    'caseNumber': d.caseNumber,
    'displayId': d.displayId,
    'status': d.status.wireValue,
    'priority': d.priority.wireValue,
    'charityId': d.charityId,
    'registrationDate': d.registrationDate,
    'createdAtUtc': d.createdAtUtc?.toIso8601String(),
    'updatedAtUtc': d.updatedAtUtc?.toIso8601String(),
    'rowVersion': d.rowVersion,
    'beneficiary': {
      'fullName': d.beneficiary.fullName,
      'nationalId': d.beneficiary.nationalId,
      'age': d.beneficiary.age,
      'gender': d.beneficiary.gender,
      'birthGovernorate': d.beneficiary.birthGovernorate,
      'phonePrimary': d.beneficiary.phonePrimary,
      'phoneSecondary': d.beneficiary.phoneSecondary,
      'address': d.beneficiary.address,
      'centerId': d.beneficiary.centerId,
      'villageId': d.beneficiary.villageId,
      'rowVersion': d.beneficiary.rowVersion,
    },
    'completion': {
      'percentage': d.completionPercentage,
      'isReady': d.isReady,
    },
    'workflow': {
      'currentStage': d.status.wireValue,
      'availableActions': d.availableActions
          .map((a) => a.wireValue)
          .toList(growable: false),
    },
    if (d.returnInfo != null)
      'returnInfo': {
        'returnedBy': d.returnInfo!.returnedBy.wireValue,
        'returnedByName': d.returnInfo!.returnedByName,
        'reason': d.returnInfo!.reason,
        'returnedAtUtc': d.returnInfo!.returnedAtUtc?.toIso8601String(),
      },
  };
}
