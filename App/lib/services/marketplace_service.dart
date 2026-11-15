import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../config/config.dart';
import '../models/marketplace_model.dart';
import 'api_http_client.dart';
import 'auth_service.dart';

class MarketplaceService {
  MarketplaceService(this.authService);

  static const _publicationsRequestKey = 'marketplace-publications-search';

  final AuthService authService;
  final String baseUrl = Config.baseUrl;

  Future<Map<String, String>> _headers() async {
    final token = await authService.getValidAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<MarketplacePublicationModel>> getPublications({
    String? q,
    String? availability,
    String? volume,
    int? minTinkus,
    int? maxTinkus,
    String? sort,
    int limit = 20,
    int offset = 0,
  }) async {
    final uri = Uri.parse('$baseUrl/marketplace/publications').replace(
      queryParameters: {
        'limit': '$limit',
        'offset': '$offset',
        if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
        if (availability != null && availability != 'all')
          'availability': availability,
        if (volume != null) 'volume': volume,
        if (minTinkus != null) 'min_tinkus': '$minTinkus',
        if (maxTinkus != null) 'max_tinkus': '$maxTinkus',
        if (sort != null) 'sort': sort,
      },
    );
    final requestHeaders = await _headers();
    requestHeaders[ApiHttpClient.latestRequestKeyHeader] =
        _publicationsRequestKey;
    final response = await authService.client.get(uri, headers: requestHeaders);
    _handle(response);

    return (jsonDecode(response.body) as List)
        .map((e) =>
            MarketplacePublicationModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  void cancelPublicationsRequest() {
    final client = authService.client;
    if (client is ApiHttpClient) {
      client.cancelLatestRequest(_publicationsRequestKey);
    }
  }

  Future<List<MarketplacePublicationModel>> getMine({
    int limit = 20,
    int offset = 0,
  }) async {
    final uri = Uri.parse('$baseUrl/marketplace/publications/mine/list')
        .replace(queryParameters: {'limit': '$limit', 'offset': '$offset'});
    final response =
        await authService.client.get(uri, headers: await _headers());
    _handle(response);

    return (jsonDecode(response.body) as List)
        .map((e) =>
            MarketplacePublicationModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<MarketplacePublicationModel> createPublication({
    required int productId,
    required int publishedStock,
    int? unitTinkuPrice,
  }) async {
    final response = await authService.client.post(
      Uri.parse('$baseUrl/marketplace/publications'),
      headers: await _headers(),
      body: jsonEncode({
        'product_id': productId,
        'published_stock': publishedStock,
        'payment_mode': 'tinkus',
        'unit_tinku_price': unitTinkuPrice,
      }),
    );
    _handle(response);
    return MarketplacePublicationModel.fromJson(jsonDecode(response.body));
  }

  Future<MarketplacePublicationModel> updatePublicationStock({
    required int publicationId,
    required int publishedStock,
    int? unitTinkuPrice,
  }) async {
    final response = await authService.client.patch(
      Uri.parse('$baseUrl/marketplace/publications/$publicationId/stock'),
      headers: await _headers(),
      body: jsonEncode({
        'published_stock': publishedStock,
        'payment_mode': 'tinkus',
        'unit_tinku_price': unitTinkuPrice,
      }),
    );
    _handle(response);
    return MarketplacePublicationModel.fromJson(jsonDecode(response.body));
  }

  Future<MarketplacePublicationEstimateModel> estimatePublication({
    required int productId,
    required int publishedStock,
    int? unitTinkuPrice,
  }) async {
    final response = await authService.client.post(
      Uri.parse('$baseUrl/marketplace/publications/estimate'),
      headers: await _headers(),
      body: jsonEncode({
        'product_id': productId,
        'published_stock': publishedStock,
        'payment_mode': 'tinkus',
        'unit_tinku_price': unitTinkuPrice,
      }),
    );
    _handle(response);
    return MarketplacePublicationEstimateModel.fromJson(
        jsonDecode(response.body));
  }

  Future<void> updatePublicationStatus({
    required int publicationId,
    required String status,
  }) async {
    final response = await authService.client.patch(
      Uri.parse('$baseUrl/marketplace/publications/$publicationId/status'),
      headers: await _headers(),
      body: jsonEncode({'status': status}),
    );
    _handle(response);
  }

  Future<MarketplaceOrderModel> createOrder({
    required int publicationId,
    required int quantity,
    required String paymentMethod,
    required String fulfillment,
    int? pickupBusinessId,
    int? warehouseId,
  }) async {
    final body = <String, dynamic>{
      'items': [
        {'publication_id': publicationId, 'quantity': quantity}
      ],
      'payment_method': paymentMethod,
      'fulfillment': fulfillment,
      'pickup_business_id': pickupBusinessId,
      'warehouse_id': warehouseId,
    };
    final token = await authService.getValidAccessToken();
    if (token == null) throw ApiException(401, 'Unauthorized');
    final userId = (jsonDecode(utf8
            .decode(base64Url.decode(base64Url.normalize(token.split('.')[1]))))
        as Map)['sub'];
    final pendingKey =
        'marketplace_pending:$userId:${base64Url.encode(utf8.encode(jsonEncode(body)))}';
    final preferences = await SharedPreferences.getInstance();
    final requestId = preferences.getString(pendingKey) ?? const Uuid().v4();
    await preferences.setString(pendingKey, requestId);
    body['client_request_id'] = requestId;
    final response = await authService.client.post(
      Uri.parse('$baseUrl/marketplace/orders'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    _handle(response);
    final order = MarketplaceOrderModel.fromJson(jsonDecode(response.body));
    await preferences.remove(pendingKey);
    return order;
  }

  Future<void> registerBusinessView(int businessId) async {
    final response = await authService.client.post(
      Uri.parse('$baseUrl/marketplace/businesses/$businessId/views'),
      headers: await _headers(),
    );
    _handle(response, allowNoContent: true);
  }

  Future<void> cancelOrder(int orderId) async {
    final response = await authService.client.post(
      Uri.parse('$baseUrl/marketplace/orders/$orderId/cancel'),
      headers: await _headers(),
    );
    _handle(response);
  }

  Future<List<MarketplaceOrderModel>> getMyOrders({
    int limit = 20,
    int offset = 0,
  }) async {
    final uri = Uri.parse('$baseUrl/marketplace/orders/mine/list')
        .replace(queryParameters: {'limit': '$limit', 'offset': '$offset'});
    final response =
        await authService.client.get(uri, headers: await _headers());
    _handle(response);

    return (jsonDecode(response.body) as List)
        .map(
            (e) => MarketplaceOrderModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<MarketplaceOrderModel>> getSalesOrders({
    String? status,
    int limit = 20,
    int offset = 0,
  }) async {
    final uri = Uri.parse('$baseUrl/marketplace/orders/sales/list').replace(
      queryParameters: {
        'limit': '$limit',
        'offset': '$offset',
        if (status != null) 'status': status,
      },
    );
    final response =
        await authService.client.get(uri, headers: await _headers());
    _handle(response);
    return (jsonDecode(response.body) as List)
        .map((e) => MarketplaceOrderModel.fromJson(
              Map<String, dynamic>.from(e),
            ))
        .toList();
  }

  Future<List<MarketplaceOrderModel>> getWarehouseOrders(
      {int limit = 20, int offset = 0}) async {
    final uri = Uri.parse('$baseUrl/marketplace/orders/warehouse/list')
        .replace(queryParameters: {'limit': '$limit', 'offset': '$offset'});
    final response =
        await authService.client.get(uri, headers: await _headers());
    _handle(response);
    return (jsonDecode(response.body) as List)
        .map((item) =>
            MarketplaceOrderModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> markWarehouseOrderReady(int id) async {
    final response = await authService.client.patch(
        Uri.parse('$baseUrl/marketplace/orders/warehouse/$id/ready'),
        headers: await _headers());
    _handle(response);
  }

  Future<void> updateSalesOrderStatus(int orderId, String status) async {
    final response = await authService.client.patch(
      Uri.parse('$baseUrl/marketplace/orders/sales/$orderId/status'),
      headers: await _headers(),
      body: jsonEncode({'status': status}),
    );
    _handle(response);
  }

  Future<void> rejectSalesOrder(int orderId, String reason) async {
    final response = await authService.client.post(
      Uri.parse('$baseUrl/marketplace/orders/sales/$orderId/reject'),
      headers: await _headers(),
      body: jsonEncode({'reason': reason.trim()}),
    );
    _handle(response);
  }

  Future<MarketplaceOrderModel> validatePickupCode(String code) async {
    final normalizedCode = _normalizePickupCode(code);
    final response = await authService.client.post(
      Uri.parse('$baseUrl/marketplace/orders/validate-pickup'),
      headers: await _headers(),
      body: jsonEncode({'code': normalizedCode}),
    );
    _handle(response);
    return MarketplaceOrderModel.fromJson(jsonDecode(response.body));
  }

  String _normalizePickupCode(String rawCode) {
    final trimmed = rawCode.trim();
    if (trimmed.isEmpty) return trimmed;

    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic>) {
        final nested = decoded['pickup_code'] ?? decoded['code'];
        if (nested != null) return nested.toString().trim();
      }
    } catch (_) {
      // El QR actual contiene solo el codigo; JSON se acepta por compatibilidad.
    }

    return trimmed;
  }

  Future<BusinessViewStatsModel> getBusinessViewStats(int businessId) async {
    final response = await authService.client.get(
      Uri.parse('$baseUrl/marketplace/businesses/$businessId/view-stats'),
      headers: await _headers(),
    );
    _handle(response);
    return BusinessViewStatsModel.fromJson(jsonDecode(response.body));
  }

  Future<Map<int, int>> getBusinessViewStatsBatch(List<int> businessIds) async {
    if (businessIds.isEmpty) return {};
    final uri = Uri.parse(
      '$baseUrl/marketplace/businesses/view-stats/batch',
    ).replace(queryParameters: {'ids': businessIds.join(',')});
    final response =
        await authService.client.get(uri, headers: await _headers());
    _handle(response);
    final data = Map<String, dynamic>.from(jsonDecode(response.body));
    return data.map(
      (key, value) => MapEntry(
        int.parse(key),
        value is num ? value.toInt() : int.parse(value.toString()),
      ),
    );
  }

  void _handle(dynamic response, {bool allowNoContent = false}) {
    if (allowNoContent && response.statusCode == 204) return;
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw ApiException(response.statusCode, response.body);
  }
}
