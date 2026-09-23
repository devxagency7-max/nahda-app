/// مصدر البيانات — يجب معرفته لكل قيمة مهمة (Data Ownership Rule).
enum DataSource { dataEntry, socialWorker, reviewer, systemCalculated }

extension DataSourceX on DataSource {
  String get label => switch (this) {
    DataSource.dataEntry => 'موظف إدخال البيانات',
    DataSource.socialWorker => 'الأخصائي الاجتماعي',
    DataSource.reviewer => 'المراجع',
    DataSource.systemCalculated => 'محسوبة تلقائيًا',
  };
}

/// قيمة مع مصدرها وتاريخها — يمنع الكتابة فوق القيمة الأصلية
/// (Rule: لا يتم overwrite للبيانات المهمة، القيمة المُعلنة تبقى منفصلة عن المتحققة).
class FieldValue<T> {
  final T value;
  final DataSource source;
  final DateTime? at;
  final String? note;

  const FieldValue({
    required this.value,
    required this.source,
    this.at,
    this.note,
  });
}
