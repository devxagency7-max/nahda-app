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
  ///
  /// ⚠️ **القيمة الحالية `http://` لا `https://`** — بيانات مستفيدين حقيقية
  /// (رقم قومي، دخل، حالة صحية، هاتف) تنتقل حاليًا **نصًّا صريحًا على
  /// الشبكة**، وأي جهاز على نفس الشبكة (نقطة اتصال عامة، شبكة الجمعية) يمكنه
  /// قراءتها. هذا خطر أمني حقيقي لا افتراضي — تخزين التوكنات في Keychain/
  /// Keystore (§`secure_token_store.dart`) لا يحمي بيانات في طريقها على
  /// السلك. **يجب أن يتحوّل هذا العنوان لـ `https://` قبل أي استخدام إنتاجي
  /// فعلي** — تغيير على مستوى البنية التحتية (شهادة TLS + reverse proxy)،
  /// لا شيء يُصلَح من طرف التطبيق. راجَع مع فريق الباك إند/DevOps.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://187.77.70.246/api/v1',
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
