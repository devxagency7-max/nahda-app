import 'package:flutter_test/flutter_test.dart';
import 'package:nahda/core/network/api_envelope.dart';
import 'package:nahda/core/network/api_error_code.dart';
import 'package:nahda/core/network/api_exception.dart';

/// اختبارات غلاف الاستجابة — FLUTTER_API_DOCUMENTATION §3 و §4.
/// كل حالة هنا مأخوذة من مثال حرفي في العقد.
void main() {
  group('ApiEnvelope.parse — النجاح', () {
    test('يفكّ data من غلاف ناجح', () {
      final result = ApiEnvelope.parse<Map<String, dynamic>>(
        {
          'success': true,
          'data': {'status': 'in_research', 'caseRowVersion': 5},
          'message': null,
        },
        (data) => data as Map<String, dynamic>,
      );

      expect(result['status'], 'in_research');
      expect(result['caseRowVersion'], 5);
    });

    test('يقبل data الفارغة (مسارات بلا محتوى)', () {
      var called = false;
      ApiEnvelope.parse<void>({'success': true, 'data': null}, (data) {
        called = true;
        expect(data, isNull);
      });
      expect(called, isTrue);
    });

    test('يرمي عند جسم ليس خريطة', () {
      expect(
        () => ApiEnvelope.parse<void>('<html>404</html>', (_) {}),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.unknown,
          ),
        ),
      );
    });
  });

  group('ApiEnvelope.parseError — الأخطاء', () {
    test('يقرأ الكود والرسالة العربية', () {
      final error = ApiEnvelope.parseError({
        'success': false,
        'error': {
          'code': 'CONCURRENCY_CONFLICT',
          'message': 'تم تعديل الحالة من جهة أخرى',
        },
      }, statusCode: 409);

      expect(error.code, ApiErrorCode.concurrencyConflict);
      expect(error.message, 'تم تعديل الحالة من جهة أخرى');
      expect(error.statusCode, 409);
      expect(error.isConflict, isTrue);
    });

    test('details خريطة حقل ← أسباب', () {
      final error = ApiEnvelope.parseError({
        'success': false,
        'error': {
          'code': 'VALIDATION_ERROR',
          'message': 'بيانات غير صحيحة',
          'details': {
            'completion': ['لا يمكن إرسال الرأي قبل استيفاء جميع أقسام الحالة'],
          },
        },
      }, statusCode: 422);

      expect(error.code, ApiErrorCode.validationError);
      expect(
        error.fieldError('completion'),
        'لا يمكن إرسال الرأي قبل استيفاء جميع أقسام الحالة',
      );
    });

    test('details غائبة تعني null لا خريطة فارغة', () {
      final error = ApiEnvelope.parseError({
        'success': false,
        'error': {'code': 'CASE_NOT_FOUND', 'message': 'الحالة غير موجودة'},
      }, statusCode: 404);

      expect(error.details, isNull);
      expect(error.fieldError('anything'), isNull);
    });

    test('fieldError غير حسّاس لحالة الأحرف — مسار البحث يرجع PascalCase', () {
      // §21: مفاتيح البحث PascalCase (NationalId) لا snake_case (national_id).
      final error = ApiEnvelope.parseError({
        'success': false,
        'error': {
          'code': 'VALIDATION_ERROR',
          'message': '',
          'details': {
            'NationalId': ['نص البحث طويل جدًا'],
          },
        },
      }, statusCode: 422);

      expect(error.fieldError('nationalId'), 'نص البحث طويل جدًا');
      expect(error.fieldError('NationalId'), 'نص البحث طويل جدًا');
    });

    test('كود غير معروف يصبح unknown لا انهيار', () {
      final error = ApiEnvelope.parseError({
        'success': false,
        'error': {'code': 'SOMETHING_NEW_FROM_BACKEND', 'message': 'جديد'},
      }, statusCode: 400);

      expect(error.code, ApiErrorCode.unknown);
      expect(error.message, 'جديد');
    });

    test('يشتقّ الكود من HTTP حين يغيب الغلاف', () {
      expect(
        ApiEnvelope.parseError(null, statusCode: 403).code,
        ApiErrorCode.forbidden,
      );
      expect(
        ApiEnvelope.parseError(null, statusCode: 429).code,
        ApiErrorCode.rateLimited,
      );
      expect(
        ApiEnvelope.parseError(null, statusCode: 500).code,
        ApiErrorCode.internalError,
      );
    });
  });

  group('تصنيف الأخطاء', () {
    test('403 تعارض لا مشكلة توكن — لا refresh عليه أبدًا (§15.9)', () {
      expect(ApiErrorCode.forbidden.requiresReauth, isFalse);
      expect(ApiErrorCode.forbidden.isConflict, isTrue);
      expect(ApiErrorCode.forbidden.isRetryable, isFalse);
    });

    test('أخطاء التوكن تستوجب تسجيل دخول', () {
      expect(ApiErrorCode.tokenExpired.requiresReauth, isTrue);
      expect(ApiErrorCode.tokenRevoked.requiresReauth, isTrue);
      expect(ApiErrorCode.unauthorized.requiresReauth, isTrue);
    });

    test('أخطاء التعارض توقف تفريغ طابور الحالة', () {
      expect(ApiErrorCode.concurrencyConflict.isConflict, isTrue);
      expect(ApiErrorCode.invalidStatusTransition.isConflict, isTrue);
      expect(ApiErrorCode.opinionSlotLocked.isConflict, isTrue);
    });

    test('أخطاء التحقق لا يُعاد محاولتها — لن تنجح مهما تكرّرت', () {
      expect(ApiErrorCode.validationError.isRetryable, isFalse);
      expect(ApiErrorCode.fileTooLarge.isRetryable, isFalse);
      expect(ApiErrorCode.unsupportedFileType.isRetryable, isFalse);
    });

    test('أخطاء الشبكة المؤقتة قابلة لإعادة المحاولة', () {
      expect(ApiErrorCode.offline.isRetryable, isTrue);
      expect(ApiErrorCode.timeout.isRetryable, isTrue);
      expect(ApiErrorCode.internalError.isRetryable, isTrue);
      expect(ApiErrorCode.storageUnavailable.isRetryable, isTrue);
    });
  });

  group('Paged', () {
    test('يقرأ الصفحة كاملة', () {
      final paged = Paged.fromJson<String>({
        'items': [
          {'id': 'a'},
          {'id': 'b'},
        ],
        'page': 2,
        'limit': 20,
        'total': 137,
        'totalPages': 7,
        'hasNext': true,
        'hasPrev': true,
      }, (item) => item['id'] as String);

      expect(paged.items, ['a', 'b']);
      expect(paged.page, 2);
      expect(paged.total, 137);
      expect(paged.hasNext, isTrue);
      expect(paged.hasPrev, isTrue);
    });

    test('يتحمّل استجابة ناقصة بقيم افتراضية', () {
      final paged = Paged.fromJson<String>(
        const <String, dynamic>{},
        (item) => '${item['id']}',
      );

      expect(paged.items, isEmpty);
      expect(paged.page, 1);
      expect(paged.limit, 20);
      expect(paged.isEmpty, isTrue);
    });

    test('يتجاهل العناصر غير الصالحة بدل الانهيار', () {
      final paged = Paged.fromJson<String>({
        'items': [
          {'id': 'a'},
          'نصّ غير متوقّع',
          null,
          {'id': 'b'},
        ],
        'total': 4,
      }, (item) => item['id'] as String);

      expect(paged.items, ['a', 'b']);
    });
  });

  group('ApiException.displayMessage', () {
    test('يفضّل رسالة الخادم', () {
      const e = ApiException(
        code: ApiErrorCode.validationError,
        message: 'الرقم القومي غير صحيح',
      );
      expect(e.displayMessage, 'الرقم القومي غير صحيح');
    });

    test('يستخدم نصًّا افتراضيًا عربيًا حين تغيب رسالة الخادم', () {
      const e = ApiException(code: ApiErrorCode.offline, message: '');
      expect(e.displayMessage, contains('لا يوجد اتصال'));
      expect(e.displayMessage, contains('سيُرفَع تلقائيًا'));
    });
  });
}
