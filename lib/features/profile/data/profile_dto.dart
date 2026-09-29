/// بيانات البروفايل كما يرجعها `GET /profile` أو `PUT /profile`.
///
/// [rowVersion] **يجب** إعادة جلبه قبل أي `PUT` تالٍ — يتغيّر مع أي تعديل
/// على بيانات المستخدم، بما فيه رفع/حذف الصورة الشخصية نفسها. تمرير نسخة
/// قديمة يرجع `409 CONCURRENCY_CONFLICT` دائمًا.
class ProfileDto {
  const ProfileDto({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.gender,
    required this.region,
    required this.avatarUrl,
    required this.rowVersion,
  });

  final String fullName;
  final String email;
  final String phone;
  final String gender;
  final String region;
  final String? avatarUrl;
  final int rowVersion;

  static ProfileDto fromJson(Object? data) {
    final json = data is Map<String, dynamic> ? data : const <String, dynamic>{};
    return ProfileDto(
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      region: json['region'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      rowVersion: switch (json['rowVersion']) {
        final int v => v,
        final num v => v.toInt(),
        _ => 0,
      },
    );
  }
}
