import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../case_details/presentation/case_details_screen.dart';
import '../../home/domain/case_priority.dart';
import 'case_search_providers.dart';
import 'widgets/case_search_result_tile.dart';

/// شريط البحث في كل حالات النظام — يُفتح من الـ Home كـ Bottom Sheet
/// لتجنب تنقّل كامل الصفحة لمهمة سريعة (Search Cases — Backend Contract §15).
class CaseSearchSheet extends ConsumerStatefulWidget {
  final String? initialQuery;

  const CaseSearchSheet({super.key, this.initialQuery});

  @override
  ConsumerState<CaseSearchSheet> createState() => _CaseSearchSheetState();

  static void show(BuildContext context, {String? initialQuery}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CaseSearchSheet(initialQuery: initialQuery),
    );
  }
}

class _CaseSearchSheetState extends ConsumerState<CaseSearchSheet> {
  late final TextEditingController _controller;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery ?? '');
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(caseSearchQueryProvider.notifier).state = widget.initialQuery!;
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(caseSearchResultsProvider);
    final query = ref.watch(caseSearchQueryProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.card),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.md),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderStrong,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      textInputAction: TextInputAction.search,
                      decoration: const InputDecoration(
                        hintText: 'ابحث بالاسم، رقم الحالة، أو الرقم القومي',
                        prefixIcon: Icon(
                          Icons.search,
                          color: AppColors.textMuted,
                        ),
                      ),
                      onChanged: (value) {
                        ref.read(caseSearchQueryProvider.notifier).state =
                            value;
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('إلغاء'),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildBody(query, resultsAsync)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(String query, AsyncValue resultsAsync) {
    if (query.trim().isEmpty) {
      return const _SearchHint();
    }

    return resultsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const _SearchError(),
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
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            final result = results[index];
            return CaseSearchResultTile(
              result: result,
              onTap: () {
                Navigator.of(context).pop();
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
    Navigator.of(context).pop();
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

class _SearchHint extends StatelessWidget {
  const _SearchHint();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search, size: 36, color: AppColors.textMuted),
            SizedBox(height: AppSpacing.md),
            Text(
              'ابحث في كل حالات النظام قبل تسجيل حالة جديدة',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
              ),
            ),
          ],
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
                fontSize: 13.5,
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
