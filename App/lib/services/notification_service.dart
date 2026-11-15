import 'dart:convert';
import '../../models/notification_model.dart';
import '../../models/paginated_result.dart';
import 'base_service.dart';
import 'auth_service.dart';

class NotificationService extends BaseService<NotificationModel> {
  NotificationService(AuthService authService)
      : super("notifications", authService);

  @override
  NotificationModel fromJson(Map<String, dynamic> json) {
    return NotificationModel.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(NotificationModel model) {
    return model.toJson();
  }

  Future<void> notifyAdmins({
    required String message,
    String? senderId,
  }) async {
    await request(
      () async => client.post(
        Uri.parse('$baseUrl/$endpoint/broadcast/admins'),
        headers: await headers(),
        body: jsonEncode({
          'message': message,
          if (senderId != null) 'sender_id': senderId,
        }),
      ),
    );
  }

  // =========================
  // GET MY NOTIFICATIONS
  // =========================
  Future<List<NotificationModel>> getMine() async {
    final response = await request(
      () async => client.get(
        Uri.parse('$baseUrl/$endpoint/me'),
        headers: await headers(),
      ),
    );

    final data = jsonDecode(response.body);

    if (data is! List) {
      throw ApiException(response.statusCode, 'Formato inválido');
    }

    return data
        .map<NotificationModel>((e) => fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<PaginatedResult<NotificationModel>> getMinePage({
    int limit = 20,
    int offset = 0,
  }) async {
    final uri = Uri.parse('$baseUrl/$endpoint/me/paginated').replace(
      queryParameters: {'limit': '$limit', 'offset': '$offset'},
    );
    final response = await request(
      () async => client.get(uri, headers: await headers()),
    );
    final data = jsonDecode(response.body);

    if (data is! Map<String, dynamic> || data['items'] is! List) {
      throw ApiException(response.statusCode, 'Formato inválido');
    }

    return PaginatedResult(
      items: (data['items'] as List)
          .map((item) => fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      total: (data['total'] as num?)?.toInt() ?? 0,
      limit: (data['limit'] as num?)?.toInt() ?? limit,
      offset: (data['offset'] as num?)?.toInt() ?? offset,
      hasMore: data['has_more'] == true,
    );
  }

  // =========================
  // UNREAD COUNT
  // =========================
  Future<int> getUnreadCount() async {
    final response = await request(
      () async => client.get(
        Uri.parse('$baseUrl/$endpoint/unread-count'),
        headers: await headers(),
      ),
    );

    final data = jsonDecode(response.body);

    if (data is! Map<String, dynamic>) {
      throw ApiException(response.statusCode, 'Formato inválido');
    }

    return data['unread'] ?? data['count'] ?? 0;
  }

  // =========================
  // MARK ALL AS READ
  // =========================
  Future<void> markAllAsRead() async {
    await request(
      () async => client.patch(
        Uri.parse('$baseUrl/$endpoint/read-all'),
        headers: await headers(),
      ),
    );
  }

  // =========================
  // MARK ONE AS READ
  // =========================
  Future<void> markAsRead(int id) async {
    await request(
      () async => client.patch(
        Uri.parse('$baseUrl/$endpoint/$id/read'),
        headers: await headers(),
      ),
    );
  }

  // =========================
  // DELETE
  // =========================
  Future<void> deleteNotification(int id) async {
    await request(
      () async => client.delete(
        Uri.parse('$baseUrl/$endpoint/$id'),
        headers: await headers(),
      ),
    );
  }

  Future<void> deleteAllNotifications() async {
    await request(
      () async => client.delete(
        Uri.parse('$baseUrl/$endpoint/all'),
        headers: await headers(),
      ),
    );
  }
}
