import 'package:drift/drift.dart';

/// طابور عمليات المزامنة — القلب النابض للعمل أوفلاين.
///
/// كل كتابة يقوم بها الأخصائي تُسجَّل هنا وتُفرَّغ لاحقًا. الجدول **دائم**:
/// يبقى عبر إعادة تشغيل التطبيق وإعادة تشغيل الجهاز.
@DataClassName('SyncOperationRow')
class SyncQueue extends Table {
  /// معرّف محلي (UUID) — لا علاقة له بمعرّف الخادم.
  TextColumn get id => text()();

  /// `SyncOperationType.wireValue`.
  TextColumn get type => text()();

  /// الحالة التي تنتمي إليها العملية.
  ///
  /// التفريغ مُجمَّع حسبها: تعارض في حالة **لا يوقف** مزامنة حالة أخرى.
  TextColumn get caseId => text()();

  /// ترتيب الإنشاء داخل نفس الحالة — التفريغ يحترمه بصرامة.
  IntColumn get sequence => integer()();

  /// جسم الطلب كـ JSON.
  TextColumn get payload => text()();

  /// `Idempotency-Key` — يُولَّد **مرة واحدة** عند إنشاء العملية ولا يتغيّر.
  ///
  /// إعادة توليده في كل محاولة تُبطل الآلية وتسمح بتنفيذ مزدوج (§15.3).
  TextColumn get idempotencyKey => text().nullable()();

  /// معرّف تكرار محلي — للزيارات الميدانية التي لا يحرسها الخادم (§14.2).
  TextColumn get dedupId => text().nullable()();

  /// `rowVersion` / `caseRowVersion` وقت إنشاء العملية.
  ///
  /// قد يبطل قبل التفريغ (تعديل قسم آخر يزيد نسخة الحالة)، لذا محرّك
  /// المزامنة يُعيد الجلب قبل الإرسال.
  IntColumn get rowVersion => integer().nullable()();

  /// `SyncOperationStatus.wireValue`.
  TextColumn get status =>
      text().withDefault(const Constant('pending'))();

  IntColumn get attempts => integer().withDefault(const Constant(0))();

  /// كود الخطأ الأخير (`ApiErrorCode.wireValue`).
  TextColumn get lastErrorCode => text().nullable()();

  /// رسالة الخطأ الأخيرة بالعربية — تُعرَض للمستخدم مباشرة.
  TextColumn get lastErrorMessage => text().nullable()();

  /// متى يُسمَح بالمحاولة التالية (تباعد أسّي).
  DateTimeColumn get nextAttemptAt => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  /// وقت آخر إرسال — يكشف عملية عالقة في `inFlight` بعد موت التطبيق.
  DateTimeColumn get sentAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// كاش الحالات — مصدر الحقيقة للشاشة.
///
/// الواجهة تقرأ من هنا عبر `Stream`؛ الشبكة تحدّث هذا الجدول فتتحدّث الشاشة.
/// **لا شاشة تنتظر الشبكة.**
@DataClassName('CachedCaseRow')
class CachedCases extends Table {
  TextColumn get id => text()();

  TextColumn get caseNumber => text()();
  TextColumn get displayId => text()();

  /// قيمة wire من الحالات العشر (`draft` … `rejected`).
  TextColumn get status => text()();
  TextColumn get priority => text()();

  TextColumn get beneficiaryFullName => text()();
  TextColumn get nationalId => text().nullable()();
  TextColumn get charityId => text().nullable()();

  TextColumn get registrationDate => text().nullable()();
  RealColumn get completionPercentage =>
      real().withDefault(const Constant(0))();

  /// أقرب زيارة غير مكتملة — تُشتقّ منها حالة العرض "زيارة مجدولة".
  TextColumn get nextVisitDate => text().nullable()();
  DateTimeColumn get nextVisitStartTimeUtc => dateTime().nullable()();
  TextColumn get nextVisitLocation => text().nullable()();

  BoolColumn get isBookmarked => boolean().withDefault(const Constant(false))();

  /// نسخة صفّ الحالة — تُستخدم في `caseRowVersion` لأقسام القوائم.
  IntColumn get rowVersion => integer().nullable()();

  /// نسخة صفّ المستفيد — **عدّاد منفصل تمامًا** عن نسخة الحالة (§19).
  IntColumn get beneficiaryRowVersion => integer().nullable()();

  /// `workflow.availableActions` كـ JSON — تلميح UX فقط، ليس تفويضًا (§15.7).
  TextColumn get availableActionsJson => text().nullable()();

  /// تفاصيل الحالة الكاملة كـ JSON (استجابة `GET /cases/{id}`).
  ///
  /// نخزّنها خامًا حتى نتمكّن من العرض أوفلاين دون نمذجة كل حقل مسبقًا.
  TextColumn get detailsJson => text().nullable()();

  /// هل جُلبت التفاصيل الكاملة، أم العنوان فقط من قائمة العمل؟
  BoolColumn get hasFullDetails =>
      boolean().withDefault(const Constant(false))();

  /// حالة المزامنة المعروضة (`SyncState.name`).
  TextColumn get syncState => text().withDefault(const Constant('synced'))();

  DateTimeColumn get serverUpdatedAt => dateTime().nullable()();
  DateTimeColumn get localUpdatedAt => dateTime().nullable()();
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// أقسام الحالة المخزَّنة محليًا — كل قسم صفّ واحد بنسخته.
@DataClassName('CachedSectionRow')
class CachedSections extends Table {
  TextColumn get caseId => text()();

  /// مفتاح القسم: `beneficiary`, `housing`, `family_members` …
  TextColumn get sectionKey => text()();

  /// محتوى القسم كـ JSON.
  TextColumn get dataJson => text()();

  /// نسخة الصفّ للأقسام المفردة.
  ///
  /// `null` يعني لم يُحفَظ القسم بعد على الخادم — وهي قيمة مشروعة تُرسَل
  /// كما هي في أول حفظ لـ housing/agriculture/classification (§19).
  IntColumn get rowVersion => integer().nullable()();

  /// هل يوجد تعديل محلي لم يُرفَع؟
  BoolColumn get isDirty => boolean().withDefault(const Constant(false))();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {caseId, sectionKey};
}

/// الزيارات الميدانية — أخطر كيان في النظام.
@DataClassName('FieldVisitRow')
class LocalFieldVisits extends Table {
  /// معرّف محلي يُولَّد فور إنشاء الزيارة.
  TextColumn get id => text()();

  /// معرّف الخادم — `null` حتى تُرفَع بنجاح.
  TextColumn get serverId => text().nullable()();

  TextColumn get caseId => text()();

  /// حارس التكرار — يُولَّد مرة واحدة ولا يتغيّر مدى حياة الزيارة.
  ///
  /// `POST /field-visits` بلا حماية من الخادم (§14.2)، فهذا خط الدفاع الوحيد.
  TextColumn get dedupId => text()();

  TextColumn get visitDate => text()();
  DateTimeColumn get startTimeUtc => dateTime().nullable()();
  DateTimeColumn get endTimeUtc => dateTime().nullable()();

  /// الإحداثيات — **معًا أو لا شيء** (§15.10).
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();

  TextColumn get locationDescription => text().nullable()();
  TextColumn get outcome => text()();
  TextColumn get visitStatus => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get description => text().nullable()();

  /// معرّفات المرفقات المحلية — تُترجَم لمعرّفات الخادم عند الرفع.
  TextColumn get localAttachmentIdsJson =>
      text().withDefault(const Constant('[]'))();

  IntColumn get rowVersion => integer().nullable()();
  TextColumn get syncState => text().withDefault(const Constant('pendingSync'))();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// المرفقات — تتبّع دورة الرفع بالكامل للسماح بالاستئناف.
@DataClassName('PendingAttachmentRow')
class PendingAttachments extends Table {
  TextColumn get id => text()();
  TextColumn get caseId => text()();

  /// معرّف الخادم — يظهر بعد `/init` فقط.
  TextColumn get attachmentId => text().nullable()();

  /// مسار الملف في **مجلد التطبيق الدائم**.
  ///
  /// الصورة تُنسَخ فور التقاطها؛ مسار الكاميرا المؤقت يمسحه نظام التشغيل.
  TextColumn get localPath => text()();

  TextColumn get fileName => text()();
  TextColumn get mimeType => text()();
  IntColumn get fileSize => integer()();
  TextColumn get documentType => text()();
  TextColumn get description => text().nullable()();

  /// checksum محلي (MD5) — اختياري في العقد لكنه يكشف الملف التالف مبكرًا.
  TextColumn get checksum => text().nullable()();

  /// مرحلة الرفع: `captured` → `initialized` → `uploading` → `uploaded` → `committed`.
  ///
  /// الاستئناف يبدأ من آخر مرحلة وصلنا إليها، لا من الصفر.
  TextColumn get uploadStage =>
      text().withDefault(const Constant('captured'))();

  TextColumn get uploadUrl => text().nullable()();

  /// انتهاء صلاحية رابط الرفع — بعده يلزم `/init` جديد.
  DateTimeColumn get uploadUrlExpiresAt => dateTime().nullable()();

  /// نسبة الرفع 0–1 — تُعرَض للمستخدم لأن الصور أثقل ما يُرفَع.
  RealColumn get progress => real().withDefault(const Constant(0))();

  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastErrorMessage => text().nullable()();

  /// أي زيارة تملك هذا المرفق — يضمن رفعه قبلها.
  TextColumn get fieldVisitLocalId => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// كاش القوائم المنسدلة — **إجباري** للعمل أوفلاين.
///
/// بدونه لا يستطيع الأخصائي ملء أي نموذج في الميدان.
@DataClassName('DropdownCacheRow')
class DropdownCache extends Table {
  /// مفتاح القائمة، أو `__locations__` / `__charities__` للحالات الخاصة.
  TextColumn get key => text()();

  TextColumn get valuesJson => text()();
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {key};
}

/// الإشعارات المخزَّنة محليًا.
@DataClassName('CachedNotificationRow')
class CachedNotifications extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get subtitle => text().nullable()();
  TextColumn get icon => text().nullable()();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
  TextColumn get caseId => text().nullable()();
  DateTimeColumn get createdAtUtc => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
