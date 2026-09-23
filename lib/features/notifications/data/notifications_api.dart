import '../../../core/network/api_client.dart';

/// مسارات الإشعارات — بلا صلاحية خاصة (أي مستخدم مُصادَق)، §12/§21.
class NotificationsApi {
  const NotificationsApi(this._client);

  final ApiClient _client;

  /// `GET /notifications` — `page`/`limit` بحد أقصى 100 لكل صفحة.
  Future<Map<String, dynamic>> list({int page = 1, int limit = 50}) =>
      _client.get<Map<String, dynamic>>(
        '/notifications',
        Parse.object,
        query: {'page': page, 'limit': limit},
      );

  /// `PUT /notifications/{id}/read` — بلا جسم، مثالي للإعادة طبيعيًا (لا
  /// يحتاج Idempotency-Key: تحديث مقيَّد بشرط ملكية واحد، §21).
  Future<void> markRead(String id) =>
      _client.put<void>('/notifications/$id/read', Parse.empty);

  /// `PUT /notifications/mark-all-read` — بلا جسم؛ `markedCount: 0` نجاح
  /// طبيعي لا خطأ (idempotent فعليًا).
  Future<int> markAllRead() async {
    final result = await _client.put<Map<String, dynamic>>(
      '/notifications/mark-all-read',
      Parse.object,
    );
    final count = result['markedCount'];
    return count is int ? count : 0;
  }
}
