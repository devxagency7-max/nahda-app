/// مراحل رفع المرفق.
///
/// الاستئناف يبدأ من آخر مرحلة وصلنا إليها، لا من الصفر — مهم لأن الأخصائي
/// قد يرفع ٧ صور على شبكة متقطّعة.
enum UploadStage {
  /// التُقط وحُفِظ في مجلد التطبيق الدائم، ولم يُرفَع بعد.
  ///
  /// **لا يُستدعى `/init` في هذه المرحلة والجهاز أوفلاين** — نافذة الـ ٤٨ ساعة
  /// لحذف المرفقات اليتيمة تبدأ من `/init` لا من الالتقاط (§14.4).
  captured('captured'),

  /// تم `/init`؛ لدينا `attachmentId` و `uploadUrl` صالح ٣٠ دقيقة.
  initialized('initialized'),

  /// جارٍ رفع البايتات إلى التخزين.
  uploading('uploading'),

  /// اكتمل الرفع، ولم يُثبَّت بعد.
  uploaded('uploaded'),

  /// `/commit` نجح — المرفق صار جزءًا من الحالة.
  committed('committed'),

  /// فشل لا يُحَل بإعادة المحاولة (حجم/نوع مرفوض).
  failed('failed');

  const UploadStage(this.wireValue);

  final String wireValue;

  static UploadStage fromWire(String value) => UploadStage.values.firstWhere(
    (s) => s.wireValue == value,
    orElse: () => UploadStage.captured,
  );

  bool get isDone => this == UploadStage.committed;
  bool get needsWork => !isDone && this != UploadStage.failed;

  String get label => switch (this) {
    UploadStage.captured => 'بانتظار الرفع',
    UploadStage.initialized => 'جارٍ التحضير',
    UploadStage.uploading => 'جارٍ الرفع',
    UploadStage.uploaded => 'جارٍ التثبيت',
    UploadStage.committed => 'تم الرفع',
    UploadStage.failed => 'فشل الرفع',
  };
}

/// سياسة الملفات — مطابقة لـ `AttachmentFilePolicy` على الخادم (§21).
class AttachmentPolicy {
  const AttachmentPolicy._();

  /// ١٠ ميجابايت بالضبط.
  static const maxFileSizeBytes = 10485760;

  /// قائمة مغلقة — يُفحَص النوع **والامتداد** كلٌّ على حدة.
  static const allowedMimeTypes = {
    'image/jpeg',
    'image/png',
    'image/heic',
    'image/webp',
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  };

  static const allowedExtensions = {
    'jpg',
    'jpeg',
    'png',
    'heic',
    'heif',
    'webp',
    'pdf',
    'doc',
    'docx',
  };

  /// صلاحية رابط الرفع — ٣٠ دقيقة (أطول من رابط التحميل عمدًا لتحمّل
  /// رفع ١٠ ميجا على شبكة موبايل بطيئة).
  static const uploadUrlTtl = Duration(minutes: 30);

  /// صلاحية رابط التحميل — ١٥ دقيقة. لا يُخزَّن ولا يُعاد استخدامه.
  static const downloadUrlTtl = Duration(minutes: 15);

  /// المرفق غير المُثبَّت يُحذَف من الخادم بعد ٤٨ ساعة.
  static const orphanWindow = Duration(hours: 48);

  /// أقصى عدد رفعات متوازية — `/init` عليه حدّ معدّل.
  static const maxConcurrentUploads = 2;

  /// فحص محلي **وقت الالتقاط** لا وقت الرفع.
  ///
  /// رفض صورة بعد يومين في الميدان كارثة؛ الرفض الآن يسمح للأخصائي بإعادة
  /// التصوير فورًا.
  static String? validate({required String fileName, required int sizeBytes}) {
    if (sizeBytes <= 0) return 'الملف فارغ.';

    if (sizeBytes > maxFileSizeBytes) {
      final mb = (sizeBytes / 1048576).toStringAsFixed(1);
      return 'حجم الملف $mb ميجابايت ويتجاوز الحد المسموح (١٠ ميجابايت).';
    }

    final ext = extensionOf(fileName);
    if (ext == null || !allowedExtensions.contains(ext)) {
      return 'نوع الملف غير مدعوم. المسموح: صور، PDF، Word.';
    }

    return null;
  }

  static String? extensionOf(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot < 0 || dot == fileName.length - 1) return null;
    return fileName.substring(dot + 1).toLowerCase();
  }

  /// نوع MIME المستنتج من الامتداد.
  ///
  /// الخادم يتحقق من **البايتات الأولى** لا من هذه القيمة، لكن `/init` يرفض
  /// نوعًا خارج القائمة قبل إصدار الرابط.
  static String? mimeFor(String fileName) => switch (extensionOf(fileName)) {
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'heic' || 'heif' => 'image/heic',
    'webp' => 'image/webp',
    'pdf' => 'application/pdf',
    'doc' => 'application/msword',
    'docx' =>
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    _ => null,
  };
}

/// أنواع المستندات المستخدمة في التطبيق.
class DocumentTypes {
  const DocumentTypes._();

  static const fieldVisitPhoto = 'field_visit_photo';
  static const nationalIdCopy = 'national_id_copy';
  static const incomeProof = 'income_proof';
  static const medicalReport = 'medical_report';
  static const housingPhoto = 'housing_photo';
  static const other = 'other';

  static const labels = {
    fieldVisitPhoto: 'صورة زيارة ميدانية',
    nationalIdCopy: 'صورة البطاقة',
    incomeProof: 'إثبات دخل',
    medicalReport: 'تقرير طبي',
    housingPhoto: 'صورة السكن',
    other: 'مستند آخر',
  };
}
