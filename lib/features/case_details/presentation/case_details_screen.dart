import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/providers/data_providers.dart';
import '../../../core/sync/sync_operation.dart';
import '../../../core/utils/egyptian_national_id_parser.dart';
import '../../cases/data/dto/case_details_dto.dart';
import '../../cases/domain/case_status.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_background.dart';
import '../../home/domain/case_priority.dart';
import '../../home/presentation/home_providers.dart';
import '../../reference/domain/reference_models.dart';
import '../data/mappers/agriculture_mapper.dart';
import '../data/mappers/beneficiary_mapper.dart';
import '../data/mappers/family_members_mapper.dart';
import '../data/mappers/financial_mapper.dart';
import '../data/mappers/housing_mapper.dart';
import '../data/mappers/initial_need_mapper.dart';
import '../data/mappers/opinions_mapper.dart';
import '../data/mappers/support_mapper.dart';
import '../data/mappers/utilities_mapper.dart';
import '../domain/case_full_details.dart';
import '../domain/case_readiness.dart';
import '../domain/sections/agricultural_holding_form.dart';
import '../domain/sections/basic_info_family_form.dart';
import '../domain/sections/financial_form.dart';
import '../domain/sections/housing_form.dart';
import '../domain/sections/initial_need_form.dart';
import '../domain/sections/opinions_form.dart';
import '../domain/sections/support_form.dart';
import '../domain/sections/utilities_equipment_form.dart';
import 'case_details_providers.dart';
import 'tabs/agricultural_holding_tab.dart';
import 'tabs/basic_info_tab.dart';
import 'tabs/family_members_tab.dart';
import 'tabs/financial_tab.dart';
import 'tabs/housing_tab.dart';
import 'tabs/initial_need_attachments_tab.dart';
import 'tabs/opinions_tab.dart';
import 'tabs/support_tab.dart';
import 'tabs/utilities_equipment_tab.dart';
import 'widgets/incomplete_submit_dialog.dart';
import 'widgets/section_card.dart';
import 'widgets/tab_navigation_bar.dart';
import 'widgets/timeline_sheet.dart';

const _tabLabels = [
  'البيانات الأساسية',
  'الأفراد التابعين',
  'السكن',
  'المرافق والتجهيزات',
  'الحيازة والأصول',
  'الدخل والمصروفات',
  'المرفقات',
  'الدعم',
  'الرأي',
];

/// صفحة تفاصيل الحالة الكاملة — Case Master Data مقسّمة إلى تابات منطقية
/// (Case Data Master Prompt §1-27). كل تاب قابل للتعديل مباشرة (عدا
/// المراجعة — صلاحية المراجع فقط)، وبه شريط تقدم يوضح نسبة اكتماله.
///
/// **وضع الإنشاء** (`caseId == null`): تفتح بلا حالة موجودة على السيرفر
/// بعد — كل التابات تُملأ محليًا في الذاكرة فقط (بلا كاش SQLite ولا طابور
/// مزامنة لكل تاب)، وزر آخر تاب يجمع كل الأقسام المدعومة في طلب
/// `POST /cases` واحد بدل "إرسال للمراجعة". بعد النجاح تتحول الشاشة لوضع
/// التعديل العادي بنفس الـ `caseId` الجديد (`pushReplacement`).
class CaseDetailsScreen extends ConsumerStatefulWidget {
  final String? caseId;
  final String personName;
  final String displayId;
  final CasePriority priority;

  /// فهرس التاب المفتوح عند دخول الشاشة — تستخدمه شاشة التعارض لتوجيه
  /// المستخدم مباشرة إلى قسم "ادمج يدويًا" بدل أول تاب دائمًا.
  final int initialTabIndex;

  bool get isCreating => caseId == null;

  const CaseDetailsScreen({
    super.key,
    required this.caseId,
    required this.personName,
    required this.displayId,
    required this.priority,
    this.initialTabIndex = 0,
  });

  /// يفتح الشاشة في وضع الإنشاء — بلا `caseId`، بيانات فورم فاضية.
  static void openForCreate(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CaseDetailsScreen(
          caseId: null,
          personName: 'حالة جديدة',
          displayId: '',
          priority: CasePriority.medium,
        ),
      ),
    );
  }

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
  OpinionsFormData? _opinions;
  SupportRecommendationFormData? _support;
  UtilitiesEquipmentFormData? _utilitiesEquipment;

  /// أحدث `rowVersion`/`caseRowVersion` معروفة — تُحدَّث من كل استجابة كاش
  /// طازجة، وتُستخدَم عند بناء `apiPayload` لكل قسم (§19: لا يجوز إرسال
  /// نسخة قديمة عمدًا).
  int? _caseRowVersion;
  int? _beneficiaryRowVersion;

  /// آخر `charityId` معروف من الخادم — يُقارَن بـ `_basicInfo.charityId` عند
  /// الحفظ لمعرفة هل المستخدم غيّر الجمعية فعليًا، فنرسل
  /// `PUT /cases/{id}/charity` فقط عند الحاجة (endpoint منفصل تمامًا عن
  /// beneficiary — راجع [CharityMapper]).
  String? _lastSavedCharityId;

  /// حالة الحالة (`status`) الحالية — من نفس مصدر `_caseRowVersion` (كاش
  /// `CasesRepository`، لا [CaseFullDetails] الذي لا يحملها كـ enum). تُستخدم
  /// فقط لإظهار زر "تكليف الحالة لنفسي" حين تكون `pendingAssignment`.
  CaseStatus? _caseStatus;
  bool _accepting = false;

  /// سبب/مصدر رجوع الحالة الحالي — من `returnInfo` (أعلى مستوى استجابة
  /// `GET /cases/{id}`)، مصدر الحقيقة الوحيد المضمون لهذا (§5، رد الباك إند
  /// على طلب 14) — **لا** يُستنتج من `opinions.reviewer` وحده.
  ReturnInfoDto? _returnInfo;

  /// فهارس التابات التي عدّلها المستخدم منذ آخر حفظ ناجح — الحفظ عند
  /// المغادرة يتجاهل تابًا لم يُلمَس، فلا يُضاف `enqueue` بلا داعٍ (§2.3،
  /// القاعدة ٤: الدمج ممتاز لكنه ليس بديلًا عن تفادي الإرسال أصلًا).
  final Set<int> _dirtyTabs = {};

  // --- وضع الإنشاء فقط (widget.isCreating) — راجع _buildCreateBasicInfoTab/_submitCreate ---
  List<LocationCenter> _centers = const [];
  LocationCenter? _selectedCenter;
  LocationVillage? _selectedVillage;
  List<Charity> _charities = const [];
  Charity? _selectedCharity;
  bool _loadingReference = true;
  bool _creating = false;
  Map<String, List<String>>? _createFieldErrors;

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
    if (widget.isCreating) {
      _basicInfo = BasicInfoFormData();
      _familyMembers = FamilyMembersFormData();
      _housing = HousingFormData();
      _utilitiesEquipment = UtilitiesEquipmentFormData();
      _agriculturalHolding = AgriculturalHoldingFormData();
      _financial = FinancialFormData();
      _initialNeed = InitialNeedFormData();
      _support = SupportRecommendationFormData();
      _opinions = OpinionsFormData();
      _loadCreateReferenceData();
      return;
    }
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
    final sections = await ref
        .read(casesRepositoryProvider)
        .readAllSections(widget.caseId!);
    if (!mounted) return;
    setState(() {
      _rawSections = sections;
      // Reset cache-dependent fields the user hasn't touched yet so
      // _seedFromServerData can re-populate them from the loaded cache.
      // فهارس محدَّثة بعد شيل تابي التصنيف الاجتماعي/الاحتياجات المُقيَّمة
      // ونقل المرفقات لآخر تاب الدخل والمصروفات — راجع [_tabLabels].
      if (!_dirtyTabs.contains(1)) _familyMembers = null;
      if (!_dirtyTabs.contains(2)) _housing = null;
      if (!_dirtyTabs.contains(3)) _utilitiesEquipment = null;
      if (!_dirtyTabs.contains(8)) _opinions = null;
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

  /// يزامن دخل كل فرد تابع له دخل شهري (`FamilyMemberFormData.monthlyIncome`)
  /// كبند "مصدر دخل" مستقل في تاب الدخل والمصروفات — نفس أسلوب مزامنة "تكافل
  /// وكرامة" و"دخل أراضي زراعية". المطابقة بمعرّف الفرد (`member.id`) المخزَّن
  /// في [IncomeItemFormData.personName] (لا يُعرض، يُستخدم للمطابقة فقط).
  /// التعديل يعمل بالاتجاهين: من تاب الأفراد يحدّث البند هنا، ومن هنا (عبر
  /// [IncomeItemFormData.onExternalAmountChanged]) يكتب رجوعًا في الفرد.
  /// لو الفرد اتحذف، بنده في تاب الدخل يتشال معاه بدل ما يفضل يتيم.
  void _syncFamilyMembersIncome() {
    if (_financial == null || _familyMembers == null) return;

    const prefix = 'family_member:';
    final memberIds = _familyMembers!.members.map((m) => prefix + m.id).toSet();

    _financial!.incomeItems.removeWhere(
      (i) => i.personName.startsWith(prefix) && !memberIds.contains(i.personName),
    );

    for (final member in _familyMembers!.members) {
      final key = prefix + member.id;
      var index = _financial!.incomeItems.indexWhere(
        (i) => i.personName == key,
      );
      if (index == -1) {
        _financial!.incomeItems.add(
          IncomeItemFormData(
            personName: key,
            sourceType: 'دخل الفرد التابع — ${member.relation}',
          ),
        );
        index = _financial!.incomeItems.length - 1;
      }
      final item = _financial!.incomeItems[index];
      item.sourceType = 'دخل الفرد التابع — ${member.relation}';
      item.onExternalAmountChanged = (v) {
        member.monthlyIncome = v;
      };
      if (member.monthlyIncome != null) {
        item.amount = member.monthlyIncome;
      }
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
    // فهرس 4 = تاب الحيازة والأصول ضمن [_tabLabels] (بعد شيل تابي التصنيف
    // الاجتماعي والاحتياجات المُقيَّمة، ونقل المرفقات لآخر تاب الدخل والمصروفات).
    if (index != 4) return true;
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
        await ref.read(casesRepositoryProvider).cachedDetails(widget.caseId!);
    if (!mounted || cached == null) return;
    setState(() {
      _caseRowVersion = cached.rowVersion;
      _beneficiaryRowVersion = cached.beneficiary.rowVersion;
      _returnInfo = cached.returnInfo;
      _caseStatus = cached.status;
      // charityId مالوش نظير في CaseFullDetails (كيان عرض فقط، §423) — بيتقرا
      // من الكاش هنا زي rowVersion بالظبط. يتحدّث فقط أول مرة (`??=`) — بعد
      // كده الفورم (Dropdown الجمعية) هو مصدر الحقيقة، وإلا كل _loadRowVersions
      // كان هيدهس أي تعديل لسه ملحفظش.
      _basicInfo?.charityId ??= cached.charityId;
      _lastSavedCharityId = cached.charityId;
    });
  }

  /// قبول التكليف — `POST /cases/{id}/accept` عبر `CasesRepository.acceptAssignment`.
  /// مسموح به من حالتين (§9): `assigned` (أُسندت الحالة له من data_entry/
  /// manager فعليًا، وينقصها قبوله لينتقل لـ `in_research`) أو
  /// `pendingAssignment` (SelfAcceptCase، §2.2 من عقد الموبايل، لا مُسنَد
  /// إليه بعد). **بدون هذه الخطوة تبقى الحالة `assigned` إلى الأبد ويرفض
  /// الخادم `submit_worker_opinion` لاحقًا بـ422 مهما اكتملت البيانات** — لا
  /// يظهر الزر فقط في هذه الحالتين (راجع [_caseStatus])، والقرار النهائي
  /// خادمي دائمًا (§15.7).
  Future<void> _acceptAssignment() async {
    if (_accepting) return;
    setState(() => _accepting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(casesRepositoryProvider).acceptAssignment(widget.caseId!);
      if (!mounted) return;
      ref.invalidate(caseDetailsProvider(widget.caseId!));
      ref.invalidate(homeDataProvider);
      await _loadRowVersions();
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('تم تكليفك بالحالة')),
        );
    } on ApiException catch (e) {
      if (!mounted) return;
      // 409/422/403 هنا تعني كلها نفس الشيء عمليًا: أخصائي آخر سبقك أو
      // تغيّرت الحالة قبل ما يوصل الطلب — رسالتنا نحن، لا `e.displayMessage`
      // (رسالة الـ 422 تتضمّن اسم الحالة بالإنجليزي، غير مناسبة للعرض).
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              e.isConflict
                  ? 'الحالة دي اتكلف بيها أخصائي تاني أو اتغيرت، هنحدّث البيانات'
                  : e.displayMessage,
            ),
            backgroundColor: AppColors.danger,
          ),
        );
      if (!mounted) return;
      ref.invalidate(caseDetailsProvider(widget.caseId!));
      await _loadRowVersions();
    } finally {
      if (mounted) setState(() => _accepting = false);
    }
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
      // الحقول دي كانت ناقصة من GET /cases/{id} (اتصلحت من الباك إند —
      // commit bcc9d61) فكانت بتفضل فاضية في الفورم رغم إن BasicInfoFormData
      // أصلاً عندها الحقول دي وPUT /beneficiary بيقبلها.
      religion: data.basicInfo.religion,
      headRelation: data.basicInfo.headRelation,
      monthlyIncome: data.basicInfo.monthlyIncome,
      workType: data.basicInfo.employmentStatus,
      takafulKarama: data.basicInfo.takafulBeneficiary ?? false,
      takafulKaramaAmount: data.basicInfo.takafulAmount,
      // socialInsurance مالهاش نظير في PUT /beneficiary (اتأكد من التوثيق) —
      // بيفضل محفوظ محليًا بس، زي ما كان قبل كده.
      // centerId/villageId قابلين للتعديل فعليًا (اتأكد من الباك إند) —
      // basic_info_tab.dart بيحلّهم لاسم المركز/القرية للعرض والتعديل.
      centerId: data.basicInfo.centerId,
      villageId: data.basicInfo.villageId,
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
    // وضع الإنشاء: لا caseId بعد، فلا حفظ محلي/مزامنة لكل تاب — كل شيء يبقى
    // في الذاكرة لحد ما يُرسَل دفعة واحدة عبر _submitCreate.
    if (widget.isCreating) return;

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

  /// يحفظ بيانات كل التابات التسعة دفعة واحدة — يُستدعى من زر "حفظ" العائم.
  /// غير متاح في وضع الإنشاء (لا caseId بعد، راجع [_saveCurrentTabIfDirty]).
  Future<void> _saveAllTabs() async {
    if (widget.isCreating) return;

    final repo = ref.read(casesRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    try {
      for (var index = 0; index < _tabLabels.length; index++) {
        // "المصيدة المالية" (راجع كومنت case 5 في _saveTab): حفظ أي قسم من
        // بيانات أساسية/أفراد/زراعة يزيد rowVersion الحالة على الخادم
        // بصمت. حفظ تابات متتالية في نفس الضغطة (خلاف التنقل تاب-بتاب)
        // يجعل هذا محتملًا جدًا، فنُحدِّث `_caseRowVersion` قبل كل تاب
        // يعتمد عليه بدل الاعتماد على النسخة المأخوذة عند فتح الشاشة.
        if (_caseRowVersion != null &&
            (index == 1 || index == 3 || index == 6 || index == 7)) {
          await repo.refreshCaseDetails(widget.caseId!);
          final freshCase = await repo.readCase(widget.caseId!);
          _caseRowVersion = freshCase?.rowVersion ?? _caseRowVersion;
        }
        await _saveTab(index);
        _dirtyTabs.remove(index);
      }
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('تم حفظ كل التابات')),
        );
    } on ApiException catch (e) {
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
    final caseId = widget.caseId!;

    // فهارس محدَّثة بعد شيل تابي التصنيف الاجتماعي والاحتياجات المُقيَّمة،
    // ونقل تاب المرفقات ليجي بعد تاب الدخل والمصروفات — راجع [_tabLabels].
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
        // الجمعية: endpoint منفصل تمامًا (PUT /cases/{id}/charity)، بـ
        // caseRowVersion لا rowVersion المستفيد — نرسله فقط لو المستخدم غيّر
        // فعليًا الجمعية عن آخر قيمة معروفة من الخادم (تجنبًا لطلب زائد أو
        // 409 وهمي عند كل حفظ للتاب).
        if (_caseRowVersion != null && form.charityId != _lastSavedCharityId) {
          await repo.saveSection(
            caseId: caseId,
            sectionKey: 'charity',
            dataJson: {'charityId': form.charityId},
            apiPayload: CharityMapper.toApiPayload(
              form,
              caseRowVersion: _caseRowVersion!,
            ),
            syncType: SyncOperationType.updateCharity,
          );
          _lastSavedCharityId = form.charityId;
        }
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
      case 2: // السكن
        final form = _housing;
        if (form == null) break;
        // نجلب `rowVersion` طازجًا من الخادم مباشرة (لا من الكاش المحلي) —
        // راجع توثيق [CasesRepository.fetchFreshSectionRowVersion]: الكاش
        // محمي من الكتابة فوقه طالما هذا القسم `isDirty`، وهو بالضبط حال
        // القسم الذي نحفظه الآن، فقراءته بعد `refreshCaseDetails` كانت
        // ترجع القيمة القديمة/`null` وترتدّ بـ409 زائف.
        await repo.saveSection(
          caseId: caseId,
          sectionKey: 'housing',
          dataJson: HousingMapper.toCacheJson(form),
          apiPayload: HousingMapper.toApiPayload(
            form,
            rowVersion: await repo.fetchFreshSectionRowVersion(
              caseId,
              'housing',
            ),
          ),
          syncType: SyncOperationType.updateHousing,
        );
      case 3: // المرافق والتجهيزات
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
      case 4: // الحيازة والأصول
        final form = _agriculturalHolding;
        if (form == null) break;
        // نفس القراءة المباشرة من الخادم في تاب السكن أعلاه — راجع تعليقه.
        await repo.saveSection(
          caseId: caseId,
          sectionKey: 'agriculture',
          dataJson: AgricultureMapper.toCacheJson(form),
          apiPayload: AgricultureMapper.toApiPayload(
            form,
            rowVersion: await repo.fetchFreshSectionRowVersion(
              caseId,
              'agriculture',
            ),
          ),
          syncType: SyncOperationType.updateAgriculture,
        );
      case 5: // الدخل والمصروفات
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
      case 6: // المرفقات + الاحتياج الأولي (تاب مدمج — راجع InitialNeedAttachmentsTab)
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
      case 7: // الدعم
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
      case 8: // الرأي — لا endpoint مطابق لهذا الشكل التفصيلي (راجع
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
        caseId: widget.caseId!,
        decision: decision,
        notes: notes,
      );
      ref.invalidate(homeDataProvider);
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

  // --- وضع الإنشاء (POST /cases) ---

  Future<void> _loadCreateReferenceData() async {
    final repo = ref.read(referenceRepositoryProvider);
    final centers = await repo.centers();
    final charities = await repo.charities();
    if (!mounted) return;
    setState(() {
      _centers = centers;
      _charities = charities;
      _loadingReference = false;
    });
  }

  void _onCreateCenterChanged(LocationCenter? center) {
    setState(() {
      _selectedCenter = center;
      _selectedVillage = null;
    });
  }

  List<String>? _createErrorsFor(String field) => _createFieldErrors?[field];

  bool get _isCreateBasicInfoValid {
    final basicInfo = _basicInfo;
    if (basicInfo == null || basicInfo.caseName.trim().isEmpty) return false;
    final idResult = parseEgyptianNationalId(basicInfo.nationalId);
    if (!idResult.valid) return false;
    if (_selectedCenter == null || _selectedVillage == null) return false;
    return true;
  }

  Future<void> _submitCreate() async {
    if (!_isCreateBasicInfoValid) {
      _tabController.animateTo(0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'كمّل الحقول المطلوبة الأول: الاسم، الرقم القومي، المركز، القرية.',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    final holding = _agriculturalHolding!;
    if (!holding.isComplete && !_canLeaveTab(4)) {
      _tabController.animateTo(4);
      return;
    }

    setState(() {
      _creating = true;
      _createFieldErrors = null;
    });

    try {
      // BeneficiaryMapper.toApiPayload لا يبعت nationalId/centerId/villageId
      // (ثابتة بعد الإنشاء في وضع التعديل)، لكن POST /cases يحتاجهم — تُضاف
      // هنا يدويًا فوق ناتج المابر بدل تكرار كل الحقول الأخرى يدويًا.
      final beneficiary = BeneficiaryMapper.toApiPayload(
        _basicInfo!,
        rowVersion: 0,
      )..remove('rowVersion');
      beneficiary['nationalId'] = _basicInfo!.nationalId.trim();
      beneficiary['centerId'] = _selectedCenter!.id;
      beneficiary['villageId'] = _selectedVillage!.id;

      final payload = {
        'beneficiary': beneficiary,
        'charityId': _selectedCharity?.id,
        'priority': widget.priority.name,
        'familyMembers': FamilyMembersMapper.toApiPayload(
          _familyMembers!,
          caseRowVersion: 0,
        )..remove('caseRowVersion'),
        'housing': HousingMapper.toApiPayload(_housing!, rowVersion: null)
          ..remove('rowVersion'),
        'utilities': UtilitiesMapper.toApiPayload(
          _utilitiesEquipment!,
          caseRowVersion: 0,
        )..remove('caseRowVersion'),
        'agriculture': AgricultureMapper.toApiPayload(
          holding,
          rowVersion: null,
        )..remove('rowVersion'),
      };

      final repo = ref.read(casesRepositoryProvider);
      final result = await repo.createCase(payload);
      if (!mounted) return;

      final newCaseId = result['id'] as String?;
      final caseNumber = result['caseNumber'] as String? ?? '—';
      await _showCreateSuccessDialog(caseNumber: caseNumber);
      if (!mounted) return;

      if (newCaseId == null) {
        Navigator.of(context).pop();
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => CaseDetailsScreen(
            caseId: newCaseId,
            personName: _basicInfo!.caseName,
            displayId: caseNumber,
            priority: widget.priority,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _createFieldErrors = e.details);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.displayMessage),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _showCreateSuccessDialog({required String caseNumber}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'تمام، الحالة اتسجّلت!',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        content: Text(
          'رقم الحالة: $caseNumber',
          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('تمام'),
          ),
        ],
      ),
    );
  }

  /// تاب "البيانات الأساسية" في وضع الإنشاء — [BasicInfoTab] الحقيقي، متبوعًا
  /// بقسم Dropdown مركز/قرية/جمعية — الحقول الوحيدة اللي [BeneficiaryMapper]
  /// لا يبعتها لكن عقد `POST /cases` يفرضها كـ GUID حقيقي (راجع _submitCreate).
  Widget _buildCreateBasicInfoTab() {
    if (_loadingReference) {
      return const Center(child: CircularProgressIndicator());
    }
    return BasicInfoTab(
      initialData: _basicInfo!,
      onChanged: (v) => setState(() => _basicInfo = v),
      trailing: SectionCard(
        title: 'الجمعية والنطاق الجغرافي',
        child: Column(
          children: [
            DropdownButtonFormField<LocationCenter>(
              initialValue: _selectedCenter,
              isExpanded: true,
              decoration: InputDecoration(
                border: InputBorder.none,
                labelText: 'المركز *',
                errorText: _createErrorsFor('centerId')?.join('، '),
                hintText: 'اختر المركز',
              ),
              items: [
                for (final center in _centers)
                  DropdownMenuItem(value: center, child: Text(center.name)),
              ],
              onChanged: _onCreateCenterChanged,
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<LocationVillage>(
              initialValue: _selectedVillage,
              isExpanded: true,
              decoration: InputDecoration(
                border: InputBorder.none,
                labelText: 'القرية *',
                errorText: _createErrorsFor('villageId')?.join('، '),
                hintText: _selectedCenter == null
                    ? 'اختر المركز أولًا'
                    : 'اختر القرية',
              ),
              items: [
                for (final village in _selectedCenter?.villages ?? const [])
                  DropdownMenuItem(value: village, child: Text(village.name)),
              ],
              onChanged: _selectedCenter == null
                  ? null
                  : (v) => setState(() => _selectedVillage = v),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<Charity>(
              initialValue: _selectedCharity,
              isExpanded: true,
              decoration: const InputDecoration(
                border: InputBorder.none,
                labelText: 'الجمعية',
                hintText: 'اختياري',
              ),
              items: [
                for (final charity in _charities)
                  DropdownMenuItem(value: charity, child: Text(charity.name)),
              ],
              onChanged: (v) => setState(() => _selectedCharity = v),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCreating) return _buildCreateScaffold(context);

    final detailsAsync = ref.watch(caseDetailsProvider(widget.caseId!));

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
            if (_caseStatus == CaseStatus.pendingAssignment ||
                _caseStatus == CaseStatus.assigned)
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.xs),
                child: FilledButton.icon(
                  onPressed: _accepting ? null : _acceptAssignment,
                  icon: _accepting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.assignment_ind_outlined, size: 16),
                  label: const Text(
                    'تكليف',
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
            _syncFamilyMembersIncome();

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
                          caseId: widget.caseId,
                          initialData: _basicInfo!,
                          onChanged: (v) => setState(() {
                            _basicInfo = v;
                            _markDirty(0);
                            _syncTakafulKarama();
                          }),
                        ),
                        FamilyMembersTab(
                          caseId: widget.caseId,
                          initialData: _familyMembers!,
                          onChanged: (v) => setState(() {
                            _familyMembers = v;
                            _markDirty(1);
                            _syncTakafulKarama();
                            _syncFamilyMembersIncome();
                          }),
                        ),
                        HousingTab(
                          initialData: _housing!,
                          onChanged: (v) => setState(() {
                            _housing = v;
                            _markDirty(2);
                          }),
                        ),
                        UtilitiesEquipmentTab(
                          initialData: _utilitiesEquipment!,
                          onChanged: (v) => setState(() {
                            _utilitiesEquipment = v;
                            _markDirty(3);
                          }),
                        ),
                        AgriculturalHoldingTab(
                          key: _agriTabKey,
                          initialData: _agriculturalHolding!,
                          onChanged: (v) => setState(() {
                            _agriculturalHolding = v;
                            _markDirty(4);
                            _syncAgriculturalHolding();
                          }),
                        ),
                        FinancialTab(
                          initialData: _financial!,
                          onChanged: (v) => setState(() {
                            _financial = v;
                            _markDirty(5);
                            _syncAgriculturalHolding();
                            _syncFamilyMembersIncome();
                          }),
                        ),
                        InitialNeedAttachmentsTab(
                          caseId: widget.caseId!,
                          initialData: _initialNeed!,
                          onChanged: (v) => setState(() {
                            _initialNeed = v;
                            _markDirty(6);
                          }),
                        ),
                        SupportTab(
                          initialData: _support!,
                          onChanged: (v) => setState(() {
                            _support = v;
                            _markDirty(7);
                          }),
                          approved: data.approvedSupport,
                        ),
                        OpinionsTab(
                          initialData: _opinions!,
                          onChanged: (v) => setState(() {
                            _opinions = v;
                            _markDirty(8);
                          }),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: AppSpacing.lg,
                    bottom: 76 + MediaQuery.of(context).padding.bottom,
                    child: _SaveAllButton(onPressed: () async {
                      await _saveCurrentTabIfDirty();
                      if (!mounted) return;
                      await _saveAllTabs();
                    }),
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

  /// شاشة وضع الإنشاء — نفس هيكل شاشة التفاصيل (AppBar/TabBar/TabBarView) لكن
  /// بلا `caseDetailsProvider` (لا حالة على الخادم بعد)، وزر آخر تاب يستدعي
  /// `_submitCreate` بدل `_handleSubmitForReview`.
  Widget _buildCreateScaffold(BuildContext context) {
    _syncTakafulKarama();
    _syncAgriculturalHolding();
    _syncFamilyMembersIncome();

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            'إنشاء حالة جديدة',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
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
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 76),
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCreateBasicInfoTab(),
                  FamilyMembersTab(
                    initialData: _familyMembers!,
                    onChanged: (v) => setState(() {
                      _familyMembers = v;
                      _syncTakafulKarama();
                      _syncFamilyMembersIncome();
                    }),
                  ),
                  HousingTab(
                    initialData: _housing!,
                    onChanged: (v) => setState(() => _housing = v),
                  ),
                  UtilitiesEquipmentTab(
                    initialData: _utilitiesEquipment!,
                    onChanged: (v) => setState(() => _utilitiesEquipment = v),
                  ),
                  AgriculturalHoldingTab(
                    key: _agriTabKey,
                    initialData: _agriculturalHolding!,
                    onChanged: (v) => setState(() {
                      _agriculturalHolding = v;
                      _syncAgriculturalHolding();
                    }),
                  ),
                  FinancialTab(
                    initialData: _financial!,
                    onChanged: (v) => setState(() {
                      _financial = v;
                      _syncAgriculturalHolding();
                      _syncFamilyMembersIncome();
                    }),
                  ),
                  const _CreateModeNotSavedBanner(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.xxl),
                        child: Text(
                          'رفع المرفقات متاح بعد إنشاء الحالة فقط.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                  _CreateModeNotSavedBanner(
                    child: SupportTab(
                      initialData: _support!,
                      onChanged: (v) => setState(() => _support = v),
                      approved: null,
                    ),
                  ),
                  _CreateModeNotSavedBanner(
                    child: OpinionsTab(
                      initialData: _opinions!,
                      onChanged: (v) => setState(() => _opinions = v),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _creating
                  ? const Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : TabNavigationBar(
                      isFirstTab: _currentTabIndex == 0,
                      isLastTab: _currentTabIndex == _tabLabels.length - 1,
                      onPrevious: _goToPreviousTab,
                      onNext: _goToNextTab,
                      onSubmit: _submitCreate,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// تنبيه أعلى تابات المرفقات/الدعم/الرأي في وضع الإنشاء — عقد `POST /cases`
/// الحالي (طلب 15) لا يقبل الأقسام دي أصلًا (راجع تعليق `_submitCreate`)، فأي
/// حاجة تُكتَب هنا **لا تُرسَل ولا تُحفَظ** عند "إنشاء الحالة".
class _CreateModeNotSavedBanner extends StatelessWidget {
  final Widget child;

  const _CreateModeNotSavedBanner({required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            0,
          ),
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.warningBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: AppColors.warning),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'هذا التاب لسه مش بيتحفظ مع إنشاء الحالة — هتحتاج تدخله '
                  'تاني من شاشة تفاصيل الحالة بعد ما تتسجل.',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

/// زر "حفظ" عائم — يحفظ بيانات كل التابات دفعة واحدة، موضوع فوق زر
/// التالي/الإرسال في [TabNavigationBar] مباشرة (أسفل شمال الشاشة).
class _SaveAllButton extends StatefulWidget {
  final Future<void> Function() onPressed;

  const _SaveAllButton({required this.onPressed});

  @override
  State<_SaveAllButton> createState() => _SaveAllButtonState();
}

class _SaveAllButtonState extends State<_SaveAllButton> {
  bool _saving = false;

  Future<void> _handleTap() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await widget.onPressed();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      shape: const StadiumBorder(),
      elevation: 3,
      shadowColor: AppColors.textPrimary.withValues(alpha: 0.2),
      child: InkWell(
        onTap: _saving ? null : _handleTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 10,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_saving)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.textInverse,
                  ),
                )
              else
                const Icon(
                  Icons.save_outlined,
                  size: 18,
                  color: AppColors.textInverse,
                ),
              const SizedBox(width: 6),
              const Text(
                'حفظ',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textInverse,
                ),
              ),
            ],
          ),
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
