import 'package:flutter_test/flutter_test.dart';
import 'package:nahda/core/utils/egyptian_national_id_parser.dart';

void main() {
  group('Egyptian National ID Parser Tests', () {
    test('Parses valid National ID (Beni Suef, Male, 2005)', () {
      final now = DateTime(2026, 8, 21);
      final result = parseEgyptianNationalId('30501042201237', now: now);

      expect(result.valid, isTrue);
      expect(result.age, equals(21));
      expect(result.governorateCode, equals('22'));
      expect(result.governorateAr, equals('بني سويف'));
      expect(result.governorateEn, equals('Beni Suef'));
      expect(result.genderAr, equals('ذكر'));
      expect(result.genderEn, equals('Male'));
    });

    test('Parses valid National ID with Arabic numerals (Cairo, Female, 1998)', () {
      final now = DateTime(2026, 8, 21);
      final result = parseEgyptianNationalId('٢٩٨١٠١٥٠١٠١٢٤٨', now: now);

      expect(result.valid, isTrue);
      expect(result.age, equals(27));
      expect(result.governorateCode, equals('01'));
      expect(result.governorateAr, equals('القاهرة'));
      expect(result.genderAr, equals('أنثى'));
      expect(result.genderEn, equals('Female'));
    });

    test('Rejects National ID with invalid length', () {
      final result = parseEgyptianNationalId('3050104220123');
      expect(result.valid, isFalse);
      expect(result.error, equals('الرقم القومي غير صحيح'));
    });

    test('Rejects National ID with invalid century', () {
      final result = parseEgyptianNationalId('10501042201237');
      expect(result.valid, isFalse);
      expect(result.error, equals('الرقم القومي غير صحيح'));
    });

    test('Rejects National ID with invalid governorate code', () {
      final result = parseEgyptianNationalId('30501049901237');
      expect(result.valid, isFalse);
      expect(result.error, equals('الرقم القومي غير صحيح'));
    });
  });
}
