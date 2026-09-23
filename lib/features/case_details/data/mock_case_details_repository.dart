import '../domain/case_details_repository.dart';
import '../domain/case_full_details.dart';
import '../domain/data_source.dart';
import '../domain/sections/assessment_opinion_section.dart';
import '../domain/sections/attachments_section.dart';
import '../domain/sections/basic_info_section.dart';
import '../domain/sections/classification_needs_section.dart';
import '../domain/sections/family_section.dart';
import '../domain/sections/financial_section.dart';
import '../domain/sections/housing_section.dart';
import '../domain/sections/initial_need_section.dart';
import '../domain/sections/support_section.dart';
import '../domain/sections/timeline_section.dart';
import '../domain/sections/utilities_equipment_section.dart';
import '../domain/sections/visit_verification_section.dart';

/// Mock Data Source — يحاكي GET /api/v1/cases/{caseId}.
/// حالة #1024 مبنية بكل الأقسام كمرجع كامل؛ باقي الحالات تُبنى بحسب
/// مرحلتها الفعلية في الـ Workflow (بعض الأقسام null قبل وصول الحالة لها).
class MockCaseDetailsRepository implements CaseDetailsRepository {
  @override
  Future<CaseFullDetails> getCaseDetails(String caseId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final now = DateTime.now();

    if (caseId == 'case_1024') {
      return CaseFullDetails(
        basicInfo: BasicInfoSection(
          caseId: caseId,
          caseNumber: '#1024',
          createdAt: now.subtract(const Duration(days: 6)),
          statusLabel: 'قيد البحث الاجتماعي',
          priorityLabel: 'عاجلة',
          lastUpdatedAt: now.subtract(const Duration(hours: 2)),
          fullName: FieldValue(
            value: 'أحمد محمد السيد',
            source: DataSource.dataEntry,
            at: now.subtract(const Duration(days: 6)),
          ),
          nationalId: FieldValue(
            value: '29001011234567',
            source: DataSource.dataEntry,
            at: now.subtract(const Duration(days: 6)),
          ),
          gender: 'ذكر',
          birthDate: DateTime(1990, 1, 1),
          age: now.year - 1990,
          maritalStatus: 'متزوج',
          educationLevel: 'إعدادية',
          occupation: 'عامل يومية',
          employer: null,
          phone: FieldValue(
            value: '01000000000',
            source: DataSource.dataEntry,
            at: now.subtract(const Duration(days: 6)),
          ),
          alternatePhone: null,
          governorate: 'بني سويف',
          district: 'بني سويف',
          village: 'قرية بني عدي',
          area: null,
          addressDescription: 'بجوار مسجد القرية',
        ),
        family: FamilySection(
          familyMembersCount: 5,
          members: [
            const FamilyMember(
              name: 'منى أحمد',
              relationship: 'زوجة',
              gender: 'أنثى',
              age: 32,
              maritalStatus: 'متزوجة',
              occupation: 'ربة منزل',
              income: 0,
              livesWithFamily: true,
            ),
            const FamilyMember(
              name: 'سارة أحمد',
              relationship: 'ابنة',
              gender: 'أنثى',
              age: 9,
              educationLevel: 'ابتدائي',
              livesWithFamily: true,
            ),
            const FamilyMember(
              name: 'يوسف أحمد',
              relationship: 'ابن',
              gender: 'ذكر',
              age: 6,
              educationLevel: 'ابتدائي',
              livesWithFamily: true,
            ),
          ],
          householdHead: 'أحمد محمد السيد',
          dependentsCount: 4,
          childrenCount: 2,
          adultsCount: 2,
          elderlyCount: 0,
          workingMembersCount: 1,
          nonWorkingMembersCount: 4,
        ),
        initialNeed: const InitialNeedSection(
          needType: 'دعم مالي',
          description: 'الأسرة تعاني من دخل غير ثابت وحالة مرضية لرب الأسرة',
          priorityLevel: 'عالية',
        ),
        attachments: [
          CaseAttachment(
            id: 'att_1',
            documentType: 'بطاقة شخصية',
            fileName: 'national_id_scan.jpg',
            uploadedAt: now.subtract(const Duration(days: 6)),
            uploadedBy: DataSource.dataEntry,
            status: 'مرفوع',
          ),
          CaseAttachment(
            id: 'att_2',
            documentType: 'صور السكن',
            fileName: 'housing_1.jpg',
            uploadedAt: now.subtract(const Duration(hours: 3)),
            uploadedBy: DataSource.socialWorker,
            status: 'مرفوع',
            visitId: 'visit_1024_1',
          ),
        ],
        fieldVisit: FieldVisitSection(
          visitDate: now.subtract(const Duration(hours: 3)),
          startTime: now.subtract(const Duration(hours: 3)),
          endTime: now.subtract(const Duration(hours: 2, minutes: 20)),
          location: 'قرية بني عدي — بني سويف',
          outcome: 'تمت الزيارة والتحقق من البيانات',
          status: 'مكتملة',
          description: 'تم الاطمئنان على الأسرة وتوثيق حالة السكن والدخل',
          photos: const ['housing_1.jpg'],
        ),
        fieldVerification: const FieldVerificationSection(
          verifiedFields: ['الاسم', 'العنوان', 'عدد أفراد الأسرة'],
          unverifiedFields: ['المستوى التعليمي للزوجة'],
          differences: [
            VerifiedFieldDiff(
              fieldLabel: 'الدخل الشهري',
              originalValue: '3000 جنيه',
              verifiedValue: '2500 جنيه',
              differenceReason: 'دخل غير منتظم حسب تصريح الأسرة وقت الزيارة',
              isDifferent: true,
            ),
          ],
          socialWorkerNotes: 'الأسرة متعاونة، البيانات الأساسية مطابقة للواقع',
          verificationStatus: 'تم التحقق جزئيًا',
        ),
        housing: const HousingSection(
          housingType: 'سكن مستقل',
          ownershipStatus: 'إيجار',
          roomsCount: 2,
          housingCondition: 'متوسطة',
          wallsCondition: 'متوسطة',
          roofType: 'خرسانة',
          roofCondition: 'جيدة',
          floorsType: 'أسمنت',
          bathroomsCount: 1,
          bathroomCondition: 'متوسطة',
          housingLevel: 'محدود',
          description: 'مسكن من غرفتين بحالة متوسطة، يحتاج بعض الصيانة',
          photos: ['housing_1.jpg'],
        ),
        utilitiesEquipment: const UtilitiesEquipmentSection(
          utilities: [
            UtilityItem(
              name: 'كهرباء',
              isAvailable: true,
              condition: 'جيدة',
              sourceOrMeter: 'عداد كهرباء',
            ),
            UtilityItem(
              name: 'مياه',
              isAvailable: true,
              condition: 'جيدة',
              sourceOrMeter: 'شبكة عامة',
            ),
            UtilityItem(
              name: 'غاز',
              isAvailable: false,
              sourceOrMeter: 'أنبوبة بوتاجاز',
            ),
            UtilityItem(
              name: 'الصرف الصحي',
              isAvailable: true,
              condition: 'متوسطة',
            ),
          ],
          equipment: [
            EquipmentItem(
              name: 'ثلاجة',
              category: 'أجهزة منزلية',
              isPresent: true,
              count: 1,
              isUsable: true,
            ),
            EquipmentItem(
              name: 'غسالة',
              category: 'أجهزة منزلية',
              isPresent: false,
            ),
            EquipmentItem(
              name: 'تلفاز',
              category: 'أجهزة كهربائية',
              isPresent: true,
              count: 1,
              isUsable: true,
            ),
            EquipmentItem(
              name: 'بوتاجاز',
              category: 'أجهزة طبخ',
              isPresent: true,
              count: 1,
              isUsable: true,
            ),
          ],
        ),
        financialSummary: const FinancialSummarySection(
          incomeItems: [
            IncomeItem(
              personName: 'أحمد محمد السيد',
              sourceType: 'عمل حر',
              incomeType: 'دخل غير منتظم',
              amount: 2500,
              frequency: 'شهري',
              monthlyAmount: 2500,
              verificationStatus: 'تم التحقق ميدانيًا',
            ),
          ],
          expenseItems: [
            ExpenseItem(
              expenseType: 'إيجار',
              amount: 700,
              frequency: 'شهري',
              monthlyAmount: 700,
              verificationStatus: 'تم التحقق',
            ),
            ExpenseItem(
              expenseType: 'علاج',
              amount: 400,
              frequency: 'شهري',
              monthlyAmount: 400,
              verificationStatus: 'تم التحقق',
            ),
          ],
          totalMonthlyIncome: 2500,
          totalMonthlyExpenses: 1100,
          netIncome: 1400,
          familyMembersCount: 5,
          dependentsCount: 4,
          incomePerMember: 280,
        ),
        classification: const SocialClassificationSection(
          mainClassifications: ['دخل منخفض', 'أمراض'],
          needLevel: 'مرتفع',
          priorityLevel: 'عالية',
        ),
        assessedNeeds: const [
          AssessedNeed(
            needType: 'دعم مالي',
            description: 'دعم شهري لتغطية العلاج والمصروفات الأساسية',
            priorityLevel: 'عالية',
            reason: 'دخل منخفض وغير منتظم مع مصروفات علاجية',
            source: 'مؤكد من الاحتياج الأولي',
            status: 'معتمد للمراجعة',
          ),
          AssessedNeed(
            needType: 'علاج',
            description: 'تحتاج الأسرة لدعم علاجي مستمر',
            priorityLevel: 'عالية',
            reason: 'حالة مرضية لرب الأسرة',
            source: 'جديد من البحث الميداني',
            status: 'معتمد للمراجعة',
          ),
        ],
        socialAssessment: const SocialAssessmentSection(
          familySituation: 'أسرة مكونة من 5 أفراد، الأب هو المعيل الوحيد',
          economicSituation: 'دخل غير منتظم لا يغطي احتياجات الأسرة الأساسية',
          housingSituation: 'سكن إيجار بحالة متوسطة يحتاج صيانة',
          strengths: 'الأسرة متعاونة ومتماسكة',
          mainProblems: 'دخل غير كافٍ + حالة مرضية لرب الأسرة',
          needLevel: 'مرتفع',
          overallAssessment: 'الحالة تستحق الدعم وفق البحث الاجتماعي الميداني',
        ),
        socialWorkerOpinion: const SocialWorkerOpinionSection(
          opinion: 'حالة حقيقية تستحق الدعم',
          caseSummary:
              'أسرة من 5 أفراد تعاني من دخل منخفض وحالة مرضية لرب الأسرة',
          assessment: 'الوضع الاقتصادي والصحي يستدعي تدخلًا عاجلاً',
          reasons:
              'دخل شهري لا يغطي الاحتياجات الأساسية بعد خصم المصروفات العلاجية',
          recommendation: 'دعم مالي شهري لمدة 6 أشهر',
        ),
        supportRecommendation: const SupportRecommendationSection(
          supportType: 'مساعدة مالية',
          beneficiary: 'أحمد محمد السيد',
          proposedAmount: 1000,
          frequency: 'شهري',
          duration: '6 أشهر',
          reason: 'دخل منخفض + مصروفات علاجية',
          justification:
              'صافي الدخل بعد المصروفات لا يغطي احتياجات أسرة من 5 أفراد',
          priorityLevel: 'عالية',
        ),
        timeline: CaseTimelineSection(
          events: [
            TimelineEvent(
              label: 'تم إنشاء الحالة',
              at: now.subtract(const Duration(days: 6)),
            ),
            TimelineEvent(
              label: 'تم استكمال البيانات',
              at: now.subtract(const Duration(days: 6, hours: -1)),
            ),
            TimelineEvent(
              label: 'تم إسنادها للأخصائي',
              at: now.subtract(const Duration(days: 5)),
            ),
            TimelineEvent(
              label: 'تمت الزيارة الميدانية',
              at: now.subtract(const Duration(hours: 3)),
            ),
            TimelineEvent(
              label: 'تم استكمال البحث الاجتماعي',
              at: now.subtract(const Duration(hours: 2)),
            ),
          ],
        ),
      );
    }

    // حالة مبكرة في الـ Workflow — الأقسام اللي بعد مرحلة الإسناد لسه null.
    return CaseFullDetails(
      basicInfo: BasicInfoSection(
        caseId: caseId,
        caseNumber: caseId.contains('1005') ? '#1005' : '#0000',
        createdAt: now.subtract(const Duration(days: 3)),
        statusLabel: 'مسندة إلى الأخصائي',
        priorityLabel: 'متوسطة',
        lastUpdatedAt: now.subtract(const Duration(days: 3)),
        fullName: FieldValue(
          value: 'عبدالله محمد',
          source: DataSource.dataEntry,
          at: now.subtract(const Duration(days: 3)),
        ),
        nationalId: FieldValue(
          value: '28505050123456',
          source: DataSource.dataEntry,
          at: now.subtract(const Duration(days: 3)),
        ),
        gender: 'ذكر',
        birthDate: DateTime(1985, 5, 5),
        age: now.year - 1985,
        maritalStatus: 'متزوج',
        phone: FieldValue(
          value: '01000000001',
          source: DataSource.dataEntry,
          at: now.subtract(const Duration(days: 3)),
        ),
        governorate: 'بني سويف',
        district: 'بني سويف',
        village: 'قرية بني عدي',
      ),
      family: const FamilySection(familyMembersCount: 0, members: []),
      timeline: CaseTimelineSection(
        events: [
          TimelineEvent(
            label: 'تم إنشاء الحالة',
            at: now.subtract(const Duration(days: 3)),
          ),
          TimelineEvent(
            label: 'تم إسنادها للأخصائي',
            at: now.subtract(const Duration(days: 3)),
          ),
        ],
      ),
    );
  }
}
