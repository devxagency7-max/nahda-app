/// يحوّل الأرقام العربية (١٢٣...) والفارسية/الهندية (۱۲۳...) الشائعة في
/// لوحات المفاتيح العربية إلى أرقام إنجليزية (0-9) قبل الـ parsing — بدون
/// هذا التحويل، `double.tryParse`/`int.tryParse` يرجّعان null على أي رقم
/// مكتوب بالعربي فيبدو للمستخدم أن القيمة "لا تُحفظ".
String normalizeDigits(String input) {
  const arabicIndic = '٠١٢٣٤٥٦٧٨٩';
  const easternArabicIndic = '۰۱۲۳۴۵۶۷۸۹';
  final buffer = StringBuffer();
  for (final rune in input.runes) {
    final char = String.fromCharCode(rune);
    final arabicIndex = arabicIndic.indexOf(char);
    if (arabicIndex != -1) {
      buffer.write(arabicIndex);
      continue;
    }
    final easternIndex = easternArabicIndic.indexOf(char);
    if (easternIndex != -1) {
      buffer.write(easternIndex);
      continue;
    }
    buffer.write(char);
  }
  return buffer.toString();
}

double? parseLocalizedDouble(String input) => double.tryParse(normalizeDigits(input));

int? parseLocalizedInt(String input) => int.tryParse(normalizeDigits(input));
