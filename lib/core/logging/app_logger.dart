import 'dart:developer' as developer;

/// نقطة تسجيل مركزية واحدة — بديل عن `print`/`debugPrint` المتناثر.
///
/// لا مكتبة خارجية عمدًا (لا حاجة فعلية تبرر إضافة تبعية جديدة لمجرد
/// التسجيل). يُستخدَم `dart:developer.log` لأنه يظهر في DevTools/`flutter
/// logs` بدون تكلفة إضافية في الإصدار النهائي.
///
/// الشكل موحّد بأقسام بين قوسين مربعين (`[NETWORK]`, `[BACKEND]`, `[DATA]`,
/// `[SYNC]`) ليسهل تصفيته وقراءته أثناء تتبّع قرار أونلاين/أوفلاين.
class AppLogger {
  const AppLogger._();

  static void network(String message) => _log('NETWORK', message);
  static void backend(String message) => _log('BACKEND', message);
  static void data(String message) => _log('DATA', message);
  static void sync(String message) => _log('SYNC', message);

  static void _log(String tag, String message) {
    developer.log(message, name: tag);
  }
}
