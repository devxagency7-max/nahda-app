import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/providers/data_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/egyptian_national_id_parser.dart';
import '../../../core/widgets/app_background.dart';
import '../../case_details/data/mappers/agriculture_mapper.dart';
import '../../case_details/data/mappers/assessed_needs_mapper.dart';
import '../../case_details/data/mappers/beneficiary_mapper.dart';
import '../../case_details/data/mappers/classification_mapper.dart';
import '../../case_details/data/mappers/family_members_mapper.dart';
import '../../case_details/data/mappers/housing_mapper.dart';
import '../../case_details/data/mappers/utilities_mapper.dart';
import '../../case_details/domain/sections/agricultural_holding_form.dart';
import '../../case_details/domain/sections/assessed_needs_form.dart';
import '../../case_details/domain/sections/basic_info_family_form.dart';
import '../../case_details/domain/sections/classification_form.dart';
import '../../case_details/domain/sections/housing_form.dart';
import '../../case_details/domain/sections/opinions_form.dart';
import '../../case_details/domain/sections/support_form.dart';
import '../../case_details/domain/sections/utilities_equipment_form.dart';
import '../../case_details/presentation/tabs/agricultural_holding_tab.dart';
import '../../case_details/presentation/tabs/assessed_needs_tab.dart';
import '../../case_details/presentation/tabs/basic_info_tab.dart';
import '../../case_details/presentation/tabs/classification_tab.dart';
import '../../case_details/presentation/tabs/family_members_tab.dart';
import '../../case_details/presentation/tabs/housing_tab.dart';
import '../../case_details/presentation/tabs/opinions_tab.dart';
import '../../case_details/presentation/tabs/support_tab.dart';
import '../../case_details/presentation/tabs/utilities_equipment_tab.dart';
import '../../case_details/presentation/widgets/section_card.dart';
import '../../case_details/presentation/widgets/tab_navigation_bar.dart';
import '../../home/domain/case_priority.dart';
import '../../reference/domain/reference_models.dart';

const _tabLabels = [
  'البيانات الأساسية',
  'الأفراد التابعين',
  'السكن',
  'المرافق والتجهيزات',
  'الحيازة والأصول',
  'التصنيف الاجتماعي',
  'الاحتياجات المُقيَّمة',
  'الدعم',
  'الرأي',
];

/// شاشة إنشاء حالة جديدة — `POST /cases` (§20، مع الأقسام الاختيارية —
/// راجع `BACKEND_CHANGE_REQUEST_7.md`/طلب 15).
///
/// كل التابات تُحفَظ محليًا في الذاكرة فقط (بلا كاش SQLite ولا طابور
/// مزامنة — هذه شاشة إنشاء لحالة لا وجود لها بعد على الخادم، فليس هناك
/// `caseId`/`rowVersion` يُبنى عليه أي حفظ جزئي). زر "إنشاء الحالة" في آخر
/// تاب يجمع كل الأقسام في طلب واحد ويرسلها دفعة واحدة.
///
/// **تاب "الدخل والمصروفات" مُستبعَد مؤقتًا** — فئات المصروفات الافتراضية في
/// [FinancialFormData] (كهرباء/مياه/غاز منفصلة) لا تطابق قاعدة الخمس فئات
/// الثابتة الملزمة في العقد (`BACKEND_CHANGE_REQUEST_8.md`/طلب 16، لسه بلا
/// رد). إرساله بشكله الحالي يرجع 422 دائمًا.
///
/// **تابات "المرفقات"، "الدعم"، "الرأي" مُستبعَدة كليًا** — غير موجودة في
/// عقد `POST /cases` أصلًا (لا مكان لها قبل وجود `caseId`).
class CreateCaseScreen extends ConsumerStatefulWidget {
  const CreateCaseScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreateCaseScreen()),
    );
  }

  @override
  ConsumerState<CreateCaseScreen> createState() => _CreateCaseScreenState();
}

class _CreateCaseScreenState extends ConsumerState<CreateCaseScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _currentTabIndex = 0;

  // تاب "البيانات الأساسية" — نفس BasicInfoTab الحقيقي (تاب شاشة تفاصيل
  // الحالة بكل حقوله) لعرض/تعبئة نفس البيانات بالظبط، + Dropdown مركز/قرية
  // منفصل بجانبه لأن العقد `POST /cases` يحتاج `centerId`/`villageId` كـ
  // GUID حقيقي من السيرفر، و[BasicInfoFormData.referralDistrict]/
  // [referralVillage] نص حر (قائمة مراكز بني سويف الثابتة) لا يفي بالغرض.
  BasicInfoFormData _basicInfo = BasicInfoFormData();
  List<LocationCenter> _centers = const [];
  LocationCenter? _selectedCenter;
  LocationVillage? _selectedVillage;
  List<Charity> _charities = const [];
  Charity? _selectedCharity;
  CasePriority _priority = CasePriority.medium;
  bool _loadingReference = true;

  FamilyMembersFormData _familyMembers = FamilyMembersFormData();
  HousingFormData _housing = HousingFormData();
  UtilitiesEquipmentFormData _utilitiesEquipment = UtilitiesEquipmentFormData();
  AgriculturalHoldingFormData _agriculturalHolding =
      AgriculturalHoldingFormData();
  ClassificationFormData _classification = ClassificationFormData();
  AssessedNeedsFormData _assessedNeeds = AssessedNeedsFormData();

  // تابا "الدعم" و"الرأي" — غير مدعومين في عقد `POST /cases` الحالي (لا
  // مكان لهما قبل وجود caseId، راجع BACKEND_CHANGE_REQUEST_9.md/طلب 17).
  // يُعرَضان هنا للتطابق الشكلي مع شاشة تفاصيل الحالة فقط؛ ما يُكتَب فيهما
  // لا يُرسَل حاليًا ولا يُحفَظ بعد إغلاق الشاشة.
  SupportRecommendationFormData _support = SupportRecommendationFormData();
  OpinionsFormData _opinions = OpinionsFormData();

  bool _submitting = false;
  Map<String, List<String>>? _fieldErrors;

  final _agriTabKey = GlobalKey<AgriculturalHoldingTabState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabLabels.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _currentTabIndex = _tabController.index);
      }
    });
    _loadReferenceData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReferenceData() async {
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

  void _onCenterChanged(LocationCenter? center) {
    setState(() {
      _selectedCenter = center;
      _selectedVillage = null;
    });
  }

  List<String>? _errorsFor(String field) => _fieldErrors?[field];

  bool get _isBasicInfoValid {
    if (_basicInfo.caseName.trim().isEmpty) return false;
    final idResult = parseEgyptianNationalId(_basicInfo.nationalId);
    if (!idResult.valid) return false;
    if (_selectedCenter == null || _selectedVillage == null) return false;
    return true;
  }

  /// بوابة التحقق قبل مغادرة تاب للأمام — الرجوع للخلف مسموح دائمًا.
  /// نفس منطق `case_details_screen.dart`: تاب الحيازة فقط مقيَّد.
  bool _canLeaveTab(int index) {
    if (index == 4 && !_agriculturalHolding.isComplete) {
      _agriTabKey.currentState?.showValidationErrors();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'كمّل الحقول دي الأول قبل ما تكمل: '
              '${_agriculturalHolding.missingFields.join(' — ')}',
            ),
            backgroundColor: AppColors.danger,
          ),
        );
      return false;
    }
    return true;
  }

  void _goToPreviousTab() {
    if (_tabController.index <= 0) return;
    _tabController.animateTo(_tabController.index - 1);
  }

  void _goToNextTab() {
    if (_tabController.index >= _tabLabels.length - 1) return;
    if (!_canLeaveTab(_tabController.index)) return;
    _tabController.animateTo(_tabController.index + 1);
  }

  Future<void> _submit() async {
    if (!_isBasicInfoValid) {
      _tabController.animateTo(0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('كمّل الحقول المطلوبة الأول: الاسم، الرقم القومي، المركز، القرية.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    if (!_agriculturalHolding.isComplete) {
      if (!_canLeaveTab(4)) {
        _tabController.animateTo(4);
        return;
      }
    }

    setState(() {
      _submitting = true;
      _fieldErrors = null;
    });

    try {
      // BeneficiaryMapper.toApiPayload لا يبعت nationalId/centerId/villageId
      // (ثابتة بعد الإنشاء في شاشة التعديل)، لكن POST /cases يحتاجهم — تُضاف
      // هنا يدويًا فوق ناتج المابر بدل تكرار كل الحقول الأخرى يدويًا.
      final beneficiary = BeneficiaryMapper.toApiPayload(
        _basicInfo,
        rowVersion: 0,
      )..remove('rowVersion');
      beneficiary['nationalId'] = _basicInfo.nationalId.trim();
      beneficiary['centerId'] = _selectedCenter!.id;
      beneficiary['villageId'] = _selectedVillage!.id;

      final payload = {
        'beneficiary': beneficiary,
        'charityId': _selectedCharity?.id,
        'priority': _priority.name,
        'familyMembers': FamilyMembersMapper.toApiPayload(
          _familyMembers,
          caseRowVersion: 0,
        )..remove('caseRowVersion'),
        'housing': HousingMapper.toApiPayload(_housing, rowVersion: null)
          ..remove('rowVersion'),
        'utilities': UtilitiesMapper.toApiPayload(
          _utilitiesEquipment,
          caseRowVersion: 0,
        )..remove('caseRowVersion'),
        'agriculture': AgricultureMapper.toApiPayload(
          _agriculturalHolding,
          rowVersion: null,
        )..remove('rowVersion'),
        'classification': ClassificationMapper.toApiPayload(
          _classification,
          rowVersion: null,
        )..remove('rowVersion'),
        'assessedNeeds': AssessedNeedsMapper.toApiPayload(
          _assessedNeeds,
          caseRowVersion: 0,
        )..remove('caseRowVersion'),
      };

      final result = await ref
          .read(casesRepositoryProvider)
          .createCase(payload);

      if (!mounted) return;
      await _showSuccessDialog(
        caseNumber: result['caseNumber'] as String? ?? '—',
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _fieldErrors = e.details);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.displayMessage),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _showSuccessDialog({required String caseNumber}) {
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

  /// تاب "البيانات الأساسية" — [BasicInfoTab] الحقيقي كامل الحقول (نفس شكل
  /// أي حالة عادية في شاشة التفاصيل)، متبوعًا بقسم Dropdown مركز/قرية/جمعية/
  /// أولوية إضافي — الحقول الوحيدة اللي [BeneficiaryMapper] لا يبعتها لكن
  /// عقد `POST /cases` يفرضها كـ GUID حقيقي (راجع تعليق `_submit`).
  Widget _buildBasicInfoTab() {
    if (_loadingReference) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      children: [
        Expanded(
          child: BasicInfoTab(
            initialData: _basicInfo,
            onChanged: (v) => setState(() => _basicInfo = v),
          ),
        ),
        Container(
          constraints: const BoxConstraints(maxHeight: 260),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
        SectionCard(
          title: 'المركز *',
          child: DropdownButtonFormField<LocationCenter>(
            initialValue: _selectedCenter,
            isExpanded: true,
            decoration: InputDecoration(
              border: InputBorder.none,
              errorText: _errorsFor('centerId')?.join('، '),
              hintText: 'اختر المركز',
            ),
            items: [
              for (final center in _centers)
                DropdownMenuItem(value: center, child: Text(center.name)),
            ],
            onChanged: _onCenterChanged,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SectionCard(
          title: 'القرية *',
          child: DropdownButtonFormField<LocationVillage>(
            initialValue: _selectedVillage,
            isExpanded: true,
            decoration: InputDecoration(
              border: InputBorder.none,
              errorText: _errorsFor('villageId')?.join('، '),
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
        ),
        const SizedBox(height: AppSpacing.md),
        SectionCard(
          title: 'الجمعية',
          child: DropdownButtonFormField<Charity>(
            initialValue: _selectedCharity,
            isExpanded: true,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'اختياري',
            ),
            items: [
              for (final charity in _charities)
                DropdownMenuItem(value: charity, child: Text(charity.name)),
            ],
            onChanged: (v) => setState(() => _selectedCharity = v),
          ),
        ),
              const SizedBox(height: AppSpacing.md),
              SectionCard(
                title: 'الأولوية',
                child: Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    for (final p in CasePriority.values)
                      ChoiceChip(
                        label: Text(p.label),
                        selected: _priority == p,
                        onSelected: (_) => setState(() => _priority = p),
                        selectedColor: p.backgroundColor,
                        labelStyle: TextStyle(
                          color:
                              _priority == p ? p.color : AppColors.textMuted,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            'إنشاء حالة جديدة',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.sm),
              child: TextButton.icon(
                // معطّل دائمًا هنا — لا سجل لحالة لسه ماتسجلتش (تطابق شكلي
                // مع زر "السجل" في شاشة تفاصيل الحالة فقط، راجع الملف).
                onPressed: null,
                icon: const Icon(Icons.history, size: 16),
                label: const Text('السجل', style: TextStyle(fontSize: 12)),
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
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 76),
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBasicInfoTab(),
                  FamilyMembersTab(
                    initialData: _familyMembers,
                    onChanged: (v) => setState(() => _familyMembers = v),
                  ),
                  HousingTab(
                    initialData: _housing,
                    onChanged: (v) => setState(() => _housing = v),
                  ),
                  UtilitiesEquipmentTab(
                    initialData: _utilitiesEquipment,
                    onChanged: (v) =>
                        setState(() => _utilitiesEquipment = v),
                  ),
                  AgriculturalHoldingTab(
                    key: _agriTabKey,
                    initialData: _agriculturalHolding,
                    onChanged: (v) =>
                        setState(() => _agriculturalHolding = v),
                  ),
                  ClassificationTab(
                    initialData: _classification,
                    onChanged: (v) => setState(() => _classification = v),
                  ),
                  AssessedNeedsTab(
                    initialData: _assessedNeeds,
                    onChanged: (v) => setState(() => _assessedNeeds = v),
                  ),
                  _NotYetSavedWrapper(
                    child: SupportTab(
                      initialData: _support,
                      onChanged: (v) => setState(() => _support = v),
                    ),
                  ),
                  _NotYetSavedWrapper(
                    child: OpinionsTab(
                      initialData: _opinions,
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
              child: _submitting
                  ? const Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : TabNavigationBar(
                      isFirstTab: _currentTabIndex == 0,
                      isLastTab: _currentTabIndex == _tabLabels.length - 1,
                      onPrevious: _goToPreviousTab,
                      onNext: _goToNextTab,
                      onSubmit: _submit,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// تنبيه أعلى تابي "الدعم"/"الرأي" — العقد الحالي لـ `POST /cases` (طلب 15)
/// لا يقبل القسمين دول أصلًا (راجع `BACKEND_CHANGE_REQUEST_9.md`/طلب 17، لسه
/// بلا رد)، فأي حاجة تُكتَب هنا **لا تُرسَل ولا تُحفَظ** عند "إنشاء الحالة".
/// نعرض التاب رغم ذلك (بطلب صريح) لكن مع تحذير واضح بدل فقد صامت للبيانات.
class _NotYetSavedWrapper extends StatelessWidget {
  final Widget child;

  const _NotYetSavedWrapper({required this.child});

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
