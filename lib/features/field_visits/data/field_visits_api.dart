import '../../../core/network/api_client.dart';

/// مسارات الزيارات الميدانية والتحقق الميداني — §11 و §20.
class FieldVisitsApi {
  const FieldVisitsApi(this._client);

  final ApiClient _client;

  /// `POST /cases/{caseId}/field-visits` (FV1).
  ///
  /// ⚠️ **أخطر مسار في التطبيق** تاريخيًا. الباك إند أضاف دعم `Idempotency-Key`
  /// اختياريًا (راجع `BACKEND_CHANGE_RESPONSE.md`، طلب 4) — [idempotencyKey]
  /// هنا هو ذلك المفتاح، **وليس** بديلًا عن حماية `dedupId`/`inFlight`
  /// المحلية أدناه بل طبقة إضافية حقيقية من الخادم نفسه الآن.
  ///
  /// لا تُستدعَ مباشرة: استخدم `FieldVisitsRepository.submit` الذي يمرّر
  /// `dedupId` الزيارة كمفتاح هنا (يُولَّد مرة عند الإنشاء ويُعاد استخدامه في
  /// كل محاولة حتى النجاح، تمامًا كنصيحة الباك إند) ويحرسها أيضًا بتعليم
  /// `inFlight` ومطابقة عند الإقلاع.
  ///
  /// شروط الخادم بالترتيب: الحالة مرئية ← العميل `mobile` ← أنت المُسنَد إليه
  /// ← الحالة `in_research` أو `returned_to_worker`.
  ///
  /// `caseId` وهوية الأخصائي **لا تُرسَلان في الجسم** — يؤخذان من المسار
  /// والتوكن، وإرسالهما بلا أثر.
  Future<Map<String, dynamic>> create({
    required String caseId,
    required String visitDate,
    required String outcome,
    DateTime? startTimeUtc,
    DateTime? endTimeUtc,
    double? latitude,
    double? longitude,
    String? locationDescription,
    String? status,
    String? notes,
    String? description,
    List<String> photoAttachmentIds = const [],
    String? idempotencyKey,
  }) {
    // الإحداثيات معًا أو لا شيء — إرسال إحداهما وحدها يُرفَض بـ 422 (§15.10).
    final hasCoordinates = latitude != null && longitude != null;

    return _client.post<Map<String, dynamic>>(
      '/cases/$caseId/field-visits',
      Parse.object,
      idempotencyKey: idempotencyKey,
      body: {
        'visitDate': visitDate,
        'outcome': outcome,
        if (startTimeUtc != null)
          'startTimeUtc': startTimeUtc.toUtc().toIso8601String(),
        if (endTimeUtc != null)
          'endTimeUtc': endTimeUtc.toUtc().toIso8601String(),
        if (hasCoordinates) 'latitude': latitude,
        if (hasCoordinates) 'longitude': longitude,
        if (locationDescription != null)
          'locationDescription': locationDescription,
        if (status != null) 'status': status,
        if (notes != null) 'notes': notes,
        if (description != null) 'description': description,
        if (photoAttachmentIds.isNotEmpty)
          'photoAttachmentIds': photoAttachmentIds,
      },
    );
  }

  /// `PUT /field-visits/{id}` (FV2) — تعديل زيارة **أنشأتها أنت**.
  ///
  /// زيارة لا توجد أو تخصّ أخصائيًا آخر ترجع **404** بلا تمييز.
  Future<Map<String, dynamic>> update({
    required String visitId,
    required int rowVersion,
    String? visitDate,
    String? outcome,
    DateTime? startTimeUtc,
    DateTime? endTimeUtc,
    double? latitude,
    double? longitude,
    String? locationDescription,
    String? status,
    String? notes,
    String? description,
    List<String>? photoAttachmentIds,
  }) {
    final hasCoordinates = latitude != null && longitude != null;

    return _client.put<Map<String, dynamic>>(
      '/field-visits/$visitId',
      Parse.object,
      body: {
        'rowVersion': rowVersion,
        if (visitDate != null) 'visitDate': visitDate,
        if (outcome != null) 'outcome': outcome,
        if (startTimeUtc != null)
          'startTimeUtc': startTimeUtc.toUtc().toIso8601String(),
        if (endTimeUtc != null)
          'endTimeUtc': endTimeUtc.toUtc().toIso8601String(),
        if (hasCoordinates) 'latitude': latitude,
        if (hasCoordinates) 'longitude': longitude,
        if (locationDescription != null)
          'locationDescription': locationDescription,
        if (status != null) 'status': status,
        if (notes != null) 'notes': notes,
        if (description != null) 'description': description,
        if (photoAttachmentIds != null)
          'photoAttachmentIds': photoAttachmentIds,
      },
    );
  }

  /// `GET /cases/{id}` لا يرجع الزيارات؛ نقرأها من تفاصيل الحالة المخزَّنة
  /// أو نستنتج وجودها عند التحقق من التكرار.
  ///
  /// **يُستخدَم للتعافي**: حين يموت التطبيق أثناء إرسال زيارة ولا نعرف إن
  /// وصلت، نجلب زيارات الحالة ونطابق بالتاريخ والنتيجة قبل قرار إعادة الإرسال.
  Future<List<Map<String, dynamic>>> listForCase(String caseId) =>
      _client.get<List<Map<String, dynamic>>>(
        '/cases/$caseId/field-visits',
        Parse.list,
      );

  /// `PUT /cases/{caseId}/field-verification` (FV3) — استبدال كامل.
  ///
  /// تُرسَل `fieldLabel` و `verifiedValue` و `differenceReason` فقط؛ الخادم
  /// يحسب `originalValue` و `isDifferent` من بياناته — **لا يمكن تزويرهما**.
  /// `differenceReason` مطلوب فقط حيث يجد الخادم فرقًا فعليًا.
  Future<Map<String, dynamic>> replaceVerification({
    required String caseId,
    required int caseRowVersion,
    required List<FieldVerificationEntry> entries,
  }) => _client.put<Map<String, dynamic>>(
    '/cases/$caseId/field-verification',
    Parse.object,
    body: {
      'caseRowVersion': caseRowVersion,
      'entries': entries.map((e) => e.toJson()).toList(growable: false),
    },
  );
}

/// مدخل تحقق ميداني واحد.
class FieldVerificationEntry {
  const FieldVerificationEntry({
    required this.fieldLabel,
    required this.verifiedValue,
    this.differenceReason,
  });

  final String fieldLabel;
  final String verifiedValue;

  /// إلزامي فقط حين يكتشف الخادم فرقًا عن القيمة المسجَّلة.
  final String? differenceReason;

  Map<String, dynamic> toJson() => {
    'fieldLabel': fieldLabel,
    'verifiedValue': verifiedValue,
    if (differenceReason != null) 'differenceReason': differenceReason,
  };
}
