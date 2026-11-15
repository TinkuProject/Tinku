import 'dart:convert';
import '../../models/transport_route_model.dart';
import '../../core/enums.dart';
import 'base_service.dart';
import 'auth_service.dart';

class TransportRouteService extends BaseService<TransportRouteModel> {
  TransportRouteService(AuthService authService)
      : super("transport-routes", authService);

  @override
  TransportRouteModel fromJson(Map<String, dynamic> json) {
    return TransportRouteModel.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(TransportRouteModel model) {
    return model.toJson();
  }

  // =========================
  // GET BY LINE (PUBLIC)
  // =========================
  Future<List<TransportRouteModel>> getByLine(int lineId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/$endpoint/line/$lineId'),
    );

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }

    final data = jsonDecode(response.body);

    if (data is! List) {
      throw ApiException(response.statusCode, 'Formato inválido');
    }

    return data
        .map<TransportRouteModel>(
            (e) => fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Map<int, List<TransportRouteModel>>> getByLines({
    required List<int> lineIds,
    RouteDirection? direction,
  }) async {
    if (lineIds.isEmpty) return {};

    final uniqueIds = lineIds.toSet().toList();
    final query = {
      'line_ids': uniqueIds.join(','),
      if (direction != null) 'direction': routeDirectionToString(direction),
    };

    final uri = Uri.parse('$baseUrl/$endpoint/lines').replace(
      queryParameters: query,
    );

    final response = await client.get(uri);

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }

    final data = jsonDecode(response.body);

    if (data is! Map<String, dynamic>) {
      throw ApiException(response.statusCode, 'Formato inválido');
    }

    return data.map((key, value) {
      return MapEntry(
        int.parse(key),
        (value as List)
            .map((e) => fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
    });
  }

  // =========================
  // GET BY LINE + DIRECTION
  // =========================
  Future<List<TransportRouteModel>> getByLineAndDirection({
    required int lineId,
    required RouteDirection direction,
  }) async {
    final response = await client.get(
      Uri.parse(
        '$baseUrl/$endpoint/line/$lineId/${routeDirectionToString(direction)}',
      ),
    );

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }

    final data = jsonDecode(response.body);

    if (data is! List) {
      throw ApiException(response.statusCode, 'Formato inválido');
    }

    return data
        .map<TransportRouteModel>(
            (e) => fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // =========================
  // CREATE SINGLE
  // =========================
  Future<void> createRoute(TransportRouteModel model) async {
    await request(
          () async => client.post(
        Uri.parse('$baseUrl/$endpoint'),
        headers: await headers(),
        body: jsonEncode(model.toJson()),
      ),
    );
  }

  // =========================
  // BULK CREATE
  // =========================
  Future<void> createBulk(List<TransportRouteModel> routes) async {
    await request(
          () async => client.post(
        Uri.parse('$baseUrl/$endpoint/bulk'),
        headers: await headers(),
        body: jsonEncode(
          routes.map((e) => e.toJson()).toList(),
        ),
      ),
    );
  }

  // =========================
  // DELETE
  // =========================
  Future<void> deleteRoute(int id) async {
    await request(
          () async => client.delete(
        Uri.parse('$baseUrl/$endpoint/$id'),
        headers: await headers(),
      ),
    );
  }
}
