import 'package:dio/dio.dart';

/// مصدر الحقيقة الوحيد لهوية "الجلسة الحالية" — يُستهلَك من طبقة الشبكة
/// وطبقة البيانات لمنع أي نتيجة عملية غير متزامنة (رد API متأخر، دورة
/// مزامنة، Isolate خلفي) من التأثير على جلسة غير التي أطلقتها.
///
/// **لماذا `generation` لا `userId` وحده:** حسابان مختلفان قد يتشاركا نفس
/// الفحص لو اعتمدنا فقط "هل لا يزال هذا المستخدم مسجَّلًا؟" — تسجيل خروج ثم
/// دخول لنفس الحساب مجددًا يجب أيضًا أن يُبطل عمليات الجلسة السابقة (لا
/// ضمان أن كل حالتها المحلية لا تزال صحيحة). لذا كل `beginSession`/
/// `endSession` يزيد عدّادًا أحاديّ الاتجاه بصرف النظر عن تطابق المستخدم.
class SessionRegistry {
  int _generation = 0;
  String? _userId;
  CancelToken _cancelToken = CancelToken();

  /// رقم الجيل الحالي — يُلتقَط وقت إطلاق أي عملية غير متزامنة، ويُقارَن
  /// عند اكتمالها عبر [isCurrent].
  int get generation => _generation;

  /// معرّف المستخدم صاحب الجلسة الحالية، أو `null` قبل أول تسجيل دخول.
  String? get userId => _userId;

  /// يُمرَّر لكل طلب Dio — يُلغى بالكامل عند [endSession].
  CancelToken get cancelToken => _cancelToken;

  /// هل [capturedGeneration] لا يزال يطابق الجلسة الحالية؟ يُستدعى بعد أي
  /// عملية غير متزامنة قبل كتابة نتيجتها في Drift/Riverpod/UI.
  bool isCurrent(int capturedGeneration) => capturedGeneration == _generation;

  /// يبدأ جلسة جديدة — يُستدعى فور نجاح `login()`. يزيد الجيل وينشئ
  /// `CancelToken` جديدًا حتى لو لم يسبقه `endSession` صريح (مثل أول تشغيل
  /// للتطبيق بعد `restoreSession`).
  int beginSession(String userId) {
    _userId = userId;
    _cancelToken = CancelToken();
    return _generation += 1;
  }

  /// ينهي الجلسة الحالية — يُستدعى قبل أي مسح فعلي للتوكن/القاعدة المحلية.
  /// يزيد الجيل فورًا (فيُبطل أي عملية قيد التنفيذ بالفعل) **ثم** يُلغي
  /// الـ `CancelToken` القديم (فتُقاطَع الطلبات الجارية فعليًا على مستوى
  /// Dio، دفاع مزدوج: حتى لو لم يُطبَّق فحص الجيل في نقطة ما، الإلغاء
  /// يمنع وصول الرد أصلًا في أغلب الحالات).
  void endSession() {
    _generation += 1;
    _userId = null;
    _cancelToken.cancel('session-ended');
    _cancelToken = CancelToken();
  }
}
