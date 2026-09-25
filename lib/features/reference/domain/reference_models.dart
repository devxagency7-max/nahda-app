/// مركز مع قراه — استجابة `GET /locations`.
class LocationCenter {
  const LocationCenter({
    required this.id,
    required this.name,
    required this.villages,
  });

  final String id;
  final String name;
  final List<LocationVillage> villages;

  static LocationCenter fromJson(Map<String, dynamic> json) {
    final raw = json['villages'];
    return LocationCenter(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      villages: raw is List
          ? raw
                .whereType<Map<String, dynamic>>()
                .map(LocationVillage.fromJson)
                .toList(growable: false)
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'villages': villages.map((v) => v.toJson()).toList(growable: false),
  };
}

class LocationVillage {
  const LocationVillage({required this.id, required this.name});

  final String id;
  final String name;

  static LocationVillage fromJson(Map<String, dynamic> json) => LocationVillage(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

class Charity {
  const Charity({
    required this.id,
    required this.name,
    this.governorate,
    this.centerId,
    this.villageId,
  });

  final String id;
  final String name;
  final String? governorate;
  final String? centerId;
  final String? villageId;

  static Charity fromJson(Map<String, dynamic> json) => Charity(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    governorate: json['governorate'] as String?,
    centerId: json['centerId'] as String?,
    villageId: json['villageId'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'governorate': governorate,
    'centerId': centerId,
    'villageId': villageId,
  };
}

/// خيار في قائمة منسدلة.
class DropdownOption {
  const DropdownOption({
    required this.id,
    required this.value,
    required this.label,
    this.isOther = false,
    this.sortOrder = 0,
    this.parentOptionId,
  });

  final String id;

  /// للمفاتيح الديناميكية (`district`, `village`, `referral-*`) هذه القيمة
  /// هي **UUID الصفّ** لا نصّ — فرق مهم عند الإرسال للخادم.
  final String value;

  final String label;

  /// خيار "أخرى" — يفتح حقل نصّ حرّ.
  final bool isOther;

  final int sortOrder;
  final String? parentOptionId;

  static DropdownOption fromJson(Map<String, dynamic> json) => DropdownOption(
    id: json['id'] as String? ?? '',
    value: json['value'] as String? ?? '',
    label: json['label'] as String? ?? '',
    isOther: json['isOther'] == true,
    sortOrder: switch (json['sortOrder']) {
      final int v => v,
      final num v => v.toInt(),
      _ => 0,
    },
    parentOptionId: json['parentOptionId'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'value': value,
    'label': label,
    'isOther': isOther,
    'sortOrder': sortOrder,
    'parentOptionId': parentOptionId,
  };
}

class DropdownOptionSet {
  const DropdownOptionSet({required this.key, required this.options});

  final String key;
  final List<DropdownOption> options;

  /// إعداد معطّل يرجع قائمة فارغة لا خطأ — حالة مشروعة لا عطل.
  bool get isEmpty => options.isEmpty;

  static DropdownOptionSet fromJson(Object? data) {
    final json = data is Map<String, dynamic> ? data : const <String, dynamic>{};
    final raw = json['options'];

    final options = raw is List
        ? (raw
              .whereType<Map<String, dynamic>>()
              .map(DropdownOption.fromJson)
              .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)))
        : <DropdownOption>[];

    return DropdownOptionSet(
      key: json['key'] as String? ?? '',
      options: options,
    );
  }
}

/// مفاتيح القوائم التي يحتاجها التطبيق أوفلاين.
///
/// تُجلَب كلها عند تسجيل الدخول وعند "تحضير للعمل الميداني".
class DropdownKeys {
  const DropdownKeys._();

  static const gender = 'gender';
  static const headRelation = 'head-relation';
  static const maritalStatus = 'marital-status';
  static const education = 'education';
  static const healthStatus = 'health-status';
  static const employmentStatus = 'employment-status';
  static const religion = 'religion';
  static const housingOwnership = 'housing-ownership';
  static const housingType = 'housing-type';

  /// المفاتيح المطلوبة مسبقًا للعمل الميداني.
  ///
  /// مفتاح غير موجود على الخادم يرجع 404؛ المزامنة تتجاهله وتكمل الباقي
  /// بدل أن تفشل كلها.
  static const preloadKeys = [
    gender,
    headRelation,
    maritalStatus,
    education,
    healthStatus,
    employmentStatus,
    religion,
    housingOwnership,
    housingType,
  ];

  /// مفاتيح خاصة داخل كاش القوائم.
  static const locationsCacheKey = '__locations__';
  static const charitiesCacheKey = '__charities__';
}
