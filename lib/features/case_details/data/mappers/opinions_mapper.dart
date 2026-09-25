import '../../domain/sections/opinions_form.dart';

/// يحوّل بيانات تاب "الرأي" (3 كروت: أخصائي/مراجع/مدير) من/إلى شكل التخزين
/// المحلي، وإلى نموذج `OpinionsFormData` من استجابة `GET /cases/{id}`.
///
/// كارت الأخصائي القابل للتعديل محلّي بالكامل (لا علاقة له بـ
/// `POST /opinions/worker` المباشر — ده مسار الإرسال عبر `sync_queue`، بلا
/// قراءة رجوع — ولا بـ `SocialAssessmentSection` تقرير حر منفصل، لسه بلا
/// مسار حفظ، طلب 4 المعلّق). كارتا المراجع/المدير View-only، تُقرأ فقط —
/// [fromApiResponse] هو مصدرهما الوحيد (رد الباك إند على طلب 14).
class OpinionsMapper {
  const OpinionsMapper._();

  static Map<String, dynamic> toCacheJson(SocialWorkerOpinionCardData card) => {
    'briefOpinion': card.briefOpinion,
    'detailedReport': card.detailedReport,
    if (card.submittedAtUtc != null)
      'submittedAtUtc': card.submittedAtUtc!.toIso8601String(),
  };

  static SocialWorkerOpinionCardData fromCacheJson(
    Map<String, dynamic> json,
  ) => SocialWorkerOpinionCardData(
    briefOpinion: json['briefOpinion'] as String? ?? 'لم يتم البدء',
    detailedReport: json['detailedReport'] as String?,
    submittedAtUtc: DateTime.tryParse(
      json['submittedAtUtc'] as String? ?? '',
    ),
  );

  /// يبني الكارت من `decision`/`notes` بشكل wire (`accepted`/`rejected`) —
  /// نفس ما يُرسَل فعليًا لـ`POST /opinions/worker`. يُستخدَم وقت الإرسال
  /// نفسه، حيث القيمة المتاحة wire لا التسمية العربية.
  static SocialWorkerOpinionCardData fromWireDecision({
    required String? decision,
    String? notes,
    DateTime? submittedAtUtc,
  }) => SocialWorkerOpinionCardData(
    briefOpinion: switch (decision) {
      'accepted' => 'مقبول',
      'rejected' => 'مرفوض',
      _ => 'لم يتم البدء',
    },
    detailedReport: notes,
    submittedAtUtc: submittedAtUtc,
  );

  /// يبني `OpinionsFormData` الكامل (المراجع والمدير فقط — رأي الأخصائي
  /// يظل من الكاش المحلي عبر [fromCacheJson]) من مفتاح `opinions` كما يصل
  /// في `GET /cases/{id}`، بالإضافة لمفتاح `returnInfo` (أعلى مستوى
  /// الاستجابة، وليس جوه `opinions`) لتمييز "المدير رجّعها بعد مسح رأي
  /// المراجع" عن "المراجع رجّعها بنفسه" (رد الباك إند على طلب 14، §5).
  static ({
    ReviewerOpinionCardData? reviewer,
    DirectorDecisionCardData? director,
  })
  fromApiResponse(Object? opinionsJson) {
    final json = opinionsJson is Map<String, dynamic>
        ? opinionsJson
        : const <String, dynamic>{};
    return (
      reviewer: ReviewerOpinionCardData.fromJson(json['reviewer']),
      director: DirectorDecisionCardData.fromJson(json['manager']),
    );
  }

  /// شكل تخزين محلي لكارتي المراجع/المدير — يُكتب في `CachedSections` تحت
  /// مفتاحين منفصلين عن `opinions` (المحجوز لكارت الأخصائي المحلي) حتى لا
  /// يُستبدَل تعديل الأخصائي المعلّق (`isDirty`) ببيانات القراءة، ولا العكس.
  static Map<String, dynamic> reviewerToCacheJson(
    ReviewerOpinionCardData? card,
  ) => {
    'decision': card?.decision,
    'notes': card?.notes,
    'isSubmitted': card?.isSubmitted ?? false,
    'returnReason': card?.returnReason,
  };

  static ReviewerOpinionCardData? reviewerFromCacheJson(
    Map<String, dynamic> json,
  ) => json['decision'] == null && json['notes'] == null
      ? null
      : ReviewerOpinionCardData.fromJson(json);

  static Map<String, dynamic> directorToCacheJson(
    DirectorDecisionCardData? card,
  ) => {'decision': card?.decision, 'notes': card?.notes};

  static DirectorDecisionCardData? directorFromCacheJson(
    Map<String, dynamic> json,
  ) => json['decision'] == null && json['notes'] == null
      ? null
      : DirectorDecisionCardData.fromJson(json);

  /// شكل تخزين محلي لكارت "آخر رأي أخصائي أُرسِل" (View-only) — مفتاح منفصل
  /// (`worker_opinion_previous`) عن `opinions` المحجوز لمسودة الكتابة الحالية،
  /// حتى لا يُستبدَل تعديل معلّق للأخصائي ببيانات القراءة ولا العكس.
  static Map<String, dynamic> previousWorkerToCacheJson(
    PreviousWorkerOpinionCardData? card,
  ) => {
    'decision': card?.decision,
    'notes': card?.notes,
    'isSubmitted': card?.isSubmitted ?? false,
    'detailedReport': card?.detailedReport,
  };

  static PreviousWorkerOpinionCardData? previousWorkerFromCacheJson(
    Map<String, dynamic> json,
  ) => PreviousWorkerOpinionCardData.fromJson(json);

  /// يبني كارت "آخر رأي أخصائي أُرسِل" من استجابة `GET /cases/{id}` الخام —
  /// `opinions.worker` (نفس شكل `reviewer`/`manager`: decision/notes/
  /// isSubmitted، بالإضافة لـ `detailedReport` المتداخل جواه — الحقول الحرة،
  /// لا يتحقق منها الخادم، ترجع `null` لو الأخصائي مبعتهاش وقت تقديم رأيه).
  /// `opinions.worker` مضمَّن أصلًا في `GET /cases/{id}` نفسه — لا `endpoint`
  /// منفصل، متاح لأي دور عنده `view_cases`.
  static PreviousWorkerOpinionCardData? previousWorkerFromRaw(
    Map<String, dynamic> raw,
  ) {
    final opinions = raw['opinions'];
    final workerJson = opinions is Map<String, dynamic>
        ? opinions['worker']
        : null;
    return PreviousWorkerOpinionCardData.fromJson(workerJson);
  }
}
