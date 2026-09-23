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
}
