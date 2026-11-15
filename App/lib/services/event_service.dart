import 'dart:convert';
import '../../core/enums.dart';
import '../../models/event_model.dart';
import '../../models/paginated_result.dart';
import 'base_service.dart';
import 'auth_service.dart';

class EventService extends BaseService<EventModel> {
  EventService(AuthService authService) : super("events", authService);

  @override
  EventModel fromJson(Map<String, dynamic> json) {
    return EventModel.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(EventModel model) {
    return model.toJson();
  }

  Future<PaginatedResult<EventModel>> getPage({
    int limit = 20,
    int offset = 0,
  }) async {
    final uri = Uri.parse('$baseUrl/$endpoint/paginated').replace(
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
  // GET BY CATEGORY (PUBLIC)
  // =========================
  Future<List<EventModel>> getByCategory(int categoryId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/$endpoint/category/$categoryId'),
      headers: await headers(),
    );

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }

    final data = jsonDecode(response.body);

    if (data is! List) {
      throw ApiException(response.statusCode, 'Formato inválido');
    }

    return data
        .map<EventModel>((e) => fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // =========================
  // GET BY BUSINESS (PUBLIC)
  // =========================
  Future<List<EventModel>> getByBusiness(int businessId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/$endpoint/business/$businessId'),
      headers: await headers(),
    );

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }

    final data = jsonDecode(response.body);

    if (data is! List) {
      throw ApiException(response.statusCode, 'Formato inválido');
    }

    return data
        .map<EventModel>((e) => fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // =========================
  // GET MINE (PROTECTED)
  // =========================
  Future<List<EventModel>> getMine() async {
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
        .map<EventModel>((e) => fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<EventModel>> getByStatus(EventStatus status) async {
    final uri = Uri.parse('$baseUrl/$endpoint/admin').replace(
      queryParameters: {
        'status': eventStatusToString(status),
      },
    );

    final response = await request(
      () async => client.get(
        uri,
        headers: await headers(),
      ),
    );

    final data = jsonDecode(response.body);

    if (data is! List) {
      throw ApiException(response.statusCode, 'Formato inválido');
    }

    return data
        .map<EventModel>((e) => fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // =========================
  // GET AVAILABILITY
  // =========================
  Future<Map<String, dynamic>> getAvailability(int id) async {
    final response = await client.get(
      Uri.parse('$baseUrl/$endpoint/$id/availability'),
      headers: await headers(),
    );

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }

    final data = jsonDecode(response.body);

    if (data is! Map<String, dynamic>) {
      throw ApiException(response.statusCode, 'Formato inválido');
    }

    return data;
  }

  // =========================
  // GET DETAIL (PUBLIC AGGREGATE)
  // =========================
  Future<Map<String, dynamic>> getDetail(int id) async {
    final response = await client.get(
      Uri.parse('$baseUrl/$endpoint/$id/detail'),
      headers: await headers(),
    );

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }

    final data = jsonDecode(response.body);

    if (data is! Map<String, dynamic>) {
      throw ApiException(response.statusCode, 'Formato inválido');
    }

    return data;
  }

  // =========================
  // DELETE
  // =========================
  Future<EventModel> softDeleteEvent(int id) async {
    final response = await request(
      () async => client.delete(
        Uri.parse('$baseUrl/$endpoint/$id'),
        headers: await headers(),
      ),
    );

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return EventModel.fromJson(json);
  }

  // =========================
  // APPROVE / REJECT
  // =========================
  Future<void> approve(int id) async {
    await request(
      () async => client.patch(
        Uri.parse('$baseUrl/$endpoint/$id/approve'),
        headers: await headers(),
        body: jsonEncode({}),
      ),
    );
  }

  Future<void> reject(int id, {required String message}) async {
    await request(
      () async => client.patch(
        Uri.parse('$baseUrl/$endpoint/$id/reject'),
        headers: await headers(),
        body: jsonEncode({'message': message.trim()}),
      ),
    );
  }

  // =========================
  // =========================
  // GET BY IDS (PUBLIC)
  // =========================
  Future<List<EventModel>> getByIds(List<int> ids) async {
    if (ids.isEmpty) return [];

    final uri = Uri.parse('$baseUrl/$endpoint/batch').replace(
      queryParameters: {
        'ids': ids.join(','),
      },
    );

    final response = await client.get(uri, headers: await headers());

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }

    final data = jsonDecode(response.body);

    if (data is! List) {
      throw ApiException(response.statusCode, 'Formato inválido');
    }

    return data
        .map<EventModel>((e) => fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
