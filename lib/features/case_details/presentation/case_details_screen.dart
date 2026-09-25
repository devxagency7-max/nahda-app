import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/providers/data_providers.dart';
import '../../../core/sync/sync_operation.dart';
import '../../cases/data/cases_repository.dart';
import '../../cases/data/dto/case_details_dto.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_background.dart';
import '../../home/domain/case_priority.dart';
import '../data/mappers/agriculture_mapper.dart';
import '../data/mappers/assessed_needs_mapper.dart';
import '../data/mappers/beneficiary_mapper.dart';
import '../data/mappers/classification_mapper.dart';
import '../data/mappers/family_members_mapper.dart';
import '../data/mappers/financial_mapper.dart';
import '../data/mappers/housing_mapper.dart';
import '../data/mappers/initial_need_mapper.dart';
import '../data/mappers/opinions_mapper.dart';
import '../data/mappers/support_mapper.dart';
import '../data/mappers/utilities_mapper.dart';
import '../../field_visits/presentation/field_visits_screen.dart';
import '../domain/case_full_details.dart';
import '../domain/case_readiness.dart';
import '../domain/sections/agricultural_holding_form.dart';
import '../domain/sections/assessed_needs_form.dart';
import '../domain/sections/basic_info_family_form.dart';
import '../domain/sections/classification_form.dart';
import '../domain/sections/financial_form.dart';
import '../domain/sections/housing_form.dart';
import '../domain/sections/initial_need_form.dart';
import '../domain/sections/opinions_form.dart';
import '../domain/sections/support_form.dart';
import '../domain/sections/utilities_equipment_form.dart';
import 'case_details_providers.dart';
import 'tabs/agricultural_holding_tab.dart';
import 'tabs/assessed_needs_tab.dart';
import 'tabs/basic_info_tab.dart';
import 'tabs/classification_tab.dart';
import 'tabs/family_members_tab.dart';
import 'tabs/financial_tab.dart';
import 'tabs/housing_tab.dart';
import 'tabs/initial_need_attachments_tab.dart';
import 'tabs/opinions_tab.dart';
import 'tabs/support_tab.dart';
import 'tabs/utilities_equipment_tab.dart';
import 'widgets/incomplete_submit_dialog.dart';
import 'widgets/tab_navigation_bar.dart';
import 'widgets/timeline_sheet.dart';

const _tabLabels = [
  'البيانات الأساسية',
  'الأفراد التابعين',
  'المرفقات',
  'السكن',
  'المرافق والتجهيزات',
  'الحيازة والأصول',
  'الدخل والمصروفات',
  'التصنيف الاجتماعي',
  'الاحتياجات المُقيَّمة',
  'الدعم',
  'الرأي',
];

/// صفحة تفاصيل الحالة الكاملة — Case Master Data مقسّمة إلى تابات منطقية
/// (Case Data Master Prompt §1-27). كل تاب قابل للتعديل مباشرة (عدا
/// المراجعة — صلاحية المراجع فقط)، وبه شريط تقدم يوضح نسبة اكتماله.
class CaseDetailsScreen extends ConsumerStatefulWidget {
  final String caseId;
  final String personName;
  final String displayId;
  final CasePriority priority;

  /// فهرس التاب المفتوح عند دخول الشاشة — تستخدمه شاشة التعارض لتوجيه
  /// المستخدم مباشرة إلى قسم "ادمج يدويًا" بدل أول تاب دائمًا.
  final int initialTabIndex;

  const CaseDetailsScreen({
    super.key,
    required this.caseId,
    required this.personName,
    required this.displayId,
    required this.priority,
    this.initialTabIndex = 0,
  });

  @override
  ConsumerState<CaseDetailsScreen> createState() => _CaseDetailsScreenState();
}

class _CaseDetailsScreenState extends ConsumerState<CaseDetailsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _currentTabIndex = 0;

  BasicInfoFormData? _basicInfo;
  FamilyMembersFormData? _familyMembers;
  InitialNeedFormData? _initialNeed;
  HousingFormData? _housing;
  AgriculturalHoldingFormData? _agriculturalHolding;
  FinancialFormData? _financial;
  ClassificationFormData? _classification;
  AssessedNeedsFormData? _assessedNeeds;
  OpinionsFormData? _opinions;
  SupportRecommendationFormData? _support;
  UtilitiesEquipmentFormData? _utilitiesEquipment;

  /// أحدث `rowVersion`/`caseRowVersion` معروفة — تُحدَّث من كل استجابة كاش
  /// طازجة، وتُستخدَم عند بناء `apiPayload` لكل قسم (§19: لا يجوز إرسال
  /// نسخة قديمة عمدًا).
  int? _caseRowVersion;
  int? _beneficiaryRowVersion;

  /// سبب/مصدر رجوع الحالة الحالي — من `returnInfo` (أعلى مستوى استجابة
  /// `GET /cases/{id}`)، مصدر الحقيقة الوحيد المضمون لهذا (§5، رد الباك إند
  /// على طلب 14) — **لا** يُستنتج من `opinions.reviewer` وحده.
  ReturnInfoDto? _returnInfo;

  /// فهارس التابات التي عدّلها المستخدم منذ آخر حفظ ناجح — الحفظ عند
  /// المغادرة يتجاهل تابًا لم يُلمَس، فلا يُضاف `enqueue` بلا داعٍ (§2.3،
  /// القاعدة ٤: الدمج ممتاز لكنه ليس بديلًا عن تفادي الإرسال أصلًا).
  final Set<int> _dirtyTabs = {};

  @override
  void initState() {
    super.initState();
    _currentTabIndex = widget.initialTabIndex;
    _tabController = TabController(
      length: _tabLabels.length,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _currentTabIndex = _tabController.index);
      }
    });
    _loadRowVersions();
  }

  /// نسخة خام من `CachedSections` لكل قسم — المصدر الوحيد اللي يحتفظ بشكل
  /// الفورم الكامل بلا فقد (خلاف [CaseFullDetails] اللي بعض حقوله مسطّحة
  /// للعرض فقط). تُستخدَم في [_seedFromServerData] لملء أفراد الأسرة/السكن/
  /// المرافق بما حُفظ فعليًا محليًا بدل فورم فاضٍ.
  ///
  /// **تُحمَّل من [_seedFromServerData] لا [initState]** — يجب أن تُقرأ
  /// **بعد** نجاح `caseDetailsProvider` (أي بعد `refreshCaseDetails` إن كان
  /// أونلاين)، وإلا قرأنا الكاش القديم قبل وصول تحديث الخادم فعليًا (سباق).
  Map<String, Map<String, dynamic>>? _rawSections;
  bool _rawSectionsRequested = false;

  Future<void> _loadRawSections() async {
    final sections =
        await ref.read(casesRepositoryProvider).readAllSections(widget.caseId);
    if (!mounted) return;
    setState(() {
      _rawSections = sections;
      // Reset cache-dependent fields the user hasn't touched yet so
      // _seedFromServerData can re-populate them from the loaded cache.
      if (!_dirtyTabs.contains(1)) _familyMembers = null;
      if (!_dirtyTabs.contains(3)) _housing = null;
      if (!_dirtyTabs.contains(4)) _utilitiesEquipment = null;
      if (!_dirtyTabs.contains(10)) _opinions = null;
    });
  }

  /// يحدّث بند "تكافل وكرامة" في تاب الدخل والمصروفات تلقائيًا = مجموع
  /// مبالغ تكافل وكرامة المسجلة لرب الأسرة وللأفراد التابعين (نفس أسلوب
  /// مزامنة "دخل أراضي زراعية" من تاب الحيازة الزراعية). التحديث التلقائي
  /// يكسب دائمًا: أي تعديل يدوي سابق على البند يُستبدل عند تغيّر مصدره.
  /// لو البند اتحذف من تاب الدخل، يُعاد إنشاؤه بدل ما تُفقد المزامنة بصمت
  /// (نفس سلوك مزامنة الحيازة الزراعية — [_syncAgriculturalHolding]).
  void _syncTakafulKarama() {
    if (_financial == null) return;

    final contributors = <TakafulKaramaContributor>[];
    if (_basicInfo?.takafulKarama == true &&
        _basicInfo?.takafulKaramaAmount != null) {
      contributors.add(
        TakafulKaramaContributor(
          relation: 'رب الأسرة',
          amount: _basicInfo!.takafulKaramaAmount!,
          onAmountChanged: (v) {
            setState(() {
              _basicInfo!.takafulKaramaAmount = v;
              _syncTakafulKarama();
            });
          },
        ),
      );
    }
    if (_familyMembers != null) {
      for (final member in _familyMembers!.members) {
        if (member.takafulKarama && member.takafulKaramaAmount != null) {
          contributors.add(
            TakafulKaramaContributor(
              relation: member.relation,
              amount: member.takafulKaramaAmount!,
              onAmountChanged: (v) {
                setState(() {
                  member.takafulKaramaAmount = v;
                  _syncTakafulKarama();
                });
              },
            ),
          );
        }
      }
    }

    var index = _financial!.incomeItems.indexWhere(
      (i) => i.sourceType == 'تكافل وكرامة',
    );
    if (index == -1) {
      _financial!.incomeItems.add(
        IncomeItemFormData(sourceType: 'تكافل وكرامة', personName: 'رب الأسرة'),
      );
      index = _financial!.incomeItems.length - 1;
    }

    final total = contributors.fold<double>(0, (sum, c) => sum + c.amount);
    _financial!.incomeItems[index].contributors = contributors;
    if (contributors.isNotEmpty) {
      _financial!.incomeItems[index].amount = total;
    }
  }

  /// يزامن بندي "إيجار أراضي زراعية" (مصروف) و"دخل أراضي زراعية" (دخل) مع
  /// تاب الحيازة الزراعية في الاتجاهين:
  /// - من الحيازة للدخل: أي تعديل في المساحة/النوع/المبلغ هنا يحدّث البند.
  /// - من الدخل للحيازة: تعديل يدوي على مبلغ البند نفسه (عبر
  ///   [onExternalAmountChanged]) يكتب القيمة رجوعًا في الحيازة، فيبقى مصدر
  ///   الحقيقة متسقًا مهما كانت جهة التعديل.
  /// لو البند اتحذف من تاب الدخل، يُعاد إنشاؤه بدل ما تُفقد المزامنة بصمت.
  void _syncAgriculturalHolding() {
    if (_financial == null || _agriculturalHolding == null) return;
    final holding = _agriculturalHolding!;

    // بند المصروف — إيجار أراضي زراعية
    var rentIndex = _financial!.expenseItems.indexWhere(
      (e) => e.expenseType == 'إيجار أراضي زراعية',
    );
    if (rentIndex == -1) {
      _financial!.expenseItems
          .add(ExpenseItemFormData(expenseType: 'إيجار أراضي زراعية'));
      rentIndex = _financial!.expenseItems.length - 1;
    }
    final rentItem = _financial!.expenseItems[rentIndex];
    rentItem.onExternalAmountChanged = (v) {
      holding.landRentAmount = v;
    };
    if (holding.hasLand &&
        holding.landType == 'إيجار' &&
        holding.landRentAmount != null) {
      rentItem.amount = holding.landRentAmount;
    }

    // بند الدخل — دخل أراضي زراعية (سنوي في الحيازة، شهري في الدخل)
    var incomeIndex = _financial!.incomeItems.indexWhere(
      (i) => i.sourceType == 'دخل أراضي زراعية',
    );
    if (incomeIndex == -1) {
      _financial!.incomeItems.add(
        IncomeItemFormData(
            sourceType: 'دخل أراضي زراعية', personName: 'رب الأسرة'),
      );
      incomeIndex = _financial!.incomeItems.length - 1;
    }
    final incomeItem = _financial!.incomeItems[incomeIndex];
    incomeItem.onExternalAmountChanged = (v) {
      holding.annualLandIncome = v == null ? null : v * 12;
    };
    if (holding.hasLand &&
        holding.landType == 'تمليك' &&
        holding.annualLandIncome != null) {
      incomeItem.amount = holding.annualLandIncome! / 12.0;
    }
  }

  Future<void> _goToPreviousTab() async {
    if (_tabController.index <= 0) return;
    await _saveCurrentTabIfDirty();
    if (!mounted) return;
    _tabController.animateTo(_tabController.index - 1);
  }

  /// مفتاح تاب الحيازة — لازم عشان نطلب منه يعرض أخطاء التحقق عند المنع.
  final _agriTabKey = GlobalKey<AgriculturalHoldingTabState>();

  /// بوابة التحقق قبل مغادرة تاب للأمام. الرجوع للخلف مسموح دائمًا.
  /// حاليًا تاب الحيازة فقط هو المُقيَّد — بقية التابات تعبر كما كانت.
  ///
  /// **الحفظ المحلي يحدث دائمًا** حتى لو التاب غير مكتمل — هذه البوابة تمنع
  /// فقط الانتقال البصري، لا تمنع تخزين ما كتبه الأخصائي فعليًا.
  bool _canLeaveTab(int index) {
    // فهرس 5 = تاب الحيازة والأصول ضمن [_tabLabels].
    if (index != 5) return true;
    final holding = _agriculturalHolding;
    if (holding == null || holding.isComplete) return true;

    _agriTabKey.currentState?.showValidationErrors();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'كمّل الحقول دي الأول قبل ما تكمل: ${holding.missingFields.join(' — ')}',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
    return false;
  }

  Future<void> _goToNextTab() async {
    if (_tabController.index >= _tabLabels.length - 1) return;
    if (!_canLeaveTab(_tabController.index)) return;
    await _saveCurrentTabIfDirty();
    if (!mounted) return;
    _tabController.animateTo(_tabController.index + 1);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// يقرأ `rowVersion`/`beneficiary.rowVersion` من كاش `CasesRepository` —
  /// **المصدر الرسمي الوحيد** لهما (§19)، منفصل عن [CaseFullDetails] الذي لا
  /// يحملهما أصلًا (كيان عرض فقط).
  Future<void> _loadRowVersions() async {
    final cached =
        await ref.read(casesRepositoryProvider).cachedDetails(widget.caseId);
    if (!mounted || cached == null) return;
    setState(() {
      _caseRowVersion = cached.rowVersion;
      _beneficiaryRowVersion = cached.beneficiary.rowVersion;
      _returnInfo = cached.returnInfo;
    });
  }

  void _seedFromServerData(CaseFullDetails data) {
    if (!_rawSectionsRequested) {
      _rawSectionsRequested = true;
      _loadRawSections();
    }
    _basicInfo ??= BasicInfoFormData(
      caseName: data.basicInfo.fullName.value,
      nationalId: data.basicInfo.nationalId.value,
      educationLevel: data.basicInfo.educationLevel,
      age: data.basicInfo.age,
      gender: data.basicInfo.gender,
      phone1: data.basicInfo.phone.value,
      phone2: data.basicInfo.alternatePhone,
      job: data.basicInfo.occupation,
      district: data.basicInfo.district,
      village: data.basicInfo.village,
      address: data.basicInfo.addressDescription,
    );
    final rawSections = _rawSections;
    if (rawSections != null) {
      final family = rawSections['family_members'];
      _familyMembers ??= family != null
          ? FamilyMembersMapper.fromCacheJson(family)
          : FamilyMembersFormData();

      final housing = rawSections['housing'];
      _housing ??= housing != null
          ? HousingMapper.fromCacheJson(housing)
          : HousingFormData();

      final utilities = rawSections['utilities'];
      _utilitiesEquipment ??= utilities != null
          ? UtilitiesMapper.fromCacheJson(utilities)
          : UtilitiesEquipmentFormData();
    }
    // Fallback empty defaults — prevents null-check crash on first build
    // while _rawSections is still loading asynchronously.
    _familyMembers ??= FamilyMembersFormData();
    _housing ??= HousingFormData();
    _utilitiesEquipment ??= UtilitiesEquipmentFormData();
    _initialNeed ??= InitialNeedFormData(
      needType: data.initialNeed?.needType ?? '',
      description: data.initialNeed?.description,
      priorityLevel: data.initialNeed?.priorityLevel ?? '',
      details: data.initialNeed?.details,
      notes: data.initialNeed?.notes,
    );
    _agriculturalHolding ??= AgriculturalHoldingFormData();
    _financial ??= FinancialFormData(
      familyMembersCount: data.financialSummary?.familyMembersCount ?? 1,
    );
    _classification ??= ClassificationFormData(
      mainClassifications: data.classification?.mainClassifications.toList(),
      subClassification: data.classification?.subClassification,
      needLevel: data.classification?.needLevel ?? '',
      priorityLevel: data.classification?.priorityLevel ?? '',
      vulnerabilityLevel: data.classification?.vulnerabilityLevel,
      notes: data.classification?.notes,
    );
    _assessedNeeds ??= AssessedNeedsFormData(
      needs: [
        for (final n in data.assessedNeeds)
          AssessedNeedFormData(
            needType: n.needType,
            category: n.category,
            description: n.description,
            priorityLevel: n.priorityLevel,
            reason: n.reason,
            source: n.source,
            status: n.status,
            notes: n.notes,
          ),
      ],
    );
    if (_opinions == null && rawSections != null) {
      final opinions = rawSections['opinions'];
      final reviewerJson = rawSections['reviewer_opinion'];
      final directorJson = rawSections['manager_opinion'];
      final previousWorkerJson = rawSections['worker_opinion_previous'];
      final reviewer = reviewerJson != null
          ? OpinionsMapper.reviewerFromCacheJson(reviewerJson)
          : null;
      final previousWorkerOpinion = previousWorkerJson != null
          ? OpinionsMapper.previousWorkerFromCacheJson(previousWorkerJson)
          : null;
      final returnInfo = _returnInfo;
      // returnInfo هو مصدر الحقيقة الوحيد المضمون لسبب الرجوع — المدير قد
      // يرجع الحالة بعد أن مسح رأي المراجع بالكامل من الخادم، فيصبح
      // reviewer == null رغم أن الحالة فعلًا مرتجعة (§5، رد الباك إند طلب 14).
      _opinions = OpinionsFormData(
        socialWorker:
            opinions != null ? OpinionsMapper.fromCacheJson(opinions) : null,
        reviewer: reviewer,
        director: directorJson != null
            ? OpinionsMapper.directorFromCacheJson(directorJson)
            : null,
        previousWorkerOpinion: previousWorkerOpinion,
        returnReason: returnInfo?.reason,
        returnedByLabel: returnInfo?.returnedBy.label,
      );
    }
    _opinions ??= OpinionsFormData();
    _support ??= SupportRecommendationFormData();
  }

  /// يُستدعى من كل `onChanged` لتاب — يعلّم التاب كـ "معدَّل منذ آخر حفظ".
  void _markDirty(int tabIndex) => _dirtyTabs.add(tabIndex);

  /// يحفظ التاب الحالي محليًا (ويرسله للمزامنة إن كان قسمًا مدعومًا)، فقط
  /// إن كان قد عُدِّل فعليًا منذ آخر حفظ — يُستدعى قبل أي انتقال أو إغلاق.
  Future<void> _saveCurrentTabIfDirty() async {
    final index = _tabController.index;
    if (!_dirtyTabs.contains(index)) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await _saveTab(index);
      _dirtyTabs.remove(index);
    } on ApiException catch (e) {
      // الخادم رفض القسم — محفوظ محليًا ويبقى "معدَّلًا" ليُعاد إرساله عند
      // الحفظ التالي بعد التصحيح.
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(e.displayMessage),
            backgroundColor: AppColors.danger,
          ),
        );
    }
  }

  Future<void> _saveTab(int index) async {
    final repo = ref.read(casesRepositoryProvider);
    final caseId = widget.caseId;

    switch (index) {
      case 0: // البيانات الأساسية
        final form = _basicInfo;
        if (form == null) break;
        await repo.saveSection(
          caseId: caseId,
          sectionKey: 'beneficiary',
          dataJson: BeneficiaryMapper.toCacheJson(form),
          apiPayload: _beneficiaryRowVersion == null
              ? null
              : BeneficiaryMapper.toApiPayload(
                  form,
                  rowVersion: _beneficiaryRowVersion!,
                ),
          syncType: _beneficiaryRowVersion == null
              ? null
              : SyncOperationType.updateBeneficiary,
        );
      case 1: // الأفراد التابعين
        final form = _familyMembers;
        if (form == null) break;
        await repo.saveSection(
          caseId: caseId,
          sectionKey: 'family_members',
          dataJson: FamilyMembersMapper.toCacheJson(form),
          apiPayload: _caseRowVersion == null
              ? null
              : FamilyMembersMapper.toApiPayload(
                  form,
                  caseRowVersion: _caseRowVersion!,
                ),
          syncType: _caseRowVersion == null
              ? null
              : SyncOperationType.updateFamilyMembers,
        );
      case 2: // المرفقات + الاحتياج الأولي (تاب مدمج — راجع InitialNeedAttachmentsTab)
        final form = _initialNeed;
        if (form == null || _caseRowVersion == null) break;
        await repo.saveSection(
          caseId: caseId,
          sectionKey: 'initial_needs',
          dataJson: InitialNeedMapper.toCacheJson(form),
          apiPayload: InitialNeedMapper.toApiPayload(
            form,
            caseRowVersion: _caseRowVersion!,
          ),
          syncType: SyncOperationType.updateInitialNeeds,
        );
      case 3: // السكن
        final form = _housing;
        if (form == null) break;
        await repo.saveSection(
          caseId: caseId,
          sectionKey: 'housing',
          dataJson: HousingMapper.toCacheJson(form),
          apiPayload: HousingMapper.toApiPayload(
            form,
            rowVersion: await _sectionRowVersion(repo, caseId, 'housing'),
          ),
          syncType: SyncOperationType.updateHousing,
        );
      case 4: // المرافق والتجهيزات
        final form = _utilitiesEquipment;
        if (form == null || _caseRowVersion == null) break;
        await repo.saveSection(
          caseId: caseId,
          sectionKey: 'utilities',
          dataJson: UtilitiesMapper.toCacheJson(form),
          apiPayload: UtilitiesMapper.toApiPayload(
            form,
            caseRowVersion: _caseRowVersion!,
          ),
          syncType: SyncOperationType.updateUtilities,
        );
      case 5: // الحيازة والأصول
        final form = _agriculturalHolding;
        if (form == null) break;
        await repo.saveSection(
          caseId: caseId,
          sectionKey: 'agriculture',
          dataJson: AgricultureMapper.toCacheJson(form),
          apiPayload: AgricultureMapper.toApiPayload(
            form,
            rowVersion: await _sectionRowVersion(repo, caseId, 'agriculture'),
          ),
          syncType: SyncOperationType.updateAgriculture,
        );
      case 6: // الدخل والمصروفات
        final form = _financial;
        if (form == null || _caseRowVersion == null) break;
        // المصيدة المالية (§19): تعديل beneficiary/agriculture/family-members
        // يعيد حساب الملخص ويزيد rowVersion الحالة على الخادم بصمت —
        // `_caseRowVersion` هنا مأخوذ مرة عند فتح الشاشة (سطر ٣٠٣) ولا
        // يتحدّث تلقائيًا. محاولة تحديث لقطة قبل حفظ هذا القسم تحديدًا: فشلها
        // أوفلاين لا يمنع الحفظ المحلي (refreshCaseDetails لا يرمي)، فقط
        // يُبقي القيمة القديمة، وتعارض ٤٠٩ لاحق (لو حصل رغم ذلك) له مساره
        // المعروف عبر شاشة التعارض.
        await repo.refreshCaseDetails(caseId);
        final freshCase = await repo.readCase(caseId);
        final freshCaseRowVersion = freshCase?.rowVersion ?? _caseRowVersion!;
        await repo.saveSection(
          caseId: caseId,
          sectionKey: 'financial',
          dataJson: FinancialMapper.toCacheJson(form),
          apiPayload: FinancialMapper.toApiPayload(
            form,
            caseRowVersion: freshCaseRowVersion,
          ),
          syncType: SyncOperationType.updateFinancial,
        );
        _caseRowVersion = freshCaseRowVersion;
      case 7: // التصنيف الاجتماعي
        final form = _classification;
        if (form == null) break;
        await repo.saveSection(
          caseId: caseId,
          sectionKey: 'classification',
          dataJson: ClassificationMapper.toCacheJson(form),
          apiPayload: ClassificationMapper.toApiPayload(
            form,
            rowVersion: await _sectionRowVersion(
              repo,
              caseId,
              'classification',
            ),
          ),
          syncType: SyncOperationType.updateClassification,
        );
      case 8: // الاحتياجات المُقيَّمة
        final form = _assessedNeeds;
        if (form == null || _caseRowVersion == null) break;
        await repo.saveSection(
          caseId: caseId,
          sectionKey: 'assessed_needs',
          dataJson: AssessedNeedsMapper.toCacheJson(form),
          apiPayload: AssessedNeedsMapper.toApiPayload(
            form,
            caseRowVersion: _caseRowVersion!,
          ),
          syncType: SyncOperationType.updateAssessedNeeds,
        );
      case 9: // الدعم
        final form = _support;
        if (form == null || _caseRowVersion == null) break;
        final payload = SupportMapper.toApiPayload(
          form,
          caseRowVersion: _caseRowVersion!,
          beneficiaryName: _basicInfo?.caseName ?? '',
        );
        await repo.saveSection(
          caseId: caseId,
          sectionKey: 'support_recommendation',
          dataJson: SupportMapper.toCacheJson(form),
          apiPayload: payload,
          syncType: payload == null
              ? null
              : SyncOperationType.updateSupportRecommendations,
        );
      case 10: // الرأي — لا endpoint مطابق لهذا الشكل التفصيلي (راجع
        // BACKEND_CHANGE_REQUEST.md)؛ يُحفَظ محليًا فقط.
        //
        // **المفتاح لازم يكون 'opinions'** — نفس المفتاح اللي يقرأه
        // `_seedFromServerData` (rawSections['opinions']) والذي يكتبه
        // `submitWorkerOpinion` في `CasesRepository` بعد الإرسال الفعلي؛
        // مفتاح مختلف هنا كان يعني تعديلًا محفوظًا لن يُقرأ أبدًا.
        final form = _opinions;
        if (form == null) break;
        await repo.saveSection(
          caseId: caseId,
          sectionKey: 'opinions',
          dataJson: OpinionsMapper.toCacheJson(form.socialWorker),
        );
    }
  }

  /// نسخة صفّ قسم "مفرد" (housing/agriculture/classification) — تُقرأ من
  /// الكاش المحلي إن كان القسم قد حُفِظ سابقًا مع نسخة معروفة، أو `null`
  /// لأول حفظ (قيمة مشروعة وفق §19).
  Future<int?> _sectionRowVersion(
    CasesRepository repo,
    String caseId,
    String sectionKey,
  ) async {
    final saved = await repo.readSection(caseId, sectionKey);
    final version = saved?['rowVersion'];
    return version is int ? version : null;
  }

  Future<void> _handleSubmitForReview() async {
    final readiness = CaseReadiness(
      basicInfo: _basicInfo!,
      familyMembers: _familyMembers!,
      initialNeed: _initialNeed!,
      housing: _housing!,
      financial: _financial!,
      opinions: _opinions!,
      support: _support!,
    );

    if (!readiness.isReadyForReview) {
      final confirmed = await IncompleteSubmitDialog.show(
        context,
        readiness.missingSections,
      );
      if (!confirmed) return;
    }

    if (!mounted) return;

    final decision = _opinions?.socialWorker.decisionWireValue;
    if (decision == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('اختار "مقبول" ولا "مرفوض" في تاب الرأي الأول'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final notes = _opinions?.socialWorker.detailedReport?.trim();
    // §20: `notes` محدود بـ2000 حرف في العقد الحقيقي. نمنع الإرسال بدل قطع
    // ما كتبه الأخصائي صامتًا — المسودة المحلية الأطول تبقى محفوظة كما هي.
    if (notes != null && notes.length > 2000) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'التقرير طويل شوية (${notes.length}/2000 حرف) — اختصره وجرّب تاني',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(casesRepositoryProvider);
    try {
      // `submitWorkerOpinion` نفسها تكتب الكاش المحلي (sectionKey: 'opinions')
      // بعد الـ enqueue مباشرة — فلو رجع الأخصائي فتح التاب فورًا (بلا تغيير
      // تاب ولا إغلاق شاشة) يلاقي رأيه ظاهرًا فورًا، لا داعي لحفظ يدوي هنا.
      _dirtyTabs.remove(10);

      final sentNow = await repo.submitWorkerOpinion(
        caseId: widget.caseId,
        decision: decision,
        notes: notes,
      );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            sentNow
                ? 'تمام! الرأي وصل للمراجع'
                : 'حفظنا رأيك — هيوصل للمراجع قريبا',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } on ApiException catch (e) {
      // رفض نهائي من الخادم (مثل "الحالة غير مكتملة بعد") — يظهر الآن، لا
      // يُدفَن في الطابور.
      if (!mounted) return;
      _dirtyTabs.add(10);
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.displayMessage),
          backgroundColor: AppColors.danger,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('معلش، مقدرناش نحفظ الرأي دلوقتي — جرّب تاني'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailsAsync = ref.watch(caseDetailsProvider(widget.caseId));

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.personName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                widget.displayId,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.xs),
              child: TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => FieldVisitsScreen(
                      caseId: widget.caseId,
                      personName: widget.personName,
                    ),
                  ),
                ),
                icon: const Icon(Icons.location_on_outlined, size: 16),
                label: const Text(
                  'الزيارات',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.sm),
              child: detailsAsync.maybeWhen(
                data: (data) => TextButton.icon(
                  onPressed: () => TimelineSheet.show(context, data.timeline),
                  icon: const Icon(Icons.history, size: 16),
                  label: const Text(
                    'السجل',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                orElse: () => const SizedBox.shrink(),
              ),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.primary,
            labelStyle: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
            tabAlignment: TabAlignment.start,
            tabs: [for (final label in _tabLabels) Tab(text: label)],
          ),
        ),
        body: detailsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const _DetailsErrorState(),
          data: (data) {
            _seedFromServerData(data);
            _syncTakafulKarama();
            _syncAgriculturalHolding();

            return PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, _) async {
                if (didPop) return;
                final navigator = Navigator.of(context);
                await _saveCurrentTabIfDirty();
                if (!mounted) return;
                navigator.pop();
              },
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 76),
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        BasicInfoTab(
                          initialData: _basicInfo!,
                          onChanged: (v) => setState(() {
                            _basicInfo = v;
                            _markDirty(0);
                            _syncTakafulKarama();
                          }),
                        ),
                        FamilyMembersTab(
                          initialData: _familyMembers!,
                          onChanged: (v) => setState(() {
                            _familyMembers = v;
                            _markDirty(1);
                            _syncTakafulKarama();
                          }),
                        ),
                        InitialNeedAttachmentsTab(
                          caseId: widget.caseId,
                          initialData: _initialNeed!,
                          onChanged: (v) => setState(() {
                            _initialNeed = v;
                            _markDirty(2);
                          }),
                        ),
                        HousingTab(
                          initialData: _housing!,
                          onChanged: (v) => setState(() {
                            _housing = v;
                            _markDirty(3);
                          }),
                        ),
                        UtilitiesEquipmentTab(
                          initialData: _utilitiesEquipment!,
                          onChanged: (v) => setState(() {
                            _utilitiesEquipment = v;
                            _markDirty(4);
                          }),
                        ),
                        AgriculturalHoldingTab(
                          key: _agriTabKey,
                          initialData: _agriculturalHolding!,
                          onChanged: (v) => setState(() {
                            _agriculturalHolding = v;
                            _markDirty(5);
                            _syncAgriculturalHolding();
                          }),
                        ),
                        FinancialTab(
                          initialData: _financial!,
                          onChanged: (v) => setState(() {
                            _financial = v;
                            _markDirty(6);
                            _syncAgriculturalHolding();
                          }),
                        ),
                        ClassificationTab(
                          initialData: _classification!,
                          onChanged: (v) => setState(() {
                            _classification = v;
                            _markDirty(7);
                          }),
                        ),
                        AssessedNeedsTab(
                          initialData: _assessedNeeds!,
                          onChanged: (v) => setState(() {
                            _assessedNeeds = v;
                            _markDirty(8);
                          }),
                        ),
                        SupportTab(
                          initialData: _support!,
                          onChanged: (v) => setState(() {
                            _support = v;
                            _markDirty(9);
                          }),
                          approved: data.approvedSupport,
                        ),
                        OpinionsTab(
                          initialData: _opinions!,
                          onChanged: (v) => setState(() {
                            _opinions = v;
                            _markDirty(10);
                          }),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: TabNavigationBar(
                      isFirstTab: _currentTabIndex == 0,
                      isLastTab: _currentTabIndex == _tabLabels.length - 1,
                      onPrevious: _goToPreviousTab,
                      onNext: _goToNextTab,
                      onSubmit: _handleSubmitForReview,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DetailsErrorState extends StatelessWidget {
  const _DetailsErrorState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xxl),
        child: Text(
          'تعذر تحميل بيانات الحالة. يرجى المحاولة مرة أخرى.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: AppColors.danger,
          ),
        ),
      ),
    );
  }
}
