import 'package:geolocator/geolocator.dart';

/// نتيجة محاولة التقاط الموقع.
sealed class LocationResult {
  const LocationResult();
}

class LocationCaptured extends LocationResult {
  const LocationCaptured(this.latitude, this.longitude);
  final double latitude;
  final double longitude;
}

/// تعذّر الالتقاط — الرسالة قابلة للعرض مباشرة للمستخدم.
class LocationUnavailable extends LocationResult {
  const LocationUnavailable(this.message);
  final String message;
}

/// يلتقط إحداثيات GPS الحالية للزيارة الميدانية.
///
/// الموقع **اختياري بالكامل** في نموذج الزيارة (§15.10) — أي فشل هنا
/// (صلاحية مرفوضة، خدمة موقع مطفأة، مهلة) يُترجَم لرسالة توضيحية ولا يمنع
/// الأخصائي من إكمال الزيارة بدون إحداثيات.
class LocationService {
  const LocationService();

  Future<LocationResult> capture() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationUnavailable('خدمة الموقع مغلقة على الجهاز.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        return const LocationUnavailable('تم رفض صلاحية الموقع.');
      }
      if (permission == LocationPermission.deniedForever) {
        return const LocationUnavailable(
          'صلاحية الموقع مرفوضة دائمًا — فعّلها من إعدادات الجهاز.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      return LocationCaptured(position.latitude, position.longitude);
    } catch (_) {
      return const LocationUnavailable('تعذّر تحديد الموقع الحالي.');
    }
  }
}
