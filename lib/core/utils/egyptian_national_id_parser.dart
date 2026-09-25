class EgyptianNationalIdResult {
  final bool valid;
  final String? error;
  final int? age;
  final String? governorateCode;
  final String? governorateAr;
  final String? governorateEn;
  final String? genderAr;
  final String? genderEn;
  final String? religionAr;
  final DateTime? birthDate;

  const EgyptianNationalIdResult.invalid(this.error)
      : valid = false,
        age = null,
        governorateCode = null,
        governorateAr = null,
        governorateEn = null,
        genderAr = null,
        genderEn = null,
        religionAr = null,
        birthDate = null;

  const EgyptianNationalIdResult.valid({
    required this.age,
    required this.governorateCode,
    required this.governorateAr,
    required this.governorateEn,
    required this.genderAr,
    required this.genderEn,
    this.religionAr = 'مسلم',
    required this.birthDate,
  })  : valid = true,
        error = null;
}

const Map<String, Map<String, String>> _egyptianGovernorates = {
  '01': {'ar': 'القاهرة', 'en': 'Cairo'},
  '02': {'ar': 'الإسكندرية', 'en': 'Alexandria'},
  '03': {'ar': 'بورسعيد', 'en': 'Port Said'},
  '04': {'ar': 'السويس', 'en': 'Suez'},
  '11': {'ar': 'دمياط', 'en': 'Damietta'},
  '12': {'ar': 'الدقهلية', 'en': 'Dakahlia'},
  '13': {'ar': 'الشرقية', 'en': 'Sharqia'},
  '14': {'ar': 'القليوبية', 'en': 'Qalyubia'},
  '15': {'ar': 'كفر الشيخ', 'en': 'Kafr El Sheikh'},
  '16': {'ar': 'الغربية', 'en': 'Gharbia'},
  '17': {'ar': 'المنوفية', 'en': 'Monufia'},
  '18': {'ar': 'البحيرة', 'en': 'Beheira'},
  '19': {'ar': 'الإسماعيلية', 'en': 'Ismailia'},
  '21': {'ar': 'الجيزة', 'en': 'Giza'},
  '22': {'ar': 'بني سويف', 'en': 'Beni Suef'},
  '23': {'ar': 'الفيوم', 'en': 'Fayoum'},
  '24': {'ar': 'المنيا', 'en': 'Minya'},
  '25': {'ar': 'أسيوط', 'en': 'Assiut'},
  '26': {'ar': 'سوهاج', 'en': 'Sohag'},
  '27': {'ar': 'قنا', 'en': 'Qena'},
  '28': {'ar': 'أسوان', 'en': 'Aswan'},
  '29': {'ar': 'الأقصر', 'en': 'Luxor'},
  '31': {'ar': 'البحر الأحمر', 'en': 'Red Sea'},
  '32': {'ar': 'الوادي الجديد', 'en': 'New Valley'},
  '33': {'ar': 'مطروح', 'en': 'Matrouh'},
  '34': {'ar': 'شمال سيناء', 'en': 'North Sinai'},
  '35': {'ar': 'جنوب سيناء', 'en': 'South Sinai'},
  '88': {'ar': 'خارج الجمهورية', 'en': 'Born outside Egypt'},
};

/// Reusable Egyptian National ID Parser.
/// Accepts 14-digit Egyptian National ID (English or Arabic numerals)
/// and extracts: Age, Governorate of Birth, Gender, and Birth Date.
EgyptianNationalIdResult parseEgyptianNationalId(String? rawId, {DateTime? now}) {
  if (rawId == null || rawId.trim().isEmpty) {
    return const EgyptianNationalIdResult.invalid('يرجى إدخال الرقم القومي');
  }

  // 1. Normalize Eastern Arabic numerals (٠١٢٣٤٥٦٧٨٩) to Western (0123456789) and remove whitespace
  final normalized = _normalizeDigits(rawId.trim());

  if (normalized.length != 14) {
    return const EgyptianNationalIdResult.invalid('الرقم القومي غير صحيح');
  }

  if (!RegExp(r'^\d{14}$').hasMatch(normalized)) {
    return const EgyptianNationalIdResult.invalid('الرقم القومي غير صحيح');
  }

  // 2. Parse Century
  final centuryDigit = int.parse(normalized[0]);
  int baseYear;
  if (centuryDigit == 2) {
    baseYear = 1900;
  } else if (centuryDigit == 3) {
    baseYear = 2000;
  } else {
    return const EgyptianNationalIdResult.invalid('الرقم القومي غير صحيح');
  }

  // 3. Parse Birth Date (YY MM DD)
  final yearSuffix = int.parse(normalized.substring(1, 3));
  final month = int.parse(normalized.substring(3, 5));
  final day = int.parse(normalized.substring(5, 7));

  final fullYear = baseYear + yearSuffix;

  // Validate Month (1-12) & Day (1-31)
  if (month < 1 || month > 12 || day < 1 || day > 31) {
    return const EgyptianNationalIdResult.invalid('الرقم القومي غير صحيح');
  }

  DateTime birthDate;
  try {
    birthDate = DateTime(fullYear, month, day);
    // Extra safety: ensure Dart DateTime didn't overflow (e.g. Feb 31 -> Mar 3)
    if (birthDate.year != fullYear || birthDate.month != month || birthDate.day != day) {
      return const EgyptianNationalIdResult.invalid('الرقم القومي غير صحيح');
    }
  } catch (_) {
    return const EgyptianNationalIdResult.invalid('الرقم القومي غير صحيح');
  }

  final currentDate = now ?? DateTime.now();
  if (birthDate.isAfter(currentDate)) {
    return const EgyptianNationalIdResult.invalid('الرقم القومي غير صحيح');
  }

  // 4. Calculate Age Dynamically
  int age = currentDate.year - birthDate.year;
  if (currentDate.month < birthDate.month ||
      (currentDate.month == birthDate.month && currentDate.day < birthDate.day)) {
    age--;
  }

  if (age < 0) {
    return const EgyptianNationalIdResult.invalid('الرقم القومي غير صحيح');
  }

  // 5. Parse Governorate Code (Digits 8 & 9, index 7-8)
  final govCode = normalized.substring(7, 9);
  final govMap = _egyptianGovernorates[govCode];
  if (govMap == null) {
    return const EgyptianNationalIdResult.invalid('الرقم القومي غير صحيح');
  }

  // 6. Parse Gender from Digit 13 (Index 12)
  final genderDigit = int.parse(normalized[12]);
  final isMale = genderDigit % 2 != 0;

  return EgyptianNationalIdResult.valid(
    age: age,
    governorateCode: govCode,
    governorateAr: govMap['ar']!,
    governorateEn: govMap['en']!,
    genderAr: isMale ? 'ذكر' : 'أنثى',
    genderEn: isMale ? 'Male' : 'Female',
    religionAr: 'مسلم',
    birthDate: birthDate,
  );
}

String _normalizeDigits(String input) {
  const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  const englishDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];

  String result = input.replaceAll(RegExp(r'\s+|-'), '');
  for (int i = 0; i < arabicDigits.length; i++) {
    result = result.replaceAll(arabicDigits[i], englishDigits[i]);
  }
  return result;
}
