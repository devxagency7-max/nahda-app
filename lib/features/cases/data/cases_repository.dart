import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/network_status_service.dart';
import '../../../core/network/retry_policy.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/sync/sync_engine.dart';
import '../../../core/sync/sync_operation.dart';
import '../../../core/sync/sync_queue.dart';
import '../../case_details/data/mappers/agriculture_mapper.dart';
import '../../case_details/data/mappers/assessed_needs_mapper.dart';
import '../../case_details/data/mappers/classification_mapper.dart';
import '../../case_details/data/mappers/family_members_mapper.dart';
import '../../case_details/data/mappers/housing_mapper.dart';
import '../../case_details/data/mappers/initial_need_mapper.dart';
import '../../case_details/data/mappers/opinions_mapper.dart';
import '../../case_details/data/mappers/utilities_mapper.dart';
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

/// مستودع الحالات — Online-First: طابور العمل ([getWorkQueue]) يُجلب من
/// الخادم مباشرة عند توفّر الاتصال ويُرجَع للواجهة فورًا؛ الكاش المحلي
/// (Drift) يُحدَّث في نفس الوقت ليبقى مصدر القراءة الوحيد أثناء الأوفلاين
/// أو عند فشل الشبكة رغم كوننا أونلاين.
///
/// الحفاظ/المفضّلة/الحالات المرتجعة ([watchBookmarked], [watchReturned]) ما
/// زالت تُقرأ من الكاش مباشرة (Stream) — خارج نطاق هذا التحويل حاليًا.
class CasesRepository {
  CasesRepository({
    required CasesApi api,
    required AppDatabase db,
    required SyncQueueDao queue,
    required SyncEngine syncEngine,
    NetworkStatusService? networkStatus,
  }) : _api = api,
       _db = db,
       _queue = queue,
       _syncEngine = syncEngine,
       _networkStatus = networkStatus;

  final CasesApi _api;
  final AppDatabase _db;
  final SyncQueueDao _queue;

  /// `null` فقط في اختبارات لا تحتاج تمييز أونلاين/أوفلاين قبل قراءات
  /// online-first (`getWorkQueue`) — عندها تُعامَل كأوفلاين دومًا فتُقرأ من
  /// الكاش مباشرة، وهو المسار الذي تختبره تلك الاختبارات أصلًا.
  final NetworkStatusService? _networkStatus;

  /// يُحاوَل الإرسال عبره فورًا قبل أي `enqueue` — الاتصال هو الوضع الغالب،
  /// فتفضيله على التأجيل للطابور يعطي المستخدم شعورًا بأن عمله وصل فعلًا،
  /// لا مجرد "اتحفظ محليًا" كل مرة (راجع [SyncEngine.trySendImmediately]).
  final SyncEngine _syncEngine;
  static const _uuid = Uuid();

  // ───────────────────────── القراءة من الكاش ─────────────────────────

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

  // ───────────────────────── القراءة — Online-First ─────────────────────────

  /// طابور العمل — Online-First: يجلب من الخادم مباشرة عند توفّر الاتصال
  /// ويرجعه للواجهة فورًا (مع كتابته في الكاش)، ويقع على الكاش المحلي فقط
  /// عند الأوفلاين أو فشل شبكة حقيقي.
  Future<List<CachedCaseRow>> getWorkQueue() async {
    if (_networkStatus?.current.isOnline ?? false) {
      try {
        final paged = await RetryPolicy.run(
          () => _api.workQueue(page: 1, limit: 100),
        );
        await _upsertListItems(paged.items);
        AppLogger.data('Strategy: REMOTE (workQueue)');
      } on ApiException catch (e) {
        if (!e.isRetryable) rethrow;
        AppLogger.data('Strategy: LOCAL (workQueue) — network failure');
      }
    } else {
      AppLogger.data('Strategy: LOCAL (workQueue) — offline');
    }

    return _readWorkQueueFromCache();
  }

  Future<List<CachedCaseRow>> _readWorkQueueFromCache() {
    return (_db.select(_db.cachedCases)
          ..where(
            (t) => t.status.isIn([
              'assigned',
              'in_research',
              'returned_to_worker',
            ]),
          )
          ..orderBy([
            (t) => OrderingTerm.desc(t.nextVisitDate),
            (t) => OrderingTerm.desc(t.fetchedAt),
          ]))
        .get();
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
  ///
  /// منذ رد الباك إند على طلب 13 (`BACKEND_CHANGE_RESPONSE`)، الاستجابة
  /// نفسها تحمل كل الأقسام (`familyMembers`, `housing`, `utilities`,
  /// `agriculture`, `financial`, `initialNeeds`, `classification`,
  /// `assessedNeeds`) — نكتبها كلها في `CachedSections` هنا **فقط لو القسم
  /// غير معدَّل محليًا الآن** (`isDirty == false`)، وإلا كنا سنمحو تعديلًا
  /// معلّقًا في الطابور بنسخة الخادم القديمة قبل وصوله (§14.3، نفس قاعدة
  /// "لا تُكمل الإعادة على افتراض قديم" بس في اتجاه القراءة).
  Future<RefreshOutcome> refreshCaseDetails(String caseId) async {
    try {
      final raw = await _api.details(caseId);
      final details = CaseDetailsDto.fromJson(raw);
      await _upsertDetails(details);
      await _cacheSectionsFromDetails(caseId, raw);
      return const RefreshOutcome();
    } on ApiException catch (e) {
      return RefreshOutcome(error: e);
    }
  }

  /// يكتب كل قسم مضمّن في استجابة `GET /cases/{id}` في `CachedSections`،
  /// بنفس الشكل الذي يكتبه `saveSection` محليًا — فيقرأه `CaseDetailsRepositoryImpl`
  /// والمابرات كأي قسم محفوظ.
  Future<void> _cacheSectionsFromDetails(
    String caseId,
    Map<String, dynamic> raw,
  ) async {
    await _cacheSectionIfClean(
      caseId,
      'family_members',
      raw['familyMembers'],
      (json) => FamilyMembersMapper.toCacheJson(
        FamilyMembersMapper.fromApiResponse(json),
      ),
    );
    await _cacheSectionIfClean(
      caseId,
      'housing',
      raw['housing'],
      (json) => HousingMapper.toCacheJson(HousingMapper.fromApiResponse(json)),
    );
    await _cacheSectionIfClean(
      caseId,
      'utilities',
      raw['utilities'],
      (json) =>
          UtilitiesMapper.toCacheJson(UtilitiesMapper.fromApiResponse(json)),
    );
    await _cacheSectionIfClean(
      caseId,
      'agriculture',
      raw['agriculture'],
      (json) =>
          AgricultureMapper.toCacheJson(AgricultureMapper.fromApiResponse(json)),
    );
    await _cacheSectionIfClean(
      caseId,
      'initial_needs',
      raw['initialNeeds'],
      (json) =>
          InitialNeedMapper.toCacheJson(InitialNeedMapper.fromApiResponse(json)),
    );
    await _cacheSectionIfClean(
      caseId,
      'classification',
      raw['classification'],
      (json) => ClassificationMapper.toCacheJson(
        ClassificationMapper.fromApiResponse(json),
      ),
    );
    await _cacheSectionIfClean(
      caseId,
      'assessed_needs',
      raw['assessedNeeds'],
      (json) => AssessedNeedsMapper.toCacheJson(
        AssessedNeedsMapper.fromApiResponse(json),
      ),
    );
    // financial: لا fromApiResponse بعد — شكل الشاشة (٨ بنود افتراضية) لا
    // يطابق العقد (٥ فئات ثابتة فقط)، موثّق كتصميم يحتاج تصحيحًا منفصلًا في
    // FinancialMapper. تُترَك كما هي (كاش محلي فقط) حتى وقتها.

    // رأيا المراجع والمدير (View-only) — مفتاحان منفصلان عن 'opinions'
    // (المحجوز لمسودة الأخصائي المحلية القابلة للتعديل) حتى لا نستبدل تعديلًا
    // معلّقًا للأخصائي ببيانات قراءة، ولا العكس. رد الباك إند على طلب 14.
    final opinions = raw['opinions'];
    if (opinions is Map<String, dynamic>) {
      final parsed = OpinionsMapper.fromApiResponse(opinions);
      await _cacheSectionIfClean(
        caseId,
        'reviewer_opinion',
        opinions['reviewer'] ?? const <String, dynamic>{},
        (_) => OpinionsMapper.reviewerToCacheJson(parsed.reviewer),
      );
      await _cacheSectionIfClean(
        caseId,
        'manager_opinion',
        opinions['manager'] ?? const <String, dynamic>{},
        (_) => OpinionsMapper.directorToCacheJson(parsed.director),
      );
    }
    // آخر رأي أخصائي أُرسِل فعليًا (View-only) — `opinions.worker`، مضمَّن
    // أصلًا في `GET /cases/{id}` نفسه (بلا endpoint منفصل)، بنفس شكل
    // reviewer/manager زائد `detailedReport` متداخل جواه. مفتاح مستقل عن
    // 'opinions' (مسودة الكتابة المحلية) لنفس سبب فصل
    // reviewer_opinion/manager_opinion أعلاه.
    if (opinions is Map<String, dynamic>) {
      await _cacheSectionIfClean(
        caseId,
        'worker_opinion_previous',
        opinions['worker'] ?? const <String, dynamic>{},
        (_) => OpinionsMapper.previousWorkerToCacheJson(
          OpinionsMapper.previousWorkerFromRaw(raw),
        ),
      );
    }
  }

  Future<void> _cacheSectionIfClean(
    String caseId,
    String sectionKey,
    Object? rawSection,
    Map<String, dynamic> Function(Map<String, dynamic>) toCacheJson,
  ) async {
    if (rawSection is! Map<String, dynamic>) return;

    final existing =
        await (_db.select(_db.cachedSections)..where(
              (t) =>
                  t.caseId.equals(caseId) & t.sectionKey.equals(sectionKey),
            ))
            .getSingleOrNull();
    // تعديل معلّق لم يُرفَع بعد — لا نستبدله ببيانات الخادم القديمة.
    if (existing != null && existing.isDirty) return;

    await _db
        .into(_db.cachedSections)
        .insertOnConflictUpdate(
          CachedSectionsCompanion.insert(
            caseId: caseId,
            sectionKey: sectionKey,
            dataJson: jsonEncode(toCacheJson(rawSection)),
            rowVersion: Value(_sectionRowVersion(rawSection)),
            isDirty: const Value(false),
            updatedAt: DateTime.now(),
          ),
        );
  }

  int? _sectionRowVersion(Map<String, dynamic> json) => switch (json['rowVersion']) {
    final int i => i,
    final num n => n.toInt(),
    _ => null,
  };

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
  ///
  /// يرجع `true` لو وصل القسم للخادم فعلًا الآن. يرمي [ApiException] لو
  /// رفضه الخادم رفضًا نهائيًا (يبقى محفوظًا محليًا، ولا يدخل الطابور).
  Future<bool> saveSection({
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

    if (apiPayload == null || syncType == null) return false;

    final result = await _syncEngine.trySendImmediately(
      type: syncType,
      caseId: caseId,
      payload: apiPayload,
    );

    if (result.isSent) {
      await (_db.update(_db.cachedSections)..where(
            (t) => t.caseId.equals(caseId) & t.sectionKey.equals(sectionKey),
          ))
          .write(const CachedSectionsCompanion(isDirty: Value(false)));
      // نسخ الصفوف (rowVersion) تغيّرت على الخادم — نجلبها الآن حتى لا يحمل
      // الحفظ التالي نسخة قديمة فيرتدّ بتعارض.
      unawaited(refreshCaseDetails(caseId));
      return true;
    }
    if (result.isRejected) throw result.error!;

    await _queue.enqueue(
      type: syncType,
      caseId: caseId,
      payload: apiPayload,
      rowVersion: rowVersion,
    );
    return false;
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
  ///
  /// يرجع `true` لو وصل للخادم الآن. يرمي [ApiException] لو رفضه الخادم
  /// نهائيًا — بعد إرجاع الحالة المحلية لما كانت عليه.
  Future<bool> acceptAssignment(String caseId) async {
    final row = await readCase(caseId);
    if (row == null) return false;

    await (_db.update(_db.cachedCases)..where((t) => t.id.equals(caseId)))
        .write(
          CachedCasesCompanion(
            status: Value(CaseStatus.inResearch.wireValue),
            syncState: const Value('pendingSync'),
          ),
        );

    // يُولَّد هنا لا داخل `enqueue` — لو فشل الإرسال الفوري يصل الخادم لاحقًا
    // بنفس المفتاح (§15.3).
    final idempotencyKey = _uuid.v4();
    final payload = {'caseRowVersion': row.rowVersion};

    final result = await _syncEngine.trySendImmediately(
      type: SyncOperationType.acceptCase,
      caseId: caseId,
      payload: payload,
      idempotencyKey: idempotencyKey,
    );
    if (result.isSent) {
      await _markCaseSynced(caseId);
      return true;
    }
    if (result.isRejected) {
      await _revertCaseStatus(row);
      throw result.error!;
    }

    await _queue.enqueue(
      type: SyncOperationType.acceptCase,
      caseId: caseId,
      payload: payload,
      rowVersion: row.rowVersion,
      idempotencyKey: idempotencyKey,
    );
    return false;
  }

  Future<void> _markCaseSynced(String caseId) async {
    await (_db.update(_db.cachedCases)..where((t) => t.id.equals(caseId)))
        .write(const CachedCasesCompanion(syncState: Value('synced')));
    unawaited(refreshCaseDetails(caseId));
  }

  Future<void> _revertCaseStatus(CachedCaseRow original) =>
      (_db.update(_db.cachedCases)..where((t) => t.id.equals(original.id)))
          .write(
            CachedCasesCompanion(
              status: Value(original.status),
              syncState: Value(original.syncState),
            ),
          );

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
  ///
  /// يرجع `true` لو وصل للخادم الآن. يرمي [ApiException] لو رفضه الخادم
  /// نهائيًا (مثل "الحالة غير مكتملة بعد") — بعد إرجاع الحالة المحلية.
  Future<bool> submitWorkerOpinion({
    required String caseId,
    required String decision,
    String? notes,
  }) async {
    final row = await readCase(caseId);
    if (row == null) return false;

    await (_db.update(_db.cachedCases)..where((t) => t.id.equals(caseId)))
        .write(
          CachedCasesCompanion(
            status: Value(CaseStatus.pendingReview.wireValue),
            syncState: const Value('pendingSync'),
          ),
        );

    final idempotencyKey = _uuid.v4();
    final payload = {
      'decision': decision,
      'notes': notes,
      'caseRowVersion': row.rowVersion,
    };

    final result = await _syncEngine.trySendImmediately(
      type: SyncOperationType.submitWorkerOpinion,
      caseId: caseId,
      payload: payload,
      idempotencyKey: idempotencyKey,
    );

    if (result.isRejected) {
      await _revertCaseStatus(row);
      throw result.error!;
    }

    if (result.isSent) {
      await _markCaseSynced(caseId);
    } else {
      await _queue.enqueue(
        type: SyncOperationType.submitWorkerOpinion,
        caseId: caseId,
        payload: payload,
        rowVersion: row.rowVersion,
        idempotencyKey: idempotencyKey,
      );
    }

    // يُخزَّن هنا **فقط** للعرض عند إعادة فتح تاب الرأي — `POST
    // /opinions/worker` بلا مسار قراءة رجوع، ولا يُحذَف هذا القسم بعد
    // نجاح المزامنة (خلاف عملية الطابور نفسها) لأن التاب لسه محتاج يعرض
    // ما أُرسِل.
    final submitted = OpinionsMapper.fromWireDecision(
      decision: decision,
      notes: notes,
      submittedAtUtc: DateTime.now().toUtc(),
    );

    await _db
        .into(_db.cachedSections)
        .insertOnConflictUpdate(
          CachedSectionsCompanion.insert(
            caseId: caseId,
            sectionKey: 'opinions',
            dataJson: jsonEncode(OpinionsMapper.toCacheJson(submitted)),
            isDirty: const Value(false),
            updatedAt: DateTime.now(),
          ),
        );
    return result.isSent;
  }

  /// تبديل الحفظ — يكتب محليًا **فورًا** ثم يرسل للخادم.
  Future<void> toggleBookmark(String caseId) async {
    final row = await readCase(caseId);
    if (row == null) return;

    final next = !row.isBookmarked;

    await (_db.update(_db.cachedCases)..where((t) => t.id.equals(caseId)))
        .write(CachedCasesCompanion(isBookmarked: Value(next)));

    final type = next
        ? SyncOperationType.bookmarkCase
        : SyncOperationType.unbookmarkCase;

    final result = await _syncEngine.trySendImmediately(
      type: type,
      caseId: caseId,
      payload: const {},
    );
    if (result.isSent) return;
    if (result.isRejected) {
      await (_db.update(_db.cachedCases)..where((t) => t.id.equals(caseId)))
          .write(CachedCasesCompanion(isBookmarked: Value(row.isBookmarked)));
      throw result.error!;
    }

    await _queue.enqueue(type: type, caseId: caseId, payload: const {});
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
