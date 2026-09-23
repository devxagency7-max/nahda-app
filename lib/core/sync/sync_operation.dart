/// أنواع العمليات القابلة للوضع في طابور المزامنة.
///
/// القيمة النصّية تُخزَّن في قاعدة البيانات — **لا تُغيَّر بعد الإطلاق** وإلا
/// أصبحت العمليات المخزَّنة على أجهزة المستخدمين غير مقروءة.
enum SyncOperationType {
  // أقسام الحالة — استبدال كامل محروس بـ rowVersion
  updateBeneficiary('update_beneficiary'),
  updateFamilyMembers('update_family_members'),
  updateHousing('update_housing'),
  updateUtilities('update_utilities'),
  updateAgriculture('update_agriculture'),
  updateFinancial('update_financial'),
  updateInitialNeeds('update_initial_needs'),
  updateClassification('update_classification'),
  updateAssessedNeeds('update_assessed_needs'),
  updateSupportRecommendations('update_support_recommendations'),

  // سير العمل — تتطلب Idempotency-Key
  acceptCase('accept_case'),
  rejectAssignment('reject_assignment'),
  submitWorkerOpinion('submit_worker_opinion'),

  // الميدان
  createFieldVisit('create_field_visit'),
  updateFieldVisit('update_field_visit'),
  updateFieldVerification('update_field_verification'),

  // مرفقات
  uploadAttachment('upload_attachment'),
  deleteAttachment('delete_attachment'),

  // خفيفة
  bookmarkCase('bookmark_case'),
  unbookmarkCase('unbookmark_case'),
  markNotificationRead('mark_notification_read'),
  markAllNotificationsRead('mark_all_notifications_read');

  const SyncOperationType(this.wireValue);

  final String wireValue;

  static SyncOperationType fromWire(String value) =>
      SyncOperationType.values.firstWhere(
        (t) => t.wireValue == value,
        orElse: () => throw ArgumentError('نوع عملية غير معروف: $value'),
      );

  /// هل تتطلب هذه العملية `Idempotency-Key`؟ (§6)
  bool get requiresIdempotencyKey => switch (this) {
    SyncOperationType.acceptCase ||
    SyncOperationType.rejectAssignment ||
    SyncOperationType.submitWorkerOpinion => true,
    _ => false,
  };

  /// هل تحمل هذه العملية خطر التنفيذ المزدوج بلا حماية من الخادم؟
  ///
  /// `POST /field-visits` وحده في هذه الخانة (§14.2): لا Idempotency-Key ولا
  /// أي آلية dedup على الخادم — إعادة الإرسال تُنشئ زيارة ثانية فعليًا.
  /// لذا نحرسه بـ `dedupId` محلي ونتحقق قبل الإرسال لا بعده.
  bool get needsLocalDedup => this == SyncOperationType.createFieldVisit;

  /// هل هذه عملية على قسم من أقسام الحالة؟
  ///
  /// تعديلان متتاليان على نفس القسم قبل المزامنة يُدمجان في عملية واحدة،
  /// وإلا لضمنّا تعارض rowVersion مع الخادم (§2.3، القاعدة ٤).
  bool get isSectionUpdate => switch (this) {
    SyncOperationType.updateBeneficiary ||
    SyncOperationType.updateFamilyMembers ||
    SyncOperationType.updateHousing ||
    SyncOperationType.updateUtilities ||
    SyncOperationType.updateAgriculture ||
    SyncOperationType.updateFinancial ||
    SyncOperationType.updateInitialNeeds ||
    SyncOperationType.updateClassification ||
    SyncOperationType.updateAssessedNeeds ||
    SyncOperationType.updateSupportRecommendations ||
    SyncOperationType.updateFieldVerification => true,
    _ => false,
  };

  /// أولوية التفريغ داخل الحالة الواحدة — الأصغر أولًا.
  ///
  /// الترتيب مُلزَم بالعقد (§16.4): المرفقات تُرفَع وتُثبَّت قبل الزيارة التي
  /// تشير إليها، وتعديلات الأقسام قبل الرأي الذي تحرسه بوابة الإكمال ١٠٠٪،
  /// والرأي أخيرًا لأنه ينقل الحالة خارج نافذة التعديل.
  int get flushPriority => switch (this) {
    SyncOperationType.uploadAttachment => 0,
    SyncOperationType.deleteAttachment => 1,
    SyncOperationType.acceptCase || SyncOperationType.rejectAssignment => 2,
    SyncOperationType.createFieldVisit ||
    SyncOperationType.updateFieldVisit => 3,
    _ when isSectionUpdate => 4,
    SyncOperationType.submitWorkerOpinion => 5,
    _ => 6,
  };
}

/// حالة العملية في الطابور.
enum SyncOperationStatus {
  /// بانتظار التفريغ.
  pending('pending'),

  /// أُرسِلت ولم تصل نتيجتها بعد.
  ///
  /// حالة حرجة: لو مات التطبيق هنا، عند الإقلاع **لا نُعيد الإرسال أعمى** —
  /// نتحقق من الخادم أولًا (خصوصًا للزيارات الميدانية).
  inFlight('in_flight'),

  /// فشل قابل لإعادة المحاولة لاحقًا.
  failed('failed'),

  /// تعارض يحتاج قرار المستخدم — لا يُعاد تلقائيًا.
  conflict('conflict'),

  /// فشل نهائي لا يُحَل بإعادة المحاولة (خطأ تحقق مثلًا).
  ///
  /// **لا تُحذَف تلقائيًا أبدًا** — تبقى حتى يقرّر المستخدم، حمايةً من فقد عمله.
  deadLettered('dead_lettered');

  const SyncOperationStatus(this.wireValue);

  final String wireValue;

  static SyncOperationStatus fromWire(String value) =>
      SyncOperationStatus.values.firstWhere(
        (s) => s.wireValue == value,
        orElse: () => SyncOperationStatus.pending,
      );

  bool get isTerminal =>
      this == SyncOperationStatus.conflict ||
      this == SyncOperationStatus.deadLettered;

  /// هل تحتاج تدخّل المستخدم؟
  bool get needsUserAttention => isTerminal;
}

/// حالة مزامنة كيان (حالة، قسم، زيارة) كما تُعرَض للمستخدم.
enum SyncState {
  synced,
  pendingSync,
  syncing,
  conflict,
  failed;

  bool get hasPendingWork => this == pendingSync || this == syncing;
}

/// تباعد إعادة المحاولة — أسّي بسقف.
///
/// الأخصائي قد يكون في منطقة بلا تغطية لساعات؛ محاولة كل دقيقة تستنزف
/// البطارية بلا فائدة. السقف ٦ ساعات يضمن أن الطابور لا "ينام" للأبد أيضًا.
Duration retryBackoff(int attempts) {
  const schedule = [
    Duration(minutes: 1),
    Duration(minutes: 5),
    Duration(minutes: 15),
    Duration(hours: 1),
    Duration(hours: 3),
    Duration(hours: 6),
  ];
  if (attempts <= 0) return Duration.zero;
  final index = attempts - 1;
  return index < schedule.length ? schedule[index] : schedule.last;
}
