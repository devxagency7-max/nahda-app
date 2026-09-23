import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/providers/data_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/egyptian_national_id_parser.dart';
import '../../../core/widgets/app_background.dart';
import '../../case_details/presentation/widgets/section_card.dart';
import '../../home/domain/case_priority.dart';
import '../../reference/domain/reference_models.dart';

/// شاشة إنشاء حالة جديدة — `POST /cases` (§20).
///
/// **قيد حالي مهم:** الحالة الناتجة تُنشأ `unassigned` — صلاحية `create_case`
/// أُضيفت لـ`social_worker` (`BACKEND_CHANGE_RESPONSE_3.md`)، لكن الإسناد
/// التلقائي للمُنشئ لم يُنفَّذ بعد من الباك إند (`BACKEND_CHANGE_REQUEST_4.md`).
/// يعني الحالة **لن تظهر فورًا** في قائمة حالات الأخصائي في الـhome حتى يتم
/// إسنادها من طرف تالت (`data_entry`/`manager`/`reviewer`) أو يُنفَّذ الطلب
/// المعلّق. الشاشة تعرض تنبيهًا صريحًا بهذا القيد بعد نجاح الإنشاء.
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

class _CreateCaseScreenState extends ConsumerState<CreateCaseScreen> {
  final _fullNameController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  List<LocationCenter> _centers = const [];
  LocationCenter? _selectedCenter;
  LocationVillage? _selectedVillage;
  List<Charity> _charities = const [];
  Charity? _selectedCharity;
  CasePriority _priority = CasePriority.medium;

  EgyptianNationalIdResult? _idPreview;
  bool _loadingReference = true;
  bool _submitting = false;
  Map<String, List<String>>? _fieldErrors;

  @override
  void initState() {
    super.initState();
    _nationalIdController.addListener(_onNationalIdChanged);
    _loadReferenceData();
  }

  @override
  void dispose() {
    _nationalIdController.removeListener(_onNationalIdChanged);
    _fullNameController.dispose();
    _nationalIdController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
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

  void _onNationalIdChanged() {
    final result = parseEgyptianNationalId(_nationalIdController.text);
    setState(() => _idPreview = result.valid ? result : null);
  }

  void _onCenterChanged(LocationCenter? center) {
    setState(() {
      _selectedCenter = center;
      _selectedVillage = null; // القرية تابعة للمركز — لا تبقى من مركز سابق
    });
  }

  List<String>? _errorsFor(String field) => _fieldErrors?[field];

  bool get _isValid {
    if (_fullNameController.text.trim().isEmpty) return false;
    final idResult = parseEgyptianNationalId(_nationalIdController.text);
    if (!idResult.valid) return false;
    if (_selectedCenter == null || _selectedVillage == null) return false;
    return true;
  }

  Future<void> _submit() async {
    if (!_isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('أكمل الحقول الإلزامية: الاسم، الرقم القومي، المركز، القرية.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() {
      _submitting = true;
      _fieldErrors = null;
    });

    try {
      final payload = {
        'beneficiary': {
          'fullName': _fullNameController.text.trim(),
          'nationalId': _nationalIdController.text.trim(),
          if (_phoneController.text.trim().isNotEmpty)
            'phonePrimary': _phoneController.text.trim(),
          'centerId': _selectedCenter!.id,
          'villageId': _selectedVillage!.id,
          if (_addressController.text.trim().isNotEmpty)
            'address': _addressController.text.trim(),
        },
        'charityId': _selectedCharity?.id,
        'priority': _priority.name,
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
          'تم إنشاء الحالة',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'رقم الحالة: $caseNumber',
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'الحالة أُنشئت لكنها لم تُسنَد إليك بعد — لن تظهر في قائمة حالاتك حتى '
              'يتم إسنادها من الجهة المختصة. سنبلّغك فور توفر الإسناد التلقائي.',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('حسنًا'),
          ),
        ],
      ),
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
        ),
        body: _loadingReference
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  120,
                ),
                children: [
                  SectionCard(
                    title: 'اسم المستفيد *',
                    child: TextField(
                      controller: _fullNameController,
                      maxLength: 255,
                      decoration: InputDecoration(
                        hintText: 'الاسم الكامل',
                        border: InputBorder.none,
                        errorText: _errorsFor('fullName')?.join('، '),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SectionCard(
                    title: 'الرقم القومي *',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _nationalIdController,
                          keyboardType: TextInputType.number,
                          maxLength: 14,
                          decoration: InputDecoration(
                            hintText: '14 رقمًا',
                            border: InputBorder.none,
                            errorText: _errorsFor('nationalId')?.join('، '),
                          ),
                        ),
                        if (_idPreview != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${_idPreview!.genderAr} · العمر ${_idPreview!.age} · '
                            '${_idPreview!.governorateAr}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SectionCard(
                    title: 'رقم الهاتف',
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      maxLength: 20,
                      decoration: InputDecoration(
                        hintText: 'اختياري',
                        border: InputBorder.none,
                        errorText: _errorsFor('phonePrimary')?.join('، '),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
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
                    title: 'العنوان',
                    child: TextField(
                      controller: _addressController,
                      maxLines: 2,
                      maxLength: 1000,
                      decoration: const InputDecoration(
                        hintText: 'اختياري',
                        border: InputBorder.none,
                      ),
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
                              color: _priority == p ? p.color : AppColors.textMuted,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ElevatedButton(
              onPressed: _submitting || _loadingReference ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'إنشاء الحالة',
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
