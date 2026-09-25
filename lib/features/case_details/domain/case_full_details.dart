import 'sections/assessment_opinion_section.dart';
import 'sections/attachments_section.dart';
import 'sections/basic_info_section.dart';
import 'sections/classification_needs_section.dart';
import 'sections/family_section.dart';
import 'sections/financial_section.dart';
import 'sections/housing_section.dart';
import 'sections/initial_need_section.dart';
import 'sections/review_section.dart';
import 'sections/support_section.dart';
import 'sections/timeline_section.dart';
import 'sections/utilities_equipment_section.dart';
import 'sections/visit_verification_section.dart';

/// Case Master Data (§28 من وثيقة Case Data) — كل بيانات الحالة تحت كيان واحد.
/// الأقسام التي تعتمد على مراحل لاحقة من الـ Workflow (سكن، دخل، تقييم، دعم،
/// مراجعة) قد تكون null إذا لم تصل الحالة بعد لتلك المرحلة — لا تُخترع بيانات
/// لمرحلة لم تحدث فعليًا.
class CaseFullDetails {
  final BasicInfoSection basicInfo; // القسم 1+2+3 — دائمًا موجود
  final FamilySection family; // القسم 4+5 — دائمًا موجود
  final InitialNeedSection? initialNeed; // القسم 6
  final List<CaseAttachment> attachments; // القسم 7

  final FieldVisitSection? fieldVisit; // القسم 8
  final FieldVerificationSection? fieldVerification; // القسم 9
  final HousingSection? housing; // القسم 10
  final UtilitiesEquipmentSection? utilitiesEquipment; // القسم 11+12
  final FinancialSummarySection? financialSummary; // القسم 13+14+15
  final SocialClassificationSection? classification; // القسم 16
  final List<AssessedNeed> assessedNeeds; // القسم 17
  final SocialAssessmentSection? socialAssessment; // القسم 18
  final SocialWorkerOpinionSection? socialWorkerOpinion; // القسم 19
  final SupportRecommendationSection? supportRecommendation; // القسم 20

  final ReviewSection? review; // القسم 21
  final ApprovedSupportSection? approvedSupport; // القسم 22

  final CaseTimelineSection timeline; // القسم 26 — دائمًا موجود

  const CaseFullDetails({
    required this.basicInfo,
    required this.family,
    this.initialNeed,
    this.attachments = const [],
    this.fieldVisit,
    this.fieldVerification,
    this.housing,
    this.utilitiesEquipment,
    this.financialSummary,
    this.classification,
    this.assessedNeeds = const [],
    this.socialAssessment,
    this.socialWorkerOpinion,
    this.supportRecommendation,
    this.review,
    this.approvedSupport,
    required this.timeline,
  });
}
