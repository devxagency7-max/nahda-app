import 'dart:convert';


import '../../../core/network/api_error_code.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/app_database.dart';
import '../domain/reference_models.dart';
import 'reference_api.dart';

/// مستودع البيانات المرجعية — يقرأ من الكاش، يحدّثه من الشبكة.
///
/// **حرج للعمل أوفلاين**: القوائم المنسدلة والمراكز والقرى لا بد أن تكون
/// مخزَّنة قبل خروج الأخصائي للميدان، وإلا تعذّر ملء أي نموذج.
class ReferenceRepository {
  ReferenceRepository({required ReferenceApi api, required AppDatabase db})
    : _api = api,
      _db = db;

  final ReferenceApi _api;
  final AppDatabase _db;

  /// عمر الكاش قبل اعتباره قديمًا. البيانات المرجعية نادرة التغيّر.
  static const _staleAfter = Duration(hours: 24);

  // ───────────────────────── القراءة من الكاش ─────────────────────────

  Future<List<LocationCenter>> centers() async {
    final raw = await _readCache(DropdownKeys.locationsCacheKey);
    if (raw == null) return const [];

    final decoded = jsonDecode(raw);
    return decoded is List
        ? decoded
              .whereType<Map<String, dynamic>>()
              .map(LocationCenter.fromJson)
              .toList(growable: false)
        : const [];
  }

  /// قرى مركز بعينه — قائمة متتالية صحيحة.
  ///
  /// تُشتقّ من `/locations` لأن مفتاح `village` في `/dropdowns` يرجع كل القرى
  /// بلا ربط بمركزها (ثغرة موثّقة في العقد).
  Future<List<LocationVillage>> villagesOf(String centerId) async {
    final all = await centers();
    for (final center in all) {
      if (center.id == centerId) return center.villages;
    }
    return const [];
  }

  Future<List<Charity>> charities() async {
    final raw = await _readCache(DropdownKeys.charitiesCacheKey);
    if (raw == null) return const [];

    final decoded = jsonDecode(raw);
    return decoded is List
        ? decoded
              .whereType<Map<String, dynamic>>()
              .map(Charity.fromJson)
              .toList(growable: false)
        : const [];
  }

  Future<List<DropdownOption>> options(String key) async {
    final raw = await _readCache(key);
    if (raw == null) return const [];

    final decoded = jsonDecode(raw);
    return decoded is List
        ? decoded
              .whereType<Map<String, dynamic>>()
              .map(DropdownOption.fromJson)
              .toList(growable: false)
        : const [];
  }

  /// هل البيانات المرجعية جاهزة للعمل أوفلاين؟
  ///
  /// يُعرَض للأخصائي قبل خروجه للميدان.
  Future<bool> isReadyForOfflineWork() async {
    final locations = await _readCacheRow(DropdownKeys.locationsCacheKey);
    return locations != null;
  }

  /// متى آخر تحديث للبيانات المرجعية؟
  Future<DateTime?> lastRefreshedAt() async {
    final row = await _readCacheRow(DropdownKeys.locationsCacheKey);
    return row?.fetchedAt;
  }

  Future<bool> isStale() async {
    final at = await lastRefreshedAt();
    if (at == null) return true;
    return DateTime.now().difference(at) > _staleAfter;
  }

  // ───────────────────────── التحديث من الشبكة ─────────────────────────

  /// يجلب كل البيانات المرجعية ويخزّنها.
  ///
  /// **متسامح عمدًا**: فشل مفتاح واحد (404 لمفتاح غير مُعرَّف على الخادم مثلًا)
  /// لا يُسقِط الباقي. يرجع الخطأ الأول لغرض العرض فقط.
  Future<ApiException?> refreshAll() async {
    ApiException? firstError;

    try {
      final centers = await _api.locations();
      await _writeCache(
        DropdownKeys.locationsCacheKey,
        jsonEncode(centers.map((c) => c.toJson()).toList(growable: false)),
      );
    } on ApiException catch (e) {
      firstError ??= e;
      // انقطاع الشبكة يعني لا فائدة من محاولة الباقي.
      if (e.code == ApiErrorCode.offline) return firstError;
    }

    try {
      final charities = await _api.charities();
      await _writeCache(
        DropdownKeys.charitiesCacheKey,
        jsonEncode(charities.map((c) => c.toJson()).toList(growable: false)),
      );
    } on ApiException catch (e) {
      firstError ??= e;
      if (e.code == ApiErrorCode.offline) return firstError;
    }

    for (final key in DropdownKeys.preloadKeys) {
      try {
        final set = await _api.dropdown(key);
        await _writeCache(
          key,
          jsonEncode(set.options.map((o) => o.toJson()).toList(growable: false)),
        );
      } on ApiException catch (e) {
        // مفتاح غير مُعرَّف على هذا الخادم — ليس عطلًا، نتخطّاه بهدوء.
        if (e.code == ApiErrorCode.notFound) continue;
        firstError ??= e;
        if (e.code == ApiErrorCode.offline) break;
      }
    }

    return firstError;
  }

  /// يحدّث فقط إن كان الكاش قديمًا أو فارغًا.
  Future<ApiException?> refreshIfStale() async {
    if (!await isStale()) return null;
    return refreshAll();
  }

  // ───────────────────────── الكاش ─────────────────────────

  Future<DropdownCacheRow?> _readCacheRow(String key) =>
      (_db.select(_db.dropdownCache)..where((t) => t.key.equals(key)))
          .getSingleOrNull();

  Future<String?> _readCache(String key) async =>
      (await _readCacheRow(key))?.valuesJson;

  Future<void> _writeCache(String key, String json) => _db
      .into(_db.dropdownCache)
      .insertOnConflictUpdate(
        DropdownCacheCompanion.insert(
          key: key,
          valuesJson: json,
          fetchedAt: DateTime.now(),
        ),
      );
}
