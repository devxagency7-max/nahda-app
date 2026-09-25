import 'package:dio/dio.dart';

/// مفتاح يُمرَّر في `options.extra` ليصبح ترويسة `Idempotency-Key`.
const kIdempotencyKey = 'idempotencyKey';

/// يحوّل `extra[kIdempotencyKey]` إلى ترويسة HTTP.
///
/// **لا يولّد المفتاح إطلاقًا** — وهذا هو بيت القصيد (§14.1، §15.3):
/// المفتاح يُولَّد مرة واحدة لحظة ضغط المستخدم على الإجراء، ويُخزَّن في طابور
/// المزامنة بجوار العملية، ويُعاد استخدامه في **كل** محاولة حتى النجاح.
///
/// توليد مفتاح جديد لكل محاولة يُبطل الآلية من أساسها ويعرّضنا لتنفيذ مزدوج —
/// مثل إرسال رأي الأخصائي مرتين بعد أن تكون الحالة قد تحرّكت أصلًا.
///
/// المسارات التي تتطلبه (§6): `assign`, `accept`, `reject-assignment`,
/// `opinions/worker`, `opinions/reviewer`, `return-to-worker`,
/// `opinions/manager`, `return-for-completion`.
class IdempotencyInterceptor extends Interceptor {
  const IdempotencyInterceptor();

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    final key = options.extra[kIdempotencyKey];
    if (key is String && key.isNotEmpty) {
      options.headers['Idempotency-Key'] = key;
    }
    handler.next(options);
  }
}
