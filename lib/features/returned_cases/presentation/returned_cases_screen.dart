import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/priority_badge.dart';
import '../../case_details/presentation/case_details_screen.dart';
import '../../home/domain/home_summary.dart';
import '../../home/domain/social_worker_case.dart';

class ReturnedCasesScreen extends StatefulWidget {
  final HomeData data;

  const ReturnedCasesScreen({super.key, required this.data});

  static void open(BuildContext context, HomeData data) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReturnedCasesScreen(data: data),
      ),
    );
  }

  @override
  State<ReturnedCasesScreen> createState() => _ReturnedCasesScreenState();
}

class _ReturnedCasesScreenState extends State<ReturnedCasesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  late final List<SocialWorkerCase> _allCases = [
    ...widget.data.priorityTasks,
    ...widget.data.submittedCases,
  ];

  List<SocialWorkerCase> get _reviewerReturnedCases => _allCases
      .where((c) => c.status == CaseWorkStatus.returnedFromReview)
      .toList();

  List<SocialWorkerCase> get _managerReturnedCases => _allCases
      .where((c) => c.status == CaseWorkStatus.returnedFromManager)
      .toList();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reviewerCount = _reviewerReturnedCases.length;
    final managerCount = _managerReturnedCases.length;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('الحالات المرتجعة'),
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('مرتجعة من المراجع'),
                    if (reviewerCount > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$reviewerCount',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('مرتجعة من المدير'),
                    if (managerCount > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$managerCount',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.danger,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _ReturnedCasesList(
              cases: _reviewerReturnedCases,
              emptyMessage: 'لا توجد حالات مرتجعة من المراجع حالياً',
              defaultAuthor: 'مراجع الجودة',
            ),
            _ReturnedCasesList(
              cases: _managerReturnedCases,
              emptyMessage: 'لا توجد حالات مرتجعة من المدير حالياً',
              defaultAuthor: 'مدير الفرع',
            ),
          ],
        ),
      ),
    );
  }
}

class _ReturnedCasesList extends StatelessWidget {
  final List<SocialWorkerCase> cases;
  final String emptyMessage;
  final String defaultAuthor;

  const _ReturnedCasesList({
    required this.cases,
    required this.emptyMessage,
    required this.defaultAuthor,
  });

  @override
  Widget build(BuildContext context) {
    if (cases.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  size: 40,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: cases.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final item = cases[index];
        return _ReturnedCaseCard(caseItem: item, defaultAuthor: defaultAuthor);
      },
    );
  }
}

class _ReturnedCaseCard extends StatelessWidget {
  final SocialWorkerCase caseItem;
  final String defaultAuthor;

  const _ReturnedCaseCard({
    required this.caseItem,
    required this.defaultAuthor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            caseItem.personName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            caseItem.displayId,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      if (caseItem.village != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          caseItem.village!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Icon(
                          caseItem.hasUnsyncedChanges ? Icons.access_time_rounded : Icons.done_all,
                          size: 16,
                          color: caseItem.hasUnsyncedChanges ? AppColors.warning : Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                PriorityBadge(priority: caseItem.priority),
              ],
            ),
          ),

          // Return Reason Notes Box
          if (caseItem.returnNotes != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.warningBg.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.feedback_outlined, size: 16, color: AppColors.warning),
                      const SizedBox(width: 6),
                      Text(
                        'ملاحظات الإرجاع (${caseItem.returnAuthor ?? defaultAuthor})',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    caseItem.returnNotes!,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1, color: AppColors.border),

          // Action Button
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CaseDetailsScreen(
                      caseId: caseItem.id,
                      personName: caseItem.personName,
                      displayId: caseItem.displayId,
                      priority: caseItem.priority,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.edit_note, size: 20),
              label: const Text(
                'تعديل واستكمال الحالة',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
