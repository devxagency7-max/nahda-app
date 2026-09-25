class CaseSearchFilter {
  final String query;
  final String name;
  final String nationalId;
  final String charity;
  final String region;
  final String phone;
  final DateTime? date;

  const CaseSearchFilter({
    this.query = '',
    this.name = '',
    this.nationalId = '',
    this.charity = '',
    this.region = '',
    this.phone = '',
    this.date,
  });

  bool get isEmpty =>
      query.trim().isEmpty &&
      name.trim().isEmpty &&
      nationalId.trim().isEmpty &&
      charity.trim().isEmpty &&
      region.trim().isEmpty &&
      phone.trim().isEmpty &&
      date == null;

  int get activeCriteriaCount {
    int count = 0;
    if (name.trim().isNotEmpty) count++;
    if (nationalId.trim().isNotEmpty) count++;
    if (charity.trim().isNotEmpty) count++;
    if (region.trim().isNotEmpty) count++;
    if (phone.trim().isNotEmpty) count++;
    if (date != null) count++;
    return count;
  }

  CaseSearchFilter copyWith({
    String? query,
    String? name,
    String? nationalId,
    String? charity,
    String? region,
    String? phone,
    DateTime? date,
    bool clearDate = false,
  }) {
    return CaseSearchFilter(
      query: query ?? this.query,
      name: name ?? this.name,
      nationalId: nationalId ?? this.nationalId,
      charity: charity ?? this.charity,
      region: region ?? this.region,
      phone: phone ?? this.phone,
      date: clearDate ? null : (date ?? this.date),
    );
  }

  CaseSearchFilter clear() => const CaseSearchFilter();
}
