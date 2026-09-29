import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_background.dart';
import '../../case_details/presentation/open_case_details.dart';
import '../../home/domain/home_summary.dart';
import '../../home/domain/social_worker_case.dart';
import '../../home/presentation/widgets/case_card.dart';
import 'case_list_filter.dart';

/// صفحة الحالات المفلترة — تُفتح من كروت الأرقام السريعة في الـ Home،
/// كل كارت (زيارات اليوم / متأخرة / مرتجعة) يفتحها على التاب المطابق.
class CaseListScreen extends ConsumerStatefulWidget {
  final HomeData data;
  final CaseListFilter initialFilter;

  const CaseListScreen({
    super.key,
    required this.data,
    required this.initialFilter,
  });

  @override
  ConsumerState<CaseListScreen> createState() => _CaseListScreenState();
}

class _CaseListScreenState extends ConsumerState<CaseListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  late final List<SocialWorkerCase> _allCases = [
    ...widget.data.priorityTasks,
    ...widget.data.submittedCases,
  ];

  static const _submittedStatuses = {
    CaseWorkStatus.submittedForReview,
    CaseWorkStatus.pendingApproval,
    CaseWorkStatus.approved,
    CaseWorkStatus.rejected,
  };

  static const _savedStatuses = {
    CaseWorkStatus.assigned,
    CaseWorkStatus.inProgress,
    CaseWorkStatus.visitScheduled,
    CaseWorkStatus.readyForReview,
  };

  List<SocialWorkerCase> _casesFor(CaseListFilter filter) {
    switch (filter) {
      case CaseListFilter.allCases:
        // "كل حالاتي" = كل حالة اتبعتت فعليًا: عند المراجع، عند المدير،
        // اتقبلت، أو اترفضت.
        return _allCases
            .where((c) => _submittedStatuses.contains(c.status))
            .toList();
      case CaseListFilter.saved:
        // "الحالات المحفوظة" = الحالات المُسنَدة لهذا الأخصائي، تظهر هنا
        // فور الإرسال إليه من الـ Data Entry (status == assigned)، بلا
        // حاجة لأي فعل قبول من جانبه — بالإضافة إلى الحالات التي كلّف
        // الأخصائي نفسه بها عبر زر "تكليف" (تتحول إلى in_research)، بنفس
        // تعريف `CasesRepository.watchAssigned`.
        return _allCases.where((c) => _savedStatuses.contains(c.status)).toList();
      case CaseListFilter.returned:
        return _allCases
            .where((c) => c.status == CaseWorkStatus.returnedFromReview)
            .toList();
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: CaseListFilter.values.length,
      vsync: this,
      initialIndex: widget.initialFilter.index,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('الحالات'),
          bottom: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.primary,
            labelStyle: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
            ),
            tabs: [
              for (final filter in CaseListFilter.values)
                Tab(text: filter.label),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            for (final filter in CaseListFilter.values)
              _CaseListTab(cases: _casesFor(filter)),
          ],
        ),
      ),
    );
  }
}

class _CaseListTab extends StatelessWidget {
  final List<SocialWorkerCase> cases;

  const _CaseListTab({required this.cases});

  @override
  Widget build(BuildContext context) {
    if (cases.isEmpty) {
      return const Center(
        child: Text(
          'لا توجد حالات في هذا القسم حاليًا',
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
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
        return CaseCard(
          caseItem: item,
          onTap: () => item.openDetails(context),
        );
      },
    );
  }
}
