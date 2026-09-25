import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_background.dart';
import '../../case_details/presentation/case_details_screen.dart';
import '../../home/domain/case_priority.dart';
import '../domain/case_search_filter.dart';
import 'case_search_providers.dart';
import 'widgets/advanced_search_filter_sheet.dart';
import 'widgets/case_search_result_tile.dart';

enum SearchCategory {
  name,
  nationalId,
  charity,
  region,
  phone,
  date,
}

extension SearchCategoryX on SearchCategory {
  String get label => switch (this) {
    SearchCategory.name => 'بالاسم',
    SearchCategory.nationalId => 'بالرقم القومي',
    SearchCategory.charity => 'بالجمعية',
    SearchCategory.region => 'بالمنطقة',
    SearchCategory.phone => 'برقم الهاتف',
    SearchCategory.date => 'بالتاريخ',
  };

  String get hintText => switch (this) {
    SearchCategory.name => 'أدخل اسم المستفيد أو الحالة...',
    SearchCategory.nationalId => 'أدخل الرقم القومي (14 رقم)...',
    SearchCategory.charity => 'أدخل اسم الجمعية أو المؤسسة...',
    SearchCategory.region => 'أدخل اسم المحافظة أو القرية...',
    SearchCategory.phone => 'أدخل رقم الهاتف...',
    SearchCategory.date => 'أدخل تاريخ الحالة أو الزيارة...',
  };

  IconData get icon => switch (this) {
    SearchCategory.name => Icons.person_outline,
    SearchCategory.nationalId => Icons.badge_outlined,
    SearchCategory.charity => Icons.apartment_outlined,
    SearchCategory.region => Icons.location_on_outlined,
    SearchCategory.phone => Icons.phone_outlined,
    SearchCategory.date => Icons.calendar_today_outlined,
  };
}

class CaseSearchScreen extends ConsumerStatefulWidget {
  final String? initialQuery;

  const CaseSearchScreen({super.key, this.initialQuery});

  static void open(BuildContext context, {String? initialQuery}) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        reverseTransitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, animation, secondaryAnimation) =>
            CaseSearchScreen(initialQuery: initialQuery),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  ConsumerState<CaseSearchScreen> createState() => _CaseSearchScreenState();
}

class _CaseSearchScreenState extends ConsumerState<CaseSearchScreen> {
  late final TextEditingController _controller;
  final _focusNode = FocusNode();
  SearchCategory _selectedCategory = SearchCategory.name;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery ?? '');
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(caseSearchQueryProvider.notifier).state = widget.initialQuery!;
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onCategorySelected(SearchCategory category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  void _addCurrentTextAsFilter() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final currentFilter = ref.read(caseSearchFilterProvider);
    CaseSearchFilter updated;

    switch (_selectedCategory) {
      case SearchCategory.name:
        updated = currentFilter.copyWith(name: text);
        break;
      case SearchCategory.nationalId:
        updated = currentFilter.copyWith(nationalId: text);
        break;
      case SearchCategory.charity:
        updated = currentFilter.copyWith(charity: text);
        break;
      case SearchCategory.region:
        updated = currentFilter.copyWith(region: text);
        break;
      case SearchCategory.phone:
        updated = currentFilter.copyWith(phone: text);
        break;
      case SearchCategory.date:
        updated = currentFilter;
        break;
    }

    ref.read(caseSearchFilterProvider.notifier).state = updated;
    _controller.clear();
    ref.read(caseSearchQueryProvider.notifier).state = '';
    setState(() {});
  }

  void _removeFilterTag(String type) {
    final current = ref.read(caseSearchFilterProvider);
    CaseSearchFilter updated;
    switch (type) {
      case 'name':
        updated = current.copyWith(name: '');
        break;
      case 'nationalId':
        updated = current.copyWith(nationalId: '');
        break;
      case 'charity':
        updated = current.copyWith(charity: '');
        break;
      case 'region':
        updated = current.copyWith(region: '');
        break;
      case 'phone':
        updated = current.copyWith(phone: '');
        break;
      case 'date':
        updated = current.copyWith(clearDate: true);
        break;
      default:
        updated = current;
    }
    ref.read(caseSearchFilterProvider.notifier).state = updated;
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(caseSearchResultsProvider);
    final query = ref.watch(caseSearchQueryProvider);
    final filter = ref.watch(caseSearchFilterProvider);
    final activeCount = filter.activeCriteriaCount;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Top Header with Back button & Filter counter
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Text(
                      'البحث متعدد المعايير',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    if (_controller.text.isNotEmpty || !filter.isEmpty)
                      TextButton(
                        onPressed: () {
                          _controller.clear();
                          ref.read(caseSearchQueryProvider.notifier).state = '';
                          ref.read(caseSearchFilterProvider.notifier).state =
                              const CaseSearchFilter();
                          setState(() {});
                        },
                        child: const Text('مسح الكل'),
                      ),
                  ],
                ),
              ),

              // 2. Filter Category Chips (خانات البحث في الأعلى)
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  itemCount: SearchCategory.values.length,
                  separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final cat = SearchCategory.values[index];
                    final isSelected = cat == _selectedCategory;
                    return FilterChip(
                      selected: isSelected,
                      showCheckmark: false,
                      avatar: Icon(
                        cat.icon,
                        size: 15,
                        color: isSelected ? Colors.white : AppColors.textMuted,
                      ),
                      label: Text(
                        cat.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      backgroundColor: AppColors.surface,
                      selectedColor: AppColors.primary,
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : AppColors.border,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      onSelected: (_) => _onCategorySelected(cat),
                    );
                  },
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              // 3. Search Bar with Advanced Filter Sheet Button (Hero)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Hero(
                  tag: 'search_bar_hero',
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              focusNode: _focusNode,
                              textInputAction: TextInputAction.search,
                              onSubmitted: (_) => _addCurrentTextAsFilter(),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText: _selectedCategory.hintText,
                                hintStyle: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textMuted,
                                ),
                                prefixIcon: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.search,
                                      size: 20,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                suffixIcon: _controller.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.add_circle,
                                            size: 22, color: AppColors.primary),
                                        tooltip: 'إضافة كمعيار بحث',
                                        onPressed: _addCurrentTextAsFilter,
                                      )
                                    : null,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: 16,
                                ),
                              ),
                              onChanged: (value) {
                                ref.read(caseSearchQueryProvider.notifier).state = value;
                                setState(() {});
                              },
                            ),
                          ),

                          // Advanced Filter Button (تصفية متقدمة)
                          Padding(
                            padding: const EdgeInsets.only(left: 8, right: 4),
                            child: InkWell(
                              onTap: () => AdvancedSearchFilterSheet.show(context),
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: activeCount > 0
                                      ? AppColors.primary
                                      : AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.tune,
                                      size: 18,
                                      color: activeCount > 0
                                          ? Colors.white
                                          : AppColors.primary,
                                    ),
                                    if (activeCount > 0) ...[
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          '$activeCount',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 4. Active Criteria Tags / Pills (Idea 1: كبسولات المعايير النشطة)
              if (!filter.isEmpty) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    children: [
                      if (filter.name.isNotEmpty)
                        _buildActivePill('الاسم: ${filter.name}', () => _removeFilterTag('name')),
                      if (filter.nationalId.isNotEmpty)
                        _buildActivePill('الرقم القومي: ${filter.nationalId}', () => _removeFilterTag('nationalId')),
                      if (filter.charity.isNotEmpty)
                        _buildActivePill('الجمعية: ${filter.charity}', () => _removeFilterTag('charity')),
                      if (filter.region.isNotEmpty)
                        _buildActivePill('المنطقة: ${filter.region}', () => _removeFilterTag('region')),
                      if (filter.phone.isNotEmpty)
                        _buildActivePill('الهاتف: ${filter.phone}', () => _removeFilterTag('phone')),
                      if (filter.date != null)
                        _buildActivePill('التاريخ: ${filter.date!.year}/${filter.date!.month}/${filter.date!.day}', () => _removeFilterTag('date')),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.sm),

              // 5. Search Results Body
              Expanded(child: _buildBody(query, filter, resultsAsync)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivePill(String text, VoidCallback onRemove) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Chip(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        labelPadding: const EdgeInsets.only(right: 4),
        label: Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
        deleteIcon: const Icon(Icons.close, size: 14, color: AppColors.primary),
        onDeleted: onRemove,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
      ),
    );
  }

  Widget _buildBody(String query, CaseSearchFilter filter, AsyncValue resultsAsync) {
    if (query.trim().isEmpty && filter.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_selectedCategory.icon, size: 42, color: AppColors.primary.withValues(alpha: 0.4)),
              const SizedBox(height: AppSpacing.md),
              Text(
                'البحث متعدد المعايير: ${_selectedCategory.label}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'يمكنك دمج البحث بالاسم، الرقم القومي، الجمعية، المنطقة، الهاتف والتاريخ في نفس الوقت',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return resultsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const _SearchError(),
      data: (results) {
        if (results.isEmpty) {
          return _NoResults(onCreateNew: () => _openNewCase(context));
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          itemCount: results.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            final result = results[index];
            return CaseSearchResultTile(
              result: result,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CaseDetailsScreen(
                      caseId: result.id,
                      personName: result.personName,
                      displayId: result.displayId,
                      priority: result.priority,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _openNewCase(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CaseDetailsScreen(
          caseId: 'new_${DateTime.now().millisecondsSinceEpoch}',
          personName: 'حالة جديدة',
          displayId: 'مسودة',
          priority: CasePriority.medium,
        ),
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  final VoidCallback onCreateNew;

  const _NoResults({required this.onCreateNew});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'لم يتم العثور على حالة مطابقة',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: onCreateNew,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('تسجيل حالة جديدة'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchError extends StatelessWidget {
  const _SearchError();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xxl),
        child: Text(
          'تعذر إتمام البحث، تحقق من الاتصال بالإنترنت',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.danger,
          ),
        ),
      ),
    );
  }
}
