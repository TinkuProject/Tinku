import 'dart:convert';

import '../config/config.dart';
import '../models/warehouse_model.dart';
import 'auth_service.dart';

class WarehouseService {
  WarehouseService(this.authService);

  final AuthService authService;
  final String baseUrl = Config.baseUrl;

  Future<Map<String, String>> _headers() async {
    final token = await authService.getValidAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<WarehouseModel>> getActive() async {
    final response = await authService.client.get(
      Uri.parse('$baseUrl/warehouses'),
      headers: await _headers(),
    );
    _handle(response);

    return (jsonDecode(response.body) as List)
        .map((e) => WarehouseModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<WarehouseModel>> getMine() async {
    final response = await authService.client.get(
      Uri.parse('$baseUrl/warehouses/mine/list'),
      headers: await _headers(),
    );
    _handle(response);

    return (jsonDecode(response.body) as List)
        .map((e) => WarehouseModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<WarehouseModel>> getAdmin({String? status}) async {
    final uri = Uri.parse('$baseUrl/warehouses/admin/all').replace(
      queryParameters: {
        if (status != null) 'status': status,
      },
    );
    final response = await authService.client.get(uri, headers: await _headers());
    _handle(response);

    return (jsonDecode(response.body) as List)
        .map((e) => WarehouseModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<WarehouseModel> create({
    required String name,
    String? description,
    String? phone,
    String? email,
    String? address,
    double? latitude,
    double? longitude,
  }) async {
    final response = await authService.client.post(
      Uri.parse('$baseUrl/warehouses'),
      headers: await _headers(),
      body: jsonEncode({
        'name': name,
        'description': description,
        'phone': phone,
        'email': email,
        'address': address,
        if (latitude != null && longitude != null)
          'location': {
            'latitude': latitude,
            'longitude': longitude,
          },
      }),
    );
    _handle(response);
    return WarehouseModel.fromJson(jsonDecode(response.body));
  }

  Future<void> updateStatus({
    required int warehouseId,
    required String status,
    bool? validated,
  }) async {
    final response = await authService.client.patch(
      Uri.parse('$baseUrl/warehouses/$warehouseId/status'),
      headers: await _headers(),
      body: jsonEncode({
        'status': status,
        if (validated != null) 'validated': validated,
      }),
    );
    _handle(response);
  }

  Future<void> approveWarehouse(int warehouseId) async {
    final response = await authService.client.patch(
      Uri.parse('$baseUrl/warehouses/$warehouseId/approve'),
      headers: await _headers(),
      body: jsonEncode({}),
    );
    _handle(response);
  }

  Future<void> rejectWarehouse(int warehouseId, {required String message}) async {
    final response = await authService.client.patch(
      Uri.parse('$baseUrl/warehouses/$warehouseId/reject'),
      headers: await _headers(),
      body: jsonEncode({'message': message.trim()}),
    );
    _handle(response);
  }

  Future<List<WarehouseInventoryModel>> getInventory(int warehouseId) async {
    final response = await authService.client.get(
      Uri.parse('$baseUrl/warehouses/$warehouseId/inventory'),
      headers: await _headers(),
    );
    _handle(response);

    return (jsonDecode(response.body) as List)
        .map((e) => WarehouseInventoryModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<WarehouseLocationModel>> getLocations(int warehouseId) async {
    final response = await authService.client.get(
      Uri.parse('$baseUrl/warehouses/$warehouseId/locations'),
      headers: await _headers(),
    );
    _handle(response);

    return (jsonDecode(response.body) as List)
        .map((e) => WarehouseLocationModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<WarehouseLocationModel> createLocation({
    required int warehouseId,
    int? parentId,
    required String name,
    required String code,
    String? description,
    int sortOrder = 0,
  }) async {
    final response = await authService.client.post(
      Uri.parse('$baseUrl/warehouses/$warehouseId/locations'),
      headers: await _headers(),
      body: jsonEncode({
        'parent_id': parentId,
        'name': name,
        'code': code,
        'description': description,
        'sort_order': sortOrder,
      }),
    );
    _handle(response);
    return WarehouseLocationModel.fromJson(jsonDecode(response.body));
  }

  Future<WarehouseLocationModel> updateLocation({
    required int warehouseId,
    required int locationId,
    int? parentId,
    required String name,
    required String code,
    String? description,
    String status = 'active',
    int sortOrder = 0,
  }) async {
    final response = await authService.client.patch(
      Uri.parse('$baseUrl/warehouses/$warehouseId/locations/$locationId'),
      headers: await _headers(),
      body: jsonEncode({
        'parent_id': parentId,
        'name': name,
        'code': code,
        'description': description,
        'status': status,
        'sort_order': sortOrder,
      }),
    );
    _handle(response);
    return WarehouseLocationModel.fromJson(jsonDecode(response.body));
  }

  Future<void> archiveLocation({
    required int warehouseId,
    required int locationId,
  }) async {
    final response = await authService.client.delete(
      Uri.parse('$baseUrl/warehouses/$warehouseId/locations/$locationId'),
      headers: await _headers(),
    );
    _handle(response);
  }

  Future<void> setInventoryLocation({
    required int warehouseId,
    required int inventoryId,
    int? locationId,
  }) async {
    final response = await authService.client.patch(
      Uri.parse('$baseUrl/warehouses/$warehouseId/inventory/$inventoryId/location'),
      headers: await _headers(),
      body: jsonEncode({'location_id': locationId}),
    );
    _handle(response);
  }

  Future<List<WarehouseStockRequestModel>> getReceivedStockRequests({
    String? status,
  }) async {
    final uri = Uri.parse('$baseUrl/warehouses/stock-requests/received')
        .replace(queryParameters: {
      if (status != null) 'status': status,
    });
    final response = await authService.client.get(uri, headers: await _headers());
    _handle(response);

    return (jsonDecode(response.body) as List)
        .map((e) => WarehouseStockRequestModel.fromJson(
              Map<String, dynamic>.from(e),
            ))
        .toList();
  }

  Future<List<WarehouseStockRequestModel>> getSentStockRequests({
    String? status,
  }) async {
    final uri = Uri.parse('$baseUrl/warehouses/stock-requests/sent')
        .replace(queryParameters: {
      if (status != null) 'status': status,
    });
    final response = await authService.client.get(uri, headers: await _headers());
    _handle(response);

    return (jsonDecode(response.body) as List)
        .map((e) => WarehouseStockRequestModel.fromJson(
              Map<String, dynamic>.from(e),
            ))
        .toList();
  }

  Future<WarehouseStockRequestModel> createStockRequest({
    required int businessId,
    required int warehouseId,
    required int productId,
    required int quantity,
    String? notes,
  }) async {
    final response = await authService.client.post(
      Uri.parse('$baseUrl/warehouses/stock-requests'),
      headers: await _headers(),
      body: jsonEncode({
        'business_id': businessId,
        'warehouse_id': warehouseId,
        'product_id': productId,
        'quantity': quantity,
        'notes': notes,
      }),
    );
    _handle(response);
    return WarehouseStockRequestModel.fromJson(jsonDecode(response.body));
  }

  Future<void> approveStockRequest(int requestId, {int? locationId}) async {
    final response = await authService.client.patch(
      Uri.parse('$baseUrl/warehouses/stock-requests/$requestId/approve'),
      headers: await _headers(),
      body: jsonEncode({'location_id': locationId}),
    );
    _handle(response);
  }

  Future<void> markStockRequestSent(int requestId) async {
    final response = await authService.client.patch(
      Uri.parse('$baseUrl/warehouses/stock-requests/$requestId/mark-sent'),
      headers: await _headers(),
      body: jsonEncode({}),
    );
    _handle(response);
  }

  Future<void> receiveStockRequest(int requestId, {int? locationId}) async {
    final response = await authService.client.patch(
      Uri.parse('$baseUrl/warehouses/stock-requests/$requestId/receive'),
      headers: await _headers(),
      body: jsonEncode({'location_id': locationId}),
    );
    _handle(response);
  }

  Future<void> rejectStockRequest(
    int requestId, {
    required String message,
  }) async {
    final response = await authService.client.patch(
      Uri.parse('$baseUrl/warehouses/stock-requests/$requestId/reject'),
      headers: await _headers(),
      body: jsonEncode({'message': message.trim()}),
    );
    _handle(response);
  }

  Future<BusinessFulfillmentModel> getBusinessFulfillment(int businessId) async {
    final response = await authService.client.get(
      Uri.parse('$baseUrl/warehouses/business/$businessId/fulfillment'),
      headers: await _headers(),
    );
    _handle(response);
    return BusinessFulfillmentModel.fromJson(jsonDecode(response.body));
  }

  Future<BusinessFulfillmentModel> setBusinessFulfillment({
    required int businessId,
    required bool pickupInStore,
    required bool warehouseDelivery,
    required List<int> warehouseIds,
    String? notes,
  }) async {
    final response = await authService.client.put(
      Uri.parse('$baseUrl/warehouses/business/$businessId/fulfillment'),
      headers: await _headers(),
      body: jsonEncode({
        'pickup_in_store': pickupInStore,
        'warehouse_delivery': warehouseDelivery,
        'warehouse_ids': warehouseIds,
        'notes': notes,
      }),
    );
    _handle(response);
    return BusinessFulfillmentModel.fromJson(jsonDecode(response.body));
  }

  void _handle(dynamic response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw ApiException(response.statusCode, response.body);
  }
}
