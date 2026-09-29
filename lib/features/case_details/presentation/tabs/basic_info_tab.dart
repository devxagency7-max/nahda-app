import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/data_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../case_search/domain/case_search_result.dart';
import '../../../case_search/presentation/case_search_providers.dart';
import '../../../reference/domain/reference_models.dart';
import '../../domain/sections/basic_info_family_form.dart';
import '../case_details_screen.dart';
import '../widgets/editable_dropdown.dart';
import '../widgets/editable_text_field.dart';
import '../widgets/section_card.dart';
import '../widgets/tab_progress_bar.dart';

import '../../../../core/utils/egyptian_national_id_parser.dart';
import '../../../../core/utils/localized_number_parser.dart';

const _educationLevels = [
  'مؤهل عالي / جامعي',
  'مؤهل فوق متوسط',
  'مؤهل متوسط (ثانوي/دبلوم)',
  'إعدادية',
  'ابتدائية',
  'يجيد القراءة والكتابة',
  'أمي (بدون مؤهل)',
  'أخرى',
];

const _genders = ['ذكر', 'أنثى'];
const _religions = ['مسلم', 'مسيحي'];
const _workTypes = [
  'عمالة منتظمة',
  'عمالة غير منتظمة',
  'المعاش',
  'غير قادر على العمل',
  'موظف حكومي',
  'موظف خاص',
  'لا يعمل',
];

const _socialInsuranceOptions = [
  'مؤمن عليه',
  'غير مؤمن عليه',
  'صاحب معاش تأميني',
  'معاش تكافل وكرامة',
];

const _headRelations = [
  'الأب',
  'الأم',
  'الأخ',
  'الأخت',
  'الجد',
  'الجدة',
  'الزوج',
  'الزوجة',
  'الابن',
  'الابنة',
  'أخرى',
];

/// بيانات مراكز وقرى محافظة بني سويف — مطابقة لمصدر الويب
/// (web/src/data/beniSuefData.js — BENI_SUEF_DATA).
const _beniSuefDistricts = <String, List<String>>{
  'بني سويف': [
    'إبشنا',
    'الحكامنة',
    'الحلابية',
    'الدوالطة',
    'الدوية',
    'الكوم الأحمر',
    'أهناسيا الخضراء',
    'إهوه',
    'باروط',
    'باها العجوز',
    'بلفيا',
    'بني بخيت',
    'بني حمد',
    'بني رضوان',
    'بني سليمان الشرقية',
    'بني عفان',
    'بني هارون',
    'بياض العرب',
    'تزمنت الشرقية',
    'تزمنت الغربية',
    'حاجر بني سليمان',
    'دموشيا',
    'رياض',
    'سنور',
    'شريف',
    'منشأة حيدر يكن',
    'منشأة عاصم',
    'منقريش',
    'نزلة أبو سليم',
    'نزلة السعادنة',
    'نزلة معارك',
    'نعيم',
    'الزرابي',
    'تل أبو ناروز',
  ],
  'الواسطى': [
    'أبو صير الملق',
    'أبويط',
    'أطواب',
    'أنفسط',
    'إفوة',
    'الحومة',
    'الديابية',
    'المصلوب',
    'الميمون',
    'النواميس',
    'الهرم',
    'بني حدير',
    'بني سليمان',
    'بني غنيم',
    'بني محمد',
    'بني نصير',
    'جزيرة المساعدة',
    'جزيرة النور',
    'زاوية المصلوب',
    'صفط الشرقية',
    'صفط الغربية',
    'عطف إفوة',
    'قمن العروس',
    'كفر أبجيج',
    'كفر بني عثمان',
    'كوم أبو راضي',
    'كوم أدريجة',
    'معصرة أبو صير',
    'منشأة أبو صير',
    'میدوم',
    'نزلة الجنيدي',
    'ونا القس',
  ],
  'ناصر': [
    'أشمنت',
    'البرج',
    'الحرجة',
    'الحمام',
    'الرياض',
    'الزيتون',
    'المنصورة',
    'بني خليفة',
    'بني عدي',
    'بهبشين',
    'جزيرة أبو صالح',
    'دلاص',
    'دنديل',
    'طحا بوش',
    'طنسا الملق',
    'غيط البحري',
    'كفر الجزيرة',
    'كوم أبو خلاد',
    'منشأة الشركة',
    'منشأة هديب',
  ],
  'إهناسيا': [
    'أدراسية',
    'البهسمون',
    'الشوبك',
    'العواونة',
    'المسيد الأبيض',
    'النويرة',
    'براوة الوقف',
    'بني هاني',
    'بهنموه',
    'دير براوة',
    'سدمنت الجبل',
    'شرهي',
    'طما فيوم',
    'قاي',
    'قلة',
    'قلها',
    'كفر أبو شهبة',
    'كوم الرمل البحري',
    'معصرة نعسان',
    'منشأة الأمراء',
    'منشأة البديني',
    'منشأة الحاج',
    'منشأة طاهر',
    'منشأة عبد الصمد',
    'منشأة كساب',
    'منهرة',
    'منهرو',
    'منيل غيضان',
    'منيل هاني',
    'ميانة',
    'نزلة المشارقة',
    'نزلة المماليك',
    'نزلة خلف',
    'نزلة شاويش',
    'ننا',
  ],
  'ببا': [
    'أبو شربان',
    'أم الجنازير',
    'البرانقة',
    'البكرية',
    'الجزيرة الشرقية',
    'السلطاني',
    'الشهيد حسن علام',
    'الضباعنة',
    'الفقاعي',
    'الملاحية',
    'الملاحية البحرية',
    'بني أحمد',
    'بني خليل',
    'بني عقبة',
    'بني عوض',
    'بني قاسم',
    'بني مؤمنة',
    'بني ماضي',
    'بني محمد الشرقية',
    'بني هاشم',
    'جبل النور',
    'جزيرة الفقاعي',
    'جزيرة ببا',
    'رزقة المشارقة',
    'زاوية الناوية',
    'سدس الأمراء',
    'صفط راشين',
    'طحا لبيشة',
    'طرشوب',
    'طنسا بني مالو',
    'طوة',
    'غياضة الشرقية',
    'غياضة الغربية',
    'فزارة',
    'قنبش الحمراء',
    'كفر جمعة',
    'كفر منصور',
    'كفر ناصر',
    'منشأة أبو دخان',
    'منية الجيد',
    'منيل موسى',
    'نزلة الزاوية',
    'نزلة الشريف',
    'نزلة علي كيلاني',
    'هربشنت',
    'هلية',
  ],
  'سمسطا': [
    'الشنطور',
    'العساكرة',
    'القصبة',
    'المحمودية',
    'بدهل',
    'بني حلة',
    'بني محمد راشد',
    'دشاشة',
    'دشطوط',
    'سربو',
    'عزبة الشنطور',
    'عزبة قفطان',
    'كفر الشيخ عابد',
    'كفر بني علي',
    'كوم الرمل القبلي',
    'كوم النور',
    'مزورة',
    'منشأة أبو مليح',
    'منشأة سليمان',
    'نزلة الديب',
    'نزلة سعيد',
  ],
  'الفشن': [
    'أبسوج',
    'أقفهص',
    'البرقي',
    'الجفادون',
    'الجمهود',
    'الحيبة',
    'الزاوية الخضراء',
    'الشقر',
    'الفنت',
    'الفنت الغربية',
    'القضابي',
    'القليعة',
    'الكنيسة',
    'بسفا',
    'بني صالح',
    'بني منين',
    'تلت',
    'جزيرة الوكلية',
    'دلهانس',
    'شنري',
    'صالح',
    'صفط الخرسة',
    'صفط العرفا',
    'صفط النور',
    'طلا',
    'عزبة البنك',
    'عزبة تلت',
    'كفر درويش',
    'كفر منسابة',
    'منشأة السادات',
    'منشأة عمرو',
    'نزلة أقفهص',
    'نزلة البرقي',
    'نزلة حنا حنا',
  ],
};

/// تاب البيانات الأساسية — مطابق لحقول صفحة البيانات الأساسية في الويب
/// (web/index.html SECTION 1+2+3). أفراد الأسرة تاب مستقل (FamilyMembersTab).
class BasicInfoTab extends ConsumerStatefulWidget {
  /// `null` في شاشة إنشاء حالة جديدة (`create_case_screen.dart`) — الحالة
  /// لسه مالهاش `id` على السيرفر، فلا يوجد مركز/قرية/جمعية مرتبطون بعد
  /// (تلك الشاشة تعرض Dropdown مركز/قرية/جمعية منفصلًا لهذا الغرض بالذات).
  final String? caseId;
  final BasicInfoFormData initialData;
  final ValueChanged<BasicInfoFormData> onChanged;

  /// محتوى إضافي يُعرض في آخر نفس القائمة القابلة للتمرير — تستخدمه شاشة
  /// إنشاء حالة جديدة (`caseId == null`) لعرض Dropdown مركز/قرية/جمعية بلا
  /// اسكرول منفصل عن باقي حقول التاب.
  final Widget? trailing;

  const BasicInfoTab({
    super.key,
    this.caseId,
    required this.initialData,
    required this.onChanged,
    this.trailing,
  });

  @override
  ConsumerState<BasicInfoTab> createState() => _BasicInfoTabState();
}

class _BasicInfoTabState extends ConsumerState<BasicInfoTab> {
  late final BasicInfoFormData _data = widget.initialData;

  late final _caseNameCtrl = TextEditingController(text: _data.caseName);
  late final _nationalIdCtrl = TextEditingController(text: _data.nationalId);
  late final _ageCtrl = TextEditingController(
    text: _data.age?.toString() ?? '',
  );
  late final _phone1Ctrl = TextEditingController(text: _data.phone1 ?? '');
  late final _phone2Ctrl = TextEditingController(text: _data.phone2 ?? '');
  late final _jobCtrl = TextEditingController(text: _data.job ?? '');
  late final _incomeCtrl = TextEditingController(
    text: _data.monthlyIncome?.toString() ?? '',
  );
  late final _takafulKaramaAmountCtrl = TextEditingController(
    text: _data.takafulKaramaAmount?.toString() ?? '',
  );
  late final _addressCtrl = TextEditingController(text: _data.address ?? '');

  Timer? _searchDebounce;
  List<CaseSearchResult> _duplicateMatches = [];
  bool _dismissedDuplicate = false;
  String? _nationalIdError;
  EgyptianNationalIdResult? _nationalIdResult;

  /// المركز/القرية قابلان للتعديل فعليًا على حالة موجودة (اتأكد من الباك
  /// إند: `PUT /beneficiary` بيقبل `centerId`/`villageId`) — Dropdown حقيقي
  /// بمعرّفات من `GET /locations`، زي شاشة إنشاء حالة جديدة بالظبط.
  ///
  /// الجمعية (`charityId`) قابلة للتعديل كمان عبر `PUT /cases/{id}/charity`
  /// (endpoint منفصل، رد الباك إند بتاريخ 2026-09-26 — راجع
  /// `CharityMapper`/`case_details_screen.dart._saveTab` case 0).
  late bool _loadingReferral = widget.caseId != null;
  List<LocationCenter> _centers = const [];
  LocationCenter? _selectedCenter;
  LocationVillage? _selectedVillage;
  List<Charity> _charities = const [];
  Charity? _selectedCharity;

  void _notify() => widget.onChanged(_data);

  Future<void> _loadReferralInfo() async {
    final caseId = widget.caseId;
    // شاشة إنشاء حالة جديدة — _loadingReferral تبدأ false هناك.
    if (caseId == null) return;

    final cached = await ref
        .read(casesRepositoryProvider)
        .cachedDetails(caseId);
    if (!mounted || cached == null) return;

    final centerId = _data.centerId ?? cached.beneficiary.centerId;
    final villageId = _data.villageId ?? cached.beneficiary.villageId;
    final charityId = cached.charityId;

    final centers = await ref.read(referenceRepositoryProvider).centers();

    LocationCenter? selectedCenter;
    LocationVillage? selectedVillage;
    if (centerId != null && centerId.isNotEmpty) {
      for (final center in centers) {
        if (center.id == centerId) {
          selectedCenter = center;
          if (villageId != null && villageId.isNotEmpty) {
            for (final village in center.villages) {
              if (village.id == villageId) {
                selectedVillage = village;
                break;
              }
            }
          }
          break;
        }
      }
    }

    final charities = await ref.read(referenceRepositoryProvider).charities();
    Charity? selectedCharity;
    if (charityId != null && charityId.isNotEmpty) {
      for (final charity in charities) {
        if (charity.id == charityId) {
          selectedCharity = charity;
          break;
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _centers = centers;
      _selectedCenter = selectedCenter;
      _selectedVillage = selectedVillage;
      _charities = charities;
      _selectedCharity = selectedCharity;
      // بيتاخد فقط لو الفورم لسه معندوش قيمة — ماينفعش يدهس تعديل المستخدم
      // لو اختار جمعية قبل ما يخلص التحميل غير المتزامن ده.
      _data.charityId ??= selectedCharity?.id;
      _loadingReferral = false;
    });
  }

  /// الجمعيات التابعة للمركز المختار حاليًا — نفس فكرة `center.villages`
  /// بالظبط، لكن الجمعية (على عكس القرية) عنصر مستقل في `_charities` بحقل
  /// `centerId` بدل تعشيش داخل `LocationCenter`، فالفلترة هنا محلية على
  /// القائمة الكاملة المجلوبة أصلًا (بلا طلب شبكة إضافي لكل تغيير مركز).
  List<Charity> get _charitiesForSelectedCenter {
    final centerId = _selectedCenter?.id;
    if (centerId == null) return const [];
    return _charities.where((c) => c.centerId == centerId).toList();
  }

  void _onCenterChanged(LocationCenter? center) {
    setState(() {
      _selectedCenter = center;
      _selectedVillage = null;
      _data.centerId = center?.id;
      _data.villageId = null;
      // الجمعية تابعة للمركز زي القرية بالظبط — لو الجمعية الحالية مش تابعة
      // للمركز الجديد (أو مفيش مركز أصلًا) لازم تتمسح، وإلا تفضل قيمة غير
      // متسقة (جمعية من مركز تاني) محفوظة في الفورم.
      final stillValid =
          center != null &&
          _selectedCharity != null &&
          _selectedCharity!.centerId == center.id;
      if (!stillValid) {
        _selectedCharity = null;
        _data.charityId = null;
      }
    });
    _notify();
  }

  void _onVillageChanged(LocationVillage? village) {
    setState(() {
      _selectedVillage = village;
      _data.villageId = village?.id;
    });
    _notify();
  }

  void _onCharityChanged(Charity? charity) {
    setState(() {
      _selectedCharity = charity;
      _data.charityId = charity?.id;
    });
    _notify();
  }

  @override
  void initState() {
    super.initState();
    _loadReferralInfo();
    if (_data.nationalId.isNotEmpty) {
      final cleanDigits = _data.nationalId.replaceAll(RegExp(r'\s+|-'), '');
      if (cleanDigits.length == 14) {
        final parseResult = parseEgyptianNationalId(_data.nationalId);
        if (parseResult.valid) {
          _nationalIdResult = parseResult;
          _data.age = parseResult.age;
          _data.gender = parseResult.genderAr;
          _data.birthGovernorate = parseResult.governorateAr;
          if (_data.religion == null || _data.religion!.isEmpty) {
            _data.religion = parseResult.religionAr ?? 'مسلم';
          }
          _ageCtrl.text = '${parseResult.age}';
        } else {
          _nationalIdError = parseResult.error ?? 'الرقم القومي غير صحيح';
        }
      }
    }
  }

  void _processNationalId(String rawValue) {
    _data.nationalId = rawValue;
    _notify();
    _checkDuplicates();

    final cleanDigits = rawValue.replaceAll(RegExp(r'\s+|-'), '');
    if (cleanDigits.length < 14) {
      setState(() {
        _nationalIdError = null;
        _nationalIdResult = null;
      });
      return;
    }

    final parseResult = parseEgyptianNationalId(rawValue);
    if (parseResult.valid) {
      setState(() {
        _nationalIdError = null;
        _nationalIdResult = parseResult;
        _data.age = parseResult.age;
        _data.gender = parseResult.genderAr;
        _data.birthGovernorate = parseResult.governorateAr;
        if (_data.religion == null || _data.religion!.isEmpty) {
          _data.religion = parseResult.religionAr ?? 'مسلم';
        }
        _ageCtrl.text = '${parseResult.age}';
      });
      _notify();
    } else {
      setState(() {
        _nationalIdError = parseResult.error ?? 'الرقم القومي غير صحيح';
        _nationalIdResult = null;
      });
    }
  }

  void _checkDuplicates() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () async {
      final nameQuery = _data.caseName.trim();
      final idQuery = _data.nationalId.trim();

      String query = '';
      if (idQuery.length >= 4) {
        query = idQuery;
      } else if (nameQuery.length >= 3) {
        query = nameQuery;
      }

      if (query.isEmpty) {
        if (mounted && _duplicateMatches.isNotEmpty) {
          setState(() {
            _duplicateMatches = [];
            _dismissedDuplicate = false;
          });
        }
        return;
      }

      final repo = ref.read(caseSearchRepositoryProvider);
      List<CaseSearchResult> results;
      try {
        results = await repo.search(query);
      } catch (_) {
        // بحث التكرار مجرد مساعدة استباقية — فشل الشبكة (أوفلاين مثلًا) ما
        // ينفعش يوقف إدخال الحالة أو يطلع خطأ مزعج، فقط يسيب آخر نتيجة معروفة.
        return;
      }

      // استبعاد الحالة الحالية نفسها من نتائج البحث — في وضع التعديل هي
      // ستطابق بياناتها بالضرورة (نفس الاسم/الرقم القومي)، فتظهر كتكرار
      // وهمي لنفسها بدل تكرار فعلي مع حالة أخرى.
      final currentCaseId = widget.caseId;
      if (currentCaseId != null) {
        results = results.where((r) => r.id != currentCaseId).toList();
      }

      if (mounted) {
        setState(() {
          _duplicateMatches = results;
          _dismissedDuplicate = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _caseNameCtrl.dispose();
    _nationalIdCtrl.dispose();
    _ageCtrl.dispose();
    _phone1Ctrl.dispose();
    _phone2Ctrl.dispose();
    _jobCtrl.dispose();
    _incomeCtrl.dispose();
    _takafulKaramaAmountCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Widget _buildExtractedChip(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabProgressBar(progress: _data.progress),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            children: [
              if (_duplicateMatches.isNotEmpty && !_dismissedDuplicate)
                _DuplicateWarningCard(
                  duplicates: _duplicateMatches,
                  onDismiss: () {
                    setState(() => _dismissedDuplicate = true);
                  },
                ),
              SectionCard(
                title: '1. المعلومات الشخصية (رب الأسرة)',
                child: Column(
                  children: [
                    EditableTextField(
                      label: 'اسم الحالة',
                      required: true,
                      controller: _caseNameCtrl,
                      onChanged: (v) {
                        _data.caseName = v;
                        _notify();
                        _checkDuplicates();
                        setState(() {});
                      },
                    ),
                    EditableTextField(
                      label: 'الرقم القومي',
                      required: true,
                      controller: _nationalIdCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 14,
                      errorText: _nationalIdError,
                      onChanged: _processNationalId,
                    ),
                    if (_nationalIdResult != null &&
                        _nationalIdResult!.valid) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(AppRadius.input),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.verified_user_outlined,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'بيانات مستخرجة تلقائياً من الرقم القومي:',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildExtractedChip(
                                  'العمر',
                                  '${_nationalIdResult!.age} سنة',
                                ),
                                _buildExtractedChip(
                                  'محافظة الميلاد',
                                  _nationalIdResult!.governorateAr!,
                                ),
                                _buildExtractedChip(
                                  'النوع',
                                  _nationalIdResult!.genderAr!,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    EditableDropdown(
                      label: 'المرحلة التعليمية',
                      value: _data.educationLevel,
                      options: _educationLevels,
                      onChanged: (v) {
                        setState(() => _data.educationLevel = v);
                        _notify();
                      },
                    ),
                    EditableTextField(
                      label: 'السن الحالي',
                      controller: _ageCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: (v) {
                        _data.age = parseLocalizedInt(v);
                        _notify();
                        setState(() {});
                      },
                    ),
                    EditableDropdown(
                      label: 'النوع',
                      value: _data.gender,
                      options: _genders,
                      onChanged: (v) {
                        setState(() => _data.gender = v);
                        _notify();
                      },
                    ),
                    EditableDropdown(
                      label: 'الديانة',
                      value: _data.religion,
                      options: _religions,
                      onChanged: (v) {
                        setState(() => _data.religion = v);
                        _notify();
                      },
                    ),
                    EditableDropdown(
                      label: 'صلة القرابة',
                      value: _data.headRelation,
                      options: _headRelations,
                      onChanged: (v) {
                        setState(() => _data.headRelation = v);
                        _notify();
                      },
                    ),
                    EditableTextField(
                      label: 'الهاتف 1',
                      controller: _phone1Ctrl,
                      keyboardType: TextInputType.phone,
                      onChanged: (v) {
                        _data.phone1 = v;
                        _notify();
                        setState(() {});
                      },
                    ),
                    EditableTextField(
                      label: 'الهاتف 2',
                      controller: _phone2Ctrl,
                      keyboardType: TextInputType.phone,
                      onChanged: (v) {
                        _data.phone2 = v;
                        _notify();
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),
              // في شاشة إنشاء حالة جديدة (caseId == null) الكارت ده مالوش
              // معنى — تلك الشاشة عندها Dropdown مركز/قرية/جمعية منفصل خصيصًا
              // لهذا الغرض (راجع create_case_screen.dart)، ولسه معندهاش
              // caseId تجيب بيه القيم المحفوظة أصلًا.
              if (widget.caseId != null) ...[
                const SizedBox(height: AppSpacing.lg),
                SectionCard(
                  title: 'الجمعية والنطاق الجغرافي',
                  child: Column(
                    children: [
                      // المركز/القرية قابلان للتعديل فعليًا (اتأكد من الباك
                      // إند)، فبقوا Dropdown حقيقي زي شاشة إنشاء حالة جديدة.
                      if (_loadingReferral)
                        const Padding(
                          padding: EdgeInsets.only(bottom: AppSpacing.md),
                          child: LinearProgressIndicator(minHeight: 2),
                        )
                      else ...[
                        DropdownButtonFormField<LocationCenter>(
                          key: ValueKey(('center', _selectedCenter?.id)),
                          initialValue: _selectedCenter,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'المركز / المدينة',
                          ),
                          items: [
                            for (final center in _centers)
                              DropdownMenuItem(
                                value: center,
                                child: Text(center.name),
                              ),
                          ],
                          onChanged: _onCenterChanged,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        DropdownButtonFormField<LocationVillage>(
                          key: ValueKey(('village', _selectedVillage?.id)),
                          initialValue: _selectedVillage,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'القرية / المنطقة',
                            hintText: _selectedCenter == null
                                ? 'اختر المركز أولًا'
                                : null,
                          ),
                          items: [
                            for (final village
                                in _selectedCenter?.villages ?? const [])
                              DropdownMenuItem(
                                value: village,
                                child: Text(village.name),
                              ),
                          ],
                          onChanged: _selectedCenter == null
                              ? null
                              : _onVillageChanged,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        // الجمعية: PUT /cases/{id}/charity منفصل عن
                        // beneficiary — يُرسَل من case_details_screen.dart
                        // (_saveTab case 0) بـ caseRowVersion، فقط لو
                        // charityId اتغيّر فعليًا (راجع CharityMapper).
                        // معتمدة على المركز زي القرية بالظبط: معطّلة بلا
                        // مركز مختار، والقائمة مفلترة بـ centerId.
                        DropdownButtonFormField<Charity>(
                          key: ValueKey(('charity', _selectedCharity?.id)),
                          initialValue: _selectedCharity,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'الجمعية',
                            hintText: _selectedCenter == null
                                ? 'اختر المركز أولًا'
                                : null,
                          ),
                          items: [
                            for (final charity in _charitiesForSelectedCenter)
                              DropdownMenuItem(
                                value: charity,
                                child: Text(charity.name),
                              ),
                          ],
                          onChanged: _selectedCenter == null
                              ? null
                              : _onCharityChanged,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        EditableTextField(
                          label: 'العنوان بالتفصيل',
                          controller: _addressCtrl,
                          onChanged: (v) {
                            _data.address = v;
                            _notify();
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              SectionCard(
                title: '2. المعلومات الوظيفية والمالية',
                child: Column(
                  children: [
                    EditableTextField(
                      label: 'الوظيفة',
                      controller: _jobCtrl,
                      onChanged: (v) {
                        _data.job = v;
                        _notify();
                        setState(() {});
                      },
                    ),
                    EditableTextField(
                      label: 'الدخل الشهري (جنيه)',
                      controller: _incomeCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: (v) {
                        _data.monthlyIncome = parseLocalizedDouble(v);
                        _notify();
                        setState(() {});
                      },
                    ),
                    EditableDropdown(
                      label: 'طبيعة العمل',
                      value: _data.workType,
                      options: _workTypes,
                      allowOther: false,
                      onChanged: (v) {
                        setState(() => _data.workType = v);
                        _notify();
                      },
                    ),
                    EditableDropdown(
                      label: 'التأمين الاجتماعي',
                      value: _data.socialInsurance,
                      options: _socialInsuranceOptions,
                      allowOther: false,
                      onChanged: (v) {
                        setState(() => _data.socialInsurance = v);
                        _notify();
                      },
                    ),
                    CheckboxListTile(
                      value: _data.takafulKarama,
                      onChanged: (v) {
                        setState(() {
                          _data.takafulKarama = v ?? false;
                          if (!_data.takafulKarama) {
                            _data.takafulKaramaAmount = null;
                            _takafulKaramaAmountCtrl.clear();
                          }
                        });
                        _notify();
                      },
                      title: const Text(
                        'مستفيد من تكافل وكرامة',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppColors.primary,
                    ),
                    if (_data.takafulKarama)
                      EditableTextField(
                        label: 'مبلغ تكافل وكرامة (جنيه)',
                        controller: _takafulKaramaAmountCtrl,
                        keyboardType: TextInputType.number,
                        onChanged: (v) {
                          _data.takafulKaramaAmount = parseLocalizedDouble(v);
                          _notify();
                        },
                      ),
                  ],
                ),
              ),
              if (widget.trailing != null) ...[
                const SizedBox(height: AppSpacing.md),
                widget.trailing!,
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DuplicateWarningCard extends StatelessWidget {
  final List<CaseSearchResult> duplicates;
  final VoidCallback onDismiss;

  const _DuplicateWarningCard({
    required this.duplicates,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final first = duplicates.first;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.warning,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: const Text(
                  'تنبيه: توجد حالة مسجلة مسبقاً تطابق هذه البيانات',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.warning,
                  ),
                ),
              ),
              InkWell(
                onTap: onDismiss,
                child: const Icon(
                  Icons.close,
                  size: 18,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '• ${first.personName} (${first.displayId}) - ${first.village ?? ''} [${first.statusLabel}]',
            style: const TextStyle(fontSize: 12, color: AppColors.warning),
          ),
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CaseDetailsScreen(
                      caseId: first.id,
                      personName: first.personName,
                      displayId: first.displayId,
                      priority: first.priority,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.open_in_new, size: 14),
              label: const Text(
                'عرض الحالة المسجلة',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
