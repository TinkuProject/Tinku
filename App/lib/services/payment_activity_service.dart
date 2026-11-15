import 'dart:convert';

import '../models/payment_activity_item.dart';
import '../models/paginated_result.dart';
import 'auth_service.dart';
import 'base_service.dart';

class PaymentActivityService extends BaseService<PaymentActivityItem> {
  PaymentActivityService(AuthService authService)
      : super("finance", authService);

  @override
  PaymentActivityItem fromJson(Map<String, dynamic> json) {
    return PaymentActivityItem.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(PaymentActivityItem model) {
    return model.toJson();
  }

  // =========================
  // GET MINE ACTIVITY
  // =========================
  Future<List<PaymentActivityItem>> getMineActivity({
    int limit = 20,
    int offset = 0,
  }) async {
    final uri = Uri.parse('$baseUrl/$endpoint/me/activity').replace(
      queryParameters: {
        'limit': '$limit',
        'offset': '$offset',
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
        .map<PaymentActivityItem>(
          (e) => fromJson(Map<String, dynamic>.from(e)),
        )
        .toList();
  }

  Future<PaginatedResult<PaymentActivityItem>> getMineActivityPage({
    int limit = 20,
    int offset = 0,
  }) async {
    final uri = Uri.parse('$baseUrl/$endpoint/me/activity/paginated').replace(
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
}
