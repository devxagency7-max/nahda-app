// نموذج قابل للتعديل للحيازة الزراعية — تاب جديد، غير موصوف في وثائق
// المشروع الأصلية، يوثّق أي أرض/ماشية/إنتاج زراعي تملكه الأسرة كمصدر دخل
// أو أصل عيني (UNDEFINED / NEEDS BUSINESS DECISION لتفاصيل إضافية لاحقًا).

/// إجابة سؤال الحيازة: غير مُجاب عنه / نعم / لا.
///
/// كان `bool` بقيمة افتراضية `false`، وده خلّى القسم يحسب نفسه مكتملًا 100%
/// قبل ما المستخدم يفتح التاب أصلًا — مفيش فرق بين "الأسرة ماعندهاش أرض"
/// و"الأخصائي لسه ماجاوبش". التقسيم لثلاث حالات بيحل ده من جذره.
enum HoldingAnswer { unanswered, yes, no }

const _otherOption = 'أخرى';

class AgriculturalHoldingFormData {
  HoldingAnswer landAnswer;
  double? landAreaFeddan; // المساحة بالفدان
  String? landType; // تمليك / إيجار
  double? landRentAmount; // سعر الإيجار (إذا كانت إيجار)
  double? annualLandIncome; // الدخل السنوي للأرض (إذا كانت تمليك)
  String? cropType; // نوع الزراعة
  HoldingAnswer livestockAnswer;
  List<String> selectedLivestock; // الماشية والأصول الحيوانية
  String? livestockOther; // نص خيار "أخرى" في المواشي
  String? livestockDetails; // تفاصيل إضافية عن الماشية والدواجن
  String? notes;

  /// هل فتح المستخدم هذا التاب فعلًا؟ تاب لم يُزر بعد نسبته 0% مهما كانت
  /// القيم الافتراضية للحقول.
  bool visited;

  AgriculturalHoldingFormData({
    this.landAnswer = HoldingAnswer.unanswered,
    this.landAreaFeddan,
    this.landType,
    this.landRentAmount,
    this.annualLandIncome,
    this.cropType,
    this.livestockAnswer = HoldingAnswer.unanswered,
    List<String>? selectedLivestock,
    this.livestockOther,
    this.livestockDetails,
    this.notes,
    this.visited = false,
  }) : selectedLivestock = selectedLivestock ?? [];

  bool get hasLand => landAnswer == HoldingAnswer.yes;
  bool get hasLivestock => livestockAnswer == HoldingAnswer.yes;

  /// مسح الحقول التابعة لإجابة "لا" — عشان ما تفضلش قيم قديمة مخبّية
  /// تتحسب في الميزانية بعد ما المستخدم يرجع في كلامه.
  void clearLandDetailsIfDenied() {
    if (landAnswer == HoldingAnswer.yes) return;
    landType = null;
    landAreaFeddan = null;
    landRentAmount = null;
    annualLandIncome = null;
    cropType = null;
  }

  void clearLivestockDetailsIfDenied() {
    if (livestockAnswer == HoldingAnswer.yes) return;
    selectedLivestock.clear();
    livestockOther = null;
    livestockDetails = null;
  }

  /// مسح الحقل غير المناسب عند تغيير نوع الحيازة (إيجار ↔ تمليك).
  void clearIrrelevantTenureField() {
    if (landType != 'إيجار') landRentAmount = null;
    if (landType != 'تمليك') annualLandIncome = null;
  }

  bool get _landComplete {
    if (landAnswer == HoldingAnswer.no) return true;
    if (landAnswer == HoldingAnswer.unanswered) return false;
    return landAreaFeddan != null &&
        landAreaFeddan! >= 0 &&
        (landType ?? '').trim().isNotEmpty;
  }

  bool get _livestockComplete {
    if (livestockAnswer == HoldingAnswer.no) return true;
    if (livestockAnswer == HoldingAnswer.unanswered) return false;
    if (selectedLivestock.isEmpty) return false;
    // لو "أخرى" مختارة لازم نصها يتكتب، وإلا البيانات ناقصة.
    if (selectedLivestock.contains(_otherOption) &&
        (livestockOther ?? '').trim().isEmpty) {
      return false;
    }
    return true;
  }

  /// مكتمل لو تم تحديد موقف الحيازة الزراعية ولو بالنفي (لا يوجد أرض ولا
  /// ماشية) — هذا يعتبر إجابة صريحة وليس نقصًا في البيانات. أما عدم
  /// الإجابة أصلًا فيُحسب نقصًا.
  double get progress {
    if (!visited) return 0;
    int filled = 0;
    if (_landComplete) filled++;
    if (_livestockComplete) filled++;
    return filled / 2;
  }

  /// رسائل النقص المعروضة للمستخدم قبل مغادرة التاب.
  List<String> get missingFields {
    final missing = <String>[];

    if (landAnswer == HoldingAnswer.unanswered) {
      missing.add('جاوب على سؤال الأرض الزراعية (نعم / لا)');
    } else if (landAnswer == HoldingAnswer.yes) {
      if ((landType ?? '').trim().isEmpty) {
        missing.add('اختر طبيعة حيازة الأرض (تمليك / إيجار)');
      }
      if (landAreaFeddan == null) {
        missing.add('أدخل مساحة الأرض بالفدان');
      } else if (landAreaFeddan! < 0) {
        missing.add('مساحة الأرض لا يمكن أن تكون قيمة سالبة');
      }
      if (landRentAmount != null && landRentAmount! < 0) {
        missing.add('قيمة الإيجار لا يمكن أن تكون سالبة');
      }
      if (annualLandIncome != null && annualLandIncome! < 0) {
        missing.add('الدخل السنوي لا يمكن أن يكون قيمة سالبة');
      }
    }

    if (livestockAnswer == HoldingAnswer.unanswered) {
      missing.add('جاوب على سؤال المواشي (نعم / لا)');
    } else if (livestockAnswer == HoldingAnswer.yes) {
      if (selectedLivestock.isEmpty) {
        missing.add('اختر نوعًا واحدًا على الأقل من المواشي');
      } else if (selectedLivestock.contains(_otherOption) &&
          (livestockOther ?? '').trim().isEmpty) {
        missing.add('اكتب تفاصيل خيار "أخرى" في المواشي');
      }
    }

    return missing;
  }

  bool get isComplete => missingFields.isEmpty;
}
