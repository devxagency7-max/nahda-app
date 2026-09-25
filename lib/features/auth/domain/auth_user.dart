/// المستخدم المُصادَق — الأخصائي الاجتماعي.
///
/// التطبيق مبني لهذا الدور وحده: الباك إند يرفض أي دور آخر على الموبايل
/// بـ `403 PLATFORM_NOT_ALLOWED` (§2.2). لا تُبنَ شاشات لأدوار أخرى.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.permissions,
  });

  final String id;
  final String fullName;
  final String email;
  final String role;
  final List<String> permissions;

  bool get isSocialWorker => role == 'social_worker';

  bool can(String permission) => permissions.contains(permission);

  /// صلاحيات الأخصائي (§7.1). ملاحظة: `create_case` **غير ممنوحة** — لا يمكنه
  /// إنشاء حالة جديدة من التطبيق.
  bool get canEditCases => can('edit_case');
  bool get canWriteOpinion => can('write_worker_opinion');
  bool get canAcceptReject => can('accept_reject_assignment');

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'email': email,
    'role': role,
    'permissions': permissions,
  };

  static AuthUser? fromJson(Object? data) {
    if (data is! Map<String, dynamic>) return null;

    final id = data['id'];
    if (id is! String || id.isEmpty) return null;

    final rawPermissions = data['permissions'];

    return AuthUser(
      id: id,
      fullName: data['fullName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      role: data['role'] as String? ?? '',
      permissions: rawPermissions is List
          ? rawPermissions.whereType<String>().toList(growable: false)
          : const [],
    );
  }
}
