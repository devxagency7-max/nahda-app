/// حقل اختيار متعدد (Multi-select Chips) — يدعم خيار "أخرى" بنص حر.
/// كل قيمة في selected تمثل Chip محدد؛ لو "أخرى" ضمن selected، freeTextValue
/// يحمل النص المكتوب يدويًا.
class MultiSelectField {
  Set<String> selected;
  String? freeTextValue;

  MultiSelectField({Set<String>? selected, this.freeTextValue})
    : selected = selected ?? {};

  static const otherOption = 'أخرى';

  bool get hasOther => selected.contains(otherOption);

  bool get isFilled =>
      selected.isNotEmpty &&
      (!hasOther || (freeTextValue ?? '').trim().isNotEmpty);
}

/// نموذج قابل للتعديل لبيانات السكن (القسم 10) — مطابق لحقول الويب
/// (17 حقل Multi-select، كل حقل يعرض عدد الاختيارات المحددة).
class HousingFormData {
  String? housingDescription; // وصف وحالة السكن العائم

  final MultiSelectField housingType; // طبيعة السكن
  final MultiSelectField walls; // الحوائط
  final MultiSelectField roof; // السقف
  final MultiSelectField floor; // الأرضية
  final MultiSelectField entrance; // المدخل
  final MultiSelectField bathroomType; // طبيعة دورات المياه
  final MultiSelectField bathroomCondition; // حالة دورات المياه
  final MultiSelectField electricity; // الكهرباء
  final MultiSelectField waterMeter; // عداد المياه
  final MultiSelectField waterMotor; // موتور مياه
  final MultiSelectField fridge; // الثلاجة
  final MultiSelectField washer; // الغسالة
  final MultiSelectField oven; // فرن خبيز
  final MultiSelectField cookingAppliances; // أجهزة الطبخ
  final MultiSelectField computer; // حاسب آلي
  final MultiSelectField tv; // التلفاز
  final MultiSelectField freezer; // ديب فريزر
  final MultiSelectField transportation; // وسيلة مواصلات
  final MultiSelectField internet; // إنترنت

  HousingFormData({
    this.housingDescription,
    MultiSelectField? housingType,
    MultiSelectField? walls,
    MultiSelectField? roof,
    MultiSelectField? floor,
    MultiSelectField? entrance,
    MultiSelectField? bathroomType,
    MultiSelectField? bathroomCondition,
    MultiSelectField? electricity,
    MultiSelectField? waterMeter,
    MultiSelectField? waterMotor,
    MultiSelectField? fridge,
    MultiSelectField? washer,
    MultiSelectField? oven,
    MultiSelectField? cookingAppliances,
    MultiSelectField? computer,
    MultiSelectField? tv,
    MultiSelectField? freezer,
    MultiSelectField? transportation,
    MultiSelectField? internet,
  }) : housingType = housingType ?? MultiSelectField(),
       walls = walls ?? MultiSelectField(),
       roof = roof ?? MultiSelectField(),
       floor = floor ?? MultiSelectField(),
       entrance = entrance ?? MultiSelectField(),
       bathroomType = bathroomType ?? MultiSelectField(),
       bathroomCondition = bathroomCondition ?? MultiSelectField(),
       electricity = electricity ?? MultiSelectField(),
       waterMeter = waterMeter ?? MultiSelectField(),
       waterMotor = waterMotor ?? MultiSelectField(),
       fridge = fridge ?? MultiSelectField(),
       washer = washer ?? MultiSelectField(),
       oven = oven ?? MultiSelectField(),
       cookingAppliances = cookingAppliances ?? MultiSelectField(),
       computer = computer ?? MultiSelectField(),
       tv = tv ?? MultiSelectField(),
       freezer = freezer ?? MultiSelectField(),
       transportation = transportation ?? MultiSelectField(),
       internet = internet ?? MultiSelectField();

  List<MultiSelectField> get _allFields => [
    housingType,
    walls,
    roof,
    floor,
    entrance,
    bathroomCondition,
    electricity,
    waterMeter,
    waterMotor,
    fridge,
    washer,
    oven,
    cookingAppliances,
    computer,
    tv,
    freezer,
    transportation,
    internet,
  ];

  double get progress {
    final fields = _allFields;
    final filled = fields.where((f) => f.isFilled).length;
    return filled / fields.length;
  }
}
