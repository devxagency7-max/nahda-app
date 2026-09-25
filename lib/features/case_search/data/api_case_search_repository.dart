import '../../cases/data/cases_repository.dart';
import '../../cases/data/dto/case_list_item_dto.dart';
import '../../cases/domain/case_status.dart';
import '../../home/domain/case_priority.dart';
import '../../home/domain/social_worker_case.dart' show CaseWorkStatus, CaseWorkStatusX;
import '../domain/case_search_filter.dart';
import '../domain/case_search_repository.dart';
import '../domain/case_search_result.dart';

/// بحث حقيقي عبر `GET /search/cases` — يستبدل مصدر البيانات الوهمي السابق
/// بدون أي تغيير في الواجهة (نفس عقد [CaseSearchRepository]).
///
/// `GET /search/cases` (`CaseListItemDto`) لا يرجّع اسم القرية أو الجمعية أو
/// رقم الهاتف أو اسم الأخصائي المسنَد — نتركها `null` بدل اختلاقها؛ بطاقة
/// النتيجة (`CaseSearchResultTile`) بالفعل تُخفي أي قسم قيمته `null`.
class ApiCaseSearchRepository implements CaseSearchRepository {
  ApiCaseSearchRepository(this._repository);

  final CasesRepository _repository;

  @override
  Future<List<CaseSearchResult>> search(
    String query, {
    CaseSearchFilter? filter,
  }) async {
    final items = await _repository.search(
      q: _atLeast2(query),
      name: _atLeast2(filter?.name ?? ''),
      nationalId: _nonEmpty(filter?.nationalId ?? ''),
      charity: _atLeast2(filter?.charity ?? ''),
      region: _atLeast2(filter?.region ?? ''),
      phone: _nonEmpty(filter?.phone ?? ''),
      date: filter?.date == null ? null : _formatDate(filter!.date!),
      limit: 50,
    );

    return items.map(_toResult).toList(growable: false);
  }

  /// `q`/`name`/`charity`/`region` يرفضهم الخادم بـ 422 لو أقل من حرفين —
  /// لا نرسلهم بدل ما ننتظر خطأ معروف مسبقًا.
  String? _atLeast2(String value) {
    final trimmed = value.trim();
    return trimmed.length >= 2 ? trimmed : null;
  }

  /// `nationalId`/`phone` مطابقة تامة بلا حد أدنى للطول — أي نص غير فارغ صالح.
  String? _nonEmpty(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  CaseSearchResult _toResult(CaseListItemDto dto) {
    return CaseSearchResult(
      id: dto.id,
      displayId: '#${dto.displayId}',
      personName: dto.beneficiaryFullName,
      nationalId: dto.nationalId,
      village: null,
      charity: null,
      phone: null,
      registeredAt: dto.registrationDate == null
          ? null
          : DateTime.tryParse(dto.registrationDate!),
      statusLabel: _workStatus(dto).label,
      priority: _priority(dto.priority),
      assignedWorkerName: null,
      isAssignedToCurrentWorker: null,
    );
  }

  /// نفس منطق اشتقاق حالة العرض في `CaseStatusMapper._displayStatus` —
  /// `CaseListItemDto` يوفّر نفس الحقول المصدر (`completionPercentage`،
  /// `nextVisitDate`) فيصح تكرار المنطق هنا بدل تمرير `CachedCaseRow` بديل
  /// مُختلَق. غياب `returnInfo` هنا كمان (§7 عند الباك إند)، فنفترض المراجع
  /// كأشيع مصدر إرجاع، بنفس افتراض `CaseStatusMapper`.
  CaseWorkStatus _workStatus(CaseListItemDto dto) {
    switch (dto.status) {
      case CaseStatus.assigned:
        return CaseWorkStatus.assigned;
      case CaseStatus.returnedToWorker:
        return CaseWorkStatus.returnedFromReview;
      case CaseStatus.accepted:
      case CaseStatus.inResearch:
        if (dto.hasScheduledVisit) return CaseWorkStatus.visitScheduled;
        if (dto.isComplete) return CaseWorkStatus.readyForReview;
        return CaseWorkStatus.inProgress;
      case CaseStatus.pendingReview:
      case CaseStatus.pendingApproval:
      case CaseStatus.approved:
      case CaseStatus.rejected:
        return CaseWorkStatus.submittedForReview;
      case CaseStatus.draft:
      case CaseStatus.pendingAssignment:
      case CaseStatus.unknown:
        return CaseWorkStatus.assigned;
    }
  }

  CasePriority _priority(CasePriorityWire wire) => switch (wire) {
    CasePriorityWire.urgent => CasePriority.urgent,
    CasePriorityWire.high => CasePriority.high,
    CasePriorityWire.medium => CasePriority.medium,
    CasePriorityWire.low => CasePriority.low,
    CasePriorityWire.unknown => CasePriority.medium,
  };
}
