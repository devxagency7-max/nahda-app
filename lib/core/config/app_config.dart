/// إعدادات البيئة — تُمرَّر وقت البناء عبر --dart-define.
///
/// مثال:
/// ```
/// flutter run --dart-define=API_BASE_URL=https://api.nahda.org/api/v1
/// ```
library;

enum AppEnvironment { dev, staging, prod }

class AppConfig {
  const AppConfig._();

  /// عنوان الـ API الأساسي. يتضمن `/api/v1` — لا يُضاف في الـ endpoints.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://srv1990155.hstgr.cloud/api/v1',
  );

  static const String _envName = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'dev',
  );

  static AppEnvironment get environment => switch (_envName) {
    'prod' => AppEnvironment.prod,
    'staging' => AppEnvironment.staging,
    _ => AppEnvironment.dev,
  };

  static bool get isProd => environment == AppEnvironment.prod;

  /// نوع العميل — الباك إند يفرض أن الأخصائي الاجتماعي لا يدخل إلا من الموبايل.
  /// قيمة ثابتة لا تتغير (FLUTTER_API_DOCUMENTATION §2.1).
  static const String clientType = 'mobile';

  /// مهلة الاتصال والاستقبال. الميدان يعني شبكة بطيئة — مهلة كريمة عن قصد.
  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 40);

  /// مهلة رفع المرفقات — أطول بكثير (ملف حتى 10 ميجا على بيانات موبايل).
  static const Duration uploadTimeout = Duration(minutes: 5);

  /// تشغيل تسجيل الطلبات. مُعطَّل في الإنتاج — الـ payload يحتوي بيانات مستفيدين.
  static bool get enableNetworkLogging => !isProd;
}
