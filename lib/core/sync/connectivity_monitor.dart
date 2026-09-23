import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// نوع الاتصال الحالي — يهمّنا لأن رفع الصور على بيانات الموبايل مكلف.
enum ConnectionKind {
  none,
  mobile,
  wifi,
  other;

  bool get isOnline => this != ConnectionKind.none;

  /// هل يُسمَح برفع المرفقات الثقيلة؟
  ///
  /// الأخصائي في الميدان على باقة محدودة؛ ٧ صور × ١٠ ميجا تلتهمها.
  bool allowsHeavyUpload({required bool wifiOnly}) =>
      wifiOnly ? this == ConnectionKind.wifi : isOnline;
}

/// يراقب حالة الاتصال ويُطلق المزامنة عند عودته.
///
/// **تنبيه مهم:** وجود واجهة شبكة لا يعني وجود إنترنت فعلي (بوابة مقيّدة،
/// برج بلا خدمة). لذا هذا المراقب **تلميح للتوقيت لا ضمان للنجاح** — محرّك
/// المزامنة يظلّ مسؤولًا عن التعامل مع فشل الطلب رغم "وجود اتصال".
class ConnectivityMonitor {
  ConnectivityMonitor({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  final _controller = StreamController<ConnectionKind>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  ConnectionKind _current = ConnectionKind.none;
  ConnectionKind get current => _current;
  bool get isOnline => _current.isOnline;

  Stream<ConnectionKind> get changes => _controller.stream;

  final _restoredController = StreamController<ConnectionKind>.broadcast();

  /// يُطلق حدثًا عند **عودة** الاتصال بعد انقطاع — محفّز تفريغ الطابور.
  ///
  /// منفصل عن [changes] لأن الانتقال من wifi إلى mobile ليس "عودة اتصال"
  /// ولا يستدعي إعادة تفريغ كاملة.
  Stream<ConnectionKind> get onRestored => _restoredController.stream;

  Future<void> start() async {
    _current = _map(await _connectivity.checkConnectivity());

    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final next = _map(results);
      if (next == _current) return;

      final wasOffline = !_current.isOnline;
      _current = next;
      _controller.add(next);

      if (wasOffline && next.isOnline) {
        _restoredController.add(next);
      }
    });
  }

  Future<ConnectionKind> refresh() async {
    _current = _map(await _connectivity.checkConnectivity());
    return _current;
  }

  ConnectionKind _map(List<ConnectivityResult> results) {
    if (results.isEmpty || results.every((r) => r == ConnectivityResult.none)) {
      return ConnectionKind.none;
    }
    if (results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.ethernet)) {
      return ConnectionKind.wifi;
    }
    if (results.contains(ConnectivityResult.mobile)) {
      return ConnectionKind.mobile;
    }
    return ConnectionKind.other;
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    await _controller.close();
    await _restoredController.close();
  }
}
