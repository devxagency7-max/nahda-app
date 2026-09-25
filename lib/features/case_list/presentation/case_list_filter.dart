/// الأقسام الثلاثة المطابقة لأرقام الـ Home السريعة (كل حالاتي / المحفوظة / المرجعة).
enum CaseListFilter { allCases, saved, returned }

extension CaseListFilterX on CaseListFilter {
  String get label => switch (this) {
    CaseListFilter.allCases => 'كل حالاتي',
    CaseListFilter.saved => 'الحالات المحفوظة',
    CaseListFilter.returned => 'الحالات المرتجعة',
  };
}
