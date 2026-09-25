import 'social_worker_case.dart';

/// أرقام Home السريعة — Social Worker Spec §5.3.
/// أرقام يُلقى عليها نظرة سريعة، وليست Analytics.
class HomeCounters {
  final int allCases;
  final int savedCases;
  final int returnedCases;

  const HomeCounters({
    required this.allCases,
    required this.savedCases,
    required this.returnedCases,
  });
}

class HomeData {
  final String socialWorkerName;
  final int unreadNotifications;
  final HomeCounters counters;
  final List<SocialWorkerCase> priorityTasks; // "مهامي دلوقتي"
  final List<SocialWorkerCase> submittedCases; // "الحالات التي تم إرسالها"

  const HomeData({
    required this.socialWorkerName,
    required this.unreadNotifications,
    required this.counters,
    required this.priorityTasks,
    required this.submittedCases,
  });
}
