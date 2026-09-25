# خطة ربط تطبيق النهضة (Flutter) بالـ Backend

مرجع العقد: `../FLUTTER_API_DOCUMENTATION.md` — هو مصدر الحقيقة الوحيد. أي قدرة غير موجودة فيه لا توجد في الباك إند.

---

## 0. الوضع الحالي (ما تم فحصه فعليًا)

**التطبيق:** ~13.8k سطر Dart، واجهات كاملة بالعربية/RTL لدور الأخصائي الاجتماعي فقط. حالته:

| المحور | الحالة الحالية |
|---|---|
| طبقة HTTP | **غير موجودة** — لا `dio`/`http` في `pubspec.yaml` |
| المصادقة | `login_screen.dart` وهمي: `Future.delayed(700ms)` ثم `Navigator.pushReplacement` |
| التنقّل | `go_router` مثبت في `pubspec.yaml` لكن **غير مستخدم** — لا يوجد `lib/core/routing/` |
| البيانات | 3 Mock repositories: `MockHomeRepository`, `MockCaseDetailsRepository`, `MockCaseSearchRepository` |
| إدارة الحالة | `flutter_riverpod` مثبت ومستخدم جزئيًا (`user_profile_provider.dart`) |
| التخزين الآمن | **غير موجود** — لا `flutter_secure_storage` |
| قاعدة بيانات محلية | **غير موجودة** — لا يوجد offline queue رغم وجود `SyncStatusBadge` و `hasUnsyncedChanges` في الـ UI |
| FCM | **غير موجود** — لا `firebase_messaging` |
| `rowVersion` | **غير موجود في أي موديل** |

**الخبر الجيد:** المعمارية نظيفة (feature-first + domain/data/presentation) والـ repositories خلف `abstract class`، فالاستبدال بـ API implementations لا يمس الـ UI.

---

## 0.1 القرارات المحسومة (من صاحب المنتج — 2026-09-18)

| # | القرار | الأثر |
|---|---|---|
| 1 | **Offline كامل** — الأخصائي يملأ الحالة ويصوّر ويسجّل الزيارة بدون نت، وكل شيء يُرفَع تلقائيًا عند عودة الاتصال. بمستوى احترافي. | المرحلة 7 تصبح **ركنًا أساسيًا لا إضافة**، وتُبنى المعمارية حولها من اليوم الأول (§2.1) |
| 2 | **الباك إند يعدّل أسماء الحالات وحقول الإرجاع** — طُلب منهم رسميًا (§7) | العمل على الحالات وشاشة الإرجاع **موقوف حتى ردّهم** |
| 3 | **الحقول الناقصة مطلوبة في النموذج الورقي** — تُطلَب من الباك إند، لا تُحذَف من الـ UI | تبويب البيانات الأساسية **موقوف جزئيًا حتى ردّهم** |

**نتيجة القرارين 2 و 3:** التطبيق يبدأ بالمراحل غير المعتمدة على ردّ الباك إند (0 → 1 → 2 → 3 قراءة)، ويُعاد ترتيب الباقي حسب ردّهم. راجع §5.

---

## 1. فجوات العقد الحرجة

### 1.1 حالات الحالة (Status) — **بانتظار الباك إند**

`SocialWorkerCase.status` عندنا 7 قيم عرض: `assigned, visitScheduled, inProgress, returnedFromReview, returnedFromManager, readyForReview, submittedForReview`.

العقد يعرّف **10 قيم wire**: `draft, pending_assignment, assigned, accepted, in_research, pending_review, returned_to_worker, pending_approval, approved, rejected`.

المشاكل:
- `visitScheduled` و `readyForReview` **لا وجود لهما على الشبكة**. "زيارة مجدولة" مشتقّة من `nextVisitDate != null` على حالة `in_research`. "جاهزة للإرسال" مشتقّة من `completion.isReady == true`.
- `returnedFromReview` و `returnedFromManager` **كلاهما `returned_to_worker` واحدة**. الباك إند لا يفرّق بين الإرجاع من المراجع والإرجاع من المدير.

**الحالة: طُلب من الباك إند إضافة `returnInfo` للتمييز + توضيح ناتج `return-for-completion`** (§7).

**حتى يردّوا:** يُبنى `CaseStatusMapper` كطبقة عزل واحدة. لو أضافوا `returnInfo` يُقرأ منها؛ لو رفضوا يُشتَقّ من الـ Timeline. **الـ UI لا يتغيّر في الحالتين** — هذا هو الغرض من المترجم.

### 1.2 حقول ناقصة في الباك إند — **بانتظار الباك إند**

`BasicInfoSection` يحتوي حقولًا معلّمة أصلًا `UNDEFINED / NEEDS BUSINESS DECISION`، والعقد يؤكد أنها **غير موجودة** في `PUT /cases/{id}/beneficiary`:

`email`, `street`, `buildingNumber`, `floor`, `apartmentNumber`, `landmark`, `employer`, `area`

**قرار صاحب المنتج: هذه الحقول مطلوبة في النموذج الورقي** — طُلبت إضافتها رسميًا (§7). لا تُحذَف من الـ UI.

**حتى يردّوا:** تبقى الحقول في الشاشة بعلامة "لا تُحفَظ بعد" وتُستبعَد من الـ payload. بمجرد إضافتها يُفعَّل الربط.

بالمقابل الـ `beneficiary` PUT يحتوي حقولًا **ليست في الـ UI ويجب إضافتها للشاشة**: `religion`, `maritalStatus`, `healthStatus`, `employmentStatus`, `takafulBeneficiary`, `takafulAmount`.

كذلك `age`/`gender`/`birthGovernorate` **مشتقّة من الرقم القومي server-side** وغير قابلة للتعديل إطلاقًا — لكن `lib/core/utils/egyptian_national_id_parser.dart` عندنا يحسبها محليًا. يبقى للعرض الفوري أثناء العمل بدون نت، والخادم هو الحكم النهائي.

### 1.3 اختلافات شكل البيانات

| القسم | الـ mock | العقد |
|---|---|---|
| السكن | `roomsCount: int?` | `roomsCount: String?` (نصّ، max 50) |
| السكن | `photos: List<String>` | **لا يوجد حقل صور في `PUT /housing`** — الصور مرفقات منفصلة |
| السكن | `wallsCondition`, `roofType`, `floorsType`, `housingLevel`, `socialWorkerNotes` | `walls`, `roof`, `floor`, `entrance`, `sanitation`, `electricity`, `water`, `waterMotor`, `internet`, `transport` — أسماء وحقول مختلفة كليًا |
| الأجهزة | `EquipmentItem{name, category, isPresent, count, condition, isUsable, notes}` | `appliances[{applianceKey, isPresent}]` — **حقلان فقط** |
| المصروفات | قائمة حرة `ExpenseItem` | **5 تصنيفات ثابتة بالحرف** لا تزيد ولا تنقص، وإلا 422 |
| الدخل | `IncomeItem` بـ 10 حقول | `{label, amount, period}` فقط للبنود اليدوية؛ البنود التلقائية server-owned |
| أفراد الأسرة | `birthDate`, `livesWithFamily`, `employer` | `isStudent`, `educationStage`, `grade`, `university`, `takafulBeneficiary`, `takafulAmount`, `sortOrder` |
| التصنيف/الزراعة | مصفوفات | **الاستجابة ترجع `mainClassificationsJson` و `selectedLivestockJson` كنصوص JSON** تحتاج `jsonDecode` يدوي |

**التصنيفات الخمسة الثابتة للمصروفات (بالحرف):**
`الأكل والشرب` · `المصروفات الدراسية` · `الكهرباء، المياه، الغاز` · `الإيجار` · `القسط`

بند سادس `إيجار الأراضي الزراعية` يُحسَب تلقائيًا ولا يُرسَل أبدًا من العميل.

### 1.4 تسجيل الدخول

الشاشة الحالية تطلب **اسم مستخدم** (`محمد أحمد`). العقد يطلب **email + password** مع `X-Client-Type: mobile`. يجب تغيير الحقل والـ validator.

### 1.5 الأخصائي لا يستطيع إنشاء حالة

`create_case` **غير ممنوحة** لـ `social_worker`. لو في الـ UI أي مسار "حالة جديدة" (موجود `CaseOrigin.socialWorker` في الموديل) فهو **غير قابل للتنفيذ** ويجب حذفه أو إخفاؤه.

### 1.6 بوابة الإكمال 100%

`POST /opinions/worker` مرفوض إن لم تكن نسبة الإكمال **100%** لكل الأقسام التسعة (`beneficiary, family_members, housing, utilities, agriculture, financial, initial_needs, classification, assessed_needs`). الحساب server-side ولا يُقلَّد محليًا — يُستخدم `GET /cases/{id}/completion` للتلميح فقط، والزر يبقى قابلًا للضغط والخادم هو الحكم.

`lib/features/case_details/domain/case_readiness.dart` و `incomplete_submit_dialog.dart` موجودان — يُعاد ربطهما بالـ endpoint.

---

## 2. المعمارية المستهدفة — Offline-First

### 2.1 المبدأ الحاكم

بما أن القرار هو **Offline كامل**، المعمارية تنقلب رأسًا على عقب عن التطبيق العادي:

> **قاعدة البيانات المحلية هي مصدر الحقيقة للواجهة. الشبكة مجرد آلية مزامنة في الخلفية.**

عمليًا:
- **لا شاشة تنتظر الشبكة أبدًا.** كل شاشة تقرأ من Drift عبر `Stream`، والشبكة تحدّث Drift فيتحدّث العرض تلقائيًا.
- **لا زرّ حفظ يفشل بسبب النت.** الحفظ يكتب محليًا ويضع عملية في الطابور، وينجح فورًا.
- **لا مؤشّر تحميل (spinner) على العمليات الكتابية** — يُستبدَل بحالة مزامنة على مستوى الحالة نفسها.

هذا هو الفرق بين "تطبيق يشتغل أوفلاين" و"تطبيق أوفلاين محترف". الأول يعرض رسالة خطأ ويحفظ في الذاكرة؛ الثاني لا يعرف الفرق أصلًا.

**نتيجة مباشرة:** لا يوجد "مرحلة online ثم نضيف offline" — لأن ذلك يعني إعادة كتابة كل repository لاحقًا. تُبنى صحيحة من أول سطر.

### 2.2 البنية

```
lib/core/
  network/
    api_client.dart              # Dio + baseUrl + X-Client-Type
    api_envelope.dart            # {success, data, error} → parse موحّد
    api_exception.dart           # ErrorCode enum من §8 (30 كود)
    interceptors/
      auth_interceptor.dart      # Bearer + refresh مُسلسَل (mutex واحد)
      idempotency_interceptor.dart
      error_interceptor.dart     # envelope → ApiException
  storage/
    secure_token_store.dart      # flutter_secure_storage — Keychain/Keystore
    app_database.dart            # Drift
    tables/
      cases_table.dart           # كاش الحالات + rowVersion + حالة المزامنة
      case_sections_table.dart   # الأقسام التسعة، كل قسم برقم نسخته
      field_visits_table.dart    # الزيارات + dedupId محلي
      pending_attachments_table.dart  # ملفات ملتقطة لم تُرفَع بعد
      sync_queue_table.dart      # طابور العمليات الدائم
  sync/
    sync_engine.dart             # المحرّك — ترتيب التفريغ وحدوده
    sync_queue.dart              # CRUD على الطابور
    operation.dart               # نموذج العملية (sealed class لكل نوع)
    conflict_resolver.dart       # منطق 409 والعرض على المستخدم
    connectivity_monitor.dart    # مراقبة الاتصال + إطلاق التفريغ
    attachment_uploader.dart     # init → PUT → commit مع استئناف
lib/features/*/data/
  *_offline_repository.dart      # يقرأ Drift، يكتب Drift + الطابور
  remote/*_api.dart              # استدعاءات الشبكة الخام (يستخدمها sync_engine فقط)
  dto/                           # DTOs مطابقة للعقد حرفيًا
  *_mapper.dart                  # DTO ⇄ Drift ⇄ domain
```

**نقطة معمارية مهمة:** الـ repository **لا يستدعي الشبكة مباشرة أبدًا**. يكتب في Drift ويضيف للطابور فقط. `SyncEngine` وحده يملك الشبكة. هذا يمنع أسوأ خطأ في تطبيقات الأوفلاين: مسارين للكتابة (واحد online وواحد offline) يتعارضان.

### 2.3 نموذج العملية في الطابور

```dart
sealed class SyncOperation {
  String get id;                  // معرّف محلي (UUID)
  String get caseId;              // للتجميع وإيقاف الطابور عند التعارض
  int get sequence;               // ترتيب الإنشاء داخل نفس الحالة
  String? get idempotencyKey;     // للمسارات التسع — يُولَّد مرة ولا يتغيّر
  String? get dedupId;            // للزيارات الميدانية تحديدًا
  int get attempts;
  String? get lastError;
  DateTime get createdAt;
  SyncOpStatus get status;        // pending | inFlight | failed | conflict | done
}
```

**قواعد الطابور:**
1. العمليات **مجمّعة حسب `caseId`**. تعارض في حالة لا يوقف مزامنة حالة أخرى.
2. داخل الحالة الواحدة الترتيب **صارم** بـ `sequence` — لا تفريغ متوازٍ.
3. `idempotencyKey` يُولَّد **لحظة ضغط المستخدم** ويُخزَّن مع العملية. لا يُعاد توليده أبدًا.
4. تعديلان على نفس القسم قبل المزامنة → **يُدمجان في عملية واحدة** (آخر قيمة تفوز محليًا). هذا يمنع تعارض `rowVersion` المؤكَّد مع الخادم.

### 2.4 حالة المزامنة المعروضة للمستخدم

`SyncStatusBadge` و `hasUnsyncedChanges` موجودان في الـ UI بالفعل — يُربَطان بحالة حقيقية:

| الحالة | المعنى للأخصائي | العرض |
|---|---|---|
| `synced` | كل شيء على الخادم | بدون علامة |
| `pendingSync` | محفوظ على الجهاز، بانتظار الشبكة | ⏳ "بانتظار المزامنة" |
| `syncing` | جارٍ الرفع الآن | 🔄 متحرّكة |
| `conflict` | تغيّر شيء على الخادم — يحتاج قرارك | ⚠️ **قابلة للضغط** → شاشة التعارض |
| `failed` | فشل لا يُحلّ بإعادة المحاولة | ❌ مع سبب واضح بالعربي |

**الصور:** لها شريط تقدّم منفصل لأنها الأثقل — الأخصائي يحتاج يعرف أن 3 صور من 7 رُفعت قبل ما يقفل التطبيق.

### 2.5 قواعد ثابتة

1. الـ DTO يطابق العقد **حرفيًا**. أي تجميل يحدث في الـ mapper فقط.
2. الـ domain models تبقى كما هي قدر الإمكان — الـ mapper يمتصّ الفرق.
3. الـ Mock repositories **لا تُحذف** — تبقى خلف flag للتطوير والاختبار.
4. **كل كتابة تمرّ بـ Drift أولًا.** لا استثناء.
5. **لا شاشة تعرض `CircularProgressIndicator` بانتظار الشبكة** في مسار كتابي.

---

## 3. المراحل

### المرحلة 0 — التهيئة ✅ **منجزة**
- [x] **إرسال طلبات التعديل للباك إند** (§7) — الحالات + `returnInfo` + الحقول الناقصة
- [x] `baseUrl` لبيئات dev/staging/prod عبر `--dart-define` → [`app_config.dart`](lib/core/config/app_config.dart)
- [x] إضافة الحزم: `dio`, `flutter_secure_storage`, `drift`+`drift_dev`, `drift_flutter`, `connectivity_plus`, `uuid`, `crypto`, `path_provider`, `path`, `build_runner`
- [ ] حساب اختبار `social_worker` فعلي + حالة تجريبية مُسنَدة إليه ← **مطلوب منك**
- [ ] **جهاز اختبار حقيقي** — محاكي الأوفلاين لا يكفي ← **مطلوب منك**
- [ ] `firebase_core` + `firebase_messaging` — مؤجّلة للمرحلة 8 (تحتاج ملفات إعداد Firebase)

> **ملاحظة توافق:** `drift` مثبّتة على `^2.34.0` لا الأحدث، لأن `2.35+` تتطلب `meta ^1.18` بينما Flutter 3.41.9 يثبّت `meta 1.17.0`. تُرفَع عند ترقية Flutter.

### المرحلة 1 — نواة الشبكة ✅ **منجزة**
- [x] `ApiClient` على Dio + `X-Client-Type: mobile` على login/refresh/logout → [`api_client.dart`](lib/core/network/api_client.dart)
- [x] `ApiEnvelope` — parsing موحّد. `validateStatus` يقبل كل ما دون 500 فيُفَك الغلاف يدويًا حتى لـ 404 و 429 → [`api_envelope.dart`](lib/core/network/api_envelope.dart)
- [x] `ApiException` + `ApiErrorCode` بكل أكواد §8 + 3 أكواد محلية (`offline`, `timeout`, `unknown`) → [`api_error_code.dart`](lib/core/network/api_error_code.dart)
- [x] تصنيف الأكواد: `isRetryable` / `isConflict` / `requiresReauth` — يقود قرارات محرّك المزامنة
- [x] `error.details` كـ `Map<String, List<String>>`، **غائب** لا null
- [x] `fieldError()` غير حسّاس لحالة الأحرف — يعالج PascalCase الخاص بالبحث
- [x] `Paged<T>` بكل حقول §4 + تحمّل الاستجابات الناقصة
- [x] **19 اختبارًا** → [`api_envelope_test.dart`](test/core/api_envelope_test.dart)

### المرحلة 1.5 — قاعدة البيانات المحلية والطابور ✅ **منجزة**

سبقت المصادقة عمدًا: بناء الـ repositories على الشبكة أولًا يعني إعادة كتابتها بالكامل.

- [x] مخطط Drift بـ 7 جداول → [`sync_tables.dart`](lib/core/storage/tables/sync_tables.dart)
  `sync_queue`, `cached_cases`, `cached_sections`, `local_field_visits`, `pending_attachments`, `dropdown_cache`, `cached_notifications`
- [x] كل جدول قابل للكتابة يحمل `rowVersion` + `syncState` + `localUpdatedAt` / `serverUpdatedAt`
- [x] فصل `rowVersion` (الحالة) عن `beneficiaryRowVersion` — عدّادان مستقلان كما ينصّ §19
- [x] `SyncOperationType` بـ 22 نوعًا + `flushPriority` يفرض ترتيب §16.4 → [`sync_operation.dart`](lib/core/sync/sync_operation.dart)
- [x] `SyncQueueDao` — إضافة/قراءة/فشل/حلّ تعارض → [`sync_queue.dart`](lib/core/sync/sync_queue.dart)
- [x] **دمج تعديلات القسم المتتالية** — يمنع تعارض `rowVersion` نصنعه بأنفسنا
- [x] `idempotencyKey` يُولَّد **مرة واحدة** عند الإضافة ولا يتغيّر
- [x] `dedupId` تلقائي للزيارات الميدانية + رفض الإضافة المكرّرة
- [x] تصنيف الفشل: تعارض ← `conflict` · غير قابل للإعادة ← `dead_lettered` · شبكة ← `failed` بتباعد أسّي (1د→6س)
- [x] **عزل التعارضات** — `hasBlockingOperation(caseId)` يمنع حالة متعثّرة من تعطيل غيرها
- [x] **لا حذف تلقائي** لعملية فاشلة — `discard()` بقرار المستخدم وحده
- [x] `ConnectivityMonitor` + `onRestored` كمحفّز تفريغ → [`connectivity_monitor.dart`](lib/core/sync/connectivity_monitor.dart)
- [x] **24 اختبارًا** → [`sync_queue_test.dart`](test/core/sync_queue_test.dart)
- [ ] `WorkManager` — تفريغ في الخلفية والتطبيق مغلق (يُضاف مع محرّك المزامنة، المرحلة 7)

### المرحلة 2 — المصادقة ✅ **منجزة**
- [x] `POST /auth/login` بـ email — شاشة الدخول الوهمية استُبدلت → [`login_screen.dart`](lib/features/auth/presentation/login_screen.dart)
- [x] تخزين التوكنات في `flutter_secure_storage` **فقط** → [`secure_token_store.dart`](lib/core/storage/secure_token_store.dart)
- [x] `AuthInterceptor`: 401 → محاولة refresh واحدة → فشل = خروج → [`auth_interceptor.dart`](lib/core/network/interceptors/auth_interceptor.dart)
- [x] **403 لا يُعالَج بـ refresh** — الشرط صريح في `onError`
- [x] Refresh **مُسلسَل عبر `Future` واحد مشترك** (`_refreshInFlight`) + `QueuedInterceptor`
- [x] تخزين **التوكن الأحدث فقط** — لا نسخة قديمة تُستخدَم بالخطأ
- [x] تحديث استباقي قبل انتهاء الصلاحية بـ 60 ثانية — أرخص من فشل ثم إعادة
- [x] عميل `refreshClient` منفصل بلا `AuthInterceptor` — يمنع التكرار اللانهائي
- [x] رسائل عربية لـ `PLATFORM_NOT_ALLOWED` و `ACCOUNT_LOCKED` و `RATE_LIMITED` و `offline`
- [x] `GET /auth/me` عند الإقلاع
- [x] **جلسة تعمل بدون نت** — فشل `/auth/me` بسبب الشبكة **لا يُنهي الجلسة**؛ فقط رفض صريح (401/403) يفعل
- [x] `AuthController` + `AppRoot` يراقب الحالة — لا `Navigator` يدوي → [`app_root.dart`](lib/core/routing/app_root.dart)
- [x] `isReauthSoon()` جاهزة لتحذير انتهاء الصلاحية
- [ ] عرض تحذير انتهاء الصلاحية في الواجهة (المنطق جاهز، تبقّى العرض)
- [ ] ~~`go_router`~~ — `AppRoot` بـ `AnimatedSwitcher` كافٍ حاليًا؛ يُفعَّل عند الحاجة لروابط عميقة من الإشعارات (المرحلة 8)

> **تغيير سلوك مقصود:** حُذف خيار "تذكرني" — الجلسة تُحفَظ دائمًا. الأخصائي يعمل أيامًا في الميدان ولا يُطلب منه الدخول كل مرة. كما حُذف اختبار الدخول الوهمي القديم واستُبدل بثلاثة اختبارات تحقن وحدة تحكّم مزيّفة.

### المرحلة 3 — القراءة (كاش أولًا) ✅ **منجزة**

كل استدعاء يكتب في Drift، والشاشة تقرأ من Drift عبر `Stream` — لا تنتظر الشبكة.

- [x] `GET /dashboard/work-queue` → [`cases_api.dart`](lib/features/cases/data/cases_api.dart) مع ضمان `page ≥ 1` و `limit ≤ 100` قبل الإرسال (هذا المسار يرجع 422 لا يقصّ بصمت)
- [x] `GET /dashboard/stats` → `Map<String,int>` مرن لأن الشكل يختلف حسب الدور
- [x] `GET /cases` بفلتري `status` و `bookmarked` فقط — لا فلاتر مخترَعة
- [x] `GET /cases/{id}` → [`case_details_dto.dart`](lib/features/cases/data/dto/case_details_dto.dart) بفصل صريح بين `rowVersion` و `beneficiary.rowVersion`
- [x] `GET /cases/{id}/completion` → أسماء عربية للأقسام الناقصة
- [x] `GET /cases/{id}/family-members`
- [x] `GET /search/cases` بـ `national_id` snake_case
- [x] `GET /locations` + `GET /charities` + `GET /dropdowns/{key}` → [`reference_api.dart`](lib/features/reference/data/reference_api.dart)
- [x] ⚠️ **كاش القوائم المنسدلة إجباري** → [`reference_repository.dart`](lib/features/reference/data/reference_repository.dart) — يتجاهل مفتاحًا غير مُعرَّف (404) ويُكمل الباقي بدل الفشل الكلّي
- [x] **التحميل المسبق** — `prefetchForFieldWork` يجلب تفاصيل كل حالات الطابور كاملة
- [x] زرّ "تحضير للعمل الميداني" بمؤشّر تقدّم → [`sync_status_screen.dart`](lib/features/sync/presentation/sync_status_screen.dart)
- [x] `CaseStatusMapper` — طبقة عزل تحوّل الحالات العشر إلى السبع المعروضة → [`case_status_mapper.dart`](lib/features/cases/data/case_status_mapper.dart)
- [x] ربط الشاشة الرئيسية بالكاش → [`home_providers.dart`](lib/features/home/presentation/home_providers.dart)
- [x] `StartupService` — ترتيب مُلزَم: تعافي الزيارات ← البيانات المرجعية ← طابور العمل → [`startup_service.dart`](lib/core/sync/startup_service.dart)
- [x] شريط حالة المزامنة + شاشة حالة المزامنة + تحذير الخروج بعمل غير مرفوع
- [x] **15 اختبارًا** → [`cases_repository_test.dart`](test/core/cases_repository_test.dart)
- [ ] `GET /notifications` → مؤجّلة للمرحلة 8 مع FCM

> **تغييران مقصودان في الواجهة:**
> 1. **حُذف زرّ "حالة جديدة"** من الشاشة الرئيسية — صلاحية `create_case` غير ممنوحة للأخصائي (§7.1)، فالمسار كان يؤدي حتمًا إلى 403.
> 2. **تسجيل الخروج صار محروسًا** — يحذّر برقم صريح للتغييرات غير المرفوعة، لأن الخروج يمسح التوكنات فيتعذّر تفريغ الطابور بعدها.

### المرحلة 6 — الزيارات والمرفقات 🔵 **الطبقة الخلفية منجزة**

- [x] `POST /cases/{id}/field-visits` → [`field_visits_api.dart`](lib/features/field_visits/data/field_visits_api.dart)
- [x] **ضمان المرة الواحدة ثلاثي** → [`field_visits_repository.dart`](lib/features/field_visits/data/field_visits_repository.dart):
  `dedupId` دائم · تعليم `syncing` **قبل** الإرسال ويُحفَظ · `reconcileStuckVisits()` يطابق مع الخادم عند الإقلاع
- [x] **فشل الشبكة ≠ فشل العملية** — النتيجة تُعامَل **مجهولة** لا فاشلة؛ لا إعادة إرسال قبل التحقق
- [x] تعذّر التحقق → **لا إرسال**. زيارة متأخرة أهون من زيارة مكررة في سجل رسمي
- [x] الإحداثيات معًا أو لا شيء — تُسقَط الناقصة عند الإنشاء لا عند الإرسال
- [x] `PUT /field-visits/{id}` و `PUT /cases/{id}/field-verification`
- [x] المرفقات بـ 3 خطوات مع **استئناف من آخر مرحلة** → [`attachment_uploader.dart`](lib/features/attachments/data/attachment_uploader.dart)
- [x] **نسخ الملف لمجلد دائم فور الالتقاط** — مسار الكاميرا مؤقت
- [x] **فحص الحجم والنوع وقت الالتقاط** لا وقت الرفع
- [x] رابط الرفع **٣٠ دقيقة** (لا ١٥ كما ظننّا أولًا) + هامش دقيقة قبل الانتهاء
- [x] `commit` يُعاد بأمان (`alreadyComplete`) · `init` لا يُعاد
- [x] رفع على دفعات (٢ متوازية) احترامًا لحدّ المعدّل
- [x] `cleanUpCommittedFiles()` لتحرير مساحة الجهاز
- [x] **32 اختبارًا** → [`attachment_policy_test.dart`](test/core/attachment_policy_test.dart) + [`field_visit_dedup_test.dart`](test/core/field_visit_dedup_test.dart)
- [ ] شاشات الالتقاط والزيارة (الواجهة) — الطبقة الخلفية جاهزة

### المرحلة 4 — الكتابة والتزامن (rowVersion)
- [ ] `rowVersion` / `caseRowVersion` في **كل** موديل قابل للكتابة
- [ ] الأقسام المفردة (`beneficiary`, `housing`, `agriculture`, `classification`) → `rowVersion`
  - `beneficiary.rowVersion` **غير قابل للـ null** (الصف موجود دائمًا)
  - الباقي **قابل للـ null** — يُرسَل `null` في أول حفظ
- [ ] أقسام القوائم (`family-members`, `utilities`, `initial-needs`, `assessed-needs`, `financial`) → `caseRowVersion` غير قابل للـ null
- [ ] **استبدال كامل:** حذف عنصر من المصفوفة = حذفه من الخادم
- [ ] تحديث `rowVersion` من **استجابة** كل PUT (القيمة الجديدة بعد الزيادة)
- [ ] **مصيدة حقيقية:** تعديل `beneficiary`/`agriculture`/`family-members` يُعيد حساب الملخص المالي ويزيد `rowVersion` الحالة — فـ `caseRowVersion` المخزّن لـ `/financial` يبطل بصمت. يُعاد الجلب قبل الحفظ المالي
- [ ] `jsonDecode` لـ `mainClassificationsJson` و `selectedLivestockJson`
- [ ] المسح التلقائي server-side في الزراعة: `hasLand != "yes"` يمسح كل حقول الأرض؛ `تمليك` يمسح `landRentAmount`؛ `إيجار` يمسح `annualLandIncome`. الواجهة تعكس الاستجابة لا مدخلات المستخدم
- [ ] `livestockOther` **إلزامي** حين يحتوي `selectedLivestock` على `"other"`
- [ ] `409 CONCURRENCY_CONFLICT` → شاشة تعارض: إعادة جلب + عرض الفرق + قرار المستخدم. **لا دمج تلقائي ولا كتابة فوقية**

### المرحلة 5 — سير العمل (Idempotency-Key)
- [ ] `IdempotencyInterceptor` — يقرأ المفتاح من الطلب، لا يولّده
- [ ] **المفتاح يُولَّد مرة واحدة عند ضغط المستخدم، ويُخزَّن مع العملية، ويُعاد استخدامه في كل محاولة** حتى النجاح. مفتاح جديد لكل محاولة = تنفيذ مزدوج
- [ ] الاستجابة الأولى مُخزَّنة 24 ساعة server-side بمفتاح `(key, userId)`
- [ ] `POST /cases/{id}/accept` — مساران خلف endpoint واحد:
  - قبول إسناد (`assigned` + أنت المُسنَد إليه)
  - **قبول ذاتي** (`pending_assignment` بلا مُسنَد إليه — أي أخصائي يأخذها ويصبح المُسنَد إليه)
  - كلاهما نفس اسم الإجراء `accept_assignment`؛ الخادم يقرر
  - سباق القبول الذاتي: الخاسر يحصل على **`409` أو `422` — غير محدَّد أيهما**، تُعالَج الحالتان
- [ ] `POST /cases/{id}/reject-assignment` — `reason` **اختياري** (max 1000)
- [ ] `POST /cases/{id}/opinions/worker` — `decision: accepted|rejected`, `notes` (max 2000)
  - بوابة الإكمال 100% (§1.6)
  - `403 SOCIAL_WORKER_WEB_BLOCKED` لو `client_type` ليس mobile
- [ ] `403 FORBIDDEN` عند "غير مُسنَدة إليك" — **ليس 404**، الحالة مرئية لكن غير قابلة للتعديل
- [ ] `availableActions` **تلميح UX فقط** — كل endpoint يعيد التحقق مستقلًا. لا يُعتمد عليها كتفويض

### المرحلة 6 — الزيارات الميدانية والمرفقات ⚠️ **قلب التطبيق الميداني**

هذه المرحلة هي أخطر ما في المشروع: الزيارة تُسجَّل في الميدان بلا نت، وأخطر endpoint في العقد بلا حماية من التكرار.

**الزيارة الميدانية:**
- [ ] `POST /cases/{id}/field-visits` — **لا `Idempotency-Key`، لا حماية من التكرار server-side**
  - **`dedupId` محلي دائم (UUID) يُولَّد لحظة إنشاء الزيارة في Drift ويُفحَص قبل الإرسال، لا بعده**
  - **العملية تُعلَّم `inFlight` قبل الإرسال وتُحفَظ في Drift.** لو مات التطبيق أثناء الإرسال، عند الإقلاع نجد `inFlight` → **لا نُعيد الإرسال أعمى**، بل نجلب زيارات الحالة ونطابق بالتاريخ/الوقت قبل القرار
  - `latitude`/`longitude` **معًا أو لا شيء** — لو GPS فشل، تُرسَل بدونهما لا بنصفهما
  - **GPS أوفلاين يعمل** (لا يحتاج نت) — يُلتقط ويُخزَّن وقت الزيارة الحقيقي
  - `photoAttachmentIds` تشير لمرفقات **مُثبَّتة (committed)** — فالصور تُرفَع **قبل** الزيارة في ترتيب التفريغ
  - مسموح فقط في `in_research` أو `returned_to_worker`
- [ ] `PUT /field-visits/{id}` — زياراتك أنت فقط؛ زيارة غيرك ترجع **404** (لا تمييز)
- [ ] `PUT /cases/{id}/field-verification` — استبدال كامل. تُرسَل `fieldLabel`, `verifiedValue`, `differenceReason` فقط؛ الخادم يحسب `originalValue`/`isDifferent`. `differenceReason` مطلوب فقط عند وجود فرق فعلي

**المرفقات — 3 خطوات مع استئناف:**
- [ ] `init` → `PUT` للبايتات على `uploadUrl` → `commit`
- [ ] **الصورة تُنسَخ لمجلد دائم للتطبيق فور التقاطها** — لا يُعتمد على مسار الكاميرا المؤقّت، نظام التشغيل يمسحه
- [ ] **`/init` لا يُستدعى إلا والجهاز متصل** — تجنّبًا لحرق نافذة الـ 48 ساعة على اتصال غير موجود
- [ ] حالة الرفع في Drift: `captured → initialized → uploading → uploaded → committed`. الاستئناف يبدأ من آخر حالة، لا من الصفر
- [ ] `uploadUrlExpiresAtUtc` منتهٍ → `/init` جديد (ويُقبَل المرفق اليتيم كثمن)
- [ ] **`Content-Type` يطابق `mimeType` المُرجَع بالضبط**
- [ ] حد **10 ميجا** — **يُفحَص محليًا وقت الالتقاط لا وقت الرفع.** رفض صورة بعد يومين في الميدان كارثة
- [ ] **ضغط الصور قبل التخزين** — صور الكاميرا تتجاوز 10 ميجا بسهولة، والأخصائي على بيانات موبايل
- [ ] الأنواع: jpeg, png, heic, webp, pdf, doc, docx — **يُفحَص بالـ magic bytes لا بالامتداد**
- [ ] `commit` **قابل لإعادة المحاولة بأمان** (`alreadyComplete: true`) — الكتابة الوحيدة الآمنة بلا مفتاح
- [ ] `init` **غير idempotent** — إعادة استدعائه تُنتج مرفقًا يتيمًا. يُعاد المحاولة على الرفع/التثبيت بنفس `attachmentId`
- [ ] رابط التحميل صالح **15 دقيقة** — لا يُخزَّن ولا يُعاد استخدامه
- [ ] `/init` عليه rate limit — **الرفع على دفعات (2–3 متوازية بحد أقصى)** لا دفعة واحدة
- [ ] **الرفع يحترم نوع الشبكة** — خيار "الصور على Wi-Fi فقط" (افتراضيًا مفعّل)

### المرحلة 7 — محرّك المزامنة وحلّ التعارضات

البنية بُنيت في 1.5؛ هنا يُكتَب المنطق. الباك إند **لا يقدّم أي دعم**: لا batch، لا delta feed، لا حل تعارضات.

- [ ] **ترتيب التفريغ الإلزامي** (لكل حالة على حدة):
  1. **فحص المصادقة مرة واحدة للطابور كله** — لا لكل عنصر. refresh token منتهٍ = تسجيل دخول قبل أي شيء
  2. رفع المرفقات المعلّقة بالكامل حتى `committed`
  3. `GET /cases/{id}` — تحديث `rowVersion` والحالة **قبل** أي كتابة
  4. الزيارات الميدانية (مرة واحدة بالضبط — `dedupId`)
  5. تعديلات الأقسام مقابل `rowVersion` الطازج
  6. رأي الأخصائي **أخيرًا**، بمفتاحه الأصلي
- [ ] **حدود الفشل:**
  - `409` / `422 INVALID_STATUS_TRANSITION` / `403` → **يتوقّف تفريغ باقي طابور تلك الحالة فقط**، وتُعلَّم `conflict`. الحالات الأخرى تُكمل
  - `422 VALIDATION_ERROR` → لا تُعاد المحاولة أبدًا (لن تنجح) → `failed` مع الرسالة العربية
  - خطأ شبكة / `503` → إعادة محاولة بتباعد أسّي (1د، 5د، 15د، ساعة، سقف 6 ساعات)
  - `401` → refresh مرة واحدة ثم متابعة التفريغ؛ فشله يوقف كل شيء لحين تسجيل الدخول
- [ ] **شاشة التعارض** — أهم شاشة في النظام:
  - جدول مقارنة: قيمتك ↔ قيمة الخادم، حقلًا بحقل
  - ثلاثة خيارات لكل حقل: احتفظ بقيمتي / خذ قيمة الخادم / ادمج
  - **لا دمج تلقائي ولا كتابة فوقية صامتة إطلاقًا**
  - "الحالة لم تعد مُسنَدة إليك" تُعرَض بوضوح مع إتاحة **تصدير عملك** قبل التخلّي عنه
- [ ] **حماية من فقد العمل:** عملية `failed` أو `conflict` **لا تُحذَف تلقائيًا أبدًا**. تبقى حتى يقرّر المستخدم
- [ ] ربط `SyncStatusBadge` و `hasUnsyncedChanges` بالحالة الحقيقية (§2.4)
- [ ] **شاشة "حالة المزامنة"** في القائمة: كم عملية معلّقة، كم صورة، آخر مزامنة ناجحة، زرّ "زامن الآن"
- [ ] **تحذير عند تسجيل الخروج والطابور غير فارغ** — "لديك 12 تغييرًا لم يُرفَع. الخروج الآن قد يفقدها."

### المرحلة 7.5 — اختبارات الأوفلاين (بوابة إطلاق)

لا يُطلَق التطبيق بدون اجتياز هذه، وكلها على **جهاز حقيقي**:

- [ ] ملء حالة كاملة (9 أقسام) + 7 صور + زيارة ميدانية، **وضع الطيران مفعّل طوال الوقت**، ثم تشغيل الشبكة → كل شيء يصل مرة واحدة بالضبط
- [ ] قتل التطبيق أثناء رفع صورة → الاستئناف لا يُعيد من الصفر ولا يُنتج مرفقًا مكررًا
- [ ] قتل التطبيق أثناء `POST /field-visits` → **لا زيارة مكررة** عند الإقلاع
- [ ] نت متقطّع (يظهر ويختفي كل 10 ثوانٍ) أثناء التفريغ → لا فساد بيانات
- [ ] تعديل نفس الحالة من الويب أثناء عمل الأخصائي أوفلاين → شاشة تعارض صحيحة
- [ ] إرجاع الحالة من المراجع أثناء عمل الأخصائي أوفلاين → رسالة واضحة، لا تكرار محاولات
- [ ] طابور عمره 8 أيام (refresh token منتهٍ) → تسجيل دخول ثم تفريغ سليم
- [ ] امتلاء مساحة الجهاز أثناء التقاط الصور → رسالة واضحة لا انهيار

### المرحلة 8 — الإشعارات
- [ ] Firebase + `POST /notifications/device-tokens` (`platform`: `android`|`ios` بالضبط، حساس لحالة الأحرف؛ `token` 10–512 حرفًا)
- [ ] **يُسجَّل بعد كل تسجيل دخول، وعند كل استئناف للتطبيق، وعند كل token refresh من النظام** — الخادم لا يجلبه
- [ ] لا يوجد endpoint لإلغاء التسجيل — تسجيل الخروج لا يُلغي التوكن
- [ ] `PUT /notifications/{id}/read` و `mark-all-read` — كلاهما idempotent
- [ ] فتح الإشعار → `caseId` → شاشة الحالة

### المرحلة 9 — التشطيب
- [ ] `PUT /profile`
- [ ] `POST`/`DELETE /cases/{id}/bookmark` (idempotent، بلا rowVersion)
- [ ] `GET /cases/{id}/support`
- [ ] `PUT /cases/{id}/support-recommendations`
- [ ] الخط الزمني والمراجعات من بيانات الحالة الحقيقية
- [ ] حذف/إخفاء مسارات: إنشاء حالة، رأي المراجع، اعتماد المدير — كلها **403** لهذا الدور

---

## 4. مصائد مؤكَّدة من العقد

1. **`page<=0` يرجع 422 في `work-queue` و `notifications`، ويُقَصّ بصمت في `search` و `attachments`.** لا pagination hook موحّد بلا معالجة.
2. **`beneficiary.rowVersion` ≠ `rowVersion` الحالة.** عدّادان مستقلان على صفّين مختلفين.
3. **`caseRowVersion` يبطل بصمت** بعد تعديل قسم آخر يُشغّل إعادة الحساب المالي.
4. **`selectedLivestockJson` و `mainClassificationsJson`** نصوص JSON في الاستجابة، مصفوفات في الطلب.
5. **`landType`** قيمتان عربيتان حرفيتان فقط: `تمليك` أو `إيجار`.
6. **تصنيفات المصروفات الخمسة** بالحرف، لا زيادة ولا نقصان.
7. **`details` في أخطاء البحث PascalCase** (`NationalId`) لا snake_case.
8. **الرجوع من المراجع والمدير يُنتجان نفس الحالة** — طُلب من الباك إند حقل `returnInfo` للتمييز (§7).
9. **`403` ≠ مشكلة توكن.** أبدًا لا refresh عليه.
10. **`POST /field-visits` بلا حماية تكرار.** أخطر endpoint في التطبيق.
11. **`roomsCount` نصّ** لا رقم.
12. **الرؤية عامة، التعديل مقيّد.** الأخصائي يرى كل الحالات ويعدّل المُسنَدة إليه فقط.
13. **انحراف ساعة الجهاز** يسبب 401 مبكرًا (السماحية 30 ثانية).
14. **لا يوجد delta feed.** كل مزامنة تُعيد جلب الحالة كاملة — يُحسَب لحجم البيانات على شبكة الموبايل.

---

## 5. الترتيب

| # | المرحلة | الحالة | يحتاج ردّ الباك إند؟ |
|---|---|:---:|:---:|
| 1 | 0 — التهيئة | ✅ | — |
| 2 | 1 — نواة الشبكة | ✅ | لا |
| 3 | **1.5 — قاعدة البيانات والطابور** | ✅ | لا |
| 4 | 2 — المصادقة | ✅ | لا |
| 5 | 3 — القراءة + التحميل المسبق | ✅ | لا |
| 6 | 6 — الزيارات والمرفقات | 🔵 الخلفية ✅ / الواجهة ⬜ | لا |
| 7 | 4 — الكتابة + rowVersion | ⬜ | **جزئيًا** — تبويب البيانات الأساسية ينتظر الحقول |
| 8 | 5 — سير العمل | ⬜ | **نعم** — شاشة الإرجاع تنتظر `returnInfo` |
| 9 | 7 — محرّك المزامنة | ⬜ | لا |
| 10 | 8 — الإشعارات (FCM) | ⬜ | لا *(يحتاج ملفات Firebase)* |
| 11 | 7.5 — اختبارات الأوفلاين | ⬜ | لا *(يحتاج جهازًا حقيقيًا)* |
| 12 | 9 — التشطيب | ⬜ | — |

**الحالة: 114 اختبارًا ناجحًا · صفر أخطاء تحليل · APK يُبنى بنجاح.**

**تغيّر جوهري عن النسخة الأولى:** الأوفلاين لم يعد مرحلة متأخّرة. قاعدة البيانات المحلية (1.5) تسبق كل شيء، لأن بناء repositories على الشبكة أولًا يعني إعادة كتابتها بالكامل.

**المراحل 1 → 3 و 8 لا تنتظر أحدًا** — يمكن البدء فورًا. الانتظار يبدأ عند المرحلة 4.

---

## 6. المخاطر

| الخطر | الأثر | التخفيف |
|---|---|---|
| **تأخّر ردّ الباك إند** | توقّف المراحل 4/5 | البدء بـ 1 → 1.5 → 2 → 3 → 8 فورًا (لا تعتمد على الردّ) |
| **رفض الباك إند لـ `returnInfo`** | لا تمييز لمصدر الإرجاع | خطة بديلة: الاشتقاق من الـ Timeline — يعمل بالعقد الحالي |
| **رفض إضافة الحقول الناقصة** | تعارض مع النموذج الورقي | قرار من صاحب المنتج: حذفها من الشاشة أم تخزينها في `notes` |
| **`POST /field-visits` بلا حماية** | زيارات مكررة في قاعدة البيانات | `dedupId` + `inFlight` + مطابقة عند الإقلاع (§م6) |
| **فقد عمل الأخصائي** | كارثة تشغيلية وثقة | لا حذف تلقائي لعملية فاشلة + نسخ الصور لمجلد دائم + تحذير الخروج |
| **امتلاء مساحة الجهاز** | فشل التقاط الصور | ضغط الصور + مراقبة المساحة + تنظيف المرفقات المرفوعة |

---

## 7. طلبات التعديل المُرسَلة للباك إند

**الحالة: مُرسَلة — بانتظار الردّ.** النصّ الكامل في [`BACKEND_CHANGE_REQUEST.md`](BACKEND_CHANGE_REQUEST.md).

| # | الطلب | يُعطّل |
|---|---|---|
| 1 | إضافة `returnInfo` لتمييز الإرجاع (مراجع/مدير) | شاشة الإرجاع — المرحلة 5 |
| 2 | تأكيد ناتج `return-for-completion` على `status` | المرحلة 5 |
| 3 | إضافة 8 حقول للمستفيد (`email`, `street`, `buildingNumber`, `floor`, `apartmentNumber`, `landmark`, `employer`, `area`) | تبويب البيانات الأساسية — المرحلة 4 |
| 4 | `Idempotency-Key` على `POST /field-visits` | لا يُعطّل (لدينا حلّ محلي) لكنه يقلّل الخطر جوهريًا |
| 5 | توحيد سلوك الـ pagination | لا يُعطّل — تحسين |
| 6 | `selectedLivestock` / `mainClassifications` كمصفوفات في الاستجابة | لا يُعطّل — تحسين |
