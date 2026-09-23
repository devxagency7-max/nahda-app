import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../case_search/domain/case_search_result.dart';
import '../../../case_search/presentation/case_search_providers.dart';
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

const _governorates = [
  'بني سويف',
  'القاهرة',
  'الإسكندرية',
  'بورسعيد',
  'السويس',
  'دمياط',
  'الدقهلية',
  'الشرقية',
  'القليوبية',
  'كفر الشيخ',
  'الغربية',
  'المنوفية',
  'البحيرة',
  'الإسماعيلية',
  'الجيزة',
  'الفيوم',
  'المنيا',
  'أسيوط',
  'سوهاج',
  'قنا',
  'أسوان',
  'الأقصر',
  'البحر الأحمر',
  'الوادي الجديد',
  'مطروح',
  'شمال سيناء',
  'جنوب سيناء',
  'خارج الجمهورية',
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
    'إبشنا', 'الحكامنة', 'الحلابية', 'الدوالطة', 'الدوية', 'الكوم الأحمر',
    'أهناسيا الخضراء', 'إهوه', 'باروط', 'باها العجوز', 'بلفيا', 'بني بخيت',
    'بني حمد', 'بني رضوان', 'بني سليمان الشرقية', 'بني عفان', 'بني هارون',
    'بياض العرب', 'تزمنت الشرقية', 'تزمنت الغربية', 'حاجر بني سليمان', 'دموشيا',
    'رياض', 'سنور', 'شريف', 'منشأة حيدر يكن', 'منشأة عاصم', 'منقريش',
    'نزلة أبو سليم', 'نزلة السعادنة', 'نزلة معارك', 'نعيم', 'الزرابي', 'تل أبو ناروز',
  ],
  'الواسطى': [
    'أبو صير الملق', 'أبويط', 'أطواب', 'أنفسط', 'إفوة', 'الحومة', 'الديابية',
    'المصلوب', 'الميمون', 'النواميس', 'الهرم', 'بني حدير', 'بني سليمان',
    'بني غنيم', 'بني محمد', 'بني نصير', 'جزيرة المساعدة', 'جزيرة النور',
    'زاوية المصلوب', 'صفط الشرقية', 'صفط الغربية', 'عطف إفوة', 'قمن العروس',
    'كفر أبجيج', 'كفر بني عثمان', 'كوم أبو راضي', 'كوم أدريجة', 'معصرة أبو صير',
    'منشأة أبو صير', 'میدوم', 'نزلة الجنيدي', 'ونا القس',
  ],
  'ناصر': [
    'أشمنت', 'البرج', 'الحرجة', 'الحمام', 'الرياض', 'الزيتون', 'المنصورة',
    'بني خليفة', 'بني عدي', 'بهبشين', 'جزيرة أبو صالح', 'دلاص', 'دنديل',
    'طحا بوش', 'طنسا الملق', 'غيط البحري', 'كفر الجزيرة', 'كوم أبو خلاد',
    'منشأة الشركة', 'منشأة هديب',
  ],
  'إهناسيا': [
    'أدراسية', 'البهسمون', 'الشوبك', 'العواونة', 'المسيد الأبيض', 'النويرة',
    'براوة الوقف', 'بني هاني', 'بهنموه', 'دير براوة', 'سدمنت الجبل', 'شرهي',
    'طما فيوم', 'قاي', 'قلة', 'قلها', 'كفر أبو شهبة', 'كوم الرمل البحري',
    'معصرة نعسان', 'منشأة الأمراء', 'منشأة البديني', 'منشأة الحاج', 'منشأة طاهر',
    'منشأة عبد الصمد', 'منشأة كساب', 'منهرة', 'منهرو', 'منيل غيضان', 'منيل هاني',
    'ميانة', 'نزلة المشارقة', 'نزلة المماليك', 'نزلة خلف', 'نزلة شاويش', 'ننا',
  ],
  'ببا': [
    'أبو شربان', 'أم الجنازير', 'البرانقة', 'البكرية', 'الجزيرة الشرقية',
    'السلطاني', 'الشهيد حسن علام', 'الضباعنة', 'الفقاعي', 'الملاحية',
    'الملاحية البحرية', 'بني أحمد', 'بني خليل', 'بني عقبة', 'بني عوض',
    'بني قاسم', 'بني مؤمنة', 'بني ماضي', 'بني محمد الشرقية', 'بني هاشم',
    'جبل النور', 'جزيرة الفقاعي', 'جزيرة ببا', 'رزقة المشارقة', 'زاوية الناوية',
    'سدس الأمراء', 'صفط راشين', 'طحا لبيشة', 'طرشوب', 'طنسا بني مالو', 'طوة',
    'غياضة الشرقية', 'غياضة الغربية', 'فزارة', 'قنبش الحمراء', 'كفر جمعة',
    'كفر منصور', 'كفر ناصر', 'منشأة أبو دخان', 'منية الجيد', 'منيل موسى',
    'نزلة الزاوية', 'نزلة الشريف', 'نزلة علي كيلاني', 'هربشنت', 'هلية',
  ],
  'سمسطا': [
    'الشنطور', 'العساكرة', 'القصبة', 'المحمودية', 'بدهل', 'بني حلة',
    'بني محمد راشد', 'دشاشة', 'دشطوط', 'سربو', 'عزبة الشنطور', 'عزبة قفطان',
    'كفر الشيخ عابد', 'كفر بني علي', 'كوم الرمل القبلي', 'كوم النور', 'مزورة',
    'منشأة أبو مليح', 'منشأة سليمان', 'نزلة الديب', 'نزلة سعيد',
  ],
  'الفشن': [
    'أبسوج', 'أقفهص', 'البرقي', 'الجفادون', 'الجمهود', 'الحيبة',
    'الزاوية الخضراء', 'الشقر', 'الفنت', 'الفنت الغربية', 'القضابي',
    'القليعة', 'الكنيسة', 'بسفا', 'بني صالح', 'بني منين', 'تلت',
    'جزيرة الوكلية', 'دلهانس', 'شنري', 'صالح', 'صفط الخرسة', 'صفط العرفا',
    'صفط النور', 'طلا', 'عزبة البنك', 'عزبة تلت', 'كفر درويش', 'كفر منسابة',
    'منشأة السادات', 'منشأة عمرو', 'نزلة أقفهص', 'نزلة البرقي', 'نزلة حنا حنا',
  ],
};

const _charities = [
  'جمعية رسالة للأعمال الخيرية',
  'مؤسسة مصر الخير',
  'جمعية الأورمان',
  'بنك الطعام المصري',
];

/// تاب البيانات الأساسية — مطابق لحقول صفحة البيانات الأساسية في الويب
/// (web/index.html SECTION 1+2+3). أفراد الأسرة تاب مستقل (FamilyMembersTab).
class BasicInfoTab extends ConsumerStatefulWidget {
  final BasicInfoFormData initialData;
  final ValueChanged<BasicInfoFormData> onChanged;

  const BasicInfoTab({
    super.key,
    required this.initialData,
    required this.onChanged,
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
  late final _villageCtrl = TextEditingController(text: _data.village ?? '');
  late final _addressCtrl = TextEditingController(text: _data.address ?? '');

  Timer? _searchDebounce;
  List<CaseSearchResult> _duplicateMatches = [];
  bool _dismissedDuplicate = false;
  String? _nationalIdError;
  EgyptianNationalIdResult? _nationalIdResult;

  List<String> get _referralVillageOptions =>
      _beniSuefDistricts[_data.referralDistrict] ?? const [];

  void _notify() => widget.onChanged(_data);

  @override
  void initState() {
    super.initState();
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
    _villageCtrl.dispose();
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
                    if (_nationalIdResult != null && _nationalIdResult!.valid) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(AppRadius.input),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.verified_user_outlined, size: 18, color: AppColors.primary),
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
                                _buildExtractedChip('العمر', '${_nationalIdResult!.age} سنة'),
                                _buildExtractedChip('محافظة الميلاد', _nationalIdResult!.governorateAr!),
                                _buildExtractedChip('النوع', _nationalIdResult!.genderAr!),
                                _buildExtractedChip('الديانة', _data.religion ?? _nationalIdResult!.religionAr ?? 'مسلم'),
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
              const SizedBox(height: AppSpacing.lg),
              SectionCard(
                title: 'الجمعية والنطاق الجغرافي',
                child: Column(
                  children: [
                    EditableDropdown(
                      label: 'المركز / المدينة',
                      value: _data.referralDistrict,
                      options: _beniSuefDistricts.keys.toList(),
                      allowOther: false,
                      onChanged: (v) {
                        setState(() {
                          _data.referralDistrict = v;
                          _data.referralVillage = null;
                        });
                        _notify();
                      },
                    ),
                    EditableDropdown(
                      label: 'القرية / المنطقة',
                      value: _data.referralVillage,
                      options: _referralVillageOptions,
                      allowOther: false,
                      hintText: _data.referralDistrict == null
                          ? 'اختر المركز أولاً...'
                          : null,
                      onChanged: (v) {
                        setState(() => _data.referralVillage = v);
                        _notify();
                      },
                    ),
                    EditableDropdown(
                      label: 'الجمعية',
                      value: _data.charity,
                      options: _charities,
                      allowOther: true,
                      onChanged: (v) {
                        setState(() => _data.charity = v);
                        _notify();
                      },
                    ),
                  ],
                ),
              ),
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
              const SizedBox(height: AppSpacing.lg),
              SectionCard(
                title: '3. العنوان والموقع',
                child: Column(
                  children: [
                    EditableDropdown(
                      label: 'المحافظة',
                      value: _data.governorate,
                      options: _governorates,
                      allowOther: false,
                      onChanged: (v) {
                        setState(() => _data.governorate = v ?? 'بني سويف');
                        _notify();
                      },
                    ),
                    EditableDropdown(
                      label: 'المركز',
                      value: _data.district,
                      options: _beniSuefDistricts.keys.toList(),
                      allowOther: true,
                      onChanged: (v) {
                        setState(() => _data.district = v);
                        _notify();
                      },
                    ),
                    EditableTextField(
                      label: 'القرية',
                      controller: _villageCtrl,
                      onChanged: (v) {
                        _data.village = v;
                        _notify();
                        setState(() {});
                      },
                    ),
                    EditableTextField(
                      label: 'العنوان بالتفصيل',
                      controller: _addressCtrl,
                      onChanged: (v) {
                        _data.address = v;
                        _notify();
                      },
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

