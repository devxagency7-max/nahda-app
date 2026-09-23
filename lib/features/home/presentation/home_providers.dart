import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/providers/data_providers.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../cases/data/case_status_mapper.dart';
import '../../cases/domain/case_status.dart';
import '../domain/home_summary.dart';
import '../domain/social_worker_case.dart';

/// بيانات الشاشة الرئيسية — **من الكاش المحلي**.
///
/// تظهر فورًا عند فتح التطبيق حتى بلا اتصال، وتتحدّث تلقائيًا كلما كتبت
/// المزامنة في قاعدة البيانات. لا انتظار للشبكة ولا شاشة خطأ لانقطاعها.
final homeDataProvider = StreamProvider<HomeData>((ref) {
  final repository = ref.watch(casesRepositoryProvider);
  final user = ref.watch(currentUserProvider);

  return repository.watchWorkQueue().asyncMap((rows) async {
    final bookmarked = await repository.watchBookmarked().first;

    final cases = rows.map(CaseStatusMapper.toDisplayCase).toList();

    // "مهامي دلوقتي" مقابل "تم إرسالها" — تقسيم عرضي بحت.
    final active = <SocialWorkerCase>[];
    final submitted = <SocialWorkerCase>[];

    for (final item in cases) {
      if (item.status == CaseWorkStatus.submittedForReview) {
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
        allCases: rows.length,
        savedCases: bookmarked.length,
        returnedCases: rows
            .where((r) => r.status == CaseStatus.returnedToWorker.wireValue)
            .length,
      ),
      priorityTasks: active,
      submittedCases: submitted,
    );
  });
});

/// المرتجعة فقط — لشاشة "الحالات المرتجعة".
final returnedCasesListProvider = StreamProvider<List<SocialWorkerCase>>((ref) {
  return ref
      .watch(casesRepositoryProvider)
      .watchReturned()
      .map((rows) => rows.map(CaseStatusMapper.toDisplayCase).toList());
});

/// المحفوظة.
final savedCasesListProvider = StreamProvider<List<SocialWorkerCase>>((ref) {
  return ref
      .watch(casesRepositoryProvider)
      .watchBookmarked()
      .map((rows) => rows.map(CaseStatusMapper.toDisplayCase).toList());
});

/// حالة العرض العلوية: متصل / غير متصل / جارٍ المزامنة.
final syncBannerProvider = Provider<SyncBanner>((ref) {
  final connection = ref.watch(connectionKindProvider).valueOrNull;
  final pending = ref.watch(pendingSyncCountProvider).valueOrNull ?? 0;
  final photos = ref.watch(pendingAttachmentCountProvider).valueOrNull ?? 0;

  final isOffline = connection == null || !connection.isOnline;

  return SyncBanner(
    isOffline: isOffline,
    pendingOperations: pending,
    pendingPhotos: photos,
  );
});

/// ما يُعرَض في شريط حالة المزامنة أعلى الشاشة.
class SyncBanner {
  const SyncBanner({
    required this.isOffline,
    required this.pendingOperations,
    required this.pendingPhotos,
  });

  final bool isOffline;
  final int pendingOperations;
  final int pendingPhotos;

  bool get hasPendingWork => pendingOperations > 0 || pendingPhotos > 0;

  /// يظهر الشريط فقط حين يعني شيئًا للمستخدم.
  bool get isVisible => isOffline || hasPendingWork;

  String get message {
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
