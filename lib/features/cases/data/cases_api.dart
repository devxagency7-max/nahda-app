import '../../../core/network/api_client.dart';
import '../../../core/network/api_envelope.dart';
import '../domain/case_status.dart';
import 'dto/case_details_dto.dart';
import 'dto/case_list_item_dto.dart';

/// استدعاءات مسارات الحالات — §19 و §21 من العقد.
///
/// **تُستدعى من `SyncEngine` وطبقة التحديث فقط**، لا من الواجهة مباشرة.
class CasesApi {
  const CasesApi(this._client);

  final ApiClient _client;

  /// `GET /dashboard/work-queue` — طابور عمل الأخصائي.
  ///
  /// بلا معاملات فلترة: الدور والهوية من الـ JWT يحدّدان المحتوى تمامًا.
  /// للأخصائي: حالاته في `assigned` / `in_research` / `returned_to_worker`.
  ///
  /// **انتبه (§21):** `page <= 0` أو `limit <= 0` يرجعان **422** هنا، بينما
  /// البحث والمرفقات يقصّان بصمت. لذا نضمن قيمًا موجبة قبل الإرسال.
  Future<Paged<CaseListItemDto>> workQueue({int page = 1, int limit = 20}) =>
      _client.get<Paged<CaseListItemDto>>(
        '/dashboard/work-queue',
        (data) => Paged.fromJson(data, CaseListItemDto.fromJson),
        query: {
          'page': page < 1 ? 1 : page,
          'limit': limit < 1 ? 20 : (limit > 100 ? 100 : limit),
        },
      );

  /// `GET /dashboard/stats` — مؤشرات لوحة المعلومات.
  ///
  /// الشكل `Map<String,int>` **يختلف حسب الدور**. للأخصائي ثلاثة حقول فقط:
  /// `totalCases`, `acceptedCases`, `rejectedCases`. الحقل غير الخاص بالدور
  /// **غائب من الـ JSON** لا `null` ولا صفر — لذا لا نمذجة صارمة له (§21).
  Future<Map<String, int>> stats() => _client.get<Map<String, int>>(
    '/dashboard/stats',
    (data) {
      final json = data is Map<String, dynamic>
          ? data
          : const <String, dynamic>{};
      final result = <String, int>{};
      json.forEach((key, value) {
        if (value is num) result[key] = value.toInt();
      });
      return result;
    },
  );

  /// `GET /cases` — الفلاتر الموجودة فعلًا: `status` و `bookmarked` فقط.
  ///
  /// **لا يوجد** `assignedTo` ولا `centerId` ولا `priority` — العقد يصحّح هذا
  /// صراحةً (§19). لحالات الأخصائي استخدم [workQueue].
  Future<Paged<CaseListItemDto>> list({
    CaseStatus? status,
    bool? bookmarked,
    int page = 1,
    int limit = 20,
  }) => _client.get<Paged<CaseListItemDto>>(
    '/cases',
    (data) => Paged.fromJson(data, CaseListItemDto.fromJson),
    query: {
      if (status != null && status != CaseStatus.unknown)
        'status': status.wireValue,
      if (bookmarked != null) 'bookmarked': bookmarked,
      'page': page,
      'limit': limit,
    },
  );

  /// `GET /cases/{id}` — التفاصيل الكاملة، خام كما وصلت من الخادم.
  ///
  /// كل استدعاء ناجح يسجّل حدث تدقيق `CASE_VIEWED` على الخادم — لذا يُستدعى
  /// **مرة واحدة فقط**، والمُستدعي (`CasesRepository.refreshCaseDetails`)
  /// يبني منها `CaseDetailsDto` **و** يقرأ أقسام `housing`/`utilities`/
  /// `agriculture`/`financial`/`initialNeeds`/`classification`/
  /// `assessedNeeds`/`familyMembers` المضمّنة فيها (BACKEND_CHANGE_RESPONSE
  /// طلب 13) — إرجاعها خامًا هنا يمنع استدعاءً ثانيًا لنفس المسار.
  Future<Map<String, dynamic>> details(String caseId) =>
      _client.get<Map<String, dynamic>>('/cases/$caseId', Parse.object);

  /// `GET /cases/{id}/completion` — نسب الإكمال لكل قسم.
  Future<CaseCompletionDto> completion(String caseId) =>
      _client.get<CaseCompletionDto>(
        '/cases/$caseId/completion',
        CaseCompletionDto.fromJson,
      );

  /// `GET /cases/{id}/family-members`.
  ///
  /// يرجع `caseRowVersion` (نسخة **الحالة**) للاستخدام في الـ PUT التالي،
  /// إضافةً لحقلين محسوبين للقراءة فقط: `computedCurrentAge` و
  /// `computedCurrentEducationStage`.
  Future<Map<String, dynamic>> familyMembers(String caseId) =>
      _client.get<Map<String, dynamic>>(
        '/cases/$caseId/family-members',
        Parse.object,
      );

  /// `GET /cases/{caseId}/support` — الدعم المقترح + المعتمد + سجل الدعم
  /// المصروف قديمًا (`history[]`)، خام كما وصل من الخادم (§19.5).
  ///
  /// للعرض فقط هنا — لا `PUT` مرتبط بهذا الاستدعاء. `history[].recipientName`
  /// نص حر (لا `familyMemberId`)، فالمطابقة مع فرد بعينه تتم بالاسم لا بمعرّف.
  Future<Map<String, dynamic>> support(String caseId) =>
      _client.get<Map<String, dynamic>>('/cases/$caseId/support', Parse.object);

  /// `GET /search/cases`.
  ///
  /// **انتبه:** `national_id` بصيغة snake_case في الـ query — لا `nationalId`.
  /// وأخطاء الحقول ترجع بمفاتيح PascalCase (`NationalId`) لا بصيغة الـ query.
  ///
  /// الحقول النصّية الأربعة (`q`, `name`, `charity`, `region`) ترفض أقل من
  /// حرفين بـ 422، بينما `national_id` و `phone` بلا حدّ أدنى.
  Future<Paged<CaseListItemDto>> search({
    String? q,
    String? name,
    String? nationalId,
    String? charity,
    String? region,
    String? phone,
    String? date,
    int page = 1,
    int limit = 20,
  }) => _client.get<Paged<CaseListItemDto>>(
    '/search/cases',
    (data) => Paged.fromJson(data, CaseListItemDto.fromJson),
    query: {
      'q': q,
      'name': name,
      'national_id': nationalId,
      'charity': charity,
      'region': region,
      'phone': phone,
      'date': date,
      'page': page,
      'limit': limit,
    },
  );

  /// `POST /cases` — إنشاء حالة جديدة (draft) مع بيانات المستفيد الأساسية.
  ///
  /// **يتطلب اتصالًا فوريًا** — لا يمرّ عبر طابور المزامنة (`SyncQueueDao`)
  /// خلافًا لكل عمليات الكتابة الأخرى في هذا الملف، لأن النتيجة (`id`,
  /// `caseNumber`) لا زمة للشاشة التالية فورًا ولا معنى لتأجيلها. يُستدعى
  /// مباشرة من `CasesRepository.createCase`، لا من `SyncEngine`.
  ///
  /// **صلاحية `create_case` مطلوبة** — أُضيفت لدور `social_worker` بتاريخ
  /// 2026-09-19 (`BACKEND_CHANGE_RESPONSE_3.md`). الحالة تُنشأ حاليًا
  /// **غير مُسنَدة** (`unassigned`) — الإسناد التلقائي للمُنشئ طُلب في
  /// `BACKEND_CHANGE_REQUEST_4.md` ولم يُنفَّذ بعد من جهة الباك إند.
  ///
  /// **الحقول المحسوبة خادميًا بالكامل، لا تُرسَل أبدًا:** `age`, `gender`,
  /// `birthGovernorate` (من الرقم القومي)، `status` (دائمًا `draft`)،
  /// `caseNumber`/`displayId` (تسلسل ذري في قاعدة البيانات).
  Future<Map<String, dynamic>> create(Map<String, dynamic> payload) =>
      _client.post<Map<String, dynamic>>(
        '/cases',
        Parse.object,
        body: payload,
      );

  /// `POST /cases/{id}/bookmark` — idempotent، بلا `rowVersion`.
  Future<void> addBookmark(String caseId) =>
      _client.post<void>('/cases/$caseId/bookmark', Parse.empty);

  /// `DELETE /cases/{id}/bookmark` — idempotent أيضًا.
  Future<void> removeBookmark(String caseId) =>
      _client.delete<void>('/cases/$caseId/bookmark', Parse.empty);

  // ---------------------------------------------------------------------
  // أقسام الحالة التسعة — كل الدوال هنا PUT كامل الاستبدال، محروسة بنسخة
  // (§19 من العقد). لا تُستدعى إلا من `SyncEngine` — الحمولة (`payload`) تأتي
  // كما خُزّنت في `sync_queue`، وقد أُعدّت مسبقًا من طبقة الـ repository.
  //
  // **تمييز حرج (§19، §2.3):** الأقسام "المفردة" (beneficiary, housing,
  // agriculture, classification) تحمل `rowVersion` الخاص بصفّها هي. الأقسام
  // "القوائم" (family-members, utilities, initial/assessed-needs, financial)
  // تحمل `caseRowVersion` — نسخة **الحالة** الأم. خلطهما يعني 409 دائم.
  // ---------------------------------------------------------------------

  /// `PUT /cases/{id}/beneficiary` — مفرد، يحمل `rowVersion` **المستفيد** لا
  /// الحالة.
  Future<Map<String, dynamic>> updateBeneficiary(
    String caseId,
    Map<String, dynamic> payload,
  ) => _client.put<Map<String, dynamic>>(
    '/cases/$caseId/beneficiary',
    Parse.object,
    body: payload,
  );

  /// `PUT /cases/{id}/family-members` — استبدال كامل، `caseRowVersion`.
  Future<Map<String, dynamic>> updateFamilyMembers(
    String caseId,
    Map<String, dynamic> payload,
  ) => _client.put<Map<String, dynamic>>(
    '/cases/$caseId/family-members',
    Parse.object,
    body: payload,
  );

  /// `PUT /cases/{id}/housing` — مفرد، `rowVersion` قابل للـ null أول مرة.
  Future<Map<String, dynamic>> updateHousing(
    String caseId,
    Map<String, dynamic> payload,
  ) => _client.put<Map<String, dynamic>>(
    '/cases/$caseId/housing',
    Parse.object,
    body: payload,
  );

  /// `PUT /cases/{id}/utilities` — أجهزة + مرافق معًا، `caseRowVersion`.
  Future<Map<String, dynamic>> updateUtilities(
    String caseId,
    Map<String, dynamic> payload,
  ) => _client.put<Map<String, dynamic>>(
    '/cases/$caseId/utilities',
    Parse.object,
    body: payload,
  );

  /// `PUT /cases/{id}/agriculture` — مفرد، `rowVersion` قابل للـ null أول
  /// مرة. الخادم يمسح الحقول الشرطية (مساحة الأرض، تفاصيل الماشية...) خادميًا
  /// حسب `hasLand`/`hasLivestock` — لا تُعِد بناء منطق المسح هذا في الواجهة.
  Future<Map<String, dynamic>> updateAgriculture(
    String caseId,
    Map<String, dynamic> payload,
  ) => _client.put<Map<String, dynamic>>(
    '/cases/$caseId/agriculture',
    Parse.object,
    body: payload,
  );

  /// `PUT /cases/{id}/financial` — البنود اليدوية فقط؛ الخادم يعيد حساب
  /// البنود الآلية (دخل رب الأسرة، تكافل، دخل/إيجار الأرض) بصمت.
  ///
  /// **المصيدة (§19):** تعديل beneficiary/agriculture/family-members يُبطل
  /// `caseRowVersion` المخزّن لهذا القسم بصمت عبر إعادة حساب الملخص وزيادة
  /// نسخة الحالة — استدعِ `GET /cases/{id}` لأخذ نسخة طازجة قبل هذا الحفظ
  /// إن كانت الحمولة المخزّنة أقدم من تعديل قسم آخر لنفس الحالة.
  Future<Map<String, dynamic>> updateFinancial(
    String caseId,
    Map<String, dynamic> payload,
  ) => _client.put<Map<String, dynamic>>(
    '/cases/$caseId/financial',
    Parse.object,
    body: payload,
  );

  /// `PUT /cases/{id}/initial-needs` — استبدال كامل، `caseRowVersion`.
  Future<Map<String, dynamic>> updateInitialNeeds(
    String caseId,
    Map<String, dynamic> payload,
  ) => _client.put<Map<String, dynamic>>(
    '/cases/$caseId/initial-needs',
    Parse.object,
    body: payload,
  );

  /// `PUT /cases/{id}/classification` — مفرد، `rowVersion` قابل للـ null أول
  /// مرة. الاستجابة ترجع `mainClassificationsJson` (نص JSON) لا مصفوفة —
  /// فكّها بـ `jsonDecode` في طبقة الاستدعاء.
  Future<Map<String, dynamic>> updateClassification(
    String caseId,
    Map<String, dynamic> payload,
  ) => _client.put<Map<String, dynamic>>(
    '/cases/$caseId/classification',
    Parse.object,
    body: payload,
  );

  /// `PUT /cases/{id}/assessed-needs` — استبدال كامل، `caseRowVersion`.
  Future<Map<String, dynamic>> updateAssessedNeeds(
    String caseId,
    Map<String, dynamic> payload,
  ) => _client.put<Map<String, dynamic>>(
    '/cases/$caseId/assessed-needs',
    Parse.object,
    body: payload,
  );

  /// `PUT /cases/{id}/charity` — endpoint جديد (رد الباك إند بتاريخ
  /// 2026-09-26) لتغيير الجمعية المسؤولة عن حالة موجودة. قبل كده مفيش أي
  /// endpoint كان يقبل تعديل charityId بعد إنشاء الحالة.
  Future<Map<String, dynamic>> updateCharity(
    String caseId,
    Map<String, dynamic> payload,
  ) => _client.put<Map<String, dynamic>>(
    '/cases/$caseId/charity',
    Parse.object,
    body: payload,
  );
}
