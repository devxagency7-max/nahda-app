import '../../cases/data/cases_repository.dart';
import '../../cases/data/dto/case_details_dto.dart' as api;
import '../data/mock_case_details_repository.dart';
import '../domain/case_details_repository.dart';
import '../domain/case_full_details.dart';
import '../domain/data_source.dart';
import '../domain/sections/basic_info_section.dart' as domain;
import '../domain/sections/classification_needs_section.dart';
import '../domain/sections/family_section.dart';
import '../domain/sections/housing_section.dart';
import '../domain/sections/initial_need_section.dart';
import '../domain/sections/utilities_equipment_section.dart';

/// تنفيذ حقيقي لـ [CaseDetailsRepository] — يقرأ من الكاش المحلي
/// (`CasesRepository.cachedDetails` + `CachedSections`)، **لا شبكة مباشرة
/// إلا لـ `family_members`** (أول قسم له `GET` مستقل، راجع
/// [CasesRepository.refreshFamilyMembers]).
///
/// **الأقسام التي لها مابر محلي** (أفراد الأسرة، الاحتياج الأولي، السكن،
/// المرافق، التصنيف، الاحتياجات المُقيَّمة): تُقرأ من `CachedSections` إن
/// وُجدت، وإلا فقيمة **فاضية** (`_emptyXxx` أدناه) — لا Mock. كانت هذه
/// الأقسام تقع سابقًا على [MockCaseDetailsRepository] كل مرة لا تجد فيها
/// قسمًا محفوظًا محليًا، فتعرض بيانات وهمية ثابتة توحي بأنها بيانات الحالة
/// الحقيقية؛ إلى أن يوفّر الباك إند `GET` مستقلًا لبقية الأقسام (راجع
/// `BACKEND_CHANGE_REQUEST.md`)، الفراغ أصدق من بيانات مُختلَقة قد تُرسَل
/// للمراجع بالخطأ.
///
/// **الأقسام بلا endpoint أصلًا** (المرفقات، الزيارة الميدانية، تقييم
/// اجتماعي حر، دعم معتمد، مراجعة، الملخص المالي المحسوب خادميًا...) موثّقة
/// في `BACKEND_CHANGE_REQUEST.md` وتبقى Mock-only حتى يوفّر الباك إند مسارًا
/// لها — هذا ليس نقص تنفيذ من جهة التطبيق.
class CaseDetailsRepositoryImpl implements CaseDetailsRepository {
  CaseDetailsRepositoryImpl({
    required CasesRepository casesRepository,
    MockCaseDetailsRepository? legacyMock,
  }) : _cases = casesRepository,
       _legacyMock = legacyMock ?? MockCaseDetailsRepository();

  final CasesRepository _cases;
  final MockCaseDetailsRepository _legacyMock;

  @override
  Future<CaseFullDetails> getCaseDetails(String caseId) async {
    // يجلب أفراد الأسرة من الخادم قبل القراءة — القسم الوحيد حاليًا الذي
    // يملك `GET` مستقلًا (`CasesApi.familyMembers`)، فتُحدَّث نسخته المحلية
    // بالبيانات الحقيقية بدل الوقوع على الـ Mock أدناه. فشل الشبكة هنا
    // (أوفلاين) لا يمنع عرض ما هو مخزَّن محليًا بالفعل — نتجاهل الخطأ عمدًا.
    await _cases.refreshFamilyMembers(caseId);

    final cached = await _cases.cachedDetails(caseId);
    final sections = await _cases.readAllSections(caseId);

    // fallback كامل مؤقت للأقسام غير المُنجزة — يبقى المصدر الوحيد لما لا
    // نظام حقيقي له بعد (راجع تعليق الصنف).
    final legacy = await _legacyMock.getCaseDetails(caseId);

    return CaseFullDetails(
      basicInfo: cached != null
          ? _basicInfoFromCache(caseId, cached)
          : legacy.basicInfo,
      family: _familyFromCache(sections['family_members']) ?? _emptyFamily,
      initialNeed:
          _initialNeedFromCache(sections['initial_needs']) ?? _emptyInitialNeed,
      attachments: legacy.attachments,
      fieldVisit: legacy.fieldVisit,
      fieldVerification: legacy.fieldVerification,
      housing: _housingFromCache(sections['housing']) ?? _emptyHousing,
      utilitiesEquipment:
          _utilitiesFromCache(sections['utilities']) ?? _emptyUtilities,
      financialSummary: legacy.financialSummary, // ملخص مالي محسوب خادميًا فقط
      classification:
          _classificationFromCache(sections['classification']) ??
          _emptyClassification,
      assessedNeeds:
          _assessedNeedsFromCache(sections['assessed_needs']) ?? const [],
      // الأقسام التالية بلا endpoint في العقد — تبقى Mock-only دائمًا حتى
      // يوفّر الباك إند مسارًا (راجع BACKEND_CHANGE_REQUEST.md).
      socialAssessment: legacy.socialAssessment,
      socialWorkerOpinion: legacy.socialWorkerOpinion,
      supportRecommendation: legacy.supportRecommendation,
      review: legacy.review,
      approvedSupport: legacy.approvedSupport,
      timeline: legacy.timeline,
    );
  }

  /// قيم فاضية للأقسام التي لم تُحفَظ محليًا بعد (ولا تملك مصدر خادم مباشر
  /// حاليًا سوى `family_members`) — **لا** بيانات Mock وهمية توحي بأنها بيانات
  /// حقيقية للحالة (كانت المشكلة السابقة: كل حالة جديدة تعرض نفس بيانات
  /// [MockCaseDetailsRepository] الثابتة في تاباتها التسعة). التاب يعرضها
  /// فاضية جاهزة للتعبئة إلى أن يوفّر الباك إند `GET` مستقلًا لكل قسم.
  static const _emptyFamily = FamilySection(familyMembersCount: 0, members: []);

  static const _emptyInitialNeed = InitialNeedSection(
    needType: '',
    priorityLevel: '',
  );

  static const _emptyHousing = HousingSection(
    housingType: '',
    ownershipStatus: '',
    wallsCondition: '',
    roofType: '',
    floorsType: '',
  );

  static const _emptyUtilities = UtilitiesEquipmentSection(
    utilities: [],
    equipment: [],
  );

  static const _emptyClassification = SocialClassificationSection(
    mainClassifications: [],
    needLevel: '',
    priorityLevel: '',
  );

  /// يبني [HousingSection] من الشكل المحلي الذي كتبه `HousingMapper.toCacheJson`
  /// — يُستخدَم لعرض ما حفظه الأخصائي محليًا عند إعادة فتح الشاشة، حتى قبل
  /// وصول تأكيد من الخادم.
  HousingSection? _housingFromCache(Map<String, dynamic>? json) {
    if (json == null) return null;
    return HousingSection(
      housingType: (json['housingType'] as List?)?.join('، ') ?? '',
      ownershipStatus: '',
      wallsCondition: (json['walls'] as List?)?.join('، ') ?? '',
      roofType: (json['roof'] as List?)?.join('، ') ?? '',
      floorsType: (json['floor'] as List?)?.join('، ') ?? '',
      description: json['housingDescription'] as String?,
      photos: const [],
    );
  }

  UtilitiesEquipmentSection? _utilitiesFromCache(Map<String, dynamic>? json) {
    if (json == null) return null;
    final rawUtilities = json['utilities'] as List? ?? const [];
    final rawEquipment = json['equipment'] as List? ?? const [];
    return UtilitiesEquipmentSection(
      utilities: [
        for (final u in rawUtilities.whereType<Map<String, dynamic>>())
          UtilityItem(
            name: u['name'] as String? ?? '',
            isAvailable: u['isAvailable'] as bool? ?? false,
            condition: u['condition'] as String?,
            sourceOrMeter: u['sourceOrMeter'] as String?,
          ),
      ],
      equipment: [
        for (final e in rawEquipment.whereType<Map<String, dynamic>>())
          EquipmentItem(
            name: e['name'] as String? ?? '',
            category: e['category'] as String? ?? '',
            isPresent: e['isPresent'] as bool? ?? false,
          ),
      ],
    );
  }

  /// يبني [FamilySection] من الشكل المحلي الذي كتبه
  /// `FamilyMembersMapper.toCacheJson` — الحقول الإحصائية (عدد التابعين،
  /// الأطفال، ...) غير متاحة محليًا (الخادم لا يرجعها ضمن `PUT
  /// /family-members`، §19)، فتبقى `null` هنا؛ التاب لا يعرضها حاليًا فلا
  /// أثر مرئي لغيابها.
  FamilySection? _familyFromCache(Map<String, dynamic>? json) {
    if (json == null) return null;
    final rawMembers = json['members'] as List? ?? const [];
    final members = [
      for (final m in rawMembers.whereType<Map<String, dynamic>>())
        FamilyMember(
          name: m['name'] as String? ?? '',
          nationalId: m['nationalId'] as String?,
          relationship: m['relation'] as String? ?? '',
          gender: m['gender'] as String? ?? '',
          age: m['age'] as int?,
          educationLevel: m['educationStage'] as String?,
          occupation: m['job'] as String?,
          income: (m['monthlyIncome'] as num?)?.toDouble(),
          livesWithFamily: true,
          notes: m['notes'] as String?,
        ),
    ];
    return FamilySection(
      familyMembersCount: members.length,
      members: members,
    );
  }

  InitialNeedSection? _initialNeedFromCache(Map<String, dynamic>? json) {
    if (json == null) return null;
    return InitialNeedSection(
      needType: json['needType'] as String? ?? '',
      needCategory: json['needCategory'] as String?,
      description: json['description'] as String?,
      priorityLevel: json['priorityLevel'] as String? ?? '',
      details: json['details'] as String?,
      notes: json['notes'] as String?,
    );
  }

  SocialClassificationSection? _classificationFromCache(
    Map<String, dynamic>? json,
  ) {
    if (json == null) return null;
    return SocialClassificationSection(
      mainClassifications:
          (json['mainClassifications'] as List?)?.whereType<String>().toList(
                growable: false,
              ) ??
          const [],
      subClassification: json['subClassification'] as String?,
      needLevel: json['needLevel'] as String? ?? '',
      priorityLevel: json['priorityLevel'] as String? ?? '',
      vulnerabilityLevel: json['vulnerabilityLevel'] as String?,
      notes: json['notes'] as String?,
    );
  }

  List<AssessedNeed>? _assessedNeedsFromCache(Map<String, dynamic>? json) {
    if (json == null) return null;
    final rawNeeds = json['needs'] as List? ?? const [];
    return [
      for (final n in rawNeeds.whereType<Map<String, dynamic>>())
        AssessedNeed(
          needType: n['needType'] as String? ?? '',
          category: n['category'] as String?,
          description: n['description'] as String?,
          priorityLevel: n['priorityLevel'] as String? ?? '',
          reason: n['reason'] as String?,
          source: n['source'] as String? ?? '',
          status: n['status'] as String? ?? '',
          notes: n['notes'] as String?,
        ),
    ];
  }

  /// يبني [domain.BasicInfoSection] من بيانات الحالة المخزَّنة فعليًا في
  /// `CachedCases` عبر `CaseDetailsDto` (نفس المصدر المستخدَم في المرحلة ٢
  /// لتفريغ المزامنة) — **لا بيانات Mock**.
  domain.BasicInfoSection _basicInfoFromCache(
    String caseId,
    api.CaseDetailsDto cached,
  ) {
    return domain.BasicInfoSection(
      caseId: caseId,
      caseNumber: cached.caseNumber,
      createdAt: cached.createdAtUtc ?? DateTime.now(),
      statusLabel: cached.status.wireValue,
      priorityLabel: cached.priority.wireValue,
      lastUpdatedAt: cached.updatedAtUtc ?? DateTime.now(),
      fullName: FieldValue(
        value: cached.beneficiary.fullName,
        source: DataSource.dataEntry,
      ),
      nationalId: FieldValue(
        value: cached.beneficiary.nationalId ?? '',
        source: DataSource.dataEntry,
      ),
      gender: cached.beneficiary.gender ?? '',
      // العقد لا يرجع تاريخ ميلاد خام — فقط `age`/`gender`/`birthGovernorate`
      // مشتقّين من الرقم القومي على الخادم (§19)؛ لا قيمة حقيقية هنا.
      birthDate: DateTime.now(),
      age: cached.beneficiary.age ?? 0,
      maritalStatus: '',
      educationLevel: null,
      occupation: null,
      employer: null,
      phone: FieldValue(
        value: cached.beneficiary.phonePrimary ?? '',
        source: DataSource.dataEntry,
      ),
      alternatePhone: cached.beneficiary.phoneSecondary,
      governorate: cached.beneficiary.birthGovernorate ?? '',
      district: '',
      village: '',
      addressDescription: cached.beneficiary.address,
    );
  }
}
