import '../../../core/network/api_client.dart';
import '../domain/reference_models.dart';

/// بيانات مرجعية: المراكز والقرى والجمعيات والقوائم المنسدلة.
///
/// **حرجة للعمل أوفلاين**: بدون هذه البيانات مخزَّنة محليًا لا يستطيع الأخصائي
/// ملء أي نموذج في الميدان.
class ReferenceApi {
  const ReferenceApi(this._client);

  final ApiClient _client;

  /// `GET /locations` — كل المراكز وقراها متداخلة. بلا تصفية ولا ترقيم.
  ///
  /// **المصدر الوحيد لقائمة قرى مرتبطة بمركزها.** مفتاح `village` في
  /// `/dropdowns` يرجع كل القرى النشطة **بلا ربط بالمركز** — ثغرة موثّقة في
  /// العقد، فلا تُستخدَم لقائمة متتالية.
  Future<List<LocationCenter>> locations() => _client.get<List<LocationCenter>>(
    '/locations',
    (data) => Parse.list(data).map(LocationCenter.fromJson).toList(),
  );

  /// `GET /charities`.
  Future<List<Charity>> charities({String? search, String? centerId}) =>
      _client.get<List<Charity>>(
        '/charities',
        (data) {
          // مُصفَّحة: العناصر داخل `items`.
          final map = data is Map<String, dynamic> ? data : const {};
          final items = map['items'];
          return items is List
              ? items
                    .whereType<Map<String, dynamic>>()
                    .map(Charity.fromJson)
                    .toList()
              : <Charity>[];
        },
        query: {
          'search': search,
          'centerId': centerId,
          'limit': 100,
        },
      );

  /// `GET /dropdowns/{key}`.
  ///
  /// إعداد معطّل يرجع `options` فارغة لا 404؛ مفتاح لا يقابل أي إعداد يرجع 404.
  ///
  /// للمفاتيح الديناميكية (`district`, `village`, `referral-*`) تكون `value`
  /// هي **الـ UUID** لا نصًّا.
  Future<DropdownOptionSet> dropdown(String key) =>
      _client.get<DropdownOptionSet>(
        '/dropdowns/$key',
        DropdownOptionSet.fromJson,
      );
}
