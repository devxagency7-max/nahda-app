// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SyncQueueTable extends SyncQueue
    with TableInfo<$SyncQueueTable, SyncOperationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _caseIdMeta = const VerificationMeta('caseId');
  @override
  late final GeneratedColumn<String> caseId = GeneratedColumn<String>(
    'case_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sequenceMeta = const VerificationMeta(
    'sequence',
  );
  @override
  late final GeneratedColumn<int> sequence = GeneratedColumn<int>(
    'sequence',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idempotencyKeyMeta = const VerificationMeta(
    'idempotencyKey',
  );
  @override
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
    'idempotency_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dedupIdMeta = const VerificationMeta(
    'dedupId',
  );
  @override
  late final GeneratedColumn<String> dedupId = GeneratedColumn<String>(
    'dedup_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rowVersionMeta = const VerificationMeta(
    'rowVersion',
  );
  @override
  late final GeneratedColumn<int> rowVersion = GeneratedColumn<int>(
    'row_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorCodeMeta = const VerificationMeta(
    'lastErrorCode',
  );
  @override
  late final GeneratedColumn<String> lastErrorCode = GeneratedColumn<String>(
    'last_error_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastErrorMessageMeta = const VerificationMeta(
    'lastErrorMessage',
  );
  @override
  late final GeneratedColumn<String> lastErrorMessage = GeneratedColumn<String>(
    'last_error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nextAttemptAtMeta = const VerificationMeta(
    'nextAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextAttemptAt =
      GeneratedColumn<DateTime>(
        'next_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sentAtMeta = const VerificationMeta('sentAt');
  @override
  late final GeneratedColumn<DateTime> sentAt = GeneratedColumn<DateTime>(
    'sent_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    caseId,
    userId,
    sequence,
    payload,
    idempotencyKey,
    dedupId,
    rowVersion,
    status,
    attempts,
    lastErrorCode,
    lastErrorMessage,
    nextAttemptAt,
    createdAt,
    updatedAt,
    sentAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncOperationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('case_id')) {
      context.handle(
        _caseIdMeta,
        caseId.isAcceptableOrUnknown(data['case_id']!, _caseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_caseIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('sequence')) {
      context.handle(
        _sequenceMeta,
        sequence.isAcceptableOrUnknown(data['sequence']!, _sequenceMeta),
      );
    } else if (isInserting) {
      context.missing(_sequenceMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('idempotency_key')) {
      context.handle(
        _idempotencyKeyMeta,
        idempotencyKey.isAcceptableOrUnknown(
          data['idempotency_key']!,
          _idempotencyKeyMeta,
        ),
      );
    }
    if (data.containsKey('dedup_id')) {
      context.handle(
        _dedupIdMeta,
        dedupId.isAcceptableOrUnknown(data['dedup_id']!, _dedupIdMeta),
      );
    }
    if (data.containsKey('row_version')) {
      context.handle(
        _rowVersionMeta,
        rowVersion.isAcceptableOrUnknown(data['row_version']!, _rowVersionMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('last_error_code')) {
      context.handle(
        _lastErrorCodeMeta,
        lastErrorCode.isAcceptableOrUnknown(
          data['last_error_code']!,
          _lastErrorCodeMeta,
        ),
      );
    }
    if (data.containsKey('last_error_message')) {
      context.handle(
        _lastErrorMessageMeta,
        lastErrorMessage.isAcceptableOrUnknown(
          data['last_error_message']!,
          _lastErrorMessageMeta,
        ),
      );
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(
        _nextAttemptAtMeta,
        nextAttemptAt.isAcceptableOrUnknown(
          data['next_attempt_at']!,
          _nextAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('sent_at')) {
      context.handle(
        _sentAtMeta,
        sentAt.isAcceptableOrUnknown(data['sent_at']!, _sentAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncOperationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncOperationRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      caseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}case_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      ),
      sequence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sequence'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      idempotencyKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}idempotency_key'],
      ),
      dedupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dedup_id'],
      ),
      rowVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}row_version'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      lastErrorCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error_code'],
      ),
      lastErrorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error_message'],
      ),
      nextAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_attempt_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      sentAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}sent_at'],
      ),
    );
  }

  @override
  $SyncQueueTable createAlias(String alias) {
    return $SyncQueueTable(attachedDatabase, alias);
  }
}

class SyncOperationRow extends DataClass
    implements Insertable<SyncOperationRow> {
  /// معرّف محلي (UUID) — لا علاقة له بمعرّف الخادم.
  final String id;

  /// `SyncOperationType.wireValue`.
  final String type;

  /// الحالة التي تنتمي إليها العملية.
  ///
  /// التفريغ مُجمَّع حسبها: تعارض في حالة **لا يوقف** مزامنة حالة أخرى.
  final String caseId;

  /// معرّف المستخدم الذي أنشأ هذه العملية — `AuthUser.id` وقت `enqueue`.
  ///
  /// **`null` فقط للصفوف الموجودة قبل هذا العمود** (ترقية من الإصدار ١، راجع
  /// `AppDatabase.migration`) — لا يُنشَأ أي صفّ جديد بدونه بعد اليوم. يمنع
  /// `SyncEngine`/`background_sync.dart` من تنفيذ عملية حساب سابق بتوكن حساب
  /// لاحق على نفس الجهاز (AUTH_SESSION_AUDIT.md، مشكلة #4 CRITICAL).
  final String? userId;

  /// ترتيب الإنشاء داخل نفس الحالة — التفريغ يحترمه بصرامة.
  final int sequence;

  /// جسم الطلب كـ JSON.
  final String payload;

  /// `Idempotency-Key` — يُولَّد **مرة واحدة** عند إنشاء العملية ولا يتغيّر.
  ///
  /// إعادة توليده في كل محاولة تُبطل الآلية وتسمح بتنفيذ مزدوج (§15.3).
  final String? idempotencyKey;

  /// معرّف تكرار محلي — للزيارات الميدانية التي لا يحرسها الخادم (§14.2).
  final String? dedupId;

  /// `rowVersion` / `caseRowVersion` وقت إنشاء العملية.
  ///
  /// قد يبطل قبل التفريغ (تعديل قسم آخر يزيد نسخة الحالة)، لذا محرّك
  /// المزامنة يُعيد الجلب قبل الإرسال.
  final int? rowVersion;

  /// `SyncOperationStatus.wireValue`.
  final String status;
  final int attempts;

  /// كود الخطأ الأخير (`ApiErrorCode.wireValue`).
  final String? lastErrorCode;

  /// رسالة الخطأ الأخيرة بالعربية — تُعرَض للمستخدم مباشرة.
  final String? lastErrorMessage;

  /// متى يُسمَح بالمحاولة التالية (تباعد أسّي).
  final DateTime? nextAttemptAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// وقت آخر إرسال — يكشف عملية عالقة في `inFlight` بعد موت التطبيق.
  final DateTime? sentAt;
  const SyncOperationRow({
    required this.id,
    required this.type,
    required this.caseId,
    this.userId,
    required this.sequence,
    required this.payload,
    this.idempotencyKey,
    this.dedupId,
    this.rowVersion,
    required this.status,
    required this.attempts,
    this.lastErrorCode,
    this.lastErrorMessage,
    this.nextAttemptAt,
    required this.createdAt,
    required this.updatedAt,
    this.sentAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type'] = Variable<String>(type);
    map['case_id'] = Variable<String>(caseId);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    map['sequence'] = Variable<int>(sequence);
    map['payload'] = Variable<String>(payload);
    if (!nullToAbsent || idempotencyKey != null) {
      map['idempotency_key'] = Variable<String>(idempotencyKey);
    }
    if (!nullToAbsent || dedupId != null) {
      map['dedup_id'] = Variable<String>(dedupId);
    }
    if (!nullToAbsent || rowVersion != null) {
      map['row_version'] = Variable<int>(rowVersion);
    }
    map['status'] = Variable<String>(status);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || lastErrorCode != null) {
      map['last_error_code'] = Variable<String>(lastErrorCode);
    }
    if (!nullToAbsent || lastErrorMessage != null) {
      map['last_error_message'] = Variable<String>(lastErrorMessage);
    }
    if (!nullToAbsent || nextAttemptAt != null) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || sentAt != null) {
      map['sent_at'] = Variable<DateTime>(sentAt);
    }
    return map;
  }

  SyncQueueCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueCompanion(
      id: Value(id),
      type: Value(type),
      caseId: Value(caseId),
      userId: userId == null && nullToAbsent
          ? const Value.absent()
          : Value(userId),
      sequence: Value(sequence),
      payload: Value(payload),
      idempotencyKey: idempotencyKey == null && nullToAbsent
          ? const Value.absent()
          : Value(idempotencyKey),
      dedupId: dedupId == null && nullToAbsent
          ? const Value.absent()
          : Value(dedupId),
      rowVersion: rowVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(rowVersion),
      status: Value(status),
      attempts: Value(attempts),
      lastErrorCode: lastErrorCode == null && nullToAbsent
          ? const Value.absent()
          : Value(lastErrorCode),
      lastErrorMessage: lastErrorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(lastErrorMessage),
      nextAttemptAt: nextAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextAttemptAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      sentAt: sentAt == null && nullToAbsent
          ? const Value.absent()
          : Value(sentAt),
    );
  }

  factory SyncOperationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncOperationRow(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      caseId: serializer.fromJson<String>(json['caseId']),
      userId: serializer.fromJson<String?>(json['userId']),
      sequence: serializer.fromJson<int>(json['sequence']),
      payload: serializer.fromJson<String>(json['payload']),
      idempotencyKey: serializer.fromJson<String?>(json['idempotencyKey']),
      dedupId: serializer.fromJson<String?>(json['dedupId']),
      rowVersion: serializer.fromJson<int?>(json['rowVersion']),
      status: serializer.fromJson<String>(json['status']),
      attempts: serializer.fromJson<int>(json['attempts']),
      lastErrorCode: serializer.fromJson<String?>(json['lastErrorCode']),
      lastErrorMessage: serializer.fromJson<String?>(json['lastErrorMessage']),
      nextAttemptAt: serializer.fromJson<DateTime?>(json['nextAttemptAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      sentAt: serializer.fromJson<DateTime?>(json['sentAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(type),
      'caseId': serializer.toJson<String>(caseId),
      'userId': serializer.toJson<String?>(userId),
      'sequence': serializer.toJson<int>(sequence),
      'payload': serializer.toJson<String>(payload),
      'idempotencyKey': serializer.toJson<String?>(idempotencyKey),
      'dedupId': serializer.toJson<String?>(dedupId),
      'rowVersion': serializer.toJson<int?>(rowVersion),
      'status': serializer.toJson<String>(status),
      'attempts': serializer.toJson<int>(attempts),
      'lastErrorCode': serializer.toJson<String?>(lastErrorCode),
      'lastErrorMessage': serializer.toJson<String?>(lastErrorMessage),
      'nextAttemptAt': serializer.toJson<DateTime?>(nextAttemptAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'sentAt': serializer.toJson<DateTime?>(sentAt),
    };
  }

  SyncOperationRow copyWith({
    String? id,
    String? type,
    String? caseId,
    Value<String?> userId = const Value.absent(),
    int? sequence,
    String? payload,
    Value<String?> idempotencyKey = const Value.absent(),
    Value<String?> dedupId = const Value.absent(),
    Value<int?> rowVersion = const Value.absent(),
    String? status,
    int? attempts,
    Value<String?> lastErrorCode = const Value.absent(),
    Value<String?> lastErrorMessage = const Value.absent(),
    Value<DateTime?> nextAttemptAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> sentAt = const Value.absent(),
  }) => SyncOperationRow(
    id: id ?? this.id,
    type: type ?? this.type,
    caseId: caseId ?? this.caseId,
    userId: userId.present ? userId.value : this.userId,
    sequence: sequence ?? this.sequence,
    payload: payload ?? this.payload,
    idempotencyKey: idempotencyKey.present
        ? idempotencyKey.value
        : this.idempotencyKey,
    dedupId: dedupId.present ? dedupId.value : this.dedupId,
    rowVersion: rowVersion.present ? rowVersion.value : this.rowVersion,
    status: status ?? this.status,
    attempts: attempts ?? this.attempts,
    lastErrorCode: lastErrorCode.present
        ? lastErrorCode.value
        : this.lastErrorCode,
    lastErrorMessage: lastErrorMessage.present
        ? lastErrorMessage.value
        : this.lastErrorMessage,
    nextAttemptAt: nextAttemptAt.present
        ? nextAttemptAt.value
        : this.nextAttemptAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    sentAt: sentAt.present ? sentAt.value : this.sentAt,
  );
  SyncOperationRow copyWithCompanion(SyncQueueCompanion data) {
    return SyncOperationRow(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      caseId: data.caseId.present ? data.caseId.value : this.caseId,
      userId: data.userId.present ? data.userId.value : this.userId,
      sequence: data.sequence.present ? data.sequence.value : this.sequence,
      payload: data.payload.present ? data.payload.value : this.payload,
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
      dedupId: data.dedupId.present ? data.dedupId.value : this.dedupId,
      rowVersion: data.rowVersion.present
          ? data.rowVersion.value
          : this.rowVersion,
      status: data.status.present ? data.status.value : this.status,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      lastErrorCode: data.lastErrorCode.present
          ? data.lastErrorCode.value
          : this.lastErrorCode,
      lastErrorMessage: data.lastErrorMessage.present
          ? data.lastErrorMessage.value
          : this.lastErrorMessage,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      sentAt: data.sentAt.present ? data.sentAt.value : this.sentAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncOperationRow(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('caseId: $caseId, ')
          ..write('userId: $userId, ')
          ..write('sequence: $sequence, ')
          ..write('payload: $payload, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('dedupId: $dedupId, ')
          ..write('rowVersion: $rowVersion, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('lastErrorCode: $lastErrorCode, ')
          ..write('lastErrorMessage: $lastErrorMessage, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('sentAt: $sentAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    caseId,
    userId,
    sequence,
    payload,
    idempotencyKey,
    dedupId,
    rowVersion,
    status,
    attempts,
    lastErrorCode,
    lastErrorMessage,
    nextAttemptAt,
    createdAt,
    updatedAt,
    sentAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncOperationRow &&
          other.id == this.id &&
          other.type == this.type &&
          other.caseId == this.caseId &&
          other.userId == this.userId &&
          other.sequence == this.sequence &&
          other.payload == this.payload &&
          other.idempotencyKey == this.idempotencyKey &&
          other.dedupId == this.dedupId &&
          other.rowVersion == this.rowVersion &&
          other.status == this.status &&
          other.attempts == this.attempts &&
          other.lastErrorCode == this.lastErrorCode &&
          other.lastErrorMessage == this.lastErrorMessage &&
          other.nextAttemptAt == this.nextAttemptAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.sentAt == this.sentAt);
}

class SyncQueueCompanion extends UpdateCompanion<SyncOperationRow> {
  final Value<String> id;
  final Value<String> type;
  final Value<String> caseId;
  final Value<String?> userId;
  final Value<int> sequence;
  final Value<String> payload;
  final Value<String?> idempotencyKey;
  final Value<String?> dedupId;
  final Value<int?> rowVersion;
  final Value<String> status;
  final Value<int> attempts;
  final Value<String?> lastErrorCode;
  final Value<String?> lastErrorMessage;
  final Value<DateTime?> nextAttemptAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> sentAt;
  final Value<int> rowid;
  const SyncQueueCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.caseId = const Value.absent(),
    this.userId = const Value.absent(),
    this.sequence = const Value.absent(),
    this.payload = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.dedupId = const Value.absent(),
    this.rowVersion = const Value.absent(),
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastErrorCode = const Value.absent(),
    this.lastErrorMessage = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.sentAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncQueueCompanion.insert({
    required String id,
    required String type,
    required String caseId,
    this.userId = const Value.absent(),
    required int sequence,
    required String payload,
    this.idempotencyKey = const Value.absent(),
    this.dedupId = const Value.absent(),
    this.rowVersion = const Value.absent(),
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastErrorCode = const Value.absent(),
    this.lastErrorMessage = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.sentAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       type = Value(type),
       caseId = Value(caseId),
       sequence = Value(sequence),
       payload = Value(payload),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<SyncOperationRow> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<String>? caseId,
    Expression<String>? userId,
    Expression<int>? sequence,
    Expression<String>? payload,
    Expression<String>? idempotencyKey,
    Expression<String>? dedupId,
    Expression<int>? rowVersion,
    Expression<String>? status,
    Expression<int>? attempts,
    Expression<String>? lastErrorCode,
    Expression<String>? lastErrorMessage,
    Expression<DateTime>? nextAttemptAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? sentAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (caseId != null) 'case_id': caseId,
      if (userId != null) 'user_id': userId,
      if (sequence != null) 'sequence': sequence,
      if (payload != null) 'payload': payload,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (dedupId != null) 'dedup_id': dedupId,
      if (rowVersion != null) 'row_version': rowVersion,
      if (status != null) 'status': status,
      if (attempts != null) 'attempts': attempts,
      if (lastErrorCode != null) 'last_error_code': lastErrorCode,
      if (lastErrorMessage != null) 'last_error_message': lastErrorMessage,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (sentAt != null) 'sent_at': sentAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncQueueCompanion copyWith({
    Value<String>? id,
    Value<String>? type,
    Value<String>? caseId,
    Value<String?>? userId,
    Value<int>? sequence,
    Value<String>? payload,
    Value<String?>? idempotencyKey,
    Value<String?>? dedupId,
    Value<int?>? rowVersion,
    Value<String>? status,
    Value<int>? attempts,
    Value<String?>? lastErrorCode,
    Value<String?>? lastErrorMessage,
    Value<DateTime?>? nextAttemptAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? sentAt,
    Value<int>? rowid,
  }) {
    return SyncQueueCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      caseId: caseId ?? this.caseId,
      userId: userId ?? this.userId,
      sequence: sequence ?? this.sequence,
      payload: payload ?? this.payload,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      dedupId: dedupId ?? this.dedupId,
      rowVersion: rowVersion ?? this.rowVersion,
      status: status ?? this.status,
      attempts: attempts ?? this.attempts,
      lastErrorCode: lastErrorCode ?? this.lastErrorCode,
      lastErrorMessage: lastErrorMessage ?? this.lastErrorMessage,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sentAt: sentAt ?? this.sentAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (caseId.present) {
      map['case_id'] = Variable<String>(caseId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (sequence.present) {
      map['sequence'] = Variable<int>(sequence.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (dedupId.present) {
      map['dedup_id'] = Variable<String>(dedupId.value);
    }
    if (rowVersion.present) {
      map['row_version'] = Variable<int>(rowVersion.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (lastErrorCode.present) {
      map['last_error_code'] = Variable<String>(lastErrorCode.value);
    }
    if (lastErrorMessage.present) {
      map['last_error_message'] = Variable<String>(lastErrorMessage.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (sentAt.present) {
      map['sent_at'] = Variable<DateTime>(sentAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('caseId: $caseId, ')
          ..write('userId: $userId, ')
          ..write('sequence: $sequence, ')
          ..write('payload: $payload, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('dedupId: $dedupId, ')
          ..write('rowVersion: $rowVersion, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('lastErrorCode: $lastErrorCode, ')
          ..write('lastErrorMessage: $lastErrorMessage, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('sentAt: $sentAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedCasesTable extends CachedCases
    with TableInfo<$CachedCasesTable, CachedCaseRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedCasesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _caseNumberMeta = const VerificationMeta(
    'caseNumber',
  );
  @override
  late final GeneratedColumn<String> caseNumber = GeneratedColumn<String>(
    'case_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayIdMeta = const VerificationMeta(
    'displayId',
  );
  @override
  late final GeneratedColumn<String> displayId = GeneratedColumn<String>(
    'display_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<String> priority = GeneratedColumn<String>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _beneficiaryFullNameMeta =
      const VerificationMeta('beneficiaryFullName');
  @override
  late final GeneratedColumn<String> beneficiaryFullName =
      GeneratedColumn<String>(
        'beneficiary_full_name',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _nationalIdMeta = const VerificationMeta(
    'nationalId',
  );
  @override
  late final GeneratedColumn<String> nationalId = GeneratedColumn<String>(
    'national_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _charityIdMeta = const VerificationMeta(
    'charityId',
  );
  @override
  late final GeneratedColumn<String> charityId = GeneratedColumn<String>(
    'charity_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _registrationDateMeta = const VerificationMeta(
    'registrationDate',
  );
  @override
  late final GeneratedColumn<String> registrationDate = GeneratedColumn<String>(
    'registration_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completionPercentageMeta =
      const VerificationMeta('completionPercentage');
  @override
  late final GeneratedColumn<double> completionPercentage =
      GeneratedColumn<double>(
        'completion_percentage',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      );
  static const VerificationMeta _nextVisitDateMeta = const VerificationMeta(
    'nextVisitDate',
  );
  @override
  late final GeneratedColumn<String> nextVisitDate = GeneratedColumn<String>(
    'next_visit_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nextVisitStartTimeUtcMeta =
      const VerificationMeta('nextVisitStartTimeUtc');
  @override
  late final GeneratedColumn<DateTime> nextVisitStartTimeUtc =
      GeneratedColumn<DateTime>(
        'next_visit_start_time_utc',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _nextVisitLocationMeta = const VerificationMeta(
    'nextVisitLocation',
  );
  @override
  late final GeneratedColumn<String> nextVisitLocation =
      GeneratedColumn<String>(
        'next_visit_location',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _isBookmarkedMeta = const VerificationMeta(
    'isBookmarked',
  );
  @override
  late final GeneratedColumn<bool> isBookmarked = GeneratedColumn<bool>(
    'is_bookmarked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_bookmarked" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _rowVersionMeta = const VerificationMeta(
    'rowVersion',
  );
  @override
  late final GeneratedColumn<int> rowVersion = GeneratedColumn<int>(
    'row_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _beneficiaryRowVersionMeta =
      const VerificationMeta('beneficiaryRowVersion');
  @override
  late final GeneratedColumn<int> beneficiaryRowVersion = GeneratedColumn<int>(
    'beneficiary_row_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _availableActionsJsonMeta =
      const VerificationMeta('availableActionsJson');
  @override
  late final GeneratedColumn<String> availableActionsJson =
      GeneratedColumn<String>(
        'available_actions_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _detailsJsonMeta = const VerificationMeta(
    'detailsJson',
  );
  @override
  late final GeneratedColumn<String> detailsJson = GeneratedColumn<String>(
    'details_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hasFullDetailsMeta = const VerificationMeta(
    'hasFullDetails',
  );
  @override
  late final GeneratedColumn<bool> hasFullDetails = GeneratedColumn<bool>(
    'has_full_details',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_full_details" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _syncStateMeta = const VerificationMeta(
    'syncState',
  );
  @override
  late final GeneratedColumn<String> syncState = GeneratedColumn<String>(
    'sync_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('synced'),
  );
  static const VerificationMeta _serverUpdatedAtMeta = const VerificationMeta(
    'serverUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> serverUpdatedAt =
      GeneratedColumn<DateTime>(
        'server_updated_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _localUpdatedAtMeta = const VerificationMeta(
    'localUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> localUpdatedAt =
      GeneratedColumn<DateTime>(
        'local_updated_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    caseNumber,
    displayId,
    status,
    priority,
    beneficiaryFullName,
    nationalId,
    charityId,
    registrationDate,
    completionPercentage,
    nextVisitDate,
    nextVisitStartTimeUtc,
    nextVisitLocation,
    isBookmarked,
    rowVersion,
    beneficiaryRowVersion,
    availableActionsJson,
    detailsJson,
    hasFullDetails,
    syncState,
    serverUpdatedAt,
    localUpdatedAt,
    fetchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_cases';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedCaseRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('case_number')) {
      context.handle(
        _caseNumberMeta,
        caseNumber.isAcceptableOrUnknown(data['case_number']!, _caseNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_caseNumberMeta);
    }
    if (data.containsKey('display_id')) {
      context.handle(
        _displayIdMeta,
        displayId.isAcceptableOrUnknown(data['display_id']!, _displayIdMeta),
      );
    } else if (isInserting) {
      context.missing(_displayIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    } else if (isInserting) {
      context.missing(_priorityMeta);
    }
    if (data.containsKey('beneficiary_full_name')) {
      context.handle(
        _beneficiaryFullNameMeta,
        beneficiaryFullName.isAcceptableOrUnknown(
          data['beneficiary_full_name']!,
          _beneficiaryFullNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_beneficiaryFullNameMeta);
    }
    if (data.containsKey('national_id')) {
      context.handle(
        _nationalIdMeta,
        nationalId.isAcceptableOrUnknown(data['national_id']!, _nationalIdMeta),
      );
    }
    if (data.containsKey('charity_id')) {
      context.handle(
        _charityIdMeta,
        charityId.isAcceptableOrUnknown(data['charity_id']!, _charityIdMeta),
      );
    }
    if (data.containsKey('registration_date')) {
      context.handle(
        _registrationDateMeta,
        registrationDate.isAcceptableOrUnknown(
          data['registration_date']!,
          _registrationDateMeta,
        ),
      );
    }
    if (data.containsKey('completion_percentage')) {
      context.handle(
        _completionPercentageMeta,
        completionPercentage.isAcceptableOrUnknown(
          data['completion_percentage']!,
          _completionPercentageMeta,
        ),
      );
    }
    if (data.containsKey('next_visit_date')) {
      context.handle(
        _nextVisitDateMeta,
        nextVisitDate.isAcceptableOrUnknown(
          data['next_visit_date']!,
          _nextVisitDateMeta,
        ),
      );
    }
    if (data.containsKey('next_visit_start_time_utc')) {
      context.handle(
        _nextVisitStartTimeUtcMeta,
        nextVisitStartTimeUtc.isAcceptableOrUnknown(
          data['next_visit_start_time_utc']!,
          _nextVisitStartTimeUtcMeta,
        ),
      );
    }
    if (data.containsKey('next_visit_location')) {
      context.handle(
        _nextVisitLocationMeta,
        nextVisitLocation.isAcceptableOrUnknown(
          data['next_visit_location']!,
          _nextVisitLocationMeta,
        ),
      );
    }
    if (data.containsKey('is_bookmarked')) {
      context.handle(
        _isBookmarkedMeta,
        isBookmarked.isAcceptableOrUnknown(
          data['is_bookmarked']!,
          _isBookmarkedMeta,
        ),
      );
    }
    if (data.containsKey('row_version')) {
      context.handle(
        _rowVersionMeta,
        rowVersion.isAcceptableOrUnknown(data['row_version']!, _rowVersionMeta),
      );
    }
    if (data.containsKey('beneficiary_row_version')) {
      context.handle(
        _beneficiaryRowVersionMeta,
        beneficiaryRowVersion.isAcceptableOrUnknown(
          data['beneficiary_row_version']!,
          _beneficiaryRowVersionMeta,
        ),
      );
    }
    if (data.containsKey('available_actions_json')) {
      context.handle(
        _availableActionsJsonMeta,
        availableActionsJson.isAcceptableOrUnknown(
          data['available_actions_json']!,
          _availableActionsJsonMeta,
        ),
      );
    }
    if (data.containsKey('details_json')) {
      context.handle(
        _detailsJsonMeta,
        detailsJson.isAcceptableOrUnknown(
          data['details_json']!,
          _detailsJsonMeta,
        ),
      );
    }
    if (data.containsKey('has_full_details')) {
      context.handle(
        _hasFullDetailsMeta,
        hasFullDetails.isAcceptableOrUnknown(
          data['has_full_details']!,
          _hasFullDetailsMeta,
        ),
      );
    }
    if (data.containsKey('sync_state')) {
      context.handle(
        _syncStateMeta,
        syncState.isAcceptableOrUnknown(data['sync_state']!, _syncStateMeta),
      );
    }
    if (data.containsKey('server_updated_at')) {
      context.handle(
        _serverUpdatedAtMeta,
        serverUpdatedAt.isAcceptableOrUnknown(
          data['server_updated_at']!,
          _serverUpdatedAtMeta,
        ),
      );
    }
    if (data.containsKey('local_updated_at')) {
      context.handle(
        _localUpdatedAtMeta,
        localUpdatedAt.isAcceptableOrUnknown(
          data['local_updated_at']!,
          _localUpdatedAtMeta,
        ),
      );
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedCaseRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedCaseRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      caseNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}case_number'],
      )!,
      displayId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}priority'],
      )!,
      beneficiaryFullName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}beneficiary_full_name'],
      )!,
      nationalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}national_id'],
      ),
      charityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}charity_id'],
      ),
      registrationDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}registration_date'],
      ),
      completionPercentage: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}completion_percentage'],
      )!,
      nextVisitDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}next_visit_date'],
      ),
      nextVisitStartTimeUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_visit_start_time_utc'],
      ),
      nextVisitLocation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}next_visit_location'],
      ),
      isBookmarked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_bookmarked'],
      )!,
      rowVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}row_version'],
      ),
      beneficiaryRowVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}beneficiary_row_version'],
      ),
      availableActionsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}available_actions_json'],
      ),
      detailsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}details_json'],
      ),
      hasFullDetails: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_full_details'],
      )!,
      syncState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_state'],
      )!,
      serverUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}server_updated_at'],
      ),
      localUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}local_updated_at'],
      ),
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $CachedCasesTable createAlias(String alias) {
    return $CachedCasesTable(attachedDatabase, alias);
  }
}

class CachedCaseRow extends DataClass implements Insertable<CachedCaseRow> {
  final String id;
  final String caseNumber;
  final String displayId;

  /// قيمة wire من الحالات العشر (`draft` … `rejected`).
  final String status;
  final String priority;
  final String beneficiaryFullName;
  final String? nationalId;
  final String? charityId;
  final String? registrationDate;
  final double completionPercentage;

  /// أقرب زيارة غير مكتملة — تُشتقّ منها حالة العرض "زيارة مجدولة".
  final String? nextVisitDate;
  final DateTime? nextVisitStartTimeUtc;
  final String? nextVisitLocation;
  final bool isBookmarked;

  /// نسخة صفّ الحالة — تُستخدم في `caseRowVersion` لأقسام القوائم.
  final int? rowVersion;

  /// نسخة صفّ المستفيد — **عدّاد منفصل تمامًا** عن نسخة الحالة (§19).
  final int? beneficiaryRowVersion;

  /// `workflow.availableActions` كـ JSON — تلميح UX فقط، ليس تفويضًا (§15.7).
  final String? availableActionsJson;

  /// تفاصيل الحالة الكاملة كـ JSON (استجابة `GET /cases/{id}`).
  ///
  /// نخزّنها خامًا حتى نتمكّن من العرض أوفلاين دون نمذجة كل حقل مسبقًا.
  final String? detailsJson;

  /// هل جُلبت التفاصيل الكاملة، أم العنوان فقط من قائمة العمل؟
  final bool hasFullDetails;

  /// حالة المزامنة المعروضة (`SyncState.name`).
  final String syncState;
  final DateTime? serverUpdatedAt;
  final DateTime? localUpdatedAt;
  final DateTime fetchedAt;
  const CachedCaseRow({
    required this.id,
    required this.caseNumber,
    required this.displayId,
    required this.status,
    required this.priority,
    required this.beneficiaryFullName,
    this.nationalId,
    this.charityId,
    this.registrationDate,
    required this.completionPercentage,
    this.nextVisitDate,
    this.nextVisitStartTimeUtc,
    this.nextVisitLocation,
    required this.isBookmarked,
    this.rowVersion,
    this.beneficiaryRowVersion,
    this.availableActionsJson,
    this.detailsJson,
    required this.hasFullDetails,
    required this.syncState,
    this.serverUpdatedAt,
    this.localUpdatedAt,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['case_number'] = Variable<String>(caseNumber);
    map['display_id'] = Variable<String>(displayId);
    map['status'] = Variable<String>(status);
    map['priority'] = Variable<String>(priority);
    map['beneficiary_full_name'] = Variable<String>(beneficiaryFullName);
    if (!nullToAbsent || nationalId != null) {
      map['national_id'] = Variable<String>(nationalId);
    }
    if (!nullToAbsent || charityId != null) {
      map['charity_id'] = Variable<String>(charityId);
    }
    if (!nullToAbsent || registrationDate != null) {
      map['registration_date'] = Variable<String>(registrationDate);
    }
    map['completion_percentage'] = Variable<double>(completionPercentage);
    if (!nullToAbsent || nextVisitDate != null) {
      map['next_visit_date'] = Variable<String>(nextVisitDate);
    }
    if (!nullToAbsent || nextVisitStartTimeUtc != null) {
      map['next_visit_start_time_utc'] = Variable<DateTime>(
        nextVisitStartTimeUtc,
      );
    }
    if (!nullToAbsent || nextVisitLocation != null) {
      map['next_visit_location'] = Variable<String>(nextVisitLocation);
    }
    map['is_bookmarked'] = Variable<bool>(isBookmarked);
    if (!nullToAbsent || rowVersion != null) {
      map['row_version'] = Variable<int>(rowVersion);
    }
    if (!nullToAbsent || beneficiaryRowVersion != null) {
      map['beneficiary_row_version'] = Variable<int>(beneficiaryRowVersion);
    }
    if (!nullToAbsent || availableActionsJson != null) {
      map['available_actions_json'] = Variable<String>(availableActionsJson);
    }
    if (!nullToAbsent || detailsJson != null) {
      map['details_json'] = Variable<String>(detailsJson);
    }
    map['has_full_details'] = Variable<bool>(hasFullDetails);
    map['sync_state'] = Variable<String>(syncState);
    if (!nullToAbsent || serverUpdatedAt != null) {
      map['server_updated_at'] = Variable<DateTime>(serverUpdatedAt);
    }
    if (!nullToAbsent || localUpdatedAt != null) {
      map['local_updated_at'] = Variable<DateTime>(localUpdatedAt);
    }
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  CachedCasesCompanion toCompanion(bool nullToAbsent) {
    return CachedCasesCompanion(
      id: Value(id),
      caseNumber: Value(caseNumber),
      displayId: Value(displayId),
      status: Value(status),
      priority: Value(priority),
      beneficiaryFullName: Value(beneficiaryFullName),
      nationalId: nationalId == null && nullToAbsent
          ? const Value.absent()
          : Value(nationalId),
      charityId: charityId == null && nullToAbsent
          ? const Value.absent()
          : Value(charityId),
      registrationDate: registrationDate == null && nullToAbsent
          ? const Value.absent()
          : Value(registrationDate),
      completionPercentage: Value(completionPercentage),
      nextVisitDate: nextVisitDate == null && nullToAbsent
          ? const Value.absent()
          : Value(nextVisitDate),
      nextVisitStartTimeUtc: nextVisitStartTimeUtc == null && nullToAbsent
          ? const Value.absent()
          : Value(nextVisitStartTimeUtc),
      nextVisitLocation: nextVisitLocation == null && nullToAbsent
          ? const Value.absent()
          : Value(nextVisitLocation),
      isBookmarked: Value(isBookmarked),
      rowVersion: rowVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(rowVersion),
      beneficiaryRowVersion: beneficiaryRowVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(beneficiaryRowVersion),
      availableActionsJson: availableActionsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(availableActionsJson),
      detailsJson: detailsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(detailsJson),
      hasFullDetails: Value(hasFullDetails),
      syncState: Value(syncState),
      serverUpdatedAt: serverUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(serverUpdatedAt),
      localUpdatedAt: localUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(localUpdatedAt),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory CachedCaseRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedCaseRow(
      id: serializer.fromJson<String>(json['id']),
      caseNumber: serializer.fromJson<String>(json['caseNumber']),
      displayId: serializer.fromJson<String>(json['displayId']),
      status: serializer.fromJson<String>(json['status']),
      priority: serializer.fromJson<String>(json['priority']),
      beneficiaryFullName: serializer.fromJson<String>(
        json['beneficiaryFullName'],
      ),
      nationalId: serializer.fromJson<String?>(json['nationalId']),
      charityId: serializer.fromJson<String?>(json['charityId']),
      registrationDate: serializer.fromJson<String?>(json['registrationDate']),
      completionPercentage: serializer.fromJson<double>(
        json['completionPercentage'],
      ),
      nextVisitDate: serializer.fromJson<String?>(json['nextVisitDate']),
      nextVisitStartTimeUtc: serializer.fromJson<DateTime?>(
        json['nextVisitStartTimeUtc'],
      ),
      nextVisitLocation: serializer.fromJson<String?>(
        json['nextVisitLocation'],
      ),
      isBookmarked: serializer.fromJson<bool>(json['isBookmarked']),
      rowVersion: serializer.fromJson<int?>(json['rowVersion']),
      beneficiaryRowVersion: serializer.fromJson<int?>(
        json['beneficiaryRowVersion'],
      ),
      availableActionsJson: serializer.fromJson<String?>(
        json['availableActionsJson'],
      ),
      detailsJson: serializer.fromJson<String?>(json['detailsJson']),
      hasFullDetails: serializer.fromJson<bool>(json['hasFullDetails']),
      syncState: serializer.fromJson<String>(json['syncState']),
      serverUpdatedAt: serializer.fromJson<DateTime?>(json['serverUpdatedAt']),
      localUpdatedAt: serializer.fromJson<DateTime?>(json['localUpdatedAt']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'caseNumber': serializer.toJson<String>(caseNumber),
      'displayId': serializer.toJson<String>(displayId),
      'status': serializer.toJson<String>(status),
      'priority': serializer.toJson<String>(priority),
      'beneficiaryFullName': serializer.toJson<String>(beneficiaryFullName),
      'nationalId': serializer.toJson<String?>(nationalId),
      'charityId': serializer.toJson<String?>(charityId),
      'registrationDate': serializer.toJson<String?>(registrationDate),
      'completionPercentage': serializer.toJson<double>(completionPercentage),
      'nextVisitDate': serializer.toJson<String?>(nextVisitDate),
      'nextVisitStartTimeUtc': serializer.toJson<DateTime?>(
        nextVisitStartTimeUtc,
      ),
      'nextVisitLocation': serializer.toJson<String?>(nextVisitLocation),
      'isBookmarked': serializer.toJson<bool>(isBookmarked),
      'rowVersion': serializer.toJson<int?>(rowVersion),
      'beneficiaryRowVersion': serializer.toJson<int?>(beneficiaryRowVersion),
      'availableActionsJson': serializer.toJson<String?>(availableActionsJson),
      'detailsJson': serializer.toJson<String?>(detailsJson),
      'hasFullDetails': serializer.toJson<bool>(hasFullDetails),
      'syncState': serializer.toJson<String>(syncState),
      'serverUpdatedAt': serializer.toJson<DateTime?>(serverUpdatedAt),
      'localUpdatedAt': serializer.toJson<DateTime?>(localUpdatedAt),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  CachedCaseRow copyWith({
    String? id,
    String? caseNumber,
    String? displayId,
    String? status,
    String? priority,
    String? beneficiaryFullName,
    Value<String?> nationalId = const Value.absent(),
    Value<String?> charityId = const Value.absent(),
    Value<String?> registrationDate = const Value.absent(),
    double? completionPercentage,
    Value<String?> nextVisitDate = const Value.absent(),
    Value<DateTime?> nextVisitStartTimeUtc = const Value.absent(),
    Value<String?> nextVisitLocation = const Value.absent(),
    bool? isBookmarked,
    Value<int?> rowVersion = const Value.absent(),
    Value<int?> beneficiaryRowVersion = const Value.absent(),
    Value<String?> availableActionsJson = const Value.absent(),
    Value<String?> detailsJson = const Value.absent(),
    bool? hasFullDetails,
    String? syncState,
    Value<DateTime?> serverUpdatedAt = const Value.absent(),
    Value<DateTime?> localUpdatedAt = const Value.absent(),
    DateTime? fetchedAt,
  }) => CachedCaseRow(
    id: id ?? this.id,
    caseNumber: caseNumber ?? this.caseNumber,
    displayId: displayId ?? this.displayId,
    status: status ?? this.status,
    priority: priority ?? this.priority,
    beneficiaryFullName: beneficiaryFullName ?? this.beneficiaryFullName,
    nationalId: nationalId.present ? nationalId.value : this.nationalId,
    charityId: charityId.present ? charityId.value : this.charityId,
    registrationDate: registrationDate.present
        ? registrationDate.value
        : this.registrationDate,
    completionPercentage: completionPercentage ?? this.completionPercentage,
    nextVisitDate: nextVisitDate.present
        ? nextVisitDate.value
        : this.nextVisitDate,
    nextVisitStartTimeUtc: nextVisitStartTimeUtc.present
        ? nextVisitStartTimeUtc.value
        : this.nextVisitStartTimeUtc,
    nextVisitLocation: nextVisitLocation.present
        ? nextVisitLocation.value
        : this.nextVisitLocation,
    isBookmarked: isBookmarked ?? this.isBookmarked,
    rowVersion: rowVersion.present ? rowVersion.value : this.rowVersion,
    beneficiaryRowVersion: beneficiaryRowVersion.present
        ? beneficiaryRowVersion.value
        : this.beneficiaryRowVersion,
    availableActionsJson: availableActionsJson.present
        ? availableActionsJson.value
        : this.availableActionsJson,
    detailsJson: detailsJson.present ? detailsJson.value : this.detailsJson,
    hasFullDetails: hasFullDetails ?? this.hasFullDetails,
    syncState: syncState ?? this.syncState,
    serverUpdatedAt: serverUpdatedAt.present
        ? serverUpdatedAt.value
        : this.serverUpdatedAt,
    localUpdatedAt: localUpdatedAt.present
        ? localUpdatedAt.value
        : this.localUpdatedAt,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  CachedCaseRow copyWithCompanion(CachedCasesCompanion data) {
    return CachedCaseRow(
      id: data.id.present ? data.id.value : this.id,
      caseNumber: data.caseNumber.present
          ? data.caseNumber.value
          : this.caseNumber,
      displayId: data.displayId.present ? data.displayId.value : this.displayId,
      status: data.status.present ? data.status.value : this.status,
      priority: data.priority.present ? data.priority.value : this.priority,
      beneficiaryFullName: data.beneficiaryFullName.present
          ? data.beneficiaryFullName.value
          : this.beneficiaryFullName,
      nationalId: data.nationalId.present
          ? data.nationalId.value
          : this.nationalId,
      charityId: data.charityId.present ? data.charityId.value : this.charityId,
      registrationDate: data.registrationDate.present
          ? data.registrationDate.value
          : this.registrationDate,
      completionPercentage: data.completionPercentage.present
          ? data.completionPercentage.value
          : this.completionPercentage,
      nextVisitDate: data.nextVisitDate.present
          ? data.nextVisitDate.value
          : this.nextVisitDate,
      nextVisitStartTimeUtc: data.nextVisitStartTimeUtc.present
          ? data.nextVisitStartTimeUtc.value
          : this.nextVisitStartTimeUtc,
      nextVisitLocation: data.nextVisitLocation.present
          ? data.nextVisitLocation.value
          : this.nextVisitLocation,
      isBookmarked: data.isBookmarked.present
          ? data.isBookmarked.value
          : this.isBookmarked,
      rowVersion: data.rowVersion.present
          ? data.rowVersion.value
          : this.rowVersion,
      beneficiaryRowVersion: data.beneficiaryRowVersion.present
          ? data.beneficiaryRowVersion.value
          : this.beneficiaryRowVersion,
      availableActionsJson: data.availableActionsJson.present
          ? data.availableActionsJson.value
          : this.availableActionsJson,
      detailsJson: data.detailsJson.present
          ? data.detailsJson.value
          : this.detailsJson,
      hasFullDetails: data.hasFullDetails.present
          ? data.hasFullDetails.value
          : this.hasFullDetails,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      serverUpdatedAt: data.serverUpdatedAt.present
          ? data.serverUpdatedAt.value
          : this.serverUpdatedAt,
      localUpdatedAt: data.localUpdatedAt.present
          ? data.localUpdatedAt.value
          : this.localUpdatedAt,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedCaseRow(')
          ..write('id: $id, ')
          ..write('caseNumber: $caseNumber, ')
          ..write('displayId: $displayId, ')
          ..write('status: $status, ')
          ..write('priority: $priority, ')
          ..write('beneficiaryFullName: $beneficiaryFullName, ')
          ..write('nationalId: $nationalId, ')
          ..write('charityId: $charityId, ')
          ..write('registrationDate: $registrationDate, ')
          ..write('completionPercentage: $completionPercentage, ')
          ..write('nextVisitDate: $nextVisitDate, ')
          ..write('nextVisitStartTimeUtc: $nextVisitStartTimeUtc, ')
          ..write('nextVisitLocation: $nextVisitLocation, ')
          ..write('isBookmarked: $isBookmarked, ')
          ..write('rowVersion: $rowVersion, ')
          ..write('beneficiaryRowVersion: $beneficiaryRowVersion, ')
          ..write('availableActionsJson: $availableActionsJson, ')
          ..write('detailsJson: $detailsJson, ')
          ..write('hasFullDetails: $hasFullDetails, ')
          ..write('syncState: $syncState, ')
          ..write('serverUpdatedAt: $serverUpdatedAt, ')
          ..write('localUpdatedAt: $localUpdatedAt, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    caseNumber,
    displayId,
    status,
    priority,
    beneficiaryFullName,
    nationalId,
    charityId,
    registrationDate,
    completionPercentage,
    nextVisitDate,
    nextVisitStartTimeUtc,
    nextVisitLocation,
    isBookmarked,
    rowVersion,
    beneficiaryRowVersion,
    availableActionsJson,
    detailsJson,
    hasFullDetails,
    syncState,
    serverUpdatedAt,
    localUpdatedAt,
    fetchedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedCaseRow &&
          other.id == this.id &&
          other.caseNumber == this.caseNumber &&
          other.displayId == this.displayId &&
          other.status == this.status &&
          other.priority == this.priority &&
          other.beneficiaryFullName == this.beneficiaryFullName &&
          other.nationalId == this.nationalId &&
          other.charityId == this.charityId &&
          other.registrationDate == this.registrationDate &&
          other.completionPercentage == this.completionPercentage &&
          other.nextVisitDate == this.nextVisitDate &&
          other.nextVisitStartTimeUtc == this.nextVisitStartTimeUtc &&
          other.nextVisitLocation == this.nextVisitLocation &&
          other.isBookmarked == this.isBookmarked &&
          other.rowVersion == this.rowVersion &&
          other.beneficiaryRowVersion == this.beneficiaryRowVersion &&
          other.availableActionsJson == this.availableActionsJson &&
          other.detailsJson == this.detailsJson &&
          other.hasFullDetails == this.hasFullDetails &&
          other.syncState == this.syncState &&
          other.serverUpdatedAt == this.serverUpdatedAt &&
          other.localUpdatedAt == this.localUpdatedAt &&
          other.fetchedAt == this.fetchedAt);
}

class CachedCasesCompanion extends UpdateCompanion<CachedCaseRow> {
  final Value<String> id;
  final Value<String> caseNumber;
  final Value<String> displayId;
  final Value<String> status;
  final Value<String> priority;
  final Value<String> beneficiaryFullName;
  final Value<String?> nationalId;
  final Value<String?> charityId;
  final Value<String?> registrationDate;
  final Value<double> completionPercentage;
  final Value<String?> nextVisitDate;
  final Value<DateTime?> nextVisitStartTimeUtc;
  final Value<String?> nextVisitLocation;
  final Value<bool> isBookmarked;
  final Value<int?> rowVersion;
  final Value<int?> beneficiaryRowVersion;
  final Value<String?> availableActionsJson;
  final Value<String?> detailsJson;
  final Value<bool> hasFullDetails;
  final Value<String> syncState;
  final Value<DateTime?> serverUpdatedAt;
  final Value<DateTime?> localUpdatedAt;
  final Value<DateTime> fetchedAt;
  final Value<int> rowid;
  const CachedCasesCompanion({
    this.id = const Value.absent(),
    this.caseNumber = const Value.absent(),
    this.displayId = const Value.absent(),
    this.status = const Value.absent(),
    this.priority = const Value.absent(),
    this.beneficiaryFullName = const Value.absent(),
    this.nationalId = const Value.absent(),
    this.charityId = const Value.absent(),
    this.registrationDate = const Value.absent(),
    this.completionPercentage = const Value.absent(),
    this.nextVisitDate = const Value.absent(),
    this.nextVisitStartTimeUtc = const Value.absent(),
    this.nextVisitLocation = const Value.absent(),
    this.isBookmarked = const Value.absent(),
    this.rowVersion = const Value.absent(),
    this.beneficiaryRowVersion = const Value.absent(),
    this.availableActionsJson = const Value.absent(),
    this.detailsJson = const Value.absent(),
    this.hasFullDetails = const Value.absent(),
    this.syncState = const Value.absent(),
    this.serverUpdatedAt = const Value.absent(),
    this.localUpdatedAt = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedCasesCompanion.insert({
    required String id,
    required String caseNumber,
    required String displayId,
    required String status,
    required String priority,
    required String beneficiaryFullName,
    this.nationalId = const Value.absent(),
    this.charityId = const Value.absent(),
    this.registrationDate = const Value.absent(),
    this.completionPercentage = const Value.absent(),
    this.nextVisitDate = const Value.absent(),
    this.nextVisitStartTimeUtc = const Value.absent(),
    this.nextVisitLocation = const Value.absent(),
    this.isBookmarked = const Value.absent(),
    this.rowVersion = const Value.absent(),
    this.beneficiaryRowVersion = const Value.absent(),
    this.availableActionsJson = const Value.absent(),
    this.detailsJson = const Value.absent(),
    this.hasFullDetails = const Value.absent(),
    this.syncState = const Value.absent(),
    this.serverUpdatedAt = const Value.absent(),
    this.localUpdatedAt = const Value.absent(),
    required DateTime fetchedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       caseNumber = Value(caseNumber),
       displayId = Value(displayId),
       status = Value(status),
       priority = Value(priority),
       beneficiaryFullName = Value(beneficiaryFullName),
       fetchedAt = Value(fetchedAt);
  static Insertable<CachedCaseRow> custom({
    Expression<String>? id,
    Expression<String>? caseNumber,
    Expression<String>? displayId,
    Expression<String>? status,
    Expression<String>? priority,
    Expression<String>? beneficiaryFullName,
    Expression<String>? nationalId,
    Expression<String>? charityId,
    Expression<String>? registrationDate,
    Expression<double>? completionPercentage,
    Expression<String>? nextVisitDate,
    Expression<DateTime>? nextVisitStartTimeUtc,
    Expression<String>? nextVisitLocation,
    Expression<bool>? isBookmarked,
    Expression<int>? rowVersion,
    Expression<int>? beneficiaryRowVersion,
    Expression<String>? availableActionsJson,
    Expression<String>? detailsJson,
    Expression<bool>? hasFullDetails,
    Expression<String>? syncState,
    Expression<DateTime>? serverUpdatedAt,
    Expression<DateTime>? localUpdatedAt,
    Expression<DateTime>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (caseNumber != null) 'case_number': caseNumber,
      if (displayId != null) 'display_id': displayId,
      if (status != null) 'status': status,
      if (priority != null) 'priority': priority,
      if (beneficiaryFullName != null)
        'beneficiary_full_name': beneficiaryFullName,
      if (nationalId != null) 'national_id': nationalId,
      if (charityId != null) 'charity_id': charityId,
      if (registrationDate != null) 'registration_date': registrationDate,
      if (completionPercentage != null)
        'completion_percentage': completionPercentage,
      if (nextVisitDate != null) 'next_visit_date': nextVisitDate,
      if (nextVisitStartTimeUtc != null)
        'next_visit_start_time_utc': nextVisitStartTimeUtc,
      if (nextVisitLocation != null) 'next_visit_location': nextVisitLocation,
      if (isBookmarked != null) 'is_bookmarked': isBookmarked,
      if (rowVersion != null) 'row_version': rowVersion,
      if (beneficiaryRowVersion != null)
        'beneficiary_row_version': beneficiaryRowVersion,
      if (availableActionsJson != null)
        'available_actions_json': availableActionsJson,
      if (detailsJson != null) 'details_json': detailsJson,
      if (hasFullDetails != null) 'has_full_details': hasFullDetails,
      if (syncState != null) 'sync_state': syncState,
      if (serverUpdatedAt != null) 'server_updated_at': serverUpdatedAt,
      if (localUpdatedAt != null) 'local_updated_at': localUpdatedAt,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedCasesCompanion copyWith({
    Value<String>? id,
    Value<String>? caseNumber,
    Value<String>? displayId,
    Value<String>? status,
    Value<String>? priority,
    Value<String>? beneficiaryFullName,
    Value<String?>? nationalId,
    Value<String?>? charityId,
    Value<String?>? registrationDate,
    Value<double>? completionPercentage,
    Value<String?>? nextVisitDate,
    Value<DateTime?>? nextVisitStartTimeUtc,
    Value<String?>? nextVisitLocation,
    Value<bool>? isBookmarked,
    Value<int?>? rowVersion,
    Value<int?>? beneficiaryRowVersion,
    Value<String?>? availableActionsJson,
    Value<String?>? detailsJson,
    Value<bool>? hasFullDetails,
    Value<String>? syncState,
    Value<DateTime?>? serverUpdatedAt,
    Value<DateTime?>? localUpdatedAt,
    Value<DateTime>? fetchedAt,
    Value<int>? rowid,
  }) {
    return CachedCasesCompanion(
      id: id ?? this.id,
      caseNumber: caseNumber ?? this.caseNumber,
      displayId: displayId ?? this.displayId,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      beneficiaryFullName: beneficiaryFullName ?? this.beneficiaryFullName,
      nationalId: nationalId ?? this.nationalId,
      charityId: charityId ?? this.charityId,
      registrationDate: registrationDate ?? this.registrationDate,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      nextVisitDate: nextVisitDate ?? this.nextVisitDate,
      nextVisitStartTimeUtc:
          nextVisitStartTimeUtc ?? this.nextVisitStartTimeUtc,
      nextVisitLocation: nextVisitLocation ?? this.nextVisitLocation,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      rowVersion: rowVersion ?? this.rowVersion,
      beneficiaryRowVersion:
          beneficiaryRowVersion ?? this.beneficiaryRowVersion,
      availableActionsJson: availableActionsJson ?? this.availableActionsJson,
      detailsJson: detailsJson ?? this.detailsJson,
      hasFullDetails: hasFullDetails ?? this.hasFullDetails,
      syncState: syncState ?? this.syncState,
      serverUpdatedAt: serverUpdatedAt ?? this.serverUpdatedAt,
      localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (caseNumber.present) {
      map['case_number'] = Variable<String>(caseNumber.value);
    }
    if (displayId.present) {
      map['display_id'] = Variable<String>(displayId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (priority.present) {
      map['priority'] = Variable<String>(priority.value);
    }
    if (beneficiaryFullName.present) {
      map['beneficiary_full_name'] = Variable<String>(
        beneficiaryFullName.value,
      );
    }
    if (nationalId.present) {
      map['national_id'] = Variable<String>(nationalId.value);
    }
    if (charityId.present) {
      map['charity_id'] = Variable<String>(charityId.value);
    }
    if (registrationDate.present) {
      map['registration_date'] = Variable<String>(registrationDate.value);
    }
    if (completionPercentage.present) {
      map['completion_percentage'] = Variable<double>(
        completionPercentage.value,
      );
    }
    if (nextVisitDate.present) {
      map['next_visit_date'] = Variable<String>(nextVisitDate.value);
    }
    if (nextVisitStartTimeUtc.present) {
      map['next_visit_start_time_utc'] = Variable<DateTime>(
        nextVisitStartTimeUtc.value,
      );
    }
    if (nextVisitLocation.present) {
      map['next_visit_location'] = Variable<String>(nextVisitLocation.value);
    }
    if (isBookmarked.present) {
      map['is_bookmarked'] = Variable<bool>(isBookmarked.value);
    }
    if (rowVersion.present) {
      map['row_version'] = Variable<int>(rowVersion.value);
    }
    if (beneficiaryRowVersion.present) {
      map['beneficiary_row_version'] = Variable<int>(
        beneficiaryRowVersion.value,
      );
    }
    if (availableActionsJson.present) {
      map['available_actions_json'] = Variable<String>(
        availableActionsJson.value,
      );
    }
    if (detailsJson.present) {
      map['details_json'] = Variable<String>(detailsJson.value);
    }
    if (hasFullDetails.present) {
      map['has_full_details'] = Variable<bool>(hasFullDetails.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(syncState.value);
    }
    if (serverUpdatedAt.present) {
      map['server_updated_at'] = Variable<DateTime>(serverUpdatedAt.value);
    }
    if (localUpdatedAt.present) {
      map['local_updated_at'] = Variable<DateTime>(localUpdatedAt.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedCasesCompanion(')
          ..write('id: $id, ')
          ..write('caseNumber: $caseNumber, ')
          ..write('displayId: $displayId, ')
          ..write('status: $status, ')
          ..write('priority: $priority, ')
          ..write('beneficiaryFullName: $beneficiaryFullName, ')
          ..write('nationalId: $nationalId, ')
          ..write('charityId: $charityId, ')
          ..write('registrationDate: $registrationDate, ')
          ..write('completionPercentage: $completionPercentage, ')
          ..write('nextVisitDate: $nextVisitDate, ')
          ..write('nextVisitStartTimeUtc: $nextVisitStartTimeUtc, ')
          ..write('nextVisitLocation: $nextVisitLocation, ')
          ..write('isBookmarked: $isBookmarked, ')
          ..write('rowVersion: $rowVersion, ')
          ..write('beneficiaryRowVersion: $beneficiaryRowVersion, ')
          ..write('availableActionsJson: $availableActionsJson, ')
          ..write('detailsJson: $detailsJson, ')
          ..write('hasFullDetails: $hasFullDetails, ')
          ..write('syncState: $syncState, ')
          ..write('serverUpdatedAt: $serverUpdatedAt, ')
          ..write('localUpdatedAt: $localUpdatedAt, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedSectionsTable extends CachedSections
    with TableInfo<$CachedSectionsTable, CachedSectionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedSectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _caseIdMeta = const VerificationMeta('caseId');
  @override
  late final GeneratedColumn<String> caseId = GeneratedColumn<String>(
    'case_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sectionKeyMeta = const VerificationMeta(
    'sectionKey',
  );
  @override
  late final GeneratedColumn<String> sectionKey = GeneratedColumn<String>(
    'section_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataJsonMeta = const VerificationMeta(
    'dataJson',
  );
  @override
  late final GeneratedColumn<String> dataJson = GeneratedColumn<String>(
    'data_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rowVersionMeta = const VerificationMeta(
    'rowVersion',
  );
  @override
  late final GeneratedColumn<int> rowVersion = GeneratedColumn<int>(
    'row_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDirtyMeta = const VerificationMeta(
    'isDirty',
  );
  @override
  late final GeneratedColumn<bool> isDirty = GeneratedColumn<bool>(
    'is_dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    caseId,
    sectionKey,
    dataJson,
    rowVersion,
    isDirty,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_sections';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedSectionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('case_id')) {
      context.handle(
        _caseIdMeta,
        caseId.isAcceptableOrUnknown(data['case_id']!, _caseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_caseIdMeta);
    }
    if (data.containsKey('section_key')) {
      context.handle(
        _sectionKeyMeta,
        sectionKey.isAcceptableOrUnknown(data['section_key']!, _sectionKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_sectionKeyMeta);
    }
    if (data.containsKey('data_json')) {
      context.handle(
        _dataJsonMeta,
        dataJson.isAcceptableOrUnknown(data['data_json']!, _dataJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_dataJsonMeta);
    }
    if (data.containsKey('row_version')) {
      context.handle(
        _rowVersionMeta,
        rowVersion.isAcceptableOrUnknown(data['row_version']!, _rowVersionMeta),
      );
    }
    if (data.containsKey('is_dirty')) {
      context.handle(
        _isDirtyMeta,
        isDirty.isAcceptableOrUnknown(data['is_dirty']!, _isDirtyMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {caseId, sectionKey};
  @override
  CachedSectionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedSectionRow(
      caseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}case_id'],
      )!,
      sectionKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}section_key'],
      )!,
      dataJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data_json'],
      )!,
      rowVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}row_version'],
      ),
      isDirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_dirty'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CachedSectionsTable createAlias(String alias) {
    return $CachedSectionsTable(attachedDatabase, alias);
  }
}

class CachedSectionRow extends DataClass
    implements Insertable<CachedSectionRow> {
  final String caseId;

  /// مفتاح القسم: `beneficiary`, `housing`, `family_members` …
  final String sectionKey;

  /// محتوى القسم كـ JSON.
  final String dataJson;

  /// نسخة الصفّ للأقسام المفردة.
  ///
  /// `null` يعني لم يُحفَظ القسم بعد على الخادم — وهي قيمة مشروعة تُرسَل
  /// كما هي في أول حفظ لـ housing/agriculture/classification (§19).
  final int? rowVersion;

  /// هل يوجد تعديل محلي لم يُرفَع؟
  final bool isDirty;
  final DateTime updatedAt;
  const CachedSectionRow({
    required this.caseId,
    required this.sectionKey,
    required this.dataJson,
    this.rowVersion,
    required this.isDirty,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['case_id'] = Variable<String>(caseId);
    map['section_key'] = Variable<String>(sectionKey);
    map['data_json'] = Variable<String>(dataJson);
    if (!nullToAbsent || rowVersion != null) {
      map['row_version'] = Variable<int>(rowVersion);
    }
    map['is_dirty'] = Variable<bool>(isDirty);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CachedSectionsCompanion toCompanion(bool nullToAbsent) {
    return CachedSectionsCompanion(
      caseId: Value(caseId),
      sectionKey: Value(sectionKey),
      dataJson: Value(dataJson),
      rowVersion: rowVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(rowVersion),
      isDirty: Value(isDirty),
      updatedAt: Value(updatedAt),
    );
  }

  factory CachedSectionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedSectionRow(
      caseId: serializer.fromJson<String>(json['caseId']),
      sectionKey: serializer.fromJson<String>(json['sectionKey']),
      dataJson: serializer.fromJson<String>(json['dataJson']),
      rowVersion: serializer.fromJson<int?>(json['rowVersion']),
      isDirty: serializer.fromJson<bool>(json['isDirty']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'caseId': serializer.toJson<String>(caseId),
      'sectionKey': serializer.toJson<String>(sectionKey),
      'dataJson': serializer.toJson<String>(dataJson),
      'rowVersion': serializer.toJson<int?>(rowVersion),
      'isDirty': serializer.toJson<bool>(isDirty),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CachedSectionRow copyWith({
    String? caseId,
    String? sectionKey,
    String? dataJson,
    Value<int?> rowVersion = const Value.absent(),
    bool? isDirty,
    DateTime? updatedAt,
  }) => CachedSectionRow(
    caseId: caseId ?? this.caseId,
    sectionKey: sectionKey ?? this.sectionKey,
    dataJson: dataJson ?? this.dataJson,
    rowVersion: rowVersion.present ? rowVersion.value : this.rowVersion,
    isDirty: isDirty ?? this.isDirty,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CachedSectionRow copyWithCompanion(CachedSectionsCompanion data) {
    return CachedSectionRow(
      caseId: data.caseId.present ? data.caseId.value : this.caseId,
      sectionKey: data.sectionKey.present
          ? data.sectionKey.value
          : this.sectionKey,
      dataJson: data.dataJson.present ? data.dataJson.value : this.dataJson,
      rowVersion: data.rowVersion.present
          ? data.rowVersion.value
          : this.rowVersion,
      isDirty: data.isDirty.present ? data.isDirty.value : this.isDirty,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedSectionRow(')
          ..write('caseId: $caseId, ')
          ..write('sectionKey: $sectionKey, ')
          ..write('dataJson: $dataJson, ')
          ..write('rowVersion: $rowVersion, ')
          ..write('isDirty: $isDirty, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(caseId, sectionKey, dataJson, rowVersion, isDirty, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedSectionRow &&
          other.caseId == this.caseId &&
          other.sectionKey == this.sectionKey &&
          other.dataJson == this.dataJson &&
          other.rowVersion == this.rowVersion &&
          other.isDirty == this.isDirty &&
          other.updatedAt == this.updatedAt);
}

class CachedSectionsCompanion extends UpdateCompanion<CachedSectionRow> {
  final Value<String> caseId;
  final Value<String> sectionKey;
  final Value<String> dataJson;
  final Value<int?> rowVersion;
  final Value<bool> isDirty;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CachedSectionsCompanion({
    this.caseId = const Value.absent(),
    this.sectionKey = const Value.absent(),
    this.dataJson = const Value.absent(),
    this.rowVersion = const Value.absent(),
    this.isDirty = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedSectionsCompanion.insert({
    required String caseId,
    required String sectionKey,
    required String dataJson,
    this.rowVersion = const Value.absent(),
    this.isDirty = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : caseId = Value(caseId),
       sectionKey = Value(sectionKey),
       dataJson = Value(dataJson),
       updatedAt = Value(updatedAt);
  static Insertable<CachedSectionRow> custom({
    Expression<String>? caseId,
    Expression<String>? sectionKey,
    Expression<String>? dataJson,
    Expression<int>? rowVersion,
    Expression<bool>? isDirty,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (caseId != null) 'case_id': caseId,
      if (sectionKey != null) 'section_key': sectionKey,
      if (dataJson != null) 'data_json': dataJson,
      if (rowVersion != null) 'row_version': rowVersion,
      if (isDirty != null) 'is_dirty': isDirty,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedSectionsCompanion copyWith({
    Value<String>? caseId,
    Value<String>? sectionKey,
    Value<String>? dataJson,
    Value<int?>? rowVersion,
    Value<bool>? isDirty,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CachedSectionsCompanion(
      caseId: caseId ?? this.caseId,
      sectionKey: sectionKey ?? this.sectionKey,
      dataJson: dataJson ?? this.dataJson,
      rowVersion: rowVersion ?? this.rowVersion,
      isDirty: isDirty ?? this.isDirty,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (caseId.present) {
      map['case_id'] = Variable<String>(caseId.value);
    }
    if (sectionKey.present) {
      map['section_key'] = Variable<String>(sectionKey.value);
    }
    if (dataJson.present) {
      map['data_json'] = Variable<String>(dataJson.value);
    }
    if (rowVersion.present) {
      map['row_version'] = Variable<int>(rowVersion.value);
    }
    if (isDirty.present) {
      map['is_dirty'] = Variable<bool>(isDirty.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedSectionsCompanion(')
          ..write('caseId: $caseId, ')
          ..write('sectionKey: $sectionKey, ')
          ..write('dataJson: $dataJson, ')
          ..write('rowVersion: $rowVersion, ')
          ..write('isDirty: $isDirty, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalFieldVisitsTable extends LocalFieldVisits
    with TableInfo<$LocalFieldVisitsTable, FieldVisitRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalFieldVisitsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _caseIdMeta = const VerificationMeta('caseId');
  @override
  late final GeneratedColumn<String> caseId = GeneratedColumn<String>(
    'case_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dedupIdMeta = const VerificationMeta(
    'dedupId',
  );
  @override
  late final GeneratedColumn<String> dedupId = GeneratedColumn<String>(
    'dedup_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _visitDateMeta = const VerificationMeta(
    'visitDate',
  );
  @override
  late final GeneratedColumn<String> visitDate = GeneratedColumn<String>(
    'visit_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startTimeUtcMeta = const VerificationMeta(
    'startTimeUtc',
  );
  @override
  late final GeneratedColumn<DateTime> startTimeUtc = GeneratedColumn<DateTime>(
    'start_time_utc',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endTimeUtcMeta = const VerificationMeta(
    'endTimeUtc',
  );
  @override
  late final GeneratedColumn<DateTime> endTimeUtc = GeneratedColumn<DateTime>(
    'end_time_utc',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _locationDescriptionMeta =
      const VerificationMeta('locationDescription');
  @override
  late final GeneratedColumn<String> locationDescription =
      GeneratedColumn<String>(
        'location_description',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _outcomeMeta = const VerificationMeta(
    'outcome',
  );
  @override
  late final GeneratedColumn<String> outcome = GeneratedColumn<String>(
    'outcome',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _visitStatusMeta = const VerificationMeta(
    'visitStatus',
  );
  @override
  late final GeneratedColumn<String> visitStatus = GeneratedColumn<String>(
    'visit_status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localAttachmentIdsJsonMeta =
      const VerificationMeta('localAttachmentIdsJson');
  @override
  late final GeneratedColumn<String> localAttachmentIdsJson =
      GeneratedColumn<String>(
        'local_attachment_ids_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      );
  static const VerificationMeta _rowVersionMeta = const VerificationMeta(
    'rowVersion',
  );
  @override
  late final GeneratedColumn<int> rowVersion = GeneratedColumn<int>(
    'row_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStateMeta = const VerificationMeta(
    'syncState',
  );
  @override
  late final GeneratedColumn<String> syncState = GeneratedColumn<String>(
    'sync_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pendingSync'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverId,
    caseId,
    dedupId,
    visitDate,
    startTimeUtc,
    endTimeUtc,
    latitude,
    longitude,
    locationDescription,
    outcome,
    visitStatus,
    notes,
    description,
    localAttachmentIdsJson,
    rowVersion,
    syncState,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_field_visits';
  @override
  VerificationContext validateIntegrity(
    Insertable<FieldVisitRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('case_id')) {
      context.handle(
        _caseIdMeta,
        caseId.isAcceptableOrUnknown(data['case_id']!, _caseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_caseIdMeta);
    }
    if (data.containsKey('dedup_id')) {
      context.handle(
        _dedupIdMeta,
        dedupId.isAcceptableOrUnknown(data['dedup_id']!, _dedupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_dedupIdMeta);
    }
    if (data.containsKey('visit_date')) {
      context.handle(
        _visitDateMeta,
        visitDate.isAcceptableOrUnknown(data['visit_date']!, _visitDateMeta),
      );
    } else if (isInserting) {
      context.missing(_visitDateMeta);
    }
    if (data.containsKey('start_time_utc')) {
      context.handle(
        _startTimeUtcMeta,
        startTimeUtc.isAcceptableOrUnknown(
          data['start_time_utc']!,
          _startTimeUtcMeta,
        ),
      );
    }
    if (data.containsKey('end_time_utc')) {
      context.handle(
        _endTimeUtcMeta,
        endTimeUtc.isAcceptableOrUnknown(
          data['end_time_utc']!,
          _endTimeUtcMeta,
        ),
      );
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    }
    if (data.containsKey('location_description')) {
      context.handle(
        _locationDescriptionMeta,
        locationDescription.isAcceptableOrUnknown(
          data['location_description']!,
          _locationDescriptionMeta,
        ),
      );
    }
    if (data.containsKey('outcome')) {
      context.handle(
        _outcomeMeta,
        outcome.isAcceptableOrUnknown(data['outcome']!, _outcomeMeta),
      );
    } else if (isInserting) {
      context.missing(_outcomeMeta);
    }
    if (data.containsKey('visit_status')) {
      context.handle(
        _visitStatusMeta,
        visitStatus.isAcceptableOrUnknown(
          data['visit_status']!,
          _visitStatusMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('local_attachment_ids_json')) {
      context.handle(
        _localAttachmentIdsJsonMeta,
        localAttachmentIdsJson.isAcceptableOrUnknown(
          data['local_attachment_ids_json']!,
          _localAttachmentIdsJsonMeta,
        ),
      );
    }
    if (data.containsKey('row_version')) {
      context.handle(
        _rowVersionMeta,
        rowVersion.isAcceptableOrUnknown(data['row_version']!, _rowVersionMeta),
      );
    }
    if (data.containsKey('sync_state')) {
      context.handle(
        _syncStateMeta,
        syncState.isAcceptableOrUnknown(data['sync_state']!, _syncStateMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FieldVisitRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FieldVisitRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      ),
      caseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}case_id'],
      )!,
      dedupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dedup_id'],
      )!,
      visitDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}visit_date'],
      )!,
      startTimeUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_time_utc'],
      ),
      endTimeUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_time_utc'],
      ),
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      ),
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      ),
      locationDescription: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location_description'],
      ),
      outcome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}outcome'],
      )!,
      visitStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}visit_status'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      localAttachmentIdsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_attachment_ids_json'],
      )!,
      rowVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}row_version'],
      ),
      syncState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_state'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LocalFieldVisitsTable createAlias(String alias) {
    return $LocalFieldVisitsTable(attachedDatabase, alias);
  }
}

class FieldVisitRow extends DataClass implements Insertable<FieldVisitRow> {
  /// معرّف محلي يُولَّد فور إنشاء الزيارة.
  final String id;

  /// معرّف الخادم — `null` حتى تُرفَع بنجاح.
  final String? serverId;
  final String caseId;

  /// حارس التكرار — يُولَّد مرة واحدة ولا يتغيّر مدى حياة الزيارة.
  ///
  /// `POST /field-visits` بلا حماية من الخادم (§14.2)، فهذا خط الدفاع الوحيد.
  final String dedupId;
  final String visitDate;
  final DateTime? startTimeUtc;
  final DateTime? endTimeUtc;

  /// الإحداثيات — **معًا أو لا شيء** (§15.10).
  final double? latitude;
  final double? longitude;
  final String? locationDescription;
  final String outcome;
  final String? visitStatus;
  final String? notes;
  final String? description;

  /// معرّفات المرفقات المحلية — تُترجَم لمعرّفات الخادم عند الرفع.
  final String localAttachmentIdsJson;
  final int? rowVersion;
  final String syncState;
  final DateTime createdAt;
  final DateTime updatedAt;
  const FieldVisitRow({
    required this.id,
    this.serverId,
    required this.caseId,
    required this.dedupId,
    required this.visitDate,
    this.startTimeUtc,
    this.endTimeUtc,
    this.latitude,
    this.longitude,
    this.locationDescription,
    required this.outcome,
    this.visitStatus,
    this.notes,
    this.description,
    required this.localAttachmentIdsJson,
    this.rowVersion,
    required this.syncState,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    map['case_id'] = Variable<String>(caseId);
    map['dedup_id'] = Variable<String>(dedupId);
    map['visit_date'] = Variable<String>(visitDate);
    if (!nullToAbsent || startTimeUtc != null) {
      map['start_time_utc'] = Variable<DateTime>(startTimeUtc);
    }
    if (!nullToAbsent || endTimeUtc != null) {
      map['end_time_utc'] = Variable<DateTime>(endTimeUtc);
    }
    if (!nullToAbsent || latitude != null) {
      map['latitude'] = Variable<double>(latitude);
    }
    if (!nullToAbsent || longitude != null) {
      map['longitude'] = Variable<double>(longitude);
    }
    if (!nullToAbsent || locationDescription != null) {
      map['location_description'] = Variable<String>(locationDescription);
    }
    map['outcome'] = Variable<String>(outcome);
    if (!nullToAbsent || visitStatus != null) {
      map['visit_status'] = Variable<String>(visitStatus);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['local_attachment_ids_json'] = Variable<String>(localAttachmentIdsJson);
    if (!nullToAbsent || rowVersion != null) {
      map['row_version'] = Variable<int>(rowVersion);
    }
    map['sync_state'] = Variable<String>(syncState);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalFieldVisitsCompanion toCompanion(bool nullToAbsent) {
    return LocalFieldVisitsCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      caseId: Value(caseId),
      dedupId: Value(dedupId),
      visitDate: Value(visitDate),
      startTimeUtc: startTimeUtc == null && nullToAbsent
          ? const Value.absent()
          : Value(startTimeUtc),
      endTimeUtc: endTimeUtc == null && nullToAbsent
          ? const Value.absent()
          : Value(endTimeUtc),
      latitude: latitude == null && nullToAbsent
          ? const Value.absent()
          : Value(latitude),
      longitude: longitude == null && nullToAbsent
          ? const Value.absent()
          : Value(longitude),
      locationDescription: locationDescription == null && nullToAbsent
          ? const Value.absent()
          : Value(locationDescription),
      outcome: Value(outcome),
      visitStatus: visitStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(visitStatus),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      localAttachmentIdsJson: Value(localAttachmentIdsJson),
      rowVersion: rowVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(rowVersion),
      syncState: Value(syncState),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory FieldVisitRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FieldVisitRow(
      id: serializer.fromJson<String>(json['id']),
      serverId: serializer.fromJson<String?>(json['serverId']),
      caseId: serializer.fromJson<String>(json['caseId']),
      dedupId: serializer.fromJson<String>(json['dedupId']),
      visitDate: serializer.fromJson<String>(json['visitDate']),
      startTimeUtc: serializer.fromJson<DateTime?>(json['startTimeUtc']),
      endTimeUtc: serializer.fromJson<DateTime?>(json['endTimeUtc']),
      latitude: serializer.fromJson<double?>(json['latitude']),
      longitude: serializer.fromJson<double?>(json['longitude']),
      locationDescription: serializer.fromJson<String?>(
        json['locationDescription'],
      ),
      outcome: serializer.fromJson<String>(json['outcome']),
      visitStatus: serializer.fromJson<String?>(json['visitStatus']),
      notes: serializer.fromJson<String?>(json['notes']),
      description: serializer.fromJson<String?>(json['description']),
      localAttachmentIdsJson: serializer.fromJson<String>(
        json['localAttachmentIdsJson'],
      ),
      rowVersion: serializer.fromJson<int?>(json['rowVersion']),
      syncState: serializer.fromJson<String>(json['syncState']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'serverId': serializer.toJson<String?>(serverId),
      'caseId': serializer.toJson<String>(caseId),
      'dedupId': serializer.toJson<String>(dedupId),
      'visitDate': serializer.toJson<String>(visitDate),
      'startTimeUtc': serializer.toJson<DateTime?>(startTimeUtc),
      'endTimeUtc': serializer.toJson<DateTime?>(endTimeUtc),
      'latitude': serializer.toJson<double?>(latitude),
      'longitude': serializer.toJson<double?>(longitude),
      'locationDescription': serializer.toJson<String?>(locationDescription),
      'outcome': serializer.toJson<String>(outcome),
      'visitStatus': serializer.toJson<String?>(visitStatus),
      'notes': serializer.toJson<String?>(notes),
      'description': serializer.toJson<String?>(description),
      'localAttachmentIdsJson': serializer.toJson<String>(
        localAttachmentIdsJson,
      ),
      'rowVersion': serializer.toJson<int?>(rowVersion),
      'syncState': serializer.toJson<String>(syncState),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  FieldVisitRow copyWith({
    String? id,
    Value<String?> serverId = const Value.absent(),
    String? caseId,
    String? dedupId,
    String? visitDate,
    Value<DateTime?> startTimeUtc = const Value.absent(),
    Value<DateTime?> endTimeUtc = const Value.absent(),
    Value<double?> latitude = const Value.absent(),
    Value<double?> longitude = const Value.absent(),
    Value<String?> locationDescription = const Value.absent(),
    String? outcome,
    Value<String?> visitStatus = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<String?> description = const Value.absent(),
    String? localAttachmentIdsJson,
    Value<int?> rowVersion = const Value.absent(),
    String? syncState,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => FieldVisitRow(
    id: id ?? this.id,
    serverId: serverId.present ? serverId.value : this.serverId,
    caseId: caseId ?? this.caseId,
    dedupId: dedupId ?? this.dedupId,
    visitDate: visitDate ?? this.visitDate,
    startTimeUtc: startTimeUtc.present ? startTimeUtc.value : this.startTimeUtc,
    endTimeUtc: endTimeUtc.present ? endTimeUtc.value : this.endTimeUtc,
    latitude: latitude.present ? latitude.value : this.latitude,
    longitude: longitude.present ? longitude.value : this.longitude,
    locationDescription: locationDescription.present
        ? locationDescription.value
        : this.locationDescription,
    outcome: outcome ?? this.outcome,
    visitStatus: visitStatus.present ? visitStatus.value : this.visitStatus,
    notes: notes.present ? notes.value : this.notes,
    description: description.present ? description.value : this.description,
    localAttachmentIdsJson:
        localAttachmentIdsJson ?? this.localAttachmentIdsJson,
    rowVersion: rowVersion.present ? rowVersion.value : this.rowVersion,
    syncState: syncState ?? this.syncState,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  FieldVisitRow copyWithCompanion(LocalFieldVisitsCompanion data) {
    return FieldVisitRow(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      caseId: data.caseId.present ? data.caseId.value : this.caseId,
      dedupId: data.dedupId.present ? data.dedupId.value : this.dedupId,
      visitDate: data.visitDate.present ? data.visitDate.value : this.visitDate,
      startTimeUtc: data.startTimeUtc.present
          ? data.startTimeUtc.value
          : this.startTimeUtc,
      endTimeUtc: data.endTimeUtc.present
          ? data.endTimeUtc.value
          : this.endTimeUtc,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      locationDescription: data.locationDescription.present
          ? data.locationDescription.value
          : this.locationDescription,
      outcome: data.outcome.present ? data.outcome.value : this.outcome,
      visitStatus: data.visitStatus.present
          ? data.visitStatus.value
          : this.visitStatus,
      notes: data.notes.present ? data.notes.value : this.notes,
      description: data.description.present
          ? data.description.value
          : this.description,
      localAttachmentIdsJson: data.localAttachmentIdsJson.present
          ? data.localAttachmentIdsJson.value
          : this.localAttachmentIdsJson,
      rowVersion: data.rowVersion.present
          ? data.rowVersion.value
          : this.rowVersion,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FieldVisitRow(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('caseId: $caseId, ')
          ..write('dedupId: $dedupId, ')
          ..write('visitDate: $visitDate, ')
          ..write('startTimeUtc: $startTimeUtc, ')
          ..write('endTimeUtc: $endTimeUtc, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('locationDescription: $locationDescription, ')
          ..write('outcome: $outcome, ')
          ..write('visitStatus: $visitStatus, ')
          ..write('notes: $notes, ')
          ..write('description: $description, ')
          ..write('localAttachmentIdsJson: $localAttachmentIdsJson, ')
          ..write('rowVersion: $rowVersion, ')
          ..write('syncState: $syncState, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    serverId,
    caseId,
    dedupId,
    visitDate,
    startTimeUtc,
    endTimeUtc,
    latitude,
    longitude,
    locationDescription,
    outcome,
    visitStatus,
    notes,
    description,
    localAttachmentIdsJson,
    rowVersion,
    syncState,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FieldVisitRow &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.caseId == this.caseId &&
          other.dedupId == this.dedupId &&
          other.visitDate == this.visitDate &&
          other.startTimeUtc == this.startTimeUtc &&
          other.endTimeUtc == this.endTimeUtc &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.locationDescription == this.locationDescription &&
          other.outcome == this.outcome &&
          other.visitStatus == this.visitStatus &&
          other.notes == this.notes &&
          other.description == this.description &&
          other.localAttachmentIdsJson == this.localAttachmentIdsJson &&
          other.rowVersion == this.rowVersion &&
          other.syncState == this.syncState &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LocalFieldVisitsCompanion extends UpdateCompanion<FieldVisitRow> {
  final Value<String> id;
  final Value<String?> serverId;
  final Value<String> caseId;
  final Value<String> dedupId;
  final Value<String> visitDate;
  final Value<DateTime?> startTimeUtc;
  final Value<DateTime?> endTimeUtc;
  final Value<double?> latitude;
  final Value<double?> longitude;
  final Value<String?> locationDescription;
  final Value<String> outcome;
  final Value<String?> visitStatus;
  final Value<String?> notes;
  final Value<String?> description;
  final Value<String> localAttachmentIdsJson;
  final Value<int?> rowVersion;
  final Value<String> syncState;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalFieldVisitsCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.caseId = const Value.absent(),
    this.dedupId = const Value.absent(),
    this.visitDate = const Value.absent(),
    this.startTimeUtc = const Value.absent(),
    this.endTimeUtc = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.locationDescription = const Value.absent(),
    this.outcome = const Value.absent(),
    this.visitStatus = const Value.absent(),
    this.notes = const Value.absent(),
    this.description = const Value.absent(),
    this.localAttachmentIdsJson = const Value.absent(),
    this.rowVersion = const Value.absent(),
    this.syncState = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalFieldVisitsCompanion.insert({
    required String id,
    this.serverId = const Value.absent(),
    required String caseId,
    required String dedupId,
    required String visitDate,
    this.startTimeUtc = const Value.absent(),
    this.endTimeUtc = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.locationDescription = const Value.absent(),
    required String outcome,
    this.visitStatus = const Value.absent(),
    this.notes = const Value.absent(),
    this.description = const Value.absent(),
    this.localAttachmentIdsJson = const Value.absent(),
    this.rowVersion = const Value.absent(),
    this.syncState = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       caseId = Value(caseId),
       dedupId = Value(dedupId),
       visitDate = Value(visitDate),
       outcome = Value(outcome),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<FieldVisitRow> custom({
    Expression<String>? id,
    Expression<String>? serverId,
    Expression<String>? caseId,
    Expression<String>? dedupId,
    Expression<String>? visitDate,
    Expression<DateTime>? startTimeUtc,
    Expression<DateTime>? endTimeUtc,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<String>? locationDescription,
    Expression<String>? outcome,
    Expression<String>? visitStatus,
    Expression<String>? notes,
    Expression<String>? description,
    Expression<String>? localAttachmentIdsJson,
    Expression<int>? rowVersion,
    Expression<String>? syncState,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (caseId != null) 'case_id': caseId,
      if (dedupId != null) 'dedup_id': dedupId,
      if (visitDate != null) 'visit_date': visitDate,
      if (startTimeUtc != null) 'start_time_utc': startTimeUtc,
      if (endTimeUtc != null) 'end_time_utc': endTimeUtc,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (locationDescription != null)
        'location_description': locationDescription,
      if (outcome != null) 'outcome': outcome,
      if (visitStatus != null) 'visit_status': visitStatus,
      if (notes != null) 'notes': notes,
      if (description != null) 'description': description,
      if (localAttachmentIdsJson != null)
        'local_attachment_ids_json': localAttachmentIdsJson,
      if (rowVersion != null) 'row_version': rowVersion,
      if (syncState != null) 'sync_state': syncState,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalFieldVisitsCompanion copyWith({
    Value<String>? id,
    Value<String?>? serverId,
    Value<String>? caseId,
    Value<String>? dedupId,
    Value<String>? visitDate,
    Value<DateTime?>? startTimeUtc,
    Value<DateTime?>? endTimeUtc,
    Value<double?>? latitude,
    Value<double?>? longitude,
    Value<String?>? locationDescription,
    Value<String>? outcome,
    Value<String?>? visitStatus,
    Value<String?>? notes,
    Value<String?>? description,
    Value<String>? localAttachmentIdsJson,
    Value<int?>? rowVersion,
    Value<String>? syncState,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalFieldVisitsCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      caseId: caseId ?? this.caseId,
      dedupId: dedupId ?? this.dedupId,
      visitDate: visitDate ?? this.visitDate,
      startTimeUtc: startTimeUtc ?? this.startTimeUtc,
      endTimeUtc: endTimeUtc ?? this.endTimeUtc,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationDescription: locationDescription ?? this.locationDescription,
      outcome: outcome ?? this.outcome,
      visitStatus: visitStatus ?? this.visitStatus,
      notes: notes ?? this.notes,
      description: description ?? this.description,
      localAttachmentIdsJson:
          localAttachmentIdsJson ?? this.localAttachmentIdsJson,
      rowVersion: rowVersion ?? this.rowVersion,
      syncState: syncState ?? this.syncState,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (caseId.present) {
      map['case_id'] = Variable<String>(caseId.value);
    }
    if (dedupId.present) {
      map['dedup_id'] = Variable<String>(dedupId.value);
    }
    if (visitDate.present) {
      map['visit_date'] = Variable<String>(visitDate.value);
    }
    if (startTimeUtc.present) {
      map['start_time_utc'] = Variable<DateTime>(startTimeUtc.value);
    }
    if (endTimeUtc.present) {
      map['end_time_utc'] = Variable<DateTime>(endTimeUtc.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (locationDescription.present) {
      map['location_description'] = Variable<String>(locationDescription.value);
    }
    if (outcome.present) {
      map['outcome'] = Variable<String>(outcome.value);
    }
    if (visitStatus.present) {
      map['visit_status'] = Variable<String>(visitStatus.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (localAttachmentIdsJson.present) {
      map['local_attachment_ids_json'] = Variable<String>(
        localAttachmentIdsJson.value,
      );
    }
    if (rowVersion.present) {
      map['row_version'] = Variable<int>(rowVersion.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(syncState.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalFieldVisitsCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('caseId: $caseId, ')
          ..write('dedupId: $dedupId, ')
          ..write('visitDate: $visitDate, ')
          ..write('startTimeUtc: $startTimeUtc, ')
          ..write('endTimeUtc: $endTimeUtc, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('locationDescription: $locationDescription, ')
          ..write('outcome: $outcome, ')
          ..write('visitStatus: $visitStatus, ')
          ..write('notes: $notes, ')
          ..write('description: $description, ')
          ..write('localAttachmentIdsJson: $localAttachmentIdsJson, ')
          ..write('rowVersion: $rowVersion, ')
          ..write('syncState: $syncState, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingAttachmentsTable extends PendingAttachments
    with TableInfo<$PendingAttachmentsTable, PendingAttachmentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingAttachmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _caseIdMeta = const VerificationMeta('caseId');
  @override
  late final GeneratedColumn<String> caseId = GeneratedColumn<String>(
    'case_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attachmentIdMeta = const VerificationMeta(
    'attachmentId',
  );
  @override
  late final GeneratedColumn<String> attachmentId = GeneratedColumn<String>(
    'attachment_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localPathMeta = const VerificationMeta(
    'localPath',
  );
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
    'local_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mimeTypeMeta = const VerificationMeta(
    'mimeType',
  );
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
    'mime_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileSizeMeta = const VerificationMeta(
    'fileSize',
  );
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
    'file_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _documentTypeMeta = const VerificationMeta(
    'documentType',
  );
  @override
  late final GeneratedColumn<String> documentType = GeneratedColumn<String>(
    'document_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _checksumMeta = const VerificationMeta(
    'checksum',
  );
  @override
  late final GeneratedColumn<String> checksum = GeneratedColumn<String>(
    'checksum',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _uploadStageMeta = const VerificationMeta(
    'uploadStage',
  );
  @override
  late final GeneratedColumn<String> uploadStage = GeneratedColumn<String>(
    'upload_stage',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('captured'),
  );
  static const VerificationMeta _uploadUrlMeta = const VerificationMeta(
    'uploadUrl',
  );
  @override
  late final GeneratedColumn<String> uploadUrl = GeneratedColumn<String>(
    'upload_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _uploadUrlExpiresAtMeta =
      const VerificationMeta('uploadUrlExpiresAt');
  @override
  late final GeneratedColumn<DateTime> uploadUrlExpiresAt =
      GeneratedColumn<DateTime>(
        'upload_url_expires_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _progressMeta = const VerificationMeta(
    'progress',
  );
  @override
  late final GeneratedColumn<double> progress = GeneratedColumn<double>(
    'progress',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMessageMeta = const VerificationMeta(
    'lastErrorMessage',
  );
  @override
  late final GeneratedColumn<String> lastErrorMessage = GeneratedColumn<String>(
    'last_error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fieldVisitLocalIdMeta = const VerificationMeta(
    'fieldVisitLocalId',
  );
  @override
  late final GeneratedColumn<String> fieldVisitLocalId =
      GeneratedColumn<String>(
        'field_visit_local_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    caseId,
    attachmentId,
    localPath,
    fileName,
    mimeType,
    fileSize,
    documentType,
    description,
    checksum,
    uploadStage,
    uploadUrl,
    uploadUrlExpiresAt,
    progress,
    attempts,
    lastErrorMessage,
    fieldVisitLocalId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_attachments';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingAttachmentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('case_id')) {
      context.handle(
        _caseIdMeta,
        caseId.isAcceptableOrUnknown(data['case_id']!, _caseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_caseIdMeta);
    }
    if (data.containsKey('attachment_id')) {
      context.handle(
        _attachmentIdMeta,
        attachmentId.isAcceptableOrUnknown(
          data['attachment_id']!,
          _attachmentIdMeta,
        ),
      );
    }
    if (data.containsKey('local_path')) {
      context.handle(
        _localPathMeta,
        localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta),
      );
    } else if (isInserting) {
      context.missing(_localPathMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('mime_type')) {
      context.handle(
        _mimeTypeMeta,
        mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_mimeTypeMeta);
    }
    if (data.containsKey('file_size')) {
      context.handle(
        _fileSizeMeta,
        fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta),
      );
    } else if (isInserting) {
      context.missing(_fileSizeMeta);
    }
    if (data.containsKey('document_type')) {
      context.handle(
        _documentTypeMeta,
        documentType.isAcceptableOrUnknown(
          data['document_type']!,
          _documentTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_documentTypeMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('checksum')) {
      context.handle(
        _checksumMeta,
        checksum.isAcceptableOrUnknown(data['checksum']!, _checksumMeta),
      );
    }
    if (data.containsKey('upload_stage')) {
      context.handle(
        _uploadStageMeta,
        uploadStage.isAcceptableOrUnknown(
          data['upload_stage']!,
          _uploadStageMeta,
        ),
      );
    }
    if (data.containsKey('upload_url')) {
      context.handle(
        _uploadUrlMeta,
        uploadUrl.isAcceptableOrUnknown(data['upload_url']!, _uploadUrlMeta),
      );
    }
    if (data.containsKey('upload_url_expires_at')) {
      context.handle(
        _uploadUrlExpiresAtMeta,
        uploadUrlExpiresAt.isAcceptableOrUnknown(
          data['upload_url_expires_at']!,
          _uploadUrlExpiresAtMeta,
        ),
      );
    }
    if (data.containsKey('progress')) {
      context.handle(
        _progressMeta,
        progress.isAcceptableOrUnknown(data['progress']!, _progressMeta),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('last_error_message')) {
      context.handle(
        _lastErrorMessageMeta,
        lastErrorMessage.isAcceptableOrUnknown(
          data['last_error_message']!,
          _lastErrorMessageMeta,
        ),
      );
    }
    if (data.containsKey('field_visit_local_id')) {
      context.handle(
        _fieldVisitLocalIdMeta,
        fieldVisitLocalId.isAcceptableOrUnknown(
          data['field_visit_local_id']!,
          _fieldVisitLocalIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingAttachmentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingAttachmentRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      caseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}case_id'],
      )!,
      attachmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attachment_id'],
      ),
      localPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_path'],
      )!,
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      )!,
      mimeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime_type'],
      )!,
      fileSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size'],
      )!,
      documentType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_type'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      checksum: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}checksum'],
      ),
      uploadStage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}upload_stage'],
      )!,
      uploadUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}upload_url'],
      ),
      uploadUrlExpiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}upload_url_expires_at'],
      ),
      progress: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}progress'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      lastErrorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error_message'],
      ),
      fieldVisitLocalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_visit_local_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PendingAttachmentsTable createAlias(String alias) {
    return $PendingAttachmentsTable(attachedDatabase, alias);
  }
}

class PendingAttachmentRow extends DataClass
    implements Insertable<PendingAttachmentRow> {
  final String id;
  final String caseId;

  /// معرّف الخادم — يظهر بعد `/init` فقط.
  final String? attachmentId;

  /// مسار الملف في **مجلد التطبيق الدائم**.
  ///
  /// الصورة تُنسَخ فور التقاطها؛ مسار الكاميرا المؤقت يمسحه نظام التشغيل.
  final String localPath;
  final String fileName;
  final String mimeType;
  final int fileSize;
  final String documentType;
  final String? description;

  /// checksum محلي (MD5) — اختياري في العقد لكنه يكشف الملف التالف مبكرًا.
  final String? checksum;

  /// مرحلة الرفع: `captured` → `initialized` → `uploading` → `uploaded` → `committed`.
  ///
  /// الاستئناف يبدأ من آخر مرحلة وصلنا إليها، لا من الصفر.
  final String uploadStage;
  final String? uploadUrl;

  /// انتهاء صلاحية رابط الرفع — بعده يلزم `/init` جديد.
  final DateTime? uploadUrlExpiresAt;

  /// نسبة الرفع 0–1 — تُعرَض للمستخدم لأن الصور أثقل ما يُرفَع.
  final double progress;
  final int attempts;
  final String? lastErrorMessage;

  /// أي زيارة تملك هذا المرفق — يضمن رفعه قبلها.
  final String? fieldVisitLocalId;
  final DateTime createdAt;
  final DateTime updatedAt;
  const PendingAttachmentRow({
    required this.id,
    required this.caseId,
    this.attachmentId,
    required this.localPath,
    required this.fileName,
    required this.mimeType,
    required this.fileSize,
    required this.documentType,
    this.description,
    this.checksum,
    required this.uploadStage,
    this.uploadUrl,
    this.uploadUrlExpiresAt,
    required this.progress,
    required this.attempts,
    this.lastErrorMessage,
    this.fieldVisitLocalId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['case_id'] = Variable<String>(caseId);
    if (!nullToAbsent || attachmentId != null) {
      map['attachment_id'] = Variable<String>(attachmentId);
    }
    map['local_path'] = Variable<String>(localPath);
    map['file_name'] = Variable<String>(fileName);
    map['mime_type'] = Variable<String>(mimeType);
    map['file_size'] = Variable<int>(fileSize);
    map['document_type'] = Variable<String>(documentType);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || checksum != null) {
      map['checksum'] = Variable<String>(checksum);
    }
    map['upload_stage'] = Variable<String>(uploadStage);
    if (!nullToAbsent || uploadUrl != null) {
      map['upload_url'] = Variable<String>(uploadUrl);
    }
    if (!nullToAbsent || uploadUrlExpiresAt != null) {
      map['upload_url_expires_at'] = Variable<DateTime>(uploadUrlExpiresAt);
    }
    map['progress'] = Variable<double>(progress);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || lastErrorMessage != null) {
      map['last_error_message'] = Variable<String>(lastErrorMessage);
    }
    if (!nullToAbsent || fieldVisitLocalId != null) {
      map['field_visit_local_id'] = Variable<String>(fieldVisitLocalId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PendingAttachmentsCompanion toCompanion(bool nullToAbsent) {
    return PendingAttachmentsCompanion(
      id: Value(id),
      caseId: Value(caseId),
      attachmentId: attachmentId == null && nullToAbsent
          ? const Value.absent()
          : Value(attachmentId),
      localPath: Value(localPath),
      fileName: Value(fileName),
      mimeType: Value(mimeType),
      fileSize: Value(fileSize),
      documentType: Value(documentType),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      checksum: checksum == null && nullToAbsent
          ? const Value.absent()
          : Value(checksum),
      uploadStage: Value(uploadStage),
      uploadUrl: uploadUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(uploadUrl),
      uploadUrlExpiresAt: uploadUrlExpiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(uploadUrlExpiresAt),
      progress: Value(progress),
      attempts: Value(attempts),
      lastErrorMessage: lastErrorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(lastErrorMessage),
      fieldVisitLocalId: fieldVisitLocalId == null && nullToAbsent
          ? const Value.absent()
          : Value(fieldVisitLocalId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory PendingAttachmentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingAttachmentRow(
      id: serializer.fromJson<String>(json['id']),
      caseId: serializer.fromJson<String>(json['caseId']),
      attachmentId: serializer.fromJson<String?>(json['attachmentId']),
      localPath: serializer.fromJson<String>(json['localPath']),
      fileName: serializer.fromJson<String>(json['fileName']),
      mimeType: serializer.fromJson<String>(json['mimeType']),
      fileSize: serializer.fromJson<int>(json['fileSize']),
      documentType: serializer.fromJson<String>(json['documentType']),
      description: serializer.fromJson<String?>(json['description']),
      checksum: serializer.fromJson<String?>(json['checksum']),
      uploadStage: serializer.fromJson<String>(json['uploadStage']),
      uploadUrl: serializer.fromJson<String?>(json['uploadUrl']),
      uploadUrlExpiresAt: serializer.fromJson<DateTime?>(
        json['uploadUrlExpiresAt'],
      ),
      progress: serializer.fromJson<double>(json['progress']),
      attempts: serializer.fromJson<int>(json['attempts']),
      lastErrorMessage: serializer.fromJson<String?>(json['lastErrorMessage']),
      fieldVisitLocalId: serializer.fromJson<String?>(
        json['fieldVisitLocalId'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'caseId': serializer.toJson<String>(caseId),
      'attachmentId': serializer.toJson<String?>(attachmentId),
      'localPath': serializer.toJson<String>(localPath),
      'fileName': serializer.toJson<String>(fileName),
      'mimeType': serializer.toJson<String>(mimeType),
      'fileSize': serializer.toJson<int>(fileSize),
      'documentType': serializer.toJson<String>(documentType),
      'description': serializer.toJson<String?>(description),
      'checksum': serializer.toJson<String?>(checksum),
      'uploadStage': serializer.toJson<String>(uploadStage),
      'uploadUrl': serializer.toJson<String?>(uploadUrl),
      'uploadUrlExpiresAt': serializer.toJson<DateTime?>(uploadUrlExpiresAt),
      'progress': serializer.toJson<double>(progress),
      'attempts': serializer.toJson<int>(attempts),
      'lastErrorMessage': serializer.toJson<String?>(lastErrorMessage),
      'fieldVisitLocalId': serializer.toJson<String?>(fieldVisitLocalId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PendingAttachmentRow copyWith({
    String? id,
    String? caseId,
    Value<String?> attachmentId = const Value.absent(),
    String? localPath,
    String? fileName,
    String? mimeType,
    int? fileSize,
    String? documentType,
    Value<String?> description = const Value.absent(),
    Value<String?> checksum = const Value.absent(),
    String? uploadStage,
    Value<String?> uploadUrl = const Value.absent(),
    Value<DateTime?> uploadUrlExpiresAt = const Value.absent(),
    double? progress,
    int? attempts,
    Value<String?> lastErrorMessage = const Value.absent(),
    Value<String?> fieldVisitLocalId = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => PendingAttachmentRow(
    id: id ?? this.id,
    caseId: caseId ?? this.caseId,
    attachmentId: attachmentId.present ? attachmentId.value : this.attachmentId,
    localPath: localPath ?? this.localPath,
    fileName: fileName ?? this.fileName,
    mimeType: mimeType ?? this.mimeType,
    fileSize: fileSize ?? this.fileSize,
    documentType: documentType ?? this.documentType,
    description: description.present ? description.value : this.description,
    checksum: checksum.present ? checksum.value : this.checksum,
    uploadStage: uploadStage ?? this.uploadStage,
    uploadUrl: uploadUrl.present ? uploadUrl.value : this.uploadUrl,
    uploadUrlExpiresAt: uploadUrlExpiresAt.present
        ? uploadUrlExpiresAt.value
        : this.uploadUrlExpiresAt,
    progress: progress ?? this.progress,
    attempts: attempts ?? this.attempts,
    lastErrorMessage: lastErrorMessage.present
        ? lastErrorMessage.value
        : this.lastErrorMessage,
    fieldVisitLocalId: fieldVisitLocalId.present
        ? fieldVisitLocalId.value
        : this.fieldVisitLocalId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PendingAttachmentRow copyWithCompanion(PendingAttachmentsCompanion data) {
    return PendingAttachmentRow(
      id: data.id.present ? data.id.value : this.id,
      caseId: data.caseId.present ? data.caseId.value : this.caseId,
      attachmentId: data.attachmentId.present
          ? data.attachmentId.value
          : this.attachmentId,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      documentType: data.documentType.present
          ? data.documentType.value
          : this.documentType,
      description: data.description.present
          ? data.description.value
          : this.description,
      checksum: data.checksum.present ? data.checksum.value : this.checksum,
      uploadStage: data.uploadStage.present
          ? data.uploadStage.value
          : this.uploadStage,
      uploadUrl: data.uploadUrl.present ? data.uploadUrl.value : this.uploadUrl,
      uploadUrlExpiresAt: data.uploadUrlExpiresAt.present
          ? data.uploadUrlExpiresAt.value
          : this.uploadUrlExpiresAt,
      progress: data.progress.present ? data.progress.value : this.progress,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      lastErrorMessage: data.lastErrorMessage.present
          ? data.lastErrorMessage.value
          : this.lastErrorMessage,
      fieldVisitLocalId: data.fieldVisitLocalId.present
          ? data.fieldVisitLocalId.value
          : this.fieldVisitLocalId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingAttachmentRow(')
          ..write('id: $id, ')
          ..write('caseId: $caseId, ')
          ..write('attachmentId: $attachmentId, ')
          ..write('localPath: $localPath, ')
          ..write('fileName: $fileName, ')
          ..write('mimeType: $mimeType, ')
          ..write('fileSize: $fileSize, ')
          ..write('documentType: $documentType, ')
          ..write('description: $description, ')
          ..write('checksum: $checksum, ')
          ..write('uploadStage: $uploadStage, ')
          ..write('uploadUrl: $uploadUrl, ')
          ..write('uploadUrlExpiresAt: $uploadUrlExpiresAt, ')
          ..write('progress: $progress, ')
          ..write('attempts: $attempts, ')
          ..write('lastErrorMessage: $lastErrorMessage, ')
          ..write('fieldVisitLocalId: $fieldVisitLocalId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    caseId,
    attachmentId,
    localPath,
    fileName,
    mimeType,
    fileSize,
    documentType,
    description,
    checksum,
    uploadStage,
    uploadUrl,
    uploadUrlExpiresAt,
    progress,
    attempts,
    lastErrorMessage,
    fieldVisitLocalId,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingAttachmentRow &&
          other.id == this.id &&
          other.caseId == this.caseId &&
          other.attachmentId == this.attachmentId &&
          other.localPath == this.localPath &&
          other.fileName == this.fileName &&
          other.mimeType == this.mimeType &&
          other.fileSize == this.fileSize &&
          other.documentType == this.documentType &&
          other.description == this.description &&
          other.checksum == this.checksum &&
          other.uploadStage == this.uploadStage &&
          other.uploadUrl == this.uploadUrl &&
          other.uploadUrlExpiresAt == this.uploadUrlExpiresAt &&
          other.progress == this.progress &&
          other.attempts == this.attempts &&
          other.lastErrorMessage == this.lastErrorMessage &&
          other.fieldVisitLocalId == this.fieldVisitLocalId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PendingAttachmentsCompanion
    extends UpdateCompanion<PendingAttachmentRow> {
  final Value<String> id;
  final Value<String> caseId;
  final Value<String?> attachmentId;
  final Value<String> localPath;
  final Value<String> fileName;
  final Value<String> mimeType;
  final Value<int> fileSize;
  final Value<String> documentType;
  final Value<String?> description;
  final Value<String?> checksum;
  final Value<String> uploadStage;
  final Value<String?> uploadUrl;
  final Value<DateTime?> uploadUrlExpiresAt;
  final Value<double> progress;
  final Value<int> attempts;
  final Value<String?> lastErrorMessage;
  final Value<String?> fieldVisitLocalId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const PendingAttachmentsCompanion({
    this.id = const Value.absent(),
    this.caseId = const Value.absent(),
    this.attachmentId = const Value.absent(),
    this.localPath = const Value.absent(),
    this.fileName = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.documentType = const Value.absent(),
    this.description = const Value.absent(),
    this.checksum = const Value.absent(),
    this.uploadStage = const Value.absent(),
    this.uploadUrl = const Value.absent(),
    this.uploadUrlExpiresAt = const Value.absent(),
    this.progress = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastErrorMessage = const Value.absent(),
    this.fieldVisitLocalId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PendingAttachmentsCompanion.insert({
    required String id,
    required String caseId,
    this.attachmentId = const Value.absent(),
    required String localPath,
    required String fileName,
    required String mimeType,
    required int fileSize,
    required String documentType,
    this.description = const Value.absent(),
    this.checksum = const Value.absent(),
    this.uploadStage = const Value.absent(),
    this.uploadUrl = const Value.absent(),
    this.uploadUrlExpiresAt = const Value.absent(),
    this.progress = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastErrorMessage = const Value.absent(),
    this.fieldVisitLocalId = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       caseId = Value(caseId),
       localPath = Value(localPath),
       fileName = Value(fileName),
       mimeType = Value(mimeType),
       fileSize = Value(fileSize),
       documentType = Value(documentType),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<PendingAttachmentRow> custom({
    Expression<String>? id,
    Expression<String>? caseId,
    Expression<String>? attachmentId,
    Expression<String>? localPath,
    Expression<String>? fileName,
    Expression<String>? mimeType,
    Expression<int>? fileSize,
    Expression<String>? documentType,
    Expression<String>? description,
    Expression<String>? checksum,
    Expression<String>? uploadStage,
    Expression<String>? uploadUrl,
    Expression<DateTime>? uploadUrlExpiresAt,
    Expression<double>? progress,
    Expression<int>? attempts,
    Expression<String>? lastErrorMessage,
    Expression<String>? fieldVisitLocalId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (caseId != null) 'case_id': caseId,
      if (attachmentId != null) 'attachment_id': attachmentId,
      if (localPath != null) 'local_path': localPath,
      if (fileName != null) 'file_name': fileName,
      if (mimeType != null) 'mime_type': mimeType,
      if (fileSize != null) 'file_size': fileSize,
      if (documentType != null) 'document_type': documentType,
      if (description != null) 'description': description,
      if (checksum != null) 'checksum': checksum,
      if (uploadStage != null) 'upload_stage': uploadStage,
      if (uploadUrl != null) 'upload_url': uploadUrl,
      if (uploadUrlExpiresAt != null)
        'upload_url_expires_at': uploadUrlExpiresAt,
      if (progress != null) 'progress': progress,
      if (attempts != null) 'attempts': attempts,
      if (lastErrorMessage != null) 'last_error_message': lastErrorMessage,
      if (fieldVisitLocalId != null) 'field_visit_local_id': fieldVisitLocalId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PendingAttachmentsCompanion copyWith({
    Value<String>? id,
    Value<String>? caseId,
    Value<String?>? attachmentId,
    Value<String>? localPath,
    Value<String>? fileName,
    Value<String>? mimeType,
    Value<int>? fileSize,
    Value<String>? documentType,
    Value<String?>? description,
    Value<String?>? checksum,
    Value<String>? uploadStage,
    Value<String?>? uploadUrl,
    Value<DateTime?>? uploadUrlExpiresAt,
    Value<double>? progress,
    Value<int>? attempts,
    Value<String?>? lastErrorMessage,
    Value<String?>? fieldVisitLocalId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return PendingAttachmentsCompanion(
      id: id ?? this.id,
      caseId: caseId ?? this.caseId,
      attachmentId: attachmentId ?? this.attachmentId,
      localPath: localPath ?? this.localPath,
      fileName: fileName ?? this.fileName,
      mimeType: mimeType ?? this.mimeType,
      fileSize: fileSize ?? this.fileSize,
      documentType: documentType ?? this.documentType,
      description: description ?? this.description,
      checksum: checksum ?? this.checksum,
      uploadStage: uploadStage ?? this.uploadStage,
      uploadUrl: uploadUrl ?? this.uploadUrl,
      uploadUrlExpiresAt: uploadUrlExpiresAt ?? this.uploadUrlExpiresAt,
      progress: progress ?? this.progress,
      attempts: attempts ?? this.attempts,
      lastErrorMessage: lastErrorMessage ?? this.lastErrorMessage,
      fieldVisitLocalId: fieldVisitLocalId ?? this.fieldVisitLocalId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (caseId.present) {
      map['case_id'] = Variable<String>(caseId.value);
    }
    if (attachmentId.present) {
      map['attachment_id'] = Variable<String>(attachmentId.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (documentType.present) {
      map['document_type'] = Variable<String>(documentType.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (checksum.present) {
      map['checksum'] = Variable<String>(checksum.value);
    }
    if (uploadStage.present) {
      map['upload_stage'] = Variable<String>(uploadStage.value);
    }
    if (uploadUrl.present) {
      map['upload_url'] = Variable<String>(uploadUrl.value);
    }
    if (uploadUrlExpiresAt.present) {
      map['upload_url_expires_at'] = Variable<DateTime>(
        uploadUrlExpiresAt.value,
      );
    }
    if (progress.present) {
      map['progress'] = Variable<double>(progress.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (lastErrorMessage.present) {
      map['last_error_message'] = Variable<String>(lastErrorMessage.value);
    }
    if (fieldVisitLocalId.present) {
      map['field_visit_local_id'] = Variable<String>(fieldVisitLocalId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingAttachmentsCompanion(')
          ..write('id: $id, ')
          ..write('caseId: $caseId, ')
          ..write('attachmentId: $attachmentId, ')
          ..write('localPath: $localPath, ')
          ..write('fileName: $fileName, ')
          ..write('mimeType: $mimeType, ')
          ..write('fileSize: $fileSize, ')
          ..write('documentType: $documentType, ')
          ..write('description: $description, ')
          ..write('checksum: $checksum, ')
          ..write('uploadStage: $uploadStage, ')
          ..write('uploadUrl: $uploadUrl, ')
          ..write('uploadUrlExpiresAt: $uploadUrlExpiresAt, ')
          ..write('progress: $progress, ')
          ..write('attempts: $attempts, ')
          ..write('lastErrorMessage: $lastErrorMessage, ')
          ..write('fieldVisitLocalId: $fieldVisitLocalId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DropdownCacheTable extends DropdownCache
    with TableInfo<$DropdownCacheTable, DropdownCacheRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DropdownCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valuesJsonMeta = const VerificationMeta(
    'valuesJson',
  );
  @override
  late final GeneratedColumn<String> valuesJson = GeneratedColumn<String>(
    'values_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, valuesJson, fetchedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dropdown_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<DropdownCacheRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('values_json')) {
      context.handle(
        _valuesJsonMeta,
        valuesJson.isAcceptableOrUnknown(data['values_json']!, _valuesJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_valuesJsonMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  DropdownCacheRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DropdownCacheRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      valuesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}values_json'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $DropdownCacheTable createAlias(String alias) {
    return $DropdownCacheTable(attachedDatabase, alias);
  }
}

class DropdownCacheRow extends DataClass
    implements Insertable<DropdownCacheRow> {
  /// مفتاح القائمة، أو `__locations__` / `__charities__` للحالات الخاصة.
  final String key;
  final String valuesJson;
  final DateTime fetchedAt;
  const DropdownCacheRow({
    required this.key,
    required this.valuesJson,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['values_json'] = Variable<String>(valuesJson);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  DropdownCacheCompanion toCompanion(bool nullToAbsent) {
    return DropdownCacheCompanion(
      key: Value(key),
      valuesJson: Value(valuesJson),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory DropdownCacheRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DropdownCacheRow(
      key: serializer.fromJson<String>(json['key']),
      valuesJson: serializer.fromJson<String>(json['valuesJson']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'valuesJson': serializer.toJson<String>(valuesJson),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  DropdownCacheRow copyWith({
    String? key,
    String? valuesJson,
    DateTime? fetchedAt,
  }) => DropdownCacheRow(
    key: key ?? this.key,
    valuesJson: valuesJson ?? this.valuesJson,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  DropdownCacheRow copyWithCompanion(DropdownCacheCompanion data) {
    return DropdownCacheRow(
      key: data.key.present ? data.key.value : this.key,
      valuesJson: data.valuesJson.present
          ? data.valuesJson.value
          : this.valuesJson,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DropdownCacheRow(')
          ..write('key: $key, ')
          ..write('valuesJson: $valuesJson, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, valuesJson, fetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DropdownCacheRow &&
          other.key == this.key &&
          other.valuesJson == this.valuesJson &&
          other.fetchedAt == this.fetchedAt);
}

class DropdownCacheCompanion extends UpdateCompanion<DropdownCacheRow> {
  final Value<String> key;
  final Value<String> valuesJson;
  final Value<DateTime> fetchedAt;
  final Value<int> rowid;
  const DropdownCacheCompanion({
    this.key = const Value.absent(),
    this.valuesJson = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DropdownCacheCompanion.insert({
    required String key,
    required String valuesJson,
    required DateTime fetchedAt,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       valuesJson = Value(valuesJson),
       fetchedAt = Value(fetchedAt);
  static Insertable<DropdownCacheRow> custom({
    Expression<String>? key,
    Expression<String>? valuesJson,
    Expression<DateTime>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (valuesJson != null) 'values_json': valuesJson,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DropdownCacheCompanion copyWith({
    Value<String>? key,
    Value<String>? valuesJson,
    Value<DateTime>? fetchedAt,
    Value<int>? rowid,
  }) {
    return DropdownCacheCompanion(
      key: key ?? this.key,
      valuesJson: valuesJson ?? this.valuesJson,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (valuesJson.present) {
      map['values_json'] = Variable<String>(valuesJson.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DropdownCacheCompanion(')
          ..write('key: $key, ')
          ..write('valuesJson: $valuesJson, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedNotificationsTable extends CachedNotifications
    with TableInfo<$CachedNotificationsTable, CachedNotificationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedNotificationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subtitleMeta = const VerificationMeta(
    'subtitle',
  );
  @override
  late final GeneratedColumn<String> subtitle = GeneratedColumn<String>(
    'subtitle',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isReadMeta = const VerificationMeta('isRead');
  @override
  late final GeneratedColumn<bool> isRead = GeneratedColumn<bool>(
    'is_read',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_read" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _caseIdMeta = const VerificationMeta('caseId');
  @override
  late final GeneratedColumn<String> caseId = GeneratedColumn<String>(
    'case_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtUtcMeta = const VerificationMeta(
    'createdAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> createdAtUtc = GeneratedColumn<DateTime>(
    'created_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    subtitle,
    icon,
    isRead,
    caseId,
    createdAtUtc,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_notifications';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedNotificationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('subtitle')) {
      context.handle(
        _subtitleMeta,
        subtitle.isAcceptableOrUnknown(data['subtitle']!, _subtitleMeta),
      );
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('is_read')) {
      context.handle(
        _isReadMeta,
        isRead.isAcceptableOrUnknown(data['is_read']!, _isReadMeta),
      );
    }
    if (data.containsKey('case_id')) {
      context.handle(
        _caseIdMeta,
        caseId.isAcceptableOrUnknown(data['case_id']!, _caseIdMeta),
      );
    }
    if (data.containsKey('created_at_utc')) {
      context.handle(
        _createdAtUtcMeta,
        createdAtUtc.isAcceptableOrUnknown(
          data['created_at_utc']!,
          _createdAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtUtcMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedNotificationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedNotificationRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      subtitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subtitle'],
      ),
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      ),
      isRead: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_read'],
      )!,
      caseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}case_id'],
      ),
      createdAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at_utc'],
      )!,
    );
  }

  @override
  $CachedNotificationsTable createAlias(String alias) {
    return $CachedNotificationsTable(attachedDatabase, alias);
  }
}

class CachedNotificationRow extends DataClass
    implements Insertable<CachedNotificationRow> {
  final String id;
  final String title;
  final String? subtitle;
  final String? icon;
  final bool isRead;
  final String? caseId;
  final DateTime createdAtUtc;
  const CachedNotificationRow({
    required this.id,
    required this.title,
    this.subtitle,
    this.icon,
    required this.isRead,
    this.caseId,
    required this.createdAtUtc,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || subtitle != null) {
      map['subtitle'] = Variable<String>(subtitle);
    }
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    map['is_read'] = Variable<bool>(isRead);
    if (!nullToAbsent || caseId != null) {
      map['case_id'] = Variable<String>(caseId);
    }
    map['created_at_utc'] = Variable<DateTime>(createdAtUtc);
    return map;
  }

  CachedNotificationsCompanion toCompanion(bool nullToAbsent) {
    return CachedNotificationsCompanion(
      id: Value(id),
      title: Value(title),
      subtitle: subtitle == null && nullToAbsent
          ? const Value.absent()
          : Value(subtitle),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      isRead: Value(isRead),
      caseId: caseId == null && nullToAbsent
          ? const Value.absent()
          : Value(caseId),
      createdAtUtc: Value(createdAtUtc),
    );
  }

  factory CachedNotificationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedNotificationRow(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      subtitle: serializer.fromJson<String?>(json['subtitle']),
      icon: serializer.fromJson<String?>(json['icon']),
      isRead: serializer.fromJson<bool>(json['isRead']),
      caseId: serializer.fromJson<String?>(json['caseId']),
      createdAtUtc: serializer.fromJson<DateTime>(json['createdAtUtc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'subtitle': serializer.toJson<String?>(subtitle),
      'icon': serializer.toJson<String?>(icon),
      'isRead': serializer.toJson<bool>(isRead),
      'caseId': serializer.toJson<String?>(caseId),
      'createdAtUtc': serializer.toJson<DateTime>(createdAtUtc),
    };
  }

  CachedNotificationRow copyWith({
    String? id,
    String? title,
    Value<String?> subtitle = const Value.absent(),
    Value<String?> icon = const Value.absent(),
    bool? isRead,
    Value<String?> caseId = const Value.absent(),
    DateTime? createdAtUtc,
  }) => CachedNotificationRow(
    id: id ?? this.id,
    title: title ?? this.title,
    subtitle: subtitle.present ? subtitle.value : this.subtitle,
    icon: icon.present ? icon.value : this.icon,
    isRead: isRead ?? this.isRead,
    caseId: caseId.present ? caseId.value : this.caseId,
    createdAtUtc: createdAtUtc ?? this.createdAtUtc,
  );
  CachedNotificationRow copyWithCompanion(CachedNotificationsCompanion data) {
    return CachedNotificationRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      subtitle: data.subtitle.present ? data.subtitle.value : this.subtitle,
      icon: data.icon.present ? data.icon.value : this.icon,
      isRead: data.isRead.present ? data.isRead.value : this.isRead,
      caseId: data.caseId.present ? data.caseId.value : this.caseId,
      createdAtUtc: data.createdAtUtc.present
          ? data.createdAtUtc.value
          : this.createdAtUtc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedNotificationRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('subtitle: $subtitle, ')
          ..write('icon: $icon, ')
          ..write('isRead: $isRead, ')
          ..write('caseId: $caseId, ')
          ..write('createdAtUtc: $createdAtUtc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, title, subtitle, icon, isRead, caseId, createdAtUtc);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedNotificationRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.subtitle == this.subtitle &&
          other.icon == this.icon &&
          other.isRead == this.isRead &&
          other.caseId == this.caseId &&
          other.createdAtUtc == this.createdAtUtc);
}

class CachedNotificationsCompanion
    extends UpdateCompanion<CachedNotificationRow> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> subtitle;
  final Value<String?> icon;
  final Value<bool> isRead;
  final Value<String?> caseId;
  final Value<DateTime> createdAtUtc;
  final Value<int> rowid;
  const CachedNotificationsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.subtitle = const Value.absent(),
    this.icon = const Value.absent(),
    this.isRead = const Value.absent(),
    this.caseId = const Value.absent(),
    this.createdAtUtc = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedNotificationsCompanion.insert({
    required String id,
    required String title,
    this.subtitle = const Value.absent(),
    this.icon = const Value.absent(),
    this.isRead = const Value.absent(),
    this.caseId = const Value.absent(),
    required DateTime createdAtUtc,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       createdAtUtc = Value(createdAtUtc);
  static Insertable<CachedNotificationRow> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? subtitle,
    Expression<String>? icon,
    Expression<bool>? isRead,
    Expression<String>? caseId,
    Expression<DateTime>? createdAtUtc,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (subtitle != null) 'subtitle': subtitle,
      if (icon != null) 'icon': icon,
      if (isRead != null) 'is_read': isRead,
      if (caseId != null) 'case_id': caseId,
      if (createdAtUtc != null) 'created_at_utc': createdAtUtc,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedNotificationsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String?>? subtitle,
    Value<String?>? icon,
    Value<bool>? isRead,
    Value<String?>? caseId,
    Value<DateTime>? createdAtUtc,
    Value<int>? rowid,
  }) {
    return CachedNotificationsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      icon: icon ?? this.icon,
      isRead: isRead ?? this.isRead,
      caseId: caseId ?? this.caseId,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (subtitle.present) {
      map['subtitle'] = Variable<String>(subtitle.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (isRead.present) {
      map['is_read'] = Variable<bool>(isRead.value);
    }
    if (caseId.present) {
      map['case_id'] = Variable<String>(caseId.value);
    }
    if (createdAtUtc.present) {
      map['created_at_utc'] = Variable<DateTime>(createdAtUtc.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedNotificationsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('subtitle: $subtitle, ')
          ..write('icon: $icon, ')
          ..write('isRead: $isRead, ')
          ..write('caseId: $caseId, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SyncQueueTable syncQueue = $SyncQueueTable(this);
  late final $CachedCasesTable cachedCases = $CachedCasesTable(this);
  late final $CachedSectionsTable cachedSections = $CachedSectionsTable(this);
  late final $LocalFieldVisitsTable localFieldVisits = $LocalFieldVisitsTable(
    this,
  );
  late final $PendingAttachmentsTable pendingAttachments =
      $PendingAttachmentsTable(this);
  late final $DropdownCacheTable dropdownCache = $DropdownCacheTable(this);
  late final $CachedNotificationsTable cachedNotifications =
      $CachedNotificationsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    syncQueue,
    cachedCases,
    cachedSections,
    localFieldVisits,
    pendingAttachments,
    dropdownCache,
    cachedNotifications,
  ];
}

typedef $$SyncQueueTableCreateCompanionBuilder =
    SyncQueueCompanion Function({
      required String id,
      required String type,
      required String caseId,
      Value<String?> userId,
      required int sequence,
      required String payload,
      Value<String?> idempotencyKey,
      Value<String?> dedupId,
      Value<int?> rowVersion,
      Value<String> status,
      Value<int> attempts,
      Value<String?> lastErrorCode,
      Value<String?> lastErrorMessage,
      Value<DateTime?> nextAttemptAt,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> sentAt,
      Value<int> rowid,
    });
typedef $$SyncQueueTableUpdateCompanionBuilder =
    SyncQueueCompanion Function({
      Value<String> id,
      Value<String> type,
      Value<String> caseId,
      Value<String?> userId,
      Value<int> sequence,
      Value<String> payload,
      Value<String?> idempotencyKey,
      Value<String?> dedupId,
      Value<int?> rowVersion,
      Value<String> status,
      Value<int> attempts,
      Value<String?> lastErrorCode,
      Value<String?> lastErrorMessage,
      Value<DateTime?> nextAttemptAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> sentAt,
      Value<int> rowid,
    });

class $$SyncQueueTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get caseId => $composableBuilder(
    column: $table.caseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dedupId => $composableBuilder(
    column: $table.dedupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rowVersion => $composableBuilder(
    column: $table.rowVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastErrorMessage => $composableBuilder(
    column: $table.lastErrorMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get caseId => $composableBuilder(
    column: $table.caseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dedupId => $composableBuilder(
    column: $table.dedupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rowVersion => $composableBuilder(
    column: $table.rowVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastErrorMessage => $composableBuilder(
    column: $table.lastErrorMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get caseId =>
      $composableBuilder(column: $table.caseId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<int> get sequence =>
      $composableBuilder(column: $table.sequence, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dedupId =>
      $composableBuilder(column: $table.dedupId, builder: (column) => column);

  GeneratedColumn<int> get rowVersion => $composableBuilder(
    column: $table.rowVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastErrorMessage => $composableBuilder(
    column: $table.lastErrorMessage,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get sentAt =>
      $composableBuilder(column: $table.sentAt, builder: (column) => column);
}

class $$SyncQueueTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncQueueTable,
          SyncOperationRow,
          $$SyncQueueTableFilterComposer,
          $$SyncQueueTableOrderingComposer,
          $$SyncQueueTableAnnotationComposer,
          $$SyncQueueTableCreateCompanionBuilder,
          $$SyncQueueTableUpdateCompanionBuilder,
          (
            SyncOperationRow,
            BaseReferences<_$AppDatabase, $SyncQueueTable, SyncOperationRow>,
          ),
          SyncOperationRow,
          PrefetchHooks Function()
        > {
  $$SyncQueueTableTableManager(_$AppDatabase db, $SyncQueueTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> caseId = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                Value<int> sequence = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<String?> idempotencyKey = const Value.absent(),
                Value<String?> dedupId = const Value.absent(),
                Value<int?> rowVersion = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastErrorCode = const Value.absent(),
                Value<String?> lastErrorMessage = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> sentAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncQueueCompanion(
                id: id,
                type: type,
                caseId: caseId,
                userId: userId,
                sequence: sequence,
                payload: payload,
                idempotencyKey: idempotencyKey,
                dedupId: dedupId,
                rowVersion: rowVersion,
                status: status,
                attempts: attempts,
                lastErrorCode: lastErrorCode,
                lastErrorMessage: lastErrorMessage,
                nextAttemptAt: nextAttemptAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                sentAt: sentAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String type,
                required String caseId,
                Value<String?> userId = const Value.absent(),
                required int sequence,
                required String payload,
                Value<String?> idempotencyKey = const Value.absent(),
                Value<String?> dedupId = const Value.absent(),
                Value<int?> rowVersion = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastErrorCode = const Value.absent(),
                Value<String?> lastErrorMessage = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> sentAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncQueueCompanion.insert(
                id: id,
                type: type,
                caseId: caseId,
                userId: userId,
                sequence: sequence,
                payload: payload,
                idempotencyKey: idempotencyKey,
                dedupId: dedupId,
                rowVersion: rowVersion,
                status: status,
                attempts: attempts,
                lastErrorCode: lastErrorCode,
                lastErrorMessage: lastErrorMessage,
                nextAttemptAt: nextAttemptAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                sentAt: sentAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncQueueTable,
      SyncOperationRow,
      $$SyncQueueTableFilterComposer,
      $$SyncQueueTableOrderingComposer,
      $$SyncQueueTableAnnotationComposer,
      $$SyncQueueTableCreateCompanionBuilder,
      $$SyncQueueTableUpdateCompanionBuilder,
      (
        SyncOperationRow,
        BaseReferences<_$AppDatabase, $SyncQueueTable, SyncOperationRow>,
      ),
      SyncOperationRow,
      PrefetchHooks Function()
    >;
typedef $$CachedCasesTableCreateCompanionBuilder =
    CachedCasesCompanion Function({
      required String id,
      required String caseNumber,
      required String displayId,
      required String status,
      required String priority,
      required String beneficiaryFullName,
      Value<String?> nationalId,
      Value<String?> charityId,
      Value<String?> registrationDate,
      Value<double> completionPercentage,
      Value<String?> nextVisitDate,
      Value<DateTime?> nextVisitStartTimeUtc,
      Value<String?> nextVisitLocation,
      Value<bool> isBookmarked,
      Value<int?> rowVersion,
      Value<int?> beneficiaryRowVersion,
      Value<String?> availableActionsJson,
      Value<String?> detailsJson,
      Value<bool> hasFullDetails,
      Value<String> syncState,
      Value<DateTime?> serverUpdatedAt,
      Value<DateTime?> localUpdatedAt,
      required DateTime fetchedAt,
      Value<int> rowid,
    });
typedef $$CachedCasesTableUpdateCompanionBuilder =
    CachedCasesCompanion Function({
      Value<String> id,
      Value<String> caseNumber,
      Value<String> displayId,
      Value<String> status,
      Value<String> priority,
      Value<String> beneficiaryFullName,
      Value<String?> nationalId,
      Value<String?> charityId,
      Value<String?> registrationDate,
      Value<double> completionPercentage,
      Value<String?> nextVisitDate,
      Value<DateTime?> nextVisitStartTimeUtc,
      Value<String?> nextVisitLocation,
      Value<bool> isBookmarked,
      Value<int?> rowVersion,
      Value<int?> beneficiaryRowVersion,
      Value<String?> availableActionsJson,
      Value<String?> detailsJson,
      Value<bool> hasFullDetails,
      Value<String> syncState,
      Value<DateTime?> serverUpdatedAt,
      Value<DateTime?> localUpdatedAt,
      Value<DateTime> fetchedAt,
      Value<int> rowid,
    });

class $$CachedCasesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedCasesTable> {
  $$CachedCasesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get caseNumber => $composableBuilder(
    column: $table.caseNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayId => $composableBuilder(
    column: $table.displayId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get beneficiaryFullName => $composableBuilder(
    column: $table.beneficiaryFullName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nationalId => $composableBuilder(
    column: $table.nationalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get charityId => $composableBuilder(
    column: $table.charityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get registrationDate => $composableBuilder(
    column: $table.registrationDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get completionPercentage => $composableBuilder(
    column: $table.completionPercentage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nextVisitDate => $composableBuilder(
    column: $table.nextVisitDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextVisitStartTimeUtc => $composableBuilder(
    column: $table.nextVisitStartTimeUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nextVisitLocation => $composableBuilder(
    column: $table.nextVisitLocation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isBookmarked => $composableBuilder(
    column: $table.isBookmarked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rowVersion => $composableBuilder(
    column: $table.rowVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get beneficiaryRowVersion => $composableBuilder(
    column: $table.beneficiaryRowVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get availableActionsJson => $composableBuilder(
    column: $table.availableActionsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get detailsJson => $composableBuilder(
    column: $table.detailsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasFullDetails => $composableBuilder(
    column: $table.hasFullDetails,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedCasesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedCasesTable> {
  $$CachedCasesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get caseNumber => $composableBuilder(
    column: $table.caseNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayId => $composableBuilder(
    column: $table.displayId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get beneficiaryFullName => $composableBuilder(
    column: $table.beneficiaryFullName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nationalId => $composableBuilder(
    column: $table.nationalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get charityId => $composableBuilder(
    column: $table.charityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get registrationDate => $composableBuilder(
    column: $table.registrationDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get completionPercentage => $composableBuilder(
    column: $table.completionPercentage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nextVisitDate => $composableBuilder(
    column: $table.nextVisitDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextVisitStartTimeUtc => $composableBuilder(
    column: $table.nextVisitStartTimeUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nextVisitLocation => $composableBuilder(
    column: $table.nextVisitLocation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isBookmarked => $composableBuilder(
    column: $table.isBookmarked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rowVersion => $composableBuilder(
    column: $table.rowVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get beneficiaryRowVersion => $composableBuilder(
    column: $table.beneficiaryRowVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get availableActionsJson => $composableBuilder(
    column: $table.availableActionsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get detailsJson => $composableBuilder(
    column: $table.detailsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasFullDetails => $composableBuilder(
    column: $table.hasFullDetails,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedCasesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedCasesTable> {
  $$CachedCasesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get caseNumber => $composableBuilder(
    column: $table.caseNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get displayId =>
      $composableBuilder(column: $table.displayId, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<String> get beneficiaryFullName => $composableBuilder(
    column: $table.beneficiaryFullName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nationalId => $composableBuilder(
    column: $table.nationalId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get charityId =>
      $composableBuilder(column: $table.charityId, builder: (column) => column);

  GeneratedColumn<String> get registrationDate => $composableBuilder(
    column: $table.registrationDate,
    builder: (column) => column,
  );

  GeneratedColumn<double> get completionPercentage => $composableBuilder(
    column: $table.completionPercentage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nextVisitDate => $composableBuilder(
    column: $table.nextVisitDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get nextVisitStartTimeUtc => $composableBuilder(
    column: $table.nextVisitStartTimeUtc,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nextVisitLocation => $composableBuilder(
    column: $table.nextVisitLocation,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isBookmarked => $composableBuilder(
    column: $table.isBookmarked,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rowVersion => $composableBuilder(
    column: $table.rowVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get beneficiaryRowVersion => $composableBuilder(
    column: $table.beneficiaryRowVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get availableActionsJson => $composableBuilder(
    column: $table.availableActionsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get detailsJson => $composableBuilder(
    column: $table.detailsJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get hasFullDetails => $composableBuilder(
    column: $table.hasFullDetails,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  GeneratedColumn<DateTime> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$CachedCasesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedCasesTable,
          CachedCaseRow,
          $$CachedCasesTableFilterComposer,
          $$CachedCasesTableOrderingComposer,
          $$CachedCasesTableAnnotationComposer,
          $$CachedCasesTableCreateCompanionBuilder,
          $$CachedCasesTableUpdateCompanionBuilder,
          (
            CachedCaseRow,
            BaseReferences<_$AppDatabase, $CachedCasesTable, CachedCaseRow>,
          ),
          CachedCaseRow,
          PrefetchHooks Function()
        > {
  $$CachedCasesTableTableManager(_$AppDatabase db, $CachedCasesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedCasesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedCasesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedCasesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> caseNumber = const Value.absent(),
                Value<String> displayId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> priority = const Value.absent(),
                Value<String> beneficiaryFullName = const Value.absent(),
                Value<String?> nationalId = const Value.absent(),
                Value<String?> charityId = const Value.absent(),
                Value<String?> registrationDate = const Value.absent(),
                Value<double> completionPercentage = const Value.absent(),
                Value<String?> nextVisitDate = const Value.absent(),
                Value<DateTime?> nextVisitStartTimeUtc = const Value.absent(),
                Value<String?> nextVisitLocation = const Value.absent(),
                Value<bool> isBookmarked = const Value.absent(),
                Value<int?> rowVersion = const Value.absent(),
                Value<int?> beneficiaryRowVersion = const Value.absent(),
                Value<String?> availableActionsJson = const Value.absent(),
                Value<String?> detailsJson = const Value.absent(),
                Value<bool> hasFullDetails = const Value.absent(),
                Value<String> syncState = const Value.absent(),
                Value<DateTime?> serverUpdatedAt = const Value.absent(),
                Value<DateTime?> localUpdatedAt = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedCasesCompanion(
                id: id,
                caseNumber: caseNumber,
                displayId: displayId,
                status: status,
                priority: priority,
                beneficiaryFullName: beneficiaryFullName,
                nationalId: nationalId,
                charityId: charityId,
                registrationDate: registrationDate,
                completionPercentage: completionPercentage,
                nextVisitDate: nextVisitDate,
                nextVisitStartTimeUtc: nextVisitStartTimeUtc,
                nextVisitLocation: nextVisitLocation,
                isBookmarked: isBookmarked,
                rowVersion: rowVersion,
                beneficiaryRowVersion: beneficiaryRowVersion,
                availableActionsJson: availableActionsJson,
                detailsJson: detailsJson,
                hasFullDetails: hasFullDetails,
                syncState: syncState,
                serverUpdatedAt: serverUpdatedAt,
                localUpdatedAt: localUpdatedAt,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String caseNumber,
                required String displayId,
                required String status,
                required String priority,
                required String beneficiaryFullName,
                Value<String?> nationalId = const Value.absent(),
                Value<String?> charityId = const Value.absent(),
                Value<String?> registrationDate = const Value.absent(),
                Value<double> completionPercentage = const Value.absent(),
                Value<String?> nextVisitDate = const Value.absent(),
                Value<DateTime?> nextVisitStartTimeUtc = const Value.absent(),
                Value<String?> nextVisitLocation = const Value.absent(),
                Value<bool> isBookmarked = const Value.absent(),
                Value<int?> rowVersion = const Value.absent(),
                Value<int?> beneficiaryRowVersion = const Value.absent(),
                Value<String?> availableActionsJson = const Value.absent(),
                Value<String?> detailsJson = const Value.absent(),
                Value<bool> hasFullDetails = const Value.absent(),
                Value<String> syncState = const Value.absent(),
                Value<DateTime?> serverUpdatedAt = const Value.absent(),
                Value<DateTime?> localUpdatedAt = const Value.absent(),
                required DateTime fetchedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedCasesCompanion.insert(
                id: id,
                caseNumber: caseNumber,
                displayId: displayId,
                status: status,
                priority: priority,
                beneficiaryFullName: beneficiaryFullName,
                nationalId: nationalId,
                charityId: charityId,
                registrationDate: registrationDate,
                completionPercentage: completionPercentage,
                nextVisitDate: nextVisitDate,
                nextVisitStartTimeUtc: nextVisitStartTimeUtc,
                nextVisitLocation: nextVisitLocation,
                isBookmarked: isBookmarked,
                rowVersion: rowVersion,
                beneficiaryRowVersion: beneficiaryRowVersion,
                availableActionsJson: availableActionsJson,
                detailsJson: detailsJson,
                hasFullDetails: hasFullDetails,
                syncState: syncState,
                serverUpdatedAt: serverUpdatedAt,
                localUpdatedAt: localUpdatedAt,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedCasesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedCasesTable,
      CachedCaseRow,
      $$CachedCasesTableFilterComposer,
      $$CachedCasesTableOrderingComposer,
      $$CachedCasesTableAnnotationComposer,
      $$CachedCasesTableCreateCompanionBuilder,
      $$CachedCasesTableUpdateCompanionBuilder,
      (
        CachedCaseRow,
        BaseReferences<_$AppDatabase, $CachedCasesTable, CachedCaseRow>,
      ),
      CachedCaseRow,
      PrefetchHooks Function()
    >;
typedef $$CachedSectionsTableCreateCompanionBuilder =
    CachedSectionsCompanion Function({
      required String caseId,
      required String sectionKey,
      required String dataJson,
      Value<int?> rowVersion,
      Value<bool> isDirty,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$CachedSectionsTableUpdateCompanionBuilder =
    CachedSectionsCompanion Function({
      Value<String> caseId,
      Value<String> sectionKey,
      Value<String> dataJson,
      Value<int?> rowVersion,
      Value<bool> isDirty,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$CachedSectionsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedSectionsTable> {
  $$CachedSectionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get caseId => $composableBuilder(
    column: $table.caseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sectionKey => $composableBuilder(
    column: $table.sectionKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dataJson => $composableBuilder(
    column: $table.dataJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rowVersion => $composableBuilder(
    column: $table.rowVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedSectionsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedSectionsTable> {
  $$CachedSectionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get caseId => $composableBuilder(
    column: $table.caseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sectionKey => $composableBuilder(
    column: $table.sectionKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dataJson => $composableBuilder(
    column: $table.dataJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rowVersion => $composableBuilder(
    column: $table.rowVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedSectionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedSectionsTable> {
  $$CachedSectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get caseId =>
      $composableBuilder(column: $table.caseId, builder: (column) => column);

  GeneratedColumn<String> get sectionKey => $composableBuilder(
    column: $table.sectionKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dataJson =>
      $composableBuilder(column: $table.dataJson, builder: (column) => column);

  GeneratedColumn<int> get rowVersion => $composableBuilder(
    column: $table.rowVersion,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDirty =>
      $composableBuilder(column: $table.isDirty, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CachedSectionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedSectionsTable,
          CachedSectionRow,
          $$CachedSectionsTableFilterComposer,
          $$CachedSectionsTableOrderingComposer,
          $$CachedSectionsTableAnnotationComposer,
          $$CachedSectionsTableCreateCompanionBuilder,
          $$CachedSectionsTableUpdateCompanionBuilder,
          (
            CachedSectionRow,
            BaseReferences<
              _$AppDatabase,
              $CachedSectionsTable,
              CachedSectionRow
            >,
          ),
          CachedSectionRow,
          PrefetchHooks Function()
        > {
  $$CachedSectionsTableTableManager(
    _$AppDatabase db,
    $CachedSectionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedSectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedSectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedSectionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> caseId = const Value.absent(),
                Value<String> sectionKey = const Value.absent(),
                Value<String> dataJson = const Value.absent(),
                Value<int?> rowVersion = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedSectionsCompanion(
                caseId: caseId,
                sectionKey: sectionKey,
                dataJson: dataJson,
                rowVersion: rowVersion,
                isDirty: isDirty,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String caseId,
                required String sectionKey,
                required String dataJson,
                Value<int?> rowVersion = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedSectionsCompanion.insert(
                caseId: caseId,
                sectionKey: sectionKey,
                dataJson: dataJson,
                rowVersion: rowVersion,
                isDirty: isDirty,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedSectionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedSectionsTable,
      CachedSectionRow,
      $$CachedSectionsTableFilterComposer,
      $$CachedSectionsTableOrderingComposer,
      $$CachedSectionsTableAnnotationComposer,
      $$CachedSectionsTableCreateCompanionBuilder,
      $$CachedSectionsTableUpdateCompanionBuilder,
      (
        CachedSectionRow,
        BaseReferences<_$AppDatabase, $CachedSectionsTable, CachedSectionRow>,
      ),
      CachedSectionRow,
      PrefetchHooks Function()
    >;
typedef $$LocalFieldVisitsTableCreateCompanionBuilder =
    LocalFieldVisitsCompanion Function({
      required String id,
      Value<String?> serverId,
      required String caseId,
      required String dedupId,
      required String visitDate,
      Value<DateTime?> startTimeUtc,
      Value<DateTime?> endTimeUtc,
      Value<double?> latitude,
      Value<double?> longitude,
      Value<String?> locationDescription,
      required String outcome,
      Value<String?> visitStatus,
      Value<String?> notes,
      Value<String?> description,
      Value<String> localAttachmentIdsJson,
      Value<int?> rowVersion,
      Value<String> syncState,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$LocalFieldVisitsTableUpdateCompanionBuilder =
    LocalFieldVisitsCompanion Function({
      Value<String> id,
      Value<String?> serverId,
      Value<String> caseId,
      Value<String> dedupId,
      Value<String> visitDate,
      Value<DateTime?> startTimeUtc,
      Value<DateTime?> endTimeUtc,
      Value<double?> latitude,
      Value<double?> longitude,
      Value<String?> locationDescription,
      Value<String> outcome,
      Value<String?> visitStatus,
      Value<String?> notes,
      Value<String?> description,
      Value<String> localAttachmentIdsJson,
      Value<int?> rowVersion,
      Value<String> syncState,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$LocalFieldVisitsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalFieldVisitsTable> {
  $$LocalFieldVisitsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get caseId => $composableBuilder(
    column: $table.caseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dedupId => $composableBuilder(
    column: $table.dedupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get visitDate => $composableBuilder(
    column: $table.visitDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startTimeUtc => $composableBuilder(
    column: $table.startTimeUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endTimeUtc => $composableBuilder(
    column: $table.endTimeUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get locationDescription => $composableBuilder(
    column: $table.locationDescription,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get visitStatus => $composableBuilder(
    column: $table.visitStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localAttachmentIdsJson => $composableBuilder(
    column: $table.localAttachmentIdsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rowVersion => $composableBuilder(
    column: $table.rowVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalFieldVisitsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalFieldVisitsTable> {
  $$LocalFieldVisitsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get caseId => $composableBuilder(
    column: $table.caseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dedupId => $composableBuilder(
    column: $table.dedupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get visitDate => $composableBuilder(
    column: $table.visitDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startTimeUtc => $composableBuilder(
    column: $table.startTimeUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endTimeUtc => $composableBuilder(
    column: $table.endTimeUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get locationDescription => $composableBuilder(
    column: $table.locationDescription,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get visitStatus => $composableBuilder(
    column: $table.visitStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localAttachmentIdsJson => $composableBuilder(
    column: $table.localAttachmentIdsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rowVersion => $composableBuilder(
    column: $table.rowVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalFieldVisitsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalFieldVisitsTable> {
  $$LocalFieldVisitsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get caseId =>
      $composableBuilder(column: $table.caseId, builder: (column) => column);

  GeneratedColumn<String> get dedupId =>
      $composableBuilder(column: $table.dedupId, builder: (column) => column);

  GeneratedColumn<String> get visitDate =>
      $composableBuilder(column: $table.visitDate, builder: (column) => column);

  GeneratedColumn<DateTime> get startTimeUtc => $composableBuilder(
    column: $table.startTimeUtc,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get endTimeUtc => $composableBuilder(
    column: $table.endTimeUtc,
    builder: (column) => column,
  );

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<String> get locationDescription => $composableBuilder(
    column: $table.locationDescription,
    builder: (column) => column,
  );

  GeneratedColumn<String> get outcome =>
      $composableBuilder(column: $table.outcome, builder: (column) => column);

  GeneratedColumn<String> get visitStatus => $composableBuilder(
    column: $table.visitStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localAttachmentIdsJson => $composableBuilder(
    column: $table.localAttachmentIdsJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rowVersion => $composableBuilder(
    column: $table.rowVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalFieldVisitsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalFieldVisitsTable,
          FieldVisitRow,
          $$LocalFieldVisitsTableFilterComposer,
          $$LocalFieldVisitsTableOrderingComposer,
          $$LocalFieldVisitsTableAnnotationComposer,
          $$LocalFieldVisitsTableCreateCompanionBuilder,
          $$LocalFieldVisitsTableUpdateCompanionBuilder,
          (
            FieldVisitRow,
            BaseReferences<
              _$AppDatabase,
              $LocalFieldVisitsTable,
              FieldVisitRow
            >,
          ),
          FieldVisitRow,
          PrefetchHooks Function()
        > {
  $$LocalFieldVisitsTableTableManager(
    _$AppDatabase db,
    $LocalFieldVisitsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalFieldVisitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalFieldVisitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalFieldVisitsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                Value<String> caseId = const Value.absent(),
                Value<String> dedupId = const Value.absent(),
                Value<String> visitDate = const Value.absent(),
                Value<DateTime?> startTimeUtc = const Value.absent(),
                Value<DateTime?> endTimeUtc = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<String?> locationDescription = const Value.absent(),
                Value<String> outcome = const Value.absent(),
                Value<String?> visitStatus = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> localAttachmentIdsJson = const Value.absent(),
                Value<int?> rowVersion = const Value.absent(),
                Value<String> syncState = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalFieldVisitsCompanion(
                id: id,
                serverId: serverId,
                caseId: caseId,
                dedupId: dedupId,
                visitDate: visitDate,
                startTimeUtc: startTimeUtc,
                endTimeUtc: endTimeUtc,
                latitude: latitude,
                longitude: longitude,
                locationDescription: locationDescription,
                outcome: outcome,
                visitStatus: visitStatus,
                notes: notes,
                description: description,
                localAttachmentIdsJson: localAttachmentIdsJson,
                rowVersion: rowVersion,
                syncState: syncState,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> serverId = const Value.absent(),
                required String caseId,
                required String dedupId,
                required String visitDate,
                Value<DateTime?> startTimeUtc = const Value.absent(),
                Value<DateTime?> endTimeUtc = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<String?> locationDescription = const Value.absent(),
                required String outcome,
                Value<String?> visitStatus = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> localAttachmentIdsJson = const Value.absent(),
                Value<int?> rowVersion = const Value.absent(),
                Value<String> syncState = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalFieldVisitsCompanion.insert(
                id: id,
                serverId: serverId,
                caseId: caseId,
                dedupId: dedupId,
                visitDate: visitDate,
                startTimeUtc: startTimeUtc,
                endTimeUtc: endTimeUtc,
                latitude: latitude,
                longitude: longitude,
                locationDescription: locationDescription,
                outcome: outcome,
                visitStatus: visitStatus,
                notes: notes,
                description: description,
                localAttachmentIdsJson: localAttachmentIdsJson,
                rowVersion: rowVersion,
                syncState: syncState,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalFieldVisitsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalFieldVisitsTable,
      FieldVisitRow,
      $$LocalFieldVisitsTableFilterComposer,
      $$LocalFieldVisitsTableOrderingComposer,
      $$LocalFieldVisitsTableAnnotationComposer,
      $$LocalFieldVisitsTableCreateCompanionBuilder,
      $$LocalFieldVisitsTableUpdateCompanionBuilder,
      (
        FieldVisitRow,
        BaseReferences<_$AppDatabase, $LocalFieldVisitsTable, FieldVisitRow>,
      ),
      FieldVisitRow,
      PrefetchHooks Function()
    >;
typedef $$PendingAttachmentsTableCreateCompanionBuilder =
    PendingAttachmentsCompanion Function({
      required String id,
      required String caseId,
      Value<String?> attachmentId,
      required String localPath,
      required String fileName,
      required String mimeType,
      required int fileSize,
      required String documentType,
      Value<String?> description,
      Value<String?> checksum,
      Value<String> uploadStage,
      Value<String?> uploadUrl,
      Value<DateTime?> uploadUrlExpiresAt,
      Value<double> progress,
      Value<int> attempts,
      Value<String?> lastErrorMessage,
      Value<String?> fieldVisitLocalId,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$PendingAttachmentsTableUpdateCompanionBuilder =
    PendingAttachmentsCompanion Function({
      Value<String> id,
      Value<String> caseId,
      Value<String?> attachmentId,
      Value<String> localPath,
      Value<String> fileName,
      Value<String> mimeType,
      Value<int> fileSize,
      Value<String> documentType,
      Value<String?> description,
      Value<String?> checksum,
      Value<String> uploadStage,
      Value<String?> uploadUrl,
      Value<DateTime?> uploadUrlExpiresAt,
      Value<double> progress,
      Value<int> attempts,
      Value<String?> lastErrorMessage,
      Value<String?> fieldVisitLocalId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$PendingAttachmentsTableFilterComposer
    extends Composer<_$AppDatabase, $PendingAttachmentsTable> {
  $$PendingAttachmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get caseId => $composableBuilder(
    column: $table.caseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get attachmentId => $composableBuilder(
    column: $table.attachmentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get documentType => $composableBuilder(
    column: $table.documentType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get checksum => $composableBuilder(
    column: $table.checksum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uploadStage => $composableBuilder(
    column: $table.uploadStage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uploadUrl => $composableBuilder(
    column: $table.uploadUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get uploadUrlExpiresAt => $composableBuilder(
    column: $table.uploadUrlExpiresAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastErrorMessage => $composableBuilder(
    column: $table.lastErrorMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fieldVisitLocalId => $composableBuilder(
    column: $table.fieldVisitLocalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingAttachmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingAttachmentsTable> {
  $$PendingAttachmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get caseId => $composableBuilder(
    column: $table.caseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attachmentId => $composableBuilder(
    column: $table.attachmentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get documentType => $composableBuilder(
    column: $table.documentType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get checksum => $composableBuilder(
    column: $table.checksum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uploadStage => $composableBuilder(
    column: $table.uploadStage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uploadUrl => $composableBuilder(
    column: $table.uploadUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get uploadUrlExpiresAt => $composableBuilder(
    column: $table.uploadUrlExpiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastErrorMessage => $composableBuilder(
    column: $table.lastErrorMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fieldVisitLocalId => $composableBuilder(
    column: $table.fieldVisitLocalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingAttachmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingAttachmentsTable> {
  $$PendingAttachmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get caseId =>
      $composableBuilder(column: $table.caseId, builder: (column) => column);

  GeneratedColumn<String> get attachmentId => $composableBuilder(
    column: $table.attachmentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<int> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);

  GeneratedColumn<String> get documentType => $composableBuilder(
    column: $table.documentType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get checksum =>
      $composableBuilder(column: $table.checksum, builder: (column) => column);

  GeneratedColumn<String> get uploadStage => $composableBuilder(
    column: $table.uploadStage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get uploadUrl =>
      $composableBuilder(column: $table.uploadUrl, builder: (column) => column);

  GeneratedColumn<DateTime> get uploadUrlExpiresAt => $composableBuilder(
    column: $table.uploadUrlExpiresAt,
    builder: (column) => column,
  );

  GeneratedColumn<double> get progress =>
      $composableBuilder(column: $table.progress, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<String> get lastErrorMessage => $composableBuilder(
    column: $table.lastErrorMessage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fieldVisitLocalId => $composableBuilder(
    column: $table.fieldVisitLocalId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PendingAttachmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingAttachmentsTable,
          PendingAttachmentRow,
          $$PendingAttachmentsTableFilterComposer,
          $$PendingAttachmentsTableOrderingComposer,
          $$PendingAttachmentsTableAnnotationComposer,
          $$PendingAttachmentsTableCreateCompanionBuilder,
          $$PendingAttachmentsTableUpdateCompanionBuilder,
          (
            PendingAttachmentRow,
            BaseReferences<
              _$AppDatabase,
              $PendingAttachmentsTable,
              PendingAttachmentRow
            >,
          ),
          PendingAttachmentRow,
          PrefetchHooks Function()
        > {
  $$PendingAttachmentsTableTableManager(
    _$AppDatabase db,
    $PendingAttachmentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingAttachmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingAttachmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingAttachmentsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> caseId = const Value.absent(),
                Value<String?> attachmentId = const Value.absent(),
                Value<String> localPath = const Value.absent(),
                Value<String> fileName = const Value.absent(),
                Value<String> mimeType = const Value.absent(),
                Value<int> fileSize = const Value.absent(),
                Value<String> documentType = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> checksum = const Value.absent(),
                Value<String> uploadStage = const Value.absent(),
                Value<String?> uploadUrl = const Value.absent(),
                Value<DateTime?> uploadUrlExpiresAt = const Value.absent(),
                Value<double> progress = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastErrorMessage = const Value.absent(),
                Value<String?> fieldVisitLocalId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingAttachmentsCompanion(
                id: id,
                caseId: caseId,
                attachmentId: attachmentId,
                localPath: localPath,
                fileName: fileName,
                mimeType: mimeType,
                fileSize: fileSize,
                documentType: documentType,
                description: description,
                checksum: checksum,
                uploadStage: uploadStage,
                uploadUrl: uploadUrl,
                uploadUrlExpiresAt: uploadUrlExpiresAt,
                progress: progress,
                attempts: attempts,
                lastErrorMessage: lastErrorMessage,
                fieldVisitLocalId: fieldVisitLocalId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String caseId,
                Value<String?> attachmentId = const Value.absent(),
                required String localPath,
                required String fileName,
                required String mimeType,
                required int fileSize,
                required String documentType,
                Value<String?> description = const Value.absent(),
                Value<String?> checksum = const Value.absent(),
                Value<String> uploadStage = const Value.absent(),
                Value<String?> uploadUrl = const Value.absent(),
                Value<DateTime?> uploadUrlExpiresAt = const Value.absent(),
                Value<double> progress = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastErrorMessage = const Value.absent(),
                Value<String?> fieldVisitLocalId = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => PendingAttachmentsCompanion.insert(
                id: id,
                caseId: caseId,
                attachmentId: attachmentId,
                localPath: localPath,
                fileName: fileName,
                mimeType: mimeType,
                fileSize: fileSize,
                documentType: documentType,
                description: description,
                checksum: checksum,
                uploadStage: uploadStage,
                uploadUrl: uploadUrl,
                uploadUrlExpiresAt: uploadUrlExpiresAt,
                progress: progress,
                attempts: attempts,
                lastErrorMessage: lastErrorMessage,
                fieldVisitLocalId: fieldVisitLocalId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingAttachmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingAttachmentsTable,
      PendingAttachmentRow,
      $$PendingAttachmentsTableFilterComposer,
      $$PendingAttachmentsTableOrderingComposer,
      $$PendingAttachmentsTableAnnotationComposer,
      $$PendingAttachmentsTableCreateCompanionBuilder,
      $$PendingAttachmentsTableUpdateCompanionBuilder,
      (
        PendingAttachmentRow,
        BaseReferences<
          _$AppDatabase,
          $PendingAttachmentsTable,
          PendingAttachmentRow
        >,
      ),
      PendingAttachmentRow,
      PrefetchHooks Function()
    >;
typedef $$DropdownCacheTableCreateCompanionBuilder =
    DropdownCacheCompanion Function({
      required String key,
      required String valuesJson,
      required DateTime fetchedAt,
      Value<int> rowid,
    });
typedef $$DropdownCacheTableUpdateCompanionBuilder =
    DropdownCacheCompanion Function({
      Value<String> key,
      Value<String> valuesJson,
      Value<DateTime> fetchedAt,
      Value<int> rowid,
    });

class $$DropdownCacheTableFilterComposer
    extends Composer<_$AppDatabase, $DropdownCacheTable> {
  $$DropdownCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get valuesJson => $composableBuilder(
    column: $table.valuesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DropdownCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $DropdownCacheTable> {
  $$DropdownCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get valuesJson => $composableBuilder(
    column: $table.valuesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DropdownCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $DropdownCacheTable> {
  $$DropdownCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get valuesJson => $composableBuilder(
    column: $table.valuesJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$DropdownCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DropdownCacheTable,
          DropdownCacheRow,
          $$DropdownCacheTableFilterComposer,
          $$DropdownCacheTableOrderingComposer,
          $$DropdownCacheTableAnnotationComposer,
          $$DropdownCacheTableCreateCompanionBuilder,
          $$DropdownCacheTableUpdateCompanionBuilder,
          (
            DropdownCacheRow,
            BaseReferences<
              _$AppDatabase,
              $DropdownCacheTable,
              DropdownCacheRow
            >,
          ),
          DropdownCacheRow,
          PrefetchHooks Function()
        > {
  $$DropdownCacheTableTableManager(_$AppDatabase db, $DropdownCacheTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DropdownCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DropdownCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DropdownCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> valuesJson = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DropdownCacheCompanion(
                key: key,
                valuesJson: valuesJson,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String valuesJson,
                required DateTime fetchedAt,
                Value<int> rowid = const Value.absent(),
              }) => DropdownCacheCompanion.insert(
                key: key,
                valuesJson: valuesJson,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DropdownCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DropdownCacheTable,
      DropdownCacheRow,
      $$DropdownCacheTableFilterComposer,
      $$DropdownCacheTableOrderingComposer,
      $$DropdownCacheTableAnnotationComposer,
      $$DropdownCacheTableCreateCompanionBuilder,
      $$DropdownCacheTableUpdateCompanionBuilder,
      (
        DropdownCacheRow,
        BaseReferences<_$AppDatabase, $DropdownCacheTable, DropdownCacheRow>,
      ),
      DropdownCacheRow,
      PrefetchHooks Function()
    >;
typedef $$CachedNotificationsTableCreateCompanionBuilder =
    CachedNotificationsCompanion Function({
      required String id,
      required String title,
      Value<String?> subtitle,
      Value<String?> icon,
      Value<bool> isRead,
      Value<String?> caseId,
      required DateTime createdAtUtc,
      Value<int> rowid,
    });
typedef $$CachedNotificationsTableUpdateCompanionBuilder =
    CachedNotificationsCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String?> subtitle,
      Value<String?> icon,
      Value<bool> isRead,
      Value<String?> caseId,
      Value<DateTime> createdAtUtc,
      Value<int> rowid,
    });

class $$CachedNotificationsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedNotificationsTable> {
  $$CachedNotificationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subtitle => $composableBuilder(
    column: $table.subtitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRead => $composableBuilder(
    column: $table.isRead,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get caseId => $composableBuilder(
    column: $table.caseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedNotificationsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedNotificationsTable> {
  $$CachedNotificationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subtitle => $composableBuilder(
    column: $table.subtitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRead => $composableBuilder(
    column: $table.isRead,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get caseId => $composableBuilder(
    column: $table.caseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedNotificationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedNotificationsTable> {
  $$CachedNotificationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get subtitle =>
      $composableBuilder(column: $table.subtitle, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<bool> get isRead =>
      $composableBuilder(column: $table.isRead, builder: (column) => column);

  GeneratedColumn<String> get caseId =>
      $composableBuilder(column: $table.caseId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => column,
  );
}

class $$CachedNotificationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedNotificationsTable,
          CachedNotificationRow,
          $$CachedNotificationsTableFilterComposer,
          $$CachedNotificationsTableOrderingComposer,
          $$CachedNotificationsTableAnnotationComposer,
          $$CachedNotificationsTableCreateCompanionBuilder,
          $$CachedNotificationsTableUpdateCompanionBuilder,
          (
            CachedNotificationRow,
            BaseReferences<
              _$AppDatabase,
              $CachedNotificationsTable,
              CachedNotificationRow
            >,
          ),
          CachedNotificationRow,
          PrefetchHooks Function()
        > {
  $$CachedNotificationsTableTableManager(
    _$AppDatabase db,
    $CachedNotificationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedNotificationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedNotificationsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CachedNotificationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> subtitle = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<bool> isRead = const Value.absent(),
                Value<String?> caseId = const Value.absent(),
                Value<DateTime> createdAtUtc = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedNotificationsCompanion(
                id: id,
                title: title,
                subtitle: subtitle,
                icon: icon,
                isRead: isRead,
                caseId: caseId,
                createdAtUtc: createdAtUtc,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                Value<String?> subtitle = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<bool> isRead = const Value.absent(),
                Value<String?> caseId = const Value.absent(),
                required DateTime createdAtUtc,
                Value<int> rowid = const Value.absent(),
              }) => CachedNotificationsCompanion.insert(
                id: id,
                title: title,
                subtitle: subtitle,
                icon: icon,
                isRead: isRead,
                caseId: caseId,
                createdAtUtc: createdAtUtc,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedNotificationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedNotificationsTable,
      CachedNotificationRow,
      $$CachedNotificationsTableFilterComposer,
      $$CachedNotificationsTableOrderingComposer,
      $$CachedNotificationsTableAnnotationComposer,
      $$CachedNotificationsTableCreateCompanionBuilder,
      $$CachedNotificationsTableUpdateCompanionBuilder,
      (
        CachedNotificationRow,
        BaseReferences<
          _$AppDatabase,
          $CachedNotificationsTable,
          CachedNotificationRow
        >,
      ),
      CachedNotificationRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SyncQueueTableTableManager get syncQueue =>
      $$SyncQueueTableTableManager(_db, _db.syncQueue);
  $$CachedCasesTableTableManager get cachedCases =>
      $$CachedCasesTableTableManager(_db, _db.cachedCases);
  $$CachedSectionsTableTableManager get cachedSections =>
      $$CachedSectionsTableTableManager(_db, _db.cachedSections);
  $$LocalFieldVisitsTableTableManager get localFieldVisits =>
      $$LocalFieldVisitsTableTableManager(_db, _db.localFieldVisits);
  $$PendingAttachmentsTableTableManager get pendingAttachments =>
      $$PendingAttachmentsTableTableManager(_db, _db.pendingAttachments);
  $$DropdownCacheTableTableManager get dropdownCache =>
      $$DropdownCacheTableTableManager(_db, _db.dropdownCache);
  $$CachedNotificationsTableTableManager get cachedNotifications =>
      $$CachedNotificationsTableTableManager(_db, _db.cachedNotifications);
}
