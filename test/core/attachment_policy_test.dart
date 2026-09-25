import 'package:flutter_test/flutter_test.dart';
import 'package:nahda/features/attachments/domain/upload_stage.dart';

/// اختبارات سياسة المرفقات ومراحل الرفع.
///
/// الفحص المحلي وقت الالتقاط هو ما يمنع اكتشاف الرفض بعد يومين في الميدان.
void main() {
  group('حدّ الحجم', () {
    test('الحدّ ١٠ ميجابايت بالضبط كما في الخادم', () {
      expect(AttachmentPolicy.maxFileSizeBytes, 10485760);
    });

    test('ملف على الحدّ تمامًا مقبول', () {
      expect(
        AttachmentPolicy.validate(
          fileName: 'photo.jpg',
          sizeBytes: AttachmentPolicy.maxFileSizeBytes,
        ),
        isNull,
      );
    });

    test('ملف فوق الحدّ يُرفَض برسالة تذكر الحجم الفعلي', () {
      final error = AttachmentPolicy.validate(
        fileName: 'photo.jpg',
        sizeBytes: AttachmentPolicy.maxFileSizeBytes + 1,
      );

      expect(error, isNotNull);
      expect(error, contains('١٠ ميجابايت'));
      expect(error, contains('10.0'), reason: 'يعرض الحجم الفعلي للمستخدم');
    });

    test('ملف فارغ يُرفَض', () {
      expect(
        AttachmentPolicy.validate(fileName: 'photo.jpg', sizeBytes: 0),
        isNotNull,
      );
    });
  });

  group('الأنواع المسموحة', () {
    test('كل امتدادات القائمة المغلقة مقبولة', () {
      for (final ext in ['jpg', 'jpeg', 'png', 'heic', 'webp', 'pdf', 'doc', 'docx']) {
        expect(
          AttachmentPolicy.validate(fileName: 'file.$ext', sizeBytes: 1024),
          isNull,
          reason: 'الامتداد $ext يجب أن يُقبَل',
        );
      }
    });

    test('heic مدعوم — كاميرا آيفون تنتجه افتراضيًا', () {
      expect(AttachmentPolicy.mimeFor('IMG_2031.heic'), 'image/heic');
      expect(AttachmentPolicy.mimeFor('IMG_2031.HEIC'), 'image/heic');
    });

    test('امتداد خارج القائمة يُرفَض', () {
      for (final ext in ['exe', 'zip', 'mp4', 'txt', 'svg']) {
        expect(
          AttachmentPolicy.validate(fileName: 'file.$ext', sizeBytes: 1024),
          isNotNull,
          reason: 'الامتداد $ext يجب أن يُرفَض',
        );
      }
    });

    test('ملف بلا امتداد يُرفَض', () {
      expect(
        AttachmentPolicy.validate(fileName: 'photo', sizeBytes: 1024),
        isNotNull,
      );
      expect(
        AttachmentPolicy.validate(fileName: 'photo.', sizeBytes: 1024),
        isNotNull,
      );
    });

    test('الامتداد غير حسّاس لحالة الأحرف', () {
      expect(
        AttachmentPolicy.validate(fileName: 'PHOTO.JPG', sizeBytes: 1024),
        isNull,
      );
    });

    test('أنواع MIME تطابق القائمة المغلقة للخادم', () {
      expect(AttachmentPolicy.mimeFor('a.jpg'), 'image/jpeg');
      expect(AttachmentPolicy.mimeFor('a.jpeg'), 'image/jpeg');
      expect(AttachmentPolicy.mimeFor('a.png'), 'image/png');
      expect(AttachmentPolicy.mimeFor('a.webp'), 'image/webp');
      expect(AttachmentPolicy.mimeFor('a.pdf'), 'application/pdf');
      expect(AttachmentPolicy.mimeFor('a.doc'), 'application/msword');
      expect(
        AttachmentPolicy.mimeFor('a.docx'),
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      );
      expect(AttachmentPolicy.mimeFor('a.exe'), isNull);
    });

    test('كل نوع مُستنتَج موجود في قائمة الأنواع المسموحة', () {
      for (final ext in AttachmentPolicy.allowedExtensions) {
        final mime = AttachmentPolicy.mimeFor('file.$ext');
        expect(mime, isNotNull, reason: 'الامتداد $ext بلا نوع MIME');
        expect(
          AttachmentPolicy.allowedMimeTypes,
          contains(mime),
          reason: 'النوع $mime غير موجود في القائمة',
        );
      }
    });
  });

  group('النوافذ الزمنية', () {
    test('رابط الرفع ٣٠ دقيقة — أطول من التحميل عمدًا', () {
      expect(AttachmentPolicy.uploadUrlTtl, const Duration(minutes: 30));
      expect(AttachmentPolicy.downloadUrlTtl, const Duration(minutes: 15));
      expect(
        AttachmentPolicy.uploadUrlTtl,
        greaterThan(AttachmentPolicy.downloadUrlTtl),
        reason: 'رفع ١٠ ميجا على شبكة موبايل يحتاج وقتًا أطول',
      );
    });

    test('نافذة المرفق اليتيم ٤٨ ساعة', () {
      expect(AttachmentPolicy.orphanWindow, const Duration(hours: 48));
    });

    test('الرفع المتوازي محدود — /init عليه حدّ معدّل', () {
      expect(AttachmentPolicy.maxConcurrentUploads, lessThanOrEqualTo(3));
      expect(AttachmentPolicy.maxConcurrentUploads, greaterThan(0));
    });
  });

  group('مراحل الرفع', () {
    test('المراحل مرتّبة من الالتقاط للتثبيت', () {
      const flow = [
        UploadStage.captured,
        UploadStage.initialized,
        UploadStage.uploading,
        UploadStage.uploaded,
        UploadStage.committed,
      ];

      for (final stage in flow.take(4)) {
        expect(stage.needsWork, isTrue, reason: '${stage.name} يحتاج عملًا');
        expect(stage.isDone, isFalse);
      }

      expect(UploadStage.committed.isDone, isTrue);
      expect(UploadStage.committed.needsWork, isFalse);
    });

    test('الفشل النهائي لا يحتاج عملًا', () {
      expect(UploadStage.failed.needsWork, isFalse);
      expect(UploadStage.failed.isDone, isFalse);
    });

    test('كل مرحلة لها وصف عربي', () {
      for (final stage in UploadStage.values) {
        expect(stage.label, isNotEmpty);
      }
    });

    test('قيمة مجهولة تعود للالتقاط لا لانهيار', () {
      expect(UploadStage.fromWire('something_else'), UploadStage.captured);
    });

    test('كل قيمة تُرجَع لنفسها', () {
      for (final stage in UploadStage.values) {
        expect(UploadStage.fromWire(stage.wireValue), stage);
      }
    });
  });

  group('أنواع المستندات', () {
    test('لكل نوع اسم عربي معروض', () {
      for (final type in DocumentTypes.labels.keys) {
        expect(DocumentTypes.labels[type], isNotEmpty);
      }
      expect(
        DocumentTypes.labels[DocumentTypes.fieldVisitPhoto],
        'صورة زيارة ميدانية',
      );
    });
  });
}
