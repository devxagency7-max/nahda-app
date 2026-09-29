import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/providers/data_providers.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../cases/data/case_status_mapper.dart';
import '../../cases/domain/case_status.dart';
import '../domain/home_summary.dart';
import '../domain/social_worker_case.dart';

/// بيانات الشاشة الرئيسية — Online-First: تُبنى من استجابة الخادم مباشرة
/// عند توفّر الاتصال (عبر [CasesRepository.getWorkQueue])، وتقع على الكاش
/// المحلي فقط عند الأوفلاين أو فشل الشبكة.
final homeDataProvider = FutureProvider<HomeData>((ref) async {
  final repository = ref.watch(casesRepositoryProvider);
  final user = ref.watch(currentUserProvider);

  final rows = await repository.getWorkQueue();

  final cases = rows.map(CaseStatusMapper.toDisplayCase).toList();

  // "مهامي دلوقتي" مقابل "تم إرسالها" — تقسيم عرضي بحت.
  final active = <SocialWorkerCase>[];
  final submitted = <SocialWorkerCase>[];

  const submittedStatuses = {
    CaseWorkStatus.submittedForReview,
    CaseWorkStatus.pendingApproval,
    CaseWorkStatus.approved,
    CaseWorkStatus.rejected,
  };

  for (final item in cases) {
    if (submittedStatuses.contains(item.status)) {
      submitted.add(item);
    } else {
      active.add(item);
    }
  }

  active.sort(_byUrgency);

  return HomeData(
    socialWorkerName: user?.fullName ?? '',
    unreadNotifications: 0,
    counters: HomeCounters(
      // "كل حالاتي" = الحالات اللي اتبعتت فعليًا للمراجع فقط.
      allCases: submitted.length,
      // "الحالات المحفوظة" = الحالات المُسنَدة لهذا الأخصائي من الـ Data
      // Entry (status == assigned) — تظهر هنا فور الإسناد مباشرة، بلا أي
      // فعل قبول من جانبه — بالإضافة إلى الحالات التي كلّف الأخصائي نفسه بها
      // (status == in_research بعد الضغط على "تكليف")، طبقًا لنفس تعريف
      // `CasesRepository.watchAssigned`.
      savedCases: rows
          .where(
            (r) =>
                r.status == CaseStatus.assigned.wireValue ||
                r.status == CaseStatus.inResearch.wireValue,
          )
          .length,
      returnedCases: rows
          .where((r) => r.status == CaseStatus.returnedToWorker.wireValue)
          .length,
    ),
    priorityTasks: active,
    submittedCases: submitted,
  );
});

/// المرتجعة فقط — لشاشة "الحالات المرتجعة".
final returnedCasesListProvider = StreamProvider<List<SocialWorkerCase>>((ref) {
  return ref
      .watch(casesRepositoryProvider)
      .watchReturned()
      .map((rows) => rows.map(CaseStatusMapper.toDisplayCase).toList());
});

/// المحفوظة — الحالات المُسنَدة لهذا الأخصائي (assigned) بانتظار بدء العمل
/// عليها، تظهر تلقائيًا فور إرسالها من الـ Data Entry.
final savedCasesListProvider = StreamProvider<List<SocialWorkerCase>>((ref) {
  return ref
      .watch(casesRepositoryProvider)
      .watchAssigned()
      .map((rows) => rows.map(CaseStatusMapper.toDisplayCase).toList());
});

/// حالة العرض العلوية: متصل / غير متصل / جارٍ المزامنة.
final syncBannerProvider = Provider<SyncBanner>((ref) {
  final statusAsync = ref.watch(networkStatusProvider);
  final pending = ref.watch(pendingSyncCountProvider).valueOrNull ?? 0;
  final photos = ref.watch(pendingAttachmentCountProvider).valueOrNull ?? 0;
  final attention = ref.watch(syncNeedsAttentionCountProvider).valueOrNull ?? 0;

  // أثناء تحميل أول قراءة اتصال (لحظة إقلاع التطبيق، قبل أن ينهي
  // `NetworkStatusService.start()` أول فحص) لا قيمة بعد — `valueOrNull` تكون
  // `null`. الافتراض هنا **متصل** لا أوفلاين: الاتصال هو الوضع الغالب لهذا
  // التطبيق، فمعاملة "لسه بنتأكد" كأوفلاين تعني ومضة بانر "بدون اتصال"
  // مضلِّلة عند كل فتح للتطبيق رغم وجود إنترنت فعلي.
  final status = statusAsync.valueOrNull;
  final isOffline = status != null && !status.isOnline;

  return SyncBanner(
    isOffline: isOffline,
    pendingOperations: pending,
    pendingPhotos: photos,
    needsAttention: attention,
  );
});

/// ما يُعرَض في شريط حالة المزامنة أعلى الشاشة.
class SyncBanner {
  const SyncBanner({
    required this.isOffline,
    required this.pendingOperations,
    required this.pendingPhotos,
    this.needsAttention = 0,
  });

  final bool isOffline;
  final int pendingOperations;
  final int pendingPhotos;

  /// عمليات متوقّفة لن تُرسَل تلقائيًا — لا "جارٍ رفع" لها، بل "راجِعها".
  final int needsAttention;

  bool get hasPendingWork => pendingOperations > 0 || pendingPhotos > 0;

  bool get hasAttention => needsAttention > 0;

  /// يظهر الشريط فقط حين يعني شيئًا للمستخدم.
  bool get isVisible => isOffline || hasPendingWork || hasAttention;

  String get message {
    if (!isOffline && !hasPendingWork && hasAttention) {
      return '$needsAttention عملية لم تُقبَل من الخادم — اضغط للمراجعة';
    }
    if (isOffline && hasPendingWork) {
      return 'بدون اتصال — $_pendingLabel محفوظ على الجهاز';
    }
    if (isOffline) return 'بدون اتصال — يمكنك متابعة العمل';
    return 'جارٍ رفع $_pendingLabel';
  }

  String get _pendingLabel {
    final parts = <String>[];
    if (pendingOperations > 0) parts.add('$pendingOperations تغيير');
    if (pendingPhotos > 0) parts.add('$pendingPhotos مرفق');
    return parts.join(' و');
  }
}

/// ترتيب المهام: الأعجل أولًا، ثم الأقرب زيارة، ثم الأحدث تحديثًا.
int _byUrgency(SocialWorkerCase a, SocialWorkerCase b) {
  final byPriority = b.priority.index.compareTo(a.priority.index);
  if (byPriority != 0) return byPriority;

  final aVisit = a.scheduledVisitAt;
  final bVisit = b.scheduledVisitAt;
  if (aVisit != null && bVisit != null) return aVisit.compareTo(bVisit);
  if (aVisit != null) return -1;
  if (bVisit != null) return 1;

  return b.lastUpdatedAt.compareTo(a.lastUpdatedAt);
}
