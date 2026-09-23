import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/case_search_filter.dart';
import '../case_search_providers.dart';

class AdvancedSearchFilterSheet extends ConsumerStatefulWidget {
  const AdvancedSearchFilterSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AdvancedSearchFilterSheet(),
    );
  }

  @override
  ConsumerState<AdvancedSearchFilterSheet> createState() =>
      _AdvancedSearchFilterSheetState();
}

class _AdvancedSearchFilterSheetState
    extends ConsumerState<AdvancedSearchFilterSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _nationalIdController;
  late final TextEditingController _charityController;
  late final TextEditingController _regionController;
  late final TextEditingController _phoneController;
  DateTime? _selectedDate;

  final List<String> _quickCharities = [
    'جمعية رسالة للأعمال الخيرية',
    'مؤسسة مصر الخير',
    'جمعية الأورمان',
    'بنك الطعام المصري',
  ];

  final List<String> _quickRegions = [
    'قرية بني عدي',
    'قرية الروضة',
    'قرية الشيخ فضل',
  ];

  @override
  void initState() {
    super.initState();
    final current = ref.read(caseSearchFilterProvider);
    _nameController = TextEditingController(text: current.name);
    _nationalIdController = TextEditingController(text: current.nationalId);
    _charityController = TextEditingController(text: current.charity);
    _regionController = TextEditingController(text: current.region);
    _phoneController = TextEditingController(text: current.phone);
    _selectedDate = current.date;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nationalIdController.dispose();
    _charityController.dispose();
    _regionController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final updated = CaseSearchFilter(
      query: ref.read(caseSearchQueryProvider),
      name: _nameController.text.trim(),
      nationalId: _nationalIdController.text.trim(),
      charity: _charityController.text.trim(),
      region: _regionController.text.trim(),
      phone: _phoneController.text.trim(),
      date: _selectedDate,
    );

    ref.read(caseSearchFilterProvider.notifier).state = updated;
    Navigator.of(context).pop();
  }

  void _resetFilters() {
    _nameController.clear();
    _nationalIdController.clear();
    _charityController.clear();
    _regionController.clear();
    _phoneController.clear();
    setState(() {
      _selectedDate = null;
    });
    ref.read(caseSearchFilterProvider.notifier).state = const CaseSearchFilter();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderStrong,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                const Icon(Icons.tune, color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'التصفية والبحث المتقدم',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _resetFilters,
                  child: const Text('إعادة ضبط'),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                // 1. Name Field
                _buildField(
                  label: 'البحث بالاسم',
                  icon: Icons.person_outline,
                  controller: _nameController,
                  hintText: 'أدخل اسم المستفيد أو الحالة...',
                ),
                const SizedBox(height: AppSpacing.lg),

                // 2. National ID Field
                _buildField(
                  label: 'البحث بالرقم القومي',
                  icon: Icons.badge_outlined,
                  controller: _nationalIdController,
                  hintText: 'الرقم القومي المكون من 14 رقم...',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppSpacing.lg),

                // 3. Charity Field
                _buildField(
                  label: 'البحث بالجمعية',
                  icon: Icons.apartment_outlined,
                  controller: _charityController,
                  hintText: 'اسم الجمعية أو المؤسسة...',
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: _quickCharities.map((charity) {
                    final isSelected = _charityController.text == charity;
                    return ActionChip(
                      label: Text(
                        charity,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      backgroundColor: isSelected ? AppColors.primary : AppColors.surface,
                      onPressed: () {
                        setState(() {
                          _charityController.text = isSelected ? '' : charity;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.lg),

                // 4. Region Field
                _buildField(
                  label: 'البحث بالمنطقة / القرية',
                  icon: Icons.location_on_outlined,
                  controller: _regionController,
                  hintText: 'المحافظة، المركز، أو القرية...',
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: _quickRegions.map((region) {
                    final isSelected = _regionController.text == region;
                    return ActionChip(
                      label: Text(
                        region,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      backgroundColor: isSelected ? AppColors.primary : AppColors.surface,
                      onPressed: () {
                        setState(() {
                          _regionController.text = isSelected ? '' : region;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.lg),

                // 5. Phone Field
                _buildField(
                  label: 'البحث برقم الهاتف',
                  icon: Icons.phone_outlined,
                  controller: _phoneController,
                  hintText: '01xxxxxxxxx',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: AppSpacing.lg),

                // 6. Date Field
                const Text(
                  'البحث بالتاريخ',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Text(
                          _selectedDate != null
                              ? '${_selectedDate!.year}/${_selectedDate!.month}/${_selectedDate!.day}'
                              : 'اختر تاريخ الحالة أو الزيارة...',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _selectedDate != null ? AppColors.textPrimary : AppColors.textMuted,
                          ),
                        ),
                        const Spacer(),
                        if (_selectedDate != null)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () => setState(() => _selectedDate = null),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ElevatedButton(
              onPressed: _applyFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'تطبيق الفلاتر وعرض النتائج',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
            prefixIcon: Icon(icon, size: 18, color: AppColors.primary),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
            ),
          ),
        ),
      ],
    );
  }
}
