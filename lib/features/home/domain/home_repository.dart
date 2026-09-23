import 'home_summary.dart';

/// عقد البيانات لصفحة الـ Home — التنفيذ الحالي Mock، لاحقًا API حقيقي
/// بدون أي تغيير في طبقة الـ UI أو الـ Use Case (CTO Prompt §10).
abstract class HomeRepository {
  Future<HomeData> getHomeData();
}
