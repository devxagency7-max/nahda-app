import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/network/api_error_code.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/app_database.dart';
import '../domain/upload_stage.dart';
import 'attachments_api.dart';

const _uuid = Uuid();

/// يدير دورة حياة رفع المرفقات مع الاستئناف.
///
/// القاعدة الحاكمة: **الالتقاط لا يلمس الشبكة إطلاقًا.** الملف يُنسَخ لمجلد
/// التطبيق الدائم ويُسجَّل في Drift، والرفع يحدث لاحقًا حين تسمح الشبكة.
class AttachmentUploader {
  AttachmentUploader({required AttachmentsApi api, required AppDatabase db})
    : _api = api,
      _db = db;

  final AttachmentsApi _api;
  final AppDatabase _db;

  // ───────────────────────── الالتقاط ─────────────────────────

  /// يسجّل ملفًا للرفع لاحقًا.
  ///
  /// **ينسخ الملف لمجلد التطبيق الدائم** — مسار الكاميرا/المعرض مؤقت وقد
  /// يمسحه نظام التشغيل قبل أن تعود الشبكة، فيضيع عمل الأخصائي.
  ///
  /// يرمي [ApiException] عند رفض محلي (حجم/نوع) حتى يعيد الأخصائي التصوير فورًا
  /// بدل اكتشاف الرفض بعد يومين.
  Future<String> capture({
    required String caseId,
    required File sourceFile,
    required String documentType,
    String? fileName,
    String? description,
    String? fieldVisitLocalId,
  }) async {
    final name = fileName ?? p.basename(sourceFile.path);
    final size = await sourceFile.length();

    final rejection = AttachmentPolicy.validate(
      fileName: name,
      sizeBytes: size,
    );
    if (rejection != null) {
      throw ApiException(
        code: size > AttachmentPolicy.maxFileSizeBytes
            ? ApiErrorCode.fileTooLarge
            : ApiErrorCode.unsupportedFileType,
        message: rejection,
      );
    }

    final mimeType = AttachmentPolicy.mimeFor(name);
    if (mimeType == null) {
      throw const ApiException(
        code: ApiErrorCode.unsupportedFileType,
        message: 'نوع الملف غير مدعوم.',
      );
    }

    final id = _uuid.v4();
    final stored = await _copyToPermanentStorage(sourceFile, id, name);
    final now = DateTime.now();

    await _db
        .into(_db.pendingAttachments)
        .insert(
          PendingAttachmentsCompanion.insert(
            id: id,
            caseId: caseId,
            localPath: stored.path,
            fileName: name,
            mimeType: mimeType,
            fileSize: size,
            documentType: documentType,
            description: Value(description),
            fieldVisitLocalId: Value(fieldVisitLocalId),
            uploadStage: Value(UploadStage.captured.wireValue),
            createdAt: now,
            updatedAt: now,
          ),
        );

    return id;
  }

  Future<File> _copyToPermanentStorage(
    File source,
    String id,
    String fileName,
  ) async {
    final dir = Directory(
      p.join((await getApplicationDocumentsDirectory()).path, 'attachments'),
    );
    if (!await dir.exists()) await dir.create(recursive: true);

    final ext = AttachmentPolicy.extensionOf(fileName) ?? 'bin';
    return source.copy(p.join(dir.path, '$id.$ext'));
  }

  // ───────────────────────── الرفع ─────────────────────────

  /// يرفع مرفقًا واحدًا، مستأنفًا من آخر مرحلة وصل إليها.
  ///
  /// يرجع `true` عند اكتمال التثبيت.
  Future<bool> upload(
    String localId, {
    void Function(double progress)? onProgress,
  }) async {
    var row = await _read(localId);
    if (row == null) return false;

    var stage = UploadStage.fromWire(row.uploadStage);
    if (stage.isDone) return true;

    final file = File(row.localPath);
    if (!await file.exists()) {
      // الملف اختفى — لا جدوى من إعادة المحاولة.
      await _fail(localId, 'تعذّر العثور على الملف على الجهاز.');
      return false;
    }

    try {
      // الرابط الموقّع عمره ٣٠ دقيقة؛ المنتهي يستلزم /init جديدًا
      // مع قبول مرفق يتيم كثمن (§14.2).
      if (stage == UploadStage.initialized && _isUrlExpired(row)) {
        stage = UploadStage.captured;
      }

      if (stage == UploadStage.captured) {
        final init = await _api.init(
          caseId: row.caseId,
          documentType: row.documentType,
          fileName: row.fileName,
          mimeType: row.mimeType,
          fileSize: row.fileSize,
          description: row.description,
        );

        await _update(
          localId,
          PendingAttachmentsCompanion(
            attachmentId: Value(init.attachmentId),
            uploadUrl: Value(init.uploadUrl),
            uploadUrlExpiresAt: Value(init.expiresAtUtc),
            // الخادم قد يُطبّع النوع (مثل image/JPEG ← image/jpeg)؛
            // نحفظ قيمته لأنها ما سيُرسَل كـ Content-Type حرفيًا.
            mimeType: Value(init.mimeType),
            uploadStage: Value(UploadStage.initialized.wireValue),
          ),
        );

        row = (await _read(localId))!;
        stage = UploadStage.initialized;
      }

      if (stage == UploadStage.initialized || stage == UploadStage.uploading) {
        await _update(
          localId,
          PendingAttachmentsCompanion(
            uploadStage: Value(UploadStage.uploading.wireValue),
          ),
        );

        await _api.uploadBytes(
          uploadUrl: row.uploadUrl!,
          file: file,
          mimeType: row.mimeType,
          onProgress: (sent, total) {
            if (total <= 0) return;
            final progress = sent / total;
            onProgress?.call(progress);
            _updateProgress(localId, progress);
          },
        );

        await _update(
          localId,
          PendingAttachmentsCompanion(
            uploadStage: Value(UploadStage.uploaded.wireValue),
            progress: const Value(1),
          ),
        );
        stage = UploadStage.uploaded;
      }

      if (stage == UploadStage.uploaded) {
        final checksum = row.checksum ?? await _md5(file);

        // آمن لإعادة المحاولة: مرفق مُثبَّت أصلًا يرجع alreadyComplete
        // بدل خطأ — نستند إليه حين يضيع ردّ محاولة سابقة.
        await _api.commit(row.attachmentId!, checksum: checksum);

        await _update(
          localId,
          PendingAttachmentsCompanion(
            uploadStage: Value(UploadStage.committed.wireValue),
            checksum: Value(checksum),
            progress: const Value(1),
            lastErrorMessage: const Value(null),
          ),
        );
        return true;
      }

      return false;
    } on ApiException catch (e) {
      await _recordFailure(localId, e);
      return false;
    }
  }

  /// يرفع كل مرفقات حالة، على دفعات محدودة.
  ///
  /// `/init` عليه حدّ معدّل لكل مستخدم — رفع ١٥ صورة دفعة واحدة يستدعي 429.
  Future<bool> uploadAllForCase(
    String caseId, {
    void Function(int done, int total)? onProgress,
  }) async {
    final pending = await pendingForCase(caseId);
    if (pending.isEmpty) return true;

    var done = 0;
    var allSucceeded = true;

    for (var i = 0; i < pending.length; i += AttachmentPolicy.maxConcurrentUploads) {
      final batch = pending.skip(i).take(AttachmentPolicy.maxConcurrentUploads);

      final results = await Future.wait(batch.map((row) => upload(row.id)));

      for (final ok in results) {
        if (!ok) allSucceeded = false;
        onProgress?.call(++done, pending.length);
      }
    }

    return allSucceeded;
  }

  /// معرّفات الخادم للمرفقات المُثبَّتة لزيارة ميدانية.
  ///
  /// `photoAttachmentIds` في إنشاء الزيارة **يقبل المُثبَّت فقط** — لذا نرفع
  /// الصور بالكامل قبل إرسال الزيارة.
  Future<List<String>> committedIdsForVisit(String fieldVisitLocalId) async {
    final rows =
        await (_db.select(_db.pendingAttachments)..where(
              (t) =>
                  t.fieldVisitLocalId.equals(fieldVisitLocalId) &
                  t.uploadStage.equals(UploadStage.committed.wireValue),
            ))
            .get();

    return rows
        .map((r) => r.attachmentId)
        .whereType<String>()
        .toList(growable: false);
  }

  // ───────────────────────── القراءة ─────────────────────────

  Stream<List<PendingAttachmentRow>> watchForCase(String caseId) =>
      (_db.select(_db.pendingAttachments)
            ..where((t) => t.caseId.equals(caseId))
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .watch();

  Future<List<PendingAttachmentRow>> pendingForCase(String caseId) =>
      (_db.select(_db.pendingAttachments)
            ..where(
              (t) =>
                  t.caseId.equals(caseId) &
                  t.uploadStage.isNotIn([
                    UploadStage.committed.wireValue,
                    UploadStage.failed.wireValue,
                  ]),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .get();

  Future<List<PendingAttachmentRow>> allPending() =>
      (_db.select(_db.pendingAttachments)..where(
            (t) => t.uploadStage.isNotIn([
              UploadStage.committed.wireValue,
              UploadStage.failed.wireValue,
            ]),
          ))
          .get();

  Stream<int> watchPendingCount() {
    final query = _db.selectOnly(_db.pendingAttachments)
      ..addColumns([_db.pendingAttachments.id.count()])
      ..where(
        _db.pendingAttachments.uploadStage.isNotIn([
          UploadStage.committed.wireValue,
          UploadStage.failed.wireValue,
        ]),
      );
    return query
        .watchSingle()
        .map((row) => row.read(_db.pendingAttachments.id.count()) ?? 0);
  }

  /// يحذف مرفقًا لم يُرفَع بعد، مع ملفه المحلي.
  Future<void> discard(String localId) async {
    final row = await _read(localId);
    if (row == null) return;

    final file = File(row.localPath);
    if (await file.exists()) {
      await file.delete();
    }

    await (_db.delete(
      _db.pendingAttachments,
    )..where((t) => t.id.equals(localId))).go();
  }

  /// ينظّف ملفات المرفقات المُثبَّتة لتحرير مساحة الجهاز.
  ///
  /// آمن: المرفق صار على الخادم، والملف المحلي لم يعد لازمًا.
  Future<int> cleanUpCommittedFiles() async {
    final rows =
        await (_db.select(_db.pendingAttachments)..where(
              (t) => t.uploadStage.equals(UploadStage.committed.wireValue),
            ))
            .get();

    var freed = 0;
    for (final row in rows) {
      final file = File(row.localPath);
      if (await file.exists()) {
        freed += await file.length();
        await file.delete();
      }
    }
    return freed;
  }

  // ───────────────────────── مساعدات ─────────────────────────

  bool _isUrlExpired(PendingAttachmentRow row) {
    final expiry = row.uploadUrlExpiresAt;
    if (row.uploadUrl == null) return true;
    if (expiry == null) return false;
    // هامش دقيقة: رابط ينتهي أثناء الرفع يُفشِل العملية كلها.
    return DateTime.now().toUtc().isAfter(
      expiry.subtract(const Duration(minutes: 1)),
    );
  }

  Future<String> _md5(File file) async {
    final digest = await md5.bind(file.openRead()).first;
    return digest.toString();
  }

  Future<PendingAttachmentRow?> _read(String id) =>
      (_db.select(_db.pendingAttachments)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<void> _update(String id, PendingAttachmentsCompanion changes) =>
      (_db.update(_db.pendingAttachments)..where((t) => t.id.equals(id))).write(
        changes.copyWith(updatedAt: Value(DateTime.now())),
      );

  Future<void> _updateProgress(String id, double progress) =>
      (_db.update(_db.pendingAttachments)..where((t) => t.id.equals(id)))
          .write(PendingAttachmentsCompanion(progress: Value(progress)));

  Future<void> _recordFailure(String id, ApiException error) async {
    final row = await _read(id);
    if (row == null) return;

    // خطأ لا يُحَل بإعادة المحاولة (حجم/نوع مرفوض) يتوقف نهائيًا؛
    // الباقي يبقى معلّقًا ليُعاد تلقائيًا.
    final terminal = !error.isRetryable;

    await _update(
      id,
      PendingAttachmentsCompanion(
        attempts: Value(row.attempts + 1),
        lastErrorMessage: Value(error.displayMessage),
        uploadStage: terminal
            ? Value(UploadStage.failed.wireValue)
            : const Value.absent(),
      ),
    );
  }

  Future<void> _fail(String id, String message) => _update(
    id,
    PendingAttachmentsCompanion(
      uploadStage: Value(UploadStage.failed.wireValue),
      lastErrorMessage: Value(message),
    ),
  );
}

/// امتداد صغير لتوليد checksum من نصّ (للاختبارات).
String md5OfString(String input) => md5.convert(utf8.encode(input)).toString();
