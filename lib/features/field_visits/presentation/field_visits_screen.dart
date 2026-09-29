import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/data_providers.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_background.dart';
import '../../case_details/presentation/widgets/section_card.dart';
import 'field_visit_form_screen.dart';

/// قائمة الزيارات الميدانية المسجَّلة محليًا لحالة معيّنة.
///
/// **قيد العقد:** `PUT /field-visits/{id}` يقبل التعديل فقط من الأخصائي الذي
/// أنشأ الزيارة (`SocialWorkerId` ثابت عند الإنشاء، `404` لأي أخصائي آخر حتى
/// لو الحالة انتقلت إليه لاحقًا — راجع الملاحظة في `BACKEND_CHANGE_REQUEST_COMBINED.md`،
/// طلب جديد). بما أن كل صفوف [LocalFieldVisits] هنا زيارات هذا الجهاز فقط،
/// كلها قابلة للتعديل دومًا؛ القيد يظهر فعليًا فقط حين تُعرض لاحقًا زيارات
/// قادمة من زملاء سابقين عبر `GET /cases/{id}/field-visits` (طلب معلّق).
class FieldVisitsScreen extends ConsumerWidget {
  final String caseId;
  final String personName;

  const FieldVisitsScreen({
    super.key,
    required this.caseId,
    required this.personName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visitsAsync = ref.watch(fieldVisitsForCaseProvider(caseId));

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'الزيارات الميدانية',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              Text(
                personName,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => FieldVisitFormScreen(caseId: caseId),
            ),
          ),
          icon: const Icon(Icons.add_location_alt_outlined),
          label: const Text('زيارة جديدة'),
        ),
        body: visitsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) =>
              const Center(child: Text('تعذّر تحميل الزيارات')),
          data: (visits) {
            if (visits.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xxl),
                  child: Text(
                    'لا توجد زيارات مسجَّلة بعد.\nاضغط "زيارة جديدة" لتسجيل أول زيارة ميدانية.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                100,
              ),
              itemCount: visits.length,
              itemBuilder: (context, index) =>
                  _VisitTile(visit: visits[index], caseId: caseId),
            );
          },
        ),
      ),
    );
  }
}

class _VisitTile extends StatelessWidget {
  final FieldVisitRow visit;
  final String caseId;

  const _VisitTile({required this.visit, required this.caseId});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('d/M/yyyy', 'ar');
    final date = DateTime.tryParse(visit.visitDate);
    final status = _statusInfo(visit.syncState);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: SectionCard(
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => FieldVisitFormScreen(
                caseId: caseId,
                existingVisit: visit,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(AppRadius.input),
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      date != null ? df.format(date) : visit.visitDate,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      visit.outcome,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(status.icon, size: 13, color: status.color),
                        const SizedBox(width: 4),
                        Text(
                          status.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: status.color,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_left,
                color: AppColors.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  _StatusInfo _statusInfo(String syncState) => switch (syncState) {
    'synced' => const _StatusInfo(
      Icons.cloud_done_outlined,
      'تم الرفع للخادم',
      AppColors.success,
    ),
    'syncing' => const _StatusInfo(
      Icons.sync,
      'جارٍ الإرسال',
      AppColors.warning,
    ),
    'conflict' => const _StatusInfo(
      Icons.error_outline,
      'يحتاج مراجعة (تعارض)',
      AppColors.danger,
    ),
    'failed' => const _StatusInfo(
      Icons.error_outline,
      'فشل الإرسال',
      AppColors.danger,
    ),
    _ => const _StatusInfo(
      Icons.cloud_off_outlined,
      'بانتظار الاتصال',
      AppColors.warning,
    ),
  };
}

class _StatusInfo {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusInfo(this.icon, this.label, this.color);
}
