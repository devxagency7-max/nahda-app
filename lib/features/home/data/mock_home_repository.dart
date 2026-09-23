import '../domain/case_priority.dart';
import '../domain/home_repository.dart';
import '../domain/home_summary.dart';
import '../domain/social_worker_case.dart';

/// Mock Data Source — يحاكي زمن استجابة شبكة حقيقي.
/// عند توفر الـ Backend، يُستبدل بـ ApiHomeRepository فقط دون تغيير أي استهلاك.
class MockHomeRepository implements HomeRepository {
  @override
  Future<HomeData> getHomeData() async {
    await Future.delayed(const Duration(milliseconds: 600));

    final now = DateTime.now();

    return HomeData(
      socialWorkerName: 'محمد أحمد',
      unreadNotifications: 3,
      counters: const HomeCounters(
        allCases: 5,
        savedCases: 2,
        returnedCases: 2,
      ),
      priorityTasks: [
        SocialWorkerCase(
          id: 'case_1024',
          displayId: '#1024',
          personName: 'أحمد محمد السيد',
          village: 'قرية بني عدي',
          priority: CasePriority.urgent,
          priorityReason: 'حالة مرضية + دخل منخفض',
          status: CaseWorkStatus.visitScheduled,
          origin: CaseOrigin.dataEntry,
          scheduledVisitAt: DateTime(now.year, now.month, now.day, 10, 0),
          progress: 0.2,
          lastUpdatedAt: now.subtract(const Duration(hours: 2)),
        ),
        SocialWorkerCase(
          id: 'case_1031',
          displayId: '#1031',
          personName: 'سارة حسن علي',
          village: 'قرية الروضة',
          priority: CasePriority.high,
          status: CaseWorkStatus.returnedFromReview,
          origin: CaseOrigin.dataEntry,
          progress: 0.85,
          lastUpdatedAt: now.subtract(const Duration(hours: 5)),
          hasUnsyncedChanges: true,
          returnNotes: 'يرجى استيفاء شهادة الدخل وبيان الحالة الصحية لأفراد الأسرة وإعادة الإرسال.',
          returnAuthor: 'أ. حسام الدين (مراجع الجودة)',
        ),
        SocialWorkerCase(
          id: 'case_1048',
          displayId: '#1048',
          personName: 'محمود عبدالجواد خالد',
          village: 'قرية بني عدي',
          priority: CasePriority.urgent,
          status: CaseWorkStatus.returnedFromManager,
          origin: CaseOrigin.dataEntry,
          progress: 0.9,
          lastUpdatedAt: now.subtract(const Duration(hours: 3)),
          hasUnsyncedChanges: true,
          returnNotes: 'مطلوب مراجعة قيمة المساعدة الشهرية المقترحة مع رئيس الوحدة قبل الاعتماد النهائي.',
          returnAuthor: 'د. عادل النجار (مدير الفرع)',
        ),
        SocialWorkerCase(
          id: 'case_1040',
          displayId: '#1040',
          personName: 'محمود علي',
          village: 'قرية بني عدي',
          priority: CasePriority.medium,
          status: CaseWorkStatus.visitScheduled,
          origin: CaseOrigin.dataEntry,
          scheduledVisitAt: DateTime(now.year, now.month, now.day, 13, 30),
          progress: 0.1,
          lastUpdatedAt: now.subtract(const Duration(days: 1)),
        ),
      ],
      submittedCases: [
        SocialWorkerCase(
          id: 'case_1018',
          displayId: '#1018',
          personName: 'فاطمة السيد',
          village: 'قرية الشيخ فضل',
          priority: CasePriority.low,
          status: CaseWorkStatus.submittedForReview,
          origin: CaseOrigin.socialWorker,
          progress: 1.0,
          lastUpdatedAt: now.subtract(const Duration(days: 2)),
        ),
        SocialWorkerCase(
          id: 'case_1005',
          displayId: '#1005',
          personName: 'عبدالله محمد',
          village: 'قرية بني عدي',
          priority: CasePriority.medium,
          status: CaseWorkStatus.submittedForReview,
          origin: CaseOrigin.dataEntry,
          progress: 1.0,
          lastUpdatedAt: now.subtract(const Duration(days: 3)),
        ),
      ],
    );
  }
}
