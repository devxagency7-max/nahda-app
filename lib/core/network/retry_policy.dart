import 'api_exception.dart';

/// إعادة محاولة قصيرة ومحدودة لطلب أونلاين مباشر — **منفصلة تمامًا** عن
/// الـ backoff الطويل في `sync_queue` (دقيقة → ٦ ساعات)، والذي يظل خاصًا
/// بتعافي الأوفلاين فقط.
///
/// الهدف هنا مختلف: طلب صدر ونحن نعتقد أننا أونلاين لكنه فشل بعطل شبكة
/// عابر (hiccup) — لا ننتظر ساعات، بل نحاول ٣ مرات خلال ثوانٍ معدودة ثم
/// نستسلم فورًا لمسار fallback (Drift) أو نُظهر الخطأ.
class RetryPolicy {
  const RetryPolicy._();

  static const List<Duration> _delays = [
    Duration(milliseconds: 500),
    Duration(milliseconds: 1500),
  ];

  /// ينفّذ [request] حتى ٣ محاولات إجمالًا. يُعيد المحاولة فقط عند خطأ
  /// شبكة قابل لإعادة المحاولة (`ApiErrorCode.isRetryable`) — خطأ عمل/تحقق
  /// (400/401/403/404/422) يُرمى فورًا بلا إعادة محاولة، لأنه ليس عطلًا
  /// عابرًا سيُصلحه الانتظار.
  static Future<T> run<T>(Future<T> Function() request) async {
    for (var attempt = 0; ; attempt++) {
      try {
        return await request();
      } on ApiException catch (e) {
        final isLastAttempt = attempt >= _delays.length;
        if (!e.isRetryable || isLastAttempt) rethrow;
        await Future<void>.delayed(_delays[attempt]);
      }
    }
  }
}
