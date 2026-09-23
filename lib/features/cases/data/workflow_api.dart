import '../../../core/network/api_client.dart';

/// استدعاءات مسارات سير العمل القابلة للوصول من دور `social_worker` — §20.
///
/// **تُستدعى من `SyncEngine` فقط**، كباقي طبقة `*_api.dart` (§2.2 من خطة
/// الربط). الثلاثة المسارات هنا فقط يصل إليها هذا التطبيق فعليًا؛ الباقي
/// (`assign`, `opinions/reviewer`, `return-to-worker`, `opinions/manager`,
/// `return-for-completion`) يرجع `403` لهذا الدور ولا داعي لتنفيذه هنا.
///
/// **كل التسعة مسارات في هذه العائلة تتطلب `Idempotency-Key`** (§6) — يُولَّد
/// مرة واحدة لحظة ضغط المستخدم في `sync_queue.enqueue` ويُعاد استخدامه في كل
/// محاولة حتى النجاح؛ هذا الصنف لا يولّد مفاتيح، يمرّرها فقط.
class WorkflowApi {
  const WorkflowApi(this._client);

  final ApiClient _client;

  /// `POST /cases/{id}/accept` — يغطّي كلا من AcceptAssignment (حالة
  /// `assigned` مُسنَدة لك) و SelfAcceptCase (حالة `pending_assignment` غير
  /// مُسنَدة، أي أخصائي يقدر يقبلها) — الخادم يقرر أيهما، لا فرق من هنا.
  ///
  /// الجسم: `{ "caseRowVersion": <uint> }`.
  Future<Map<String, dynamic>> accept(
    String caseId,
    Map<String, dynamic> payload, {
    required String idempotencyKey,
  }) => _client.post<Map<String, dynamic>>(
    '/cases/$caseId/accept',
    Parse.object,
    body: payload,
    idempotencyKey: idempotencyKey,
  );

  /// `POST /cases/{id}/reject-assignment` — يفرغ الإسناد ويعيد الحالة لـ
  /// `pending_assignment` (وتصبح قابلة لـ self-accept من أخصائي آخر).
  ///
  /// الجسم: `{ "reason": <string?>, "caseRowVersion": <uint> }` — `reason`
  /// اختياري هنا (بعكس `return-to-worker` الذي يُلزمه الخادم).
  Future<Map<String, dynamic>> rejectAssignment(
    String caseId,
    Map<String, dynamic> payload, {
    required String idempotencyKey,
  }) => _client.post<Map<String, dynamic>>(
    '/cases/$caseId/reject-assignment',
    Parse.object,
    body: payload,
    idempotencyKey: idempotencyKey,
  );

  /// `POST /cases/{id}/opinions/worker` — رأي الأخصائي، ينقل الحالة لـ
  /// `pending_review`.
  ///
  /// الجسم: `{ "decision": "accepted"|"rejected", "notes": string?,
  /// "caseRowVersion": uint }`.
  ///
  /// **بوابة الإكمال ١٠٠٪ يفرضها الخادم دائمًا** — لا تُقلَّد محليًا، فقط
  /// تُستخدم كتلميح لتعطيل الزر (§20، الملاحظة على هذا المسار).
  Future<Map<String, dynamic>> submitWorkerOpinion(
    String caseId,
    Map<String, dynamic> payload, {
    required String idempotencyKey,
  }) => _client.post<Map<String, dynamic>>(
    '/cases/$caseId/opinions/worker',
    Parse.object,
    body: payload,
    idempotencyKey: idempotencyKey,
  );
}
