/// رأي الأخصائي — الكارت الوحيد القابل للتعديل من الأخصائي في تاب
/// "التقييمات". رأي المراجع ورأي مدير التنمية View-only (يُملأن من
/// الأدوار المعنية عبر شاشاتهم الخاصة، لا من تطبيق الأخصائي).
class SocialWorkerOpinionCardData {
  /// الرأي المختصر كما يعرضه الـ dropdown: 'مقبول' / 'مرفوض' / 'لم يتم البدء'.
  String? briefOpinion; // الرأي المختصر: موافق / غير موافق
  String? detailedReport;

  /// وقت آخر إرسال فعلي لـ `POST /opinions/worker` (لا وقت الكتابة/الحفظ
  /// المحلي) — `null` طالما لم يُرسَل رأي بعد. يُستخدم فقط لعرض تلميح "آخر
  /// رأي أُرسِل" فوق كارت الكتابة، **لا** يمنع الأخصائي من تعديل الحقول
  /// وإعادة الإرسال (السيرفر هو من يقرر `OpinionSlotLocked` لا الواجهة).
  final DateTime? submittedAtUtc;

  SocialWorkerOpinionCardData({
    this.briefOpinion = 'لم يتم البدء',
    this.detailedReport,
    this.submittedAtUtc,
  });

  /// القيمة السلكية لـ `decision` في `POST /opinions/worker` — `null` طالما
  /// لسه "لم يتم البدء" أو أي قيمة غير الاثنتين المعروفتين (§20، العقد يقبل
  /// `accepted`/`rejected` فقط، لا نصًا حرًا).
  String? get decisionWireValue => switch (briefOpinion) {
    'مقبول' => 'accepted',
    'مرفوض' => 'rejected',
    _ => null,
  };

  /// **لا** تعتمد على مجرد وجود نص — "لم يتم البدء" نص غير فارغ لكنه يعني
  /// عدم اتخاذ قرار فعليًا؛ استخدام [briefOpinion] مباشرة هنا كان يُظهر
  /// التاب "مكتملًا" (100%) حتى لو الأخصائي لم يختر شيئًا بعد.
  bool get isFilled =>
      decisionWireValue != null && (detailedReport ?? '').trim().isNotEmpty;
}

/// ترجمة `decision` السلكي (`accepted`/`rejected`/`returned_to_worker`/
/// `approved`) لتسمية عربية معروضة — مشتركة بين كارتي المراجع والمدير
/// (رد الباك إند على طلب 14، §3).
String? _decisionLabel(String? wireDecision) => switch (wireDecision) {
  'accepted' => 'مقبول',
  'rejected' => 'مرفوض',
  'returned_to_worker' => 'مرتجعة للأخصائي',
  'approved' => 'معتمد',
  _ => null,
};

/// رأي المراجع — View-only، يُعرض بعد أن يملأه المراجع من شاشته الخاصة.
///
/// [isSubmitted] وحده المعنى فعليًا هنا: المراجع (خلافًا للأخصائي والمدير)
/// يقدر يحفظ مسودة (`isSubmitted: false`) قبل الإرسال النهائي — رد الباك
/// إند على طلب 14، §2.
class ReviewerOpinionCardData {
  final String? decision;
  final String? notes;
  final bool isSubmitted;
  final String? returnReason;

  const ReviewerOpinionCardData({
    this.decision,
    this.notes,
    this.isSubmitted = false,
    this.returnReason,
  });

  /// التسمية العربية للرأي المختصر — `null` إن لم يُتّخذ قرار بعد.
  String? get briefOpinion => _decisionLabel(decision);

  static ReviewerOpinionCardData? fromJson(Object? data) {
    if (data is! Map<String, dynamic>) return null;
    return ReviewerOpinionCardData(
      decision: data['decision'] as String?,
      notes: data['notes'] as String?,
      isSubmitted: data['isSubmitted'] == true,
      returnReason: data['returnReason'] as String?,
    );
  }
}

/// رأي مدير التنمية — View-only، القرار النهائي (اعتماد/رفض) يُتخذ من
/// شاشة المدير الخاصة، ليس من تطبيق الأخصائي.
///
/// لا مفهوم مسودة هنا (`isSubmitted` دائمًا `true` لحظة الكتابة على الخادم،
/// رد الباك إند على طلب 14، §2) — الحقل غير محفوظ هنا لعدم فائدته.
class DirectorDecisionCardData {
  final String? decision;
  final String? notes;

  const DirectorDecisionCardData({this.decision, this.notes});

  /// التسمية العربية للقرار النهائي — `null` إن لم يُتّخذ قرار بعد.
  String? get finalDecision => _decisionLabel(decision);

  static DirectorDecisionCardData? fromJson(Object? data) {
    if (data is! Map<String, dynamic>) return null;
    return DirectorDecisionCardData(
      decision: data['decision'] as String?,
      notes: data['notes'] as String?,
    );
  }
}

/// آخر رأي أخصائي **وصل فعليًا للسيرفر** — View-only، يُعرض في كارت منفصل
/// بجانب كارت الكتابة الحالي دائمًا (لا يُستبدَل ولا يُخفى عند كتابة رأي
/// جديد؛ السيرفر وحده يقرر قفل الفتحة `OPINION_SLOT_LOCKED`، لا الواجهة).
///
/// المصدر: `opinions.worker` (نفس شكل `reviewer`/`manager`) + الحقل
/// المستقل أعلى مستوى الاستجابة `workerOpinionDetailedReport` (١٣ حقل حر لا
/// يتحقق الخادم من محتواه — راجع رد الباك إند على `POST /opinions/worker`).
class PreviousWorkerOpinionCardData {
  final String? decision;
  final String? notes;
  final bool isSubmitted;
  final Map<String, dynamic>? detailedReport;

  const PreviousWorkerOpinionCardData({
    this.decision,
    this.notes,
    this.isSubmitted = false,
    this.detailedReport,
  });

  /// التسمية العربية للرأي المختصر — `null` إن لم يوجد رأي سابق فعليًا.
  String? get briefOpinion => _decisionLabel(decision);

  static PreviousWorkerOpinionCardData? fromJson(Object? data) {
    if (data is! Map<String, dynamic>) return null;
    final decision = data['decision'] as String?;
    final notes = data['notes'] as String?;
    final detailedReport = data['detailedReport'];
    final report = detailedReport is Map
        ? Map<String, dynamic>.from(detailedReport)
        : null;
    if (decision == null && notes == null && (report == null || report.isEmpty)) {
      return null;
    }
    return PreviousWorkerOpinionCardData(
      decision: decision,
      notes: notes,
      isSubmitted: data['isSubmitted'] == true,
      detailedReport: report,
    );
  }
}

class OpinionsFormData {
  SocialWorkerOpinionCardData socialWorker;
  ReviewerOpinionCardData? reviewer;
  DirectorDecisionCardData? director;
  PreviousWorkerOpinionCardData? previousWorkerOpinion;

  /// سبب رجوع الحالة الحالي — من `returnInfo` أعلى مستوى الاستجابة، **وليس**
  /// من `opinions.reviewer`. مصدر الحقيقة الوحيد المضمون: لو المدير هو من
  /// أرجع الحالة (بعد أن راجعها)، الخادم يمسح رأي المراجع بالكامل
  /// (`opinions.reviewer` يرجع `null`) فلا تُستنتج هذه الحالة من كارت
  /// المراجع وحده (رد الباك إند على طلب 14، §5).
  final String? returnReason;

  /// من أرجع الحالة — تسمية عربية جاهزة (`ReturnSource.label`)، أو `null` إن
  /// لم تكن الحالة مرتجعة حاليًا.
  final String? returnedByLabel;

  OpinionsFormData({
    SocialWorkerOpinionCardData? socialWorker,
    this.reviewer,
    this.director,
    this.previousWorkerOpinion,
    this.returnReason,
    this.returnedByLabel,
  }) : socialWorker = socialWorker ?? SocialWorkerOpinionCardData();

  double get progress => socialWorker.isFilled ? 1.0 : 0.0;
}
