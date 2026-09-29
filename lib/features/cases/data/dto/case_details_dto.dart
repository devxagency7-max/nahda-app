import '../../domain/case_status.dart';

/// تفاصيل الحالة — استجابة `GET /cases/{id}` (§19).
class CaseDetailsDto {
  const CaseDetailsDto({
    required this.id,
    required this.caseNumber,
    required this.displayId,
    required this.status,
    required this.priority,
    this.charityId,
    this.registrationDate,
    this.createdAtUtc,
    this.updatedAtUtc,
    required this.rowVersion,
    required this.beneficiary,
    required this.completionPercentage,
    required this.isReady,
    required this.availableActions,
    this.returnInfo,
  });

  final String id;
  final String caseNumber;
  final String displayId;
  final CaseStatus status;
  final CasePriorityWire priority;
  final String? charityId;
  final String? registrationDate;
  final DateTime? createdAtUtc;
  final DateTime? updatedAtUtc;

  /// نسخة صفّ **الحالة**.
  ///
  /// تُرسَل كـ `caseRowVersion` في أقسام القوائم وإجراءات سير العمل.
  /// **ليست** نسخة المستفيد — عدّادان مستقلان على صفّين مختلفين (§19).
  final int? rowVersion;

  final BeneficiaryDto beneficiary;

  final double completionPercentage;

  /// `true` فقط حين تكتمل **كل** الأقسام التسعة.
  ///
  /// بوابة إرسال الرأي تعتمد عليها، لكن **الخادم هو الحكم** — لا يُقلَّد الحساب
  /// محليًا ولا يُعطَّل الزر بناءً عليها وحدها (§20.4).
  final bool isReady;

  /// تلميح UX لا تفويض (§15.7).
  final List<WorkflowAction> availableActions;

  /// **بانتظار الباك إند** (§7، طلب 1).
  final ReturnInfoDto? returnInfo;

  bool canPerform(WorkflowAction action) => availableActions.contains(action);

  static CaseDetailsDto fromJson(Object? data) {
    final json = data is Map<String, dynamic> ? data : const <String, dynamic>{};

    final rawActions = (json['workflow'] as Map<String, dynamic>?)
        ?.let((w) => w['availableActions']);

    return CaseDetailsDto(
      id: json['id'] as String? ?? '',
      caseNumber: json['caseNumber'] as String? ?? '',
      displayId: json['displayId'] as String? ?? '',
      status: CaseStatus.fromWire(json['status'] as String?),
      priority: CasePriorityWire.fromWire(json['priority'] as String?),
      charityId: json['charityId'] as String?,
      registrationDate: json['registrationDate'] as String?,
      createdAtUtc: _date(json['createdAtUtc']),
      updatedAtUtc: _date(json['updatedAtUtc']),
      rowVersion: _int(json['rowVersion']),
      beneficiary: BeneficiaryDto.fromJson(json['beneficiary']),
      completionPercentage: _double(
        (json['completion'] as Map<String, dynamic>?)?['percentage'],
      ),
      isReady: (json['completion'] as Map<String, dynamic>?)?['isReady'] == true,
      availableActions: rawActions is List
          ? rawActions
                .whereType<String>()
                .map(WorkflowAction.fromWire)
                .where((a) => a != WorkflowAction.unknown)
                .toList(growable: false)
          : const [],
      returnInfo: ReturnInfoDto.fromJson(json['returnInfo']),
    );
  }

  static int? _int(Object? v) => switch (v) {
    final int i => i,
    final num n => n.toInt(),
    _ => null,
  };

  static double _double(Object? v) => switch (v) {
    final num n => n.toDouble(),
    _ => 0,
  };

  static DateTime? _date(Object? v) =>
      v is String ? DateTime.tryParse(v)?.toUtc() : null;
}

/// بيانات المستفيد.
class BeneficiaryDto {
  const BeneficiaryDto({
    required this.fullName,
    this.nationalId,
    this.age,
    this.gender,
    this.birthGovernorate,
    this.phonePrimary,
    this.phoneSecondary,
    this.address,
    this.centerId,
    this.villageId,
    required this.rowVersion,
    this.religion,
    this.education,
    this.maritalStatus,
    this.healthStatus,
    this.employmentStatus,
    this.job,
    this.monthlyIncome,
    this.takafulBeneficiary,
    this.takafulAmount,
    this.headRelation,
  });

  final String fullName;
  final String? nationalId;

  /// `age` و `gender` و `birthGovernorate` **مشتقّة من الرقم القومي على الخادم**
  /// وغير قابلة للتعديل — لا وجود لها في أي طلب PUT (§19).
  final int? age;
  final String? gender;
  final String? birthGovernorate;

  final String? phonePrimary;
  final String? phoneSecondary;
  final String? address;
  final String? centerId;
  final String? villageId;

  /// نسخة صفّ **المستفيد** — تُرسَل في `PUT /beneficiary` وحدها.
  ///
  /// غير قابلة للـ null على الخادم لأن صفّ المستفيد يُنشأ مع الحالة ذرّيًا؛
  /// نجعلها nullable هنا فقط لتحمّل استجابة ناقصة دون انهيار.
  final int? rowVersion;

  // الحقول العشرة دي كانت ناقصة من رد GET /cases/{id} (بلّغنا الباك إند
  // بالمشكلة، واتصلحت وترفعت على الإنتاج — commit bcc9d61 بتاريخ 2026-09-25).
  // موجودة كلها في PUT /beneficiary من الأساس، لكن مكناش بنقراها من رد الـ
  // GET فكانت بتفضل فاضية في الفورم حتى لو متسجّلة فعليًا على السيرفر.
  final String? religion;
  final String? education;
  final String? maritalStatus;
  final String? healthStatus;
  final String? employmentStatus;
  final String? job;
  final double? monthlyIncome;
  final bool? takafulBeneficiary;
  final double? takafulAmount;
  final String? headRelation;

  static BeneficiaryDto fromJson(Object? data) {
    final json = data is Map<String, dynamic> ? data : const <String, dynamic>{};
    return BeneficiaryDto(
      fullName: json['fullName'] as String? ?? '',
      nationalId: json['nationalId'] as String?,
      age: CaseDetailsDto._int(json['age']),
      gender: json['gender'] as String?,
      birthGovernorate: json['birthGovernorate'] as String?,
      phonePrimary: json['phonePrimary'] as String?,
      phoneSecondary: json['phoneSecondary'] as String?,
      address: json['address'] as String?,
      centerId: json['centerId'] as String?,
      villageId: json['villageId'] as String?,
      rowVersion: CaseDetailsDto._int(json['rowVersion']),
      religion: json['religion'] as String?,
      education: json['education'] as String?,
      maritalStatus: json['maritalStatus'] as String?,
      healthStatus: json['healthStatus'] as String?,
      employmentStatus: json['employmentStatus'] as String?,
      job: json['job'] as String?,
      monthlyIncome: _nullableDouble(json['monthlyIncome']),
      takafulBeneficiary: json['takafulBeneficiary'] as bool?,
      takafulAmount: _nullableDouble(json['takafulAmount']),
      headRelation: json['headRelation'] as String?,
    );
  }

  /// زي `CaseDetailsDto._double` لكن بيحافظ على null بدل ما يحوّلها لصفر —
  /// مهم هنا لأن monthlyIncome/takafulAmount غير المسجّلة (null فعليًا على
  /// الخادم) لازم تفضل null، مش صفر (صفر معناها "الدخل صفر فعليًا" وده معنى مختلف تمامًا).
  static double? _nullableDouble(Object? v) => switch (v) {
    final num n => n.toDouble(),
    _ => null,
  };
}

/// معلومات الإرجاع — **مطلوبة من الباك إند، غير موجودة بعد** (§7، طلب 1).
class ReturnInfoDto {
  const ReturnInfoDto({
    required this.returnedBy,
    this.returnedByName,
    this.reason,
    this.returnedAtUtc,
  });

  final ReturnSource returnedBy;
  final String? returnedByName;
  final String? reason;
  final DateTime? returnedAtUtc;

  static ReturnInfoDto? fromJson(Object? data) {
    if (data is! Map<String, dynamic>) return null;
    return ReturnInfoDto(
      returnedBy: ReturnSource.fromWire(data['returnedBy'] as String?),
      returnedByName: data['returnedByName'] as String?,
      reason: data['reason'] as String?,
      returnedAtUtc: CaseDetailsDto._date(data['returnedAtUtc']),
    );
  }
}

/// نسبة الإكمال لكل قسم — استجابة `GET /cases/{id}/completion`.
class CaseCompletionDto {
  const CaseCompletionDto({
    required this.sections,
    required this.overallPercentage,
    required this.isReady,
  });

  /// مفتاح القسم ← نسبته. **ثنائية**: 0 أو 100، لا أوزان لكل حقل.
  final Map<String, double> sections;

  final double overallPercentage;
  final bool isReady;

  /// الأقسام التسعة المحسوبة — بهذا الترتيب (§19).
  static const sectionKeys = [
    'beneficiary',
    'family_members',
    'housing',
    'utilities',
    'agriculture',
    'financial',
    'initial_needs',
    'classification',
    'assessed_needs',
  ];

  static const sectionLabels = {
    'beneficiary': 'بيانات المستفيد',
    'family_members': 'أفراد الأسرة',
    'housing': 'السكن',
    'utilities': 'المرافق والأجهزة',
    'agriculture': 'الحيازة الزراعية',
    'financial': 'الدخل والمصروفات',
    'initial_needs': 'الاحتياج الأولي',
    'classification': 'التصنيف الاجتماعي',
    'assessed_needs': 'الاحتياجات المُقيَّمة',
  };

  /// الأقسام الناقصة — لعرضها في نافذة "لا يمكن الإرسال".
  List<String> get incompleteSections => sectionKeys
      .where((key) => (sections[key] ?? 0) < 100)
      .map((key) => sectionLabels[key] ?? key)
      .toList(growable: false);

  static CaseCompletionDto fromJson(Object? data) {
    final json = data is Map<String, dynamic> ? data : const <String, dynamic>{};
    final rawSections = json['sections'];

    final map = <String, double>{};
    if (rawSections is List) {
      for (final item in rawSections.whereType<Map<String, dynamic>>()) {
        final key = item['key'];
        if (key is String) {
          map[key] = CaseDetailsDto._double(item['percentage']);
        }
      }
    }

    return CaseCompletionDto(
      sections: map,
      overallPercentage: CaseDetailsDto._double(json['overallPercentage']),
      isReady: json['isReady'] == true,
    );
  }
}

extension _Let<T> on T {
  R let<R>(R Function(T) transform) => transform(this);
}
