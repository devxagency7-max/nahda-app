/// نموذج قابل للتعديل لعنصر مرفق واحد (القسم 11).
class UtilityItemFormData {
  String name;
  bool isAvailable;
  String? condition;
  String? sourceOrMeter;

  UtilityItemFormData({
    required this.name,
    this.isAvailable = false,
    this.condition,
    this.sourceOrMeter,
  });
}

/// نموذج قابل للتعديل لعنصر جهاز/ممتلكات واحد (القسم 12).
class EquipmentItemFormData {
  String name;
  String category;
  bool isPresent;

  EquipmentItemFormData({
    required this.name,
    required this.category,
    this.isPresent = false,
  });
}

/// القسم 11+12 — يبدأ بقائمة افتراضية قابلة للتعديل (Toggle)، والأخصائي
/// يقدر يضيف عناصر أخرى غير موجودة في القائمة الافتراضية.
class UtilitiesEquipmentFormData {
  List<UtilityItemFormData> utilities;
  List<EquipmentItemFormData> equipment;

  UtilitiesEquipmentFormData({
    List<UtilityItemFormData>? utilities,
    List<EquipmentItemFormData>? equipment,
  }) : utilities = utilities ?? _defaultUtilities(),
       equipment = equipment ?? _defaultEquipment();

  static List<UtilityItemFormData> _defaultUtilities() => [
    UtilityItemFormData(name: 'كهرباء'),
    UtilityItemFormData(name: 'مياه'),
    UtilityItemFormData(name: 'غاز'),
    UtilityItemFormData(name: 'الصرف الصحي'),
  ];

  static List<EquipmentItemFormData> _defaultEquipment() => [
    EquipmentItemFormData(name: 'ثلاجة', category: 'أجهزة منزلية'),
    EquipmentItemFormData(name: 'غسالة', category: 'أجهزة منزلية'),
    EquipmentItemFormData(name: 'تلفاز', category: 'أجهزة كهربائية'),
    EquipmentItemFormData(name: 'شاشة', category: 'أجهزة كهربائية'),
    EquipmentItemFormData(name: 'بوتاجاز', category: 'أجهزة طبخ'),
  ];

  /// مكتمل لو تم تحديد حالة كل عناصر المرافق الأساسية على الأقل
  /// (متوفر/غير متوفر لكل بند) — التجهيزات إضافية وليست شرطًا للاكتمال.
  double get progress {
    if (utilities.isEmpty) return 0;
    final markedCount = utilities
        .where((u) => u.isAvailable || u.condition != null)
        .length;
    return markedCount / utilities.length;
  }
}
