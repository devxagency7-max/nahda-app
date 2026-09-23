/// حالات الحالة كما يعرّفها الخادم — §9 من العقد. عشر قيم، لا أكثر.
enum CaseStatus {
  draft('draft'),
  pendingAssignment('pending_assignment'),
  assigned('assigned'),
  accepted('accepted'),
  inResearch('in_research'),
  pendingReview('pending_review'),
  returnedToWorker('returned_to_worker'),
  pendingApproval('pending_approval'),
  approved('approved'),
  rejected('rejected'),

  /// قيمة غير معروفة — يحمي من انهيار التطبيق لو أضاف الخادم حالة جديدة.
  unknown('unknown');

  const CaseStatus(this.wireValue);

  final String wireValue;

  static CaseStatus fromWire(String? value) {
    if (value == null) return CaseStatus.unknown;
    for (final status in CaseStatus.values) {
      if (status.wireValue == value) return status;
    }
    return CaseStatus.unknown;
  }

  /// هل نافذة البحث الميداني مفتوحة؟
  ///
  /// `FieldVisitAuthorization.AllowedStatuses` = {in_research, returned_to_worker}.
  /// خارجها لا يُقبَل تسجيل زيارة ولا إرسال رأي.
  bool get allowsFieldWork =>
      this == CaseStatus.inResearch || this == CaseStatus.returnedToWorker;

  /// هل الحالة في وضع نهائي لا يقبل أي إجراء؟
  bool get isTerminal =>
      this == CaseStatus.approved || this == CaseStatus.rejected;

  /// هل يمكن للأخصائي تعديل بيانات هذه الحالة؟
  ///
  /// الخادم يفرض هذا أيضًا؛ هذا تلميح واجهة لا تفويض.
  bool get isEditableByWorker => allowsFieldWork;
}

/// إجراءات سير العمل — §9.
///
/// **تحذير (§15.7):** `availableActions` تلميح UX فقط. كل مسار يعيد التحقق من
/// الدور والحالة وملكية الإسناد مستقلًا، وقد يرفض رغم ظهور الإجراء — مثلًا بعد
/// أن يُعيد المدير إسناد الحالة والجهاز أوفلاين.
enum WorkflowAction {
  assign('assign'),
  acceptAssignment('accept_assignment'),
  rejectAssignment('reject_assignment'),
  submitWorkerOpinion('submit_worker_opinion'),
  saveReviewerDraft('save_reviewer_draft'),
  submitReviewerOpinion('submit_reviewer_opinion'),
  returnToWorker('return_to_worker'),
  approve('approve'),
  reject('reject'),
  returnForCompletion('return_for_completion'),
  unknown('unknown');

  const WorkflowAction(this.wireValue);

  final String wireValue;

  static WorkflowAction fromWire(String? value) {
    if (value == null) return WorkflowAction.unknown;
    for (final action in WorkflowAction.values) {
      if (action.wireValue == value) return action;
    }
    return WorkflowAction.unknown;
  }

  /// الإجراءات التي يملكها الأخصائي وحده (§7.1).
  static const workerActions = {
    WorkflowAction.acceptAssignment,
    WorkflowAction.rejectAssignment,
    WorkflowAction.submitWorkerOpinion,
  };
}

/// أولوية الحالة — §9.
enum CasePriorityWire {
  low('low'),
  medium('medium'),
  high('high'),
  urgent('urgent'),
  unknown('unknown');

  const CasePriorityWire(this.wireValue);

  final String wireValue;

  static CasePriorityWire fromWire(String? value) {
    if (value == null) return CasePriorityWire.unknown;
    for (final p in CasePriorityWire.values) {
      if (p.wireValue == value) return p;
    }
    return CasePriorityWire.unknown;
  }

  String get label => switch (this) {
    CasePriorityWire.low => 'منخفضة',
    CasePriorityWire.medium => 'متوسطة',
    CasePriorityWire.high => 'مرتفعة',
    CasePriorityWire.urgent => 'عاجلة',
    CasePriorityWire.unknown => '—',
  };
}

/// مصدر إرجاع الحالة.
///
/// **بانتظار الباك إند** (§7، طلب 1): حاليًا `return-to-worker` (المراجع) و
/// `return-for-completion` (المدير) ينتجان `returned_to_worker` واحدة، فلا
/// يمكن التمييز. طُلبت إضافة `returnInfo`؛ حتى تصل، القيمة `unknown`.
enum ReturnSource {
  reviewer('reviewer'),
  manager('manager'),
  unknown('unknown');

  const ReturnSource(this.wireValue);

  final String wireValue;

  static ReturnSource fromWire(String? value) {
    if (value == null) return ReturnSource.unknown;
    for (final s in ReturnSource.values) {
      if (s.wireValue == value) return s;
    }
    return ReturnSource.unknown;
  }

  String get label => switch (this) {
    ReturnSource.reviewer => 'مرتجعة من المراجع',
    ReturnSource.manager => 'مرتجعة من المدير',
    ReturnSource.unknown => 'مرتجعة إليك',
  };
}
