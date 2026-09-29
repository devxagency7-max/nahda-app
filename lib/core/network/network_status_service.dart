import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../config/app_config.dart';
import '../logging/app_logger.dart';

/// حالة الاتصال كما يراها بقية التطبيق — قرار واحد مركزي بدل أن تفحص كل
/// شاشة أو Repository الاتصال بنفسها.
///
/// **الفرق بين `offline` و `backendUnavailable`:** الأول يعني عدم وجود
/// واجهة شبكة أصلًا (لا واي فاي ولا بيانات)؛ الثاني يعني وجود واجهة شبكة
/// لكن فشل الوصول لعنوان الـ backend تحديدًا (بوابة مقيّدة، خادم نازل).
/// كلاهما يُعامَلان بنفس الأسلوب من طبقة البيانات (Drift fallback) —
/// التفريق مفيد للعرض/التسجيل فقط، لا لتغيير القرار.
enum NetworkStatus {
  online,
  backendUnavailable,
  offline;

  bool get isOnline => this == NetworkStatus.online;
}

/// مراقب مركزي لحالة الاتصال — **حالة محفوظة تُحدَّث دوريًا وعند تغيّرات
/// النظام**، وليس فحصًا يُعاد عند كل طلب.
///
/// **قاعدة معمارية مهمة:** لا تستخدم [current] كبوابة تمنع إرسال الطلب أو
/// تسمح به بشكل صارم. الطلب الفعلي هو الاختبار الحقيقي الوحيد — [current]
/// يُستخدَم فقط لاختيار المسار الأولي (API أونلاين أم Drift أوفلاين
/// مباشرة) قبل أي محاولة شبكة. فحص الحالة قبل كل طلب مباشرة (`checkNow()`
/// ثم الطلب) يُدخل سباقًا زمنيًا (الحالة تتغيّر خلال المدة بين الفحص
/// والطلب) بلا أي فائدة حقيقية — الطلب نفسه سيكتشف فشل الشبكة على أي حال.
class NetworkStatusService {
  NetworkStatusService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  final _controller = StreamController<NetworkStatus>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _osSubscription;
  Timer? _periodicProbe;

  NetworkStatus _current = NetworkStatus.offline;
  NetworkStatus get current => _current;

  Stream<NetworkStatus> get statusStream => _controller.stream;

  /// يُطلق حدثًا عند **عودة** الاتصال بعد انقطاع فعلي — محفّز تفريغ الطابور.
  final _restoredController = StreamController<NetworkStatus>.broadcast();
  Stream<NetworkStatus> get onRestored => _restoredController.stream;

  /// يبدأ المراقبة: فحص أولي فوري، ثم إعادة فحص عند كل تغيّر في واجهة
  /// الشبكة (فوري)، مع فحص دوري احتياطي (كل ٣٠ ثانية) يلتقط حالات
  /// "البوابة المقيّدة تحرّرت" أو "الخادم رجع" التي لا تُصدر حدث نظام.
  Future<void> start() async {
    await _probe();

    _osSubscription = _connectivity.onConnectivityChanged.listen((_) {
      unawaited(_probe());
    });

    _periodicProbe = Timer.periodic(
      const Duration(seconds: 30),
      (_) => unawaited(_probe()),
    );
  }

  /// فحص فوري يدوي — يُستخدَم عند نقاط قرار حاسمة (بدء التشغيل، استئناف
  /// التطبيق) حيث نحتاج قرارًا طازجًا **قبل** المتابعة، لا عند كل طلب API.
  Future<NetworkStatus> checkNow() => _probe();

  Future<NetworkStatus> _probe() async {
    final hasInterface = await _hasNetworkInterface();

    final next = hasInterface
        ? (await _canReachBackend() ? NetworkStatus.online : NetworkStatus.backendUnavailable)
        : NetworkStatus.offline;

    _apply(next);
    return next;
  }

  void _apply(NetworkStatus next) {
    final wasOnline = _current.isOnline;
    final changed = next != _current;
    _current = next;

    if (changed) {
      _controller.add(next);
      _log(next);
      if (!wasOnline && next.isOnline) {
        _restoredController.add(next);
      }
    }
  }

  void _log(NetworkStatus status) {
    switch (status) {
      case NetworkStatus.online:
        AppLogger.network('Internet: CONNECTED');
        AppLogger.backend('Reachable: YES');
      case NetworkStatus.backendUnavailable:
        AppLogger.network('Internet: CONNECTED');
        AppLogger.backend('Reachable: NO');
      case NetworkStatus.offline:
        AppLogger.network('Internet: DISCONNECTED');
    }
  }

  Future<bool> _hasNetworkInterface() async {
    final results = await _connectivity.checkConnectivity();
    return results.isNotEmpty &&
        results.any((r) => r != ConnectivityResult.none);
  }

  /// فحص وصول حقيقي لعنوان الـ backend نفسه — لا خادم عام خارجي. السؤال
  /// المهم لهذا التطبيق هو "هل خادمنا قابل للوصول؟" لا "هل يوجد إنترنت في
  /// العموم؟" (راجع `AppConfig.apiBaseUrl`).
  Future<bool> _canReachBackend({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      final uri = Uri.parse(AppConfig.apiBaseUrl);
      final socket = await Socket.connect(
        uri.host,
        uri.hasPort ? uri.port : (uri.scheme == 'https' ? 443 : 80),
        timeout: timeout,
      );
      socket.destroy();
      return true;
    } on Object {
      return false;
    }
  }

  Future<void> dispose() async {
    _periodicProbe?.cancel();
    await _osSubscription?.cancel();
    await _controller.close();
    await _restoredController.close();
  }
}
