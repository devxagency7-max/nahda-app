import 'dart:convert';

import '../../domain/sections/classification_form.dart';

/// يحوّل [ClassificationFormData] من/إلى شكل التخزين المحلي وشكل
/// `PUT /cases/{id}/classification` (§19) — مفرد، `rowVersion` قابل للـ null
/// أول حفظ.
class ClassificationMapper {
  const ClassificationMapper._();

  static Map<String, dynamic> toCacheJson(ClassificationFormData form) => {
    'mainClassifications': form.mainClassifications,
    'subClassification': form.subClassification,
    'needLevel': form.needLevel,
    'priorityLevel': form.priorityLevel,
    'vulnerabilityLevel': form.vulnerabilityLevel,
    'notes': form.notes,
  };

  static Map<String, dynamic> toApiPayload(
    ClassificationFormData form, {
    required int? rowVersion,
  }) => {
    'mainClassifications': form.mainClassifications,
    'subClassification': form.subClassification,
    'needLevel': form.needLevel,
    'priorityLevel': form.priorityLevel,
    'vulnerabilityLevel': form.vulnerabilityLevel,
    'notes': form.notes,
    'rowVersion': rowVersion,
  };

  /// يبني [ClassificationFormData] من استجابة `PUT`/`GET /classification`
  /// الفعلية من الخادم — `mainClassificationsJson` نص JSON، لا مصفوفة
  /// (نفس عدم تطابق الطلب/الرد الموجود في الزراعة، §19).
  static ClassificationFormData fromApiResponse(Map<String, dynamic> json) {
    final raw = json['mainClassificationsJson'] as String?;
    final mainClassifications = raw == null || raw.isEmpty
        ? const <String>[]
        : (jsonDecode(raw) as List? ?? const [])
              .whereType<String>()
              .toList(growable: false);

    return ClassificationFormData(
      mainClassifications: mainClassifications,
      subClassification: json['subClassification'] as String?,
      needLevel: json['needLevel'] as String? ?? '',
      priorityLevel: json['priorityLevel'] as String? ?? '',
      vulnerabilityLevel: json['vulnerabilityLevel'] as String?,
      notes: json['notes'] as String?,
    );
  }
}
