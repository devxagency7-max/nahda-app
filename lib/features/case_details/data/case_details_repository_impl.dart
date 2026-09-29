import '../../cases/data/cases_repository.dart';
import '../../cases/data/dto/case_details_dto.dart' as api;
import '../domain/case_details_repository.dart';
import '../domain/case_full_details.dart';
import '../domain/data_source.dart';
import '../domain/sections/basic_info_section.dart' as domain;
import '../domain/sections/classification_needs_section.dart';
import '../domain/sections/family_section.dart';
import '../domain/sections/housing_section.dart';
import '../domain/sections/initial_need_section.dart';
import '../domain/sections/timeline_section.dart';
import '../domain/sections/utilities_equipment_section.dart';

/// تنفيذ حقيقي لـ [CaseDetailsRepository] — يقرأ من الكاش المحلي
/// (`CasesRepository.cachedDetails` + `CachedSections`)، بعد محاولة تحديثه
/// من `GET /cases/{id}` (`CasesRepository.refreshCaseDetails`) الذي يحمل كل
/// الأقسام منذ رد الباك إند على طلب 13. فشل الشبكة هنا (أوفلاين) لا يمنع
/// عرض ما هو مخزَّن محليًا بالفعل — يُتجاهَل عمدًا.
///
/// **الأقسام التي لها مابر محلي** (أفراد الأسرة، الاحتياج الأولي، السكن،
/// المرافق، التصنيف، الاحتياجات المُقيَّمة): تُقرأ من `CachedSections` إن
/// وُجدت (سواء من تعديل محلي معلّق أو من آخر تحديث ناجح من الخادم)، وإلا
/// فقيمة **فاضية** (`_emptyXxx` أدناه).
///
/// **الأقسام بلا endpoint أصلًا** (المرفقات، الزيارة الميدانية، التحقق
/// الميداني، الملخص المالي المحسوب خادميًا، التقييم الاجتماعي الحر، رأي
/// الأخصائي، الدعم المقترح، المراجعة، الدعم المعتمد): ترجع `null`/فاضية —
/// **لا بيانات Mock مطلقًا**. موثّقة في `BACKEND_CHANGE_REQUEST.md` وتبقى
/// فاضية حتى يوفّر الباك إند مسارًا لها — هذا ليس نقص تنفيذ من جهة التطبيق،
/// والفراغ أصدق من بيانات مُختلَقة قد تُرسَل للمراجع بالخطأ.
class CaseDetailsRepositoryImpl implements CaseDetailsRepository {
  CaseDetailsRepositoryImpl({required CasesRepository casesRepository})
    : _cases = casesRepository;

  final CasesRepository _cases;

  @override
  Future<CaseFullDetails> getCaseDetails(String caseId) async {
    // يحدّث كل الأقسام من الخادم قبل القراءة (يتجاهل تعديلًا محليًا معلّقًا
    // لم يُرفَع بعد — راجع `_cacheSectionIfClean`). فشل الشبكة هنا (أوفلاين)
    // لا يمنع عرض ما هو مخزَّن محليًا بالفعل — نتجاهل الخطأ عمدًا.
    await _cases.refreshCaseDetails(caseId);

    final cached = await _cases.cachedDetails(caseId);
    final sections = await _cases.readAllSections(caseId);

    return CaseFullDetails(
      basicInfo: cached != null
          ? _basicInfoFromCache(caseId, cached)
          : _emptyBasicInfo(caseId),
      family: _familyFromCache(sections['family_members']) ?? _emptyFamily,
      initialNeed:
          _initialNeedFromCache(sections['initial_needs']) ?? _emptyInitialNeed,
      attachments: const [],
      fieldVisit: null,
      fieldVerification: null,
      housing: _housingFromCache(sections['housing']) ?? _emptyHousing,
      utilitiesEquipment:
          _utilitiesFromCache(sections['utilities']) ?? _emptyUtilities,
      // ملخص مالي محسوب خادميًا فقط — لا مصدر محلي، ولا endpoint بعد.
      financialSummary: null,
      classification:
          _classificationFromCache(sections['classification']) ??
          _emptyClassification,
      assessedNeeds:
          _assessedNeedsFromCache(sections['assessed_needs']) ?? const [],
      // الأقسام التالية بلا endpoint في العقد — تبقى فاضية حتى يوفّر الباك
      // إند مسارًا (راجع BACKEND_CHANGE_REQUEST.md). لا بيانات Mock مطلقًا.
      socialAssessment: null,
      socialWorkerOpinion: null,
      supportRecommendation: null,
      review: null,
      approvedSupport: null,
      timeline: const CaseTimelineSection(events: []),
    );
  }

  /// قيم فاضية للأقسام التي لم تُحفَظ محليًا بعد (ولا تملك مصدر خادم مباشر
  /// حاليًا سوى `family_members`) — **لا** بيانات Mock وهمية توحي بأنها بيانات
  /// حقيقية للحالة. التاب يعرضها فاضية جاهزة للتعبئة إلى أن يوفّر الباك إند
  /// `GET` مستقلًا لكل قسم.
  domain.BasicInfoSection _emptyBasicInfo(String caseId) =>
      domain.BasicInfoSection(
        caseId: caseId,
        caseNumber: '',
        createdAt: DateTime.now(),
        statusLabel: '',
        priorityLabel: '',
        lastUpdatedAt: DateTime.now(),
        fullName: const FieldValue(value: '', source: DataSource.dataEntry),
        nationalId: const FieldValue(value: '', source: DataSource.dataEntry),
        gender: '',
        birthDate: DateTime.now(),
        age: 0,
        maritalStatus: '',
        phone: const FieldValue(value: '', source: DataSource.dataEntry),
        governorate: '',
        district: '',
        village: '',
      );

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
      maritalStatus: cached.beneficiary.maritalStatus ?? '',
      educationLevel: cached.beneficiary.education,
      occupation: cached.beneficiary.job,
      employer: null,
      phone: FieldValue(
        value: cached.beneficiary.phonePrimary ?? '',
        source: DataSource.dataEntry,
      ),
      alternatePhone: cached.beneficiary.phoneSecondary,
      religion: cached.beneficiary.religion,
      monthlyIncome: cached.beneficiary.monthlyIncome,
      employmentStatus: cached.beneficiary.employmentStatus,
      takafulBeneficiary: cached.beneficiary.takafulBeneficiary,
      takafulAmount: cached.beneficiary.takafulAmount,
      headRelation: cached.beneficiary.headRelation,
      governorate: cached.beneficiary.birthGovernorate ?? '',
      district: '',
      village: '',
      centerId: cached.beneficiary.centerId,
      villageId: cached.beneficiary.villageId,
      addressDescription: cached.beneficiary.address,
    );
  }
}
