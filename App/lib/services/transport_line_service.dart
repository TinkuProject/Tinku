import 'dart:convert';
import '../../models/transport_line_model.dart';
import 'base_service.dart';
import 'auth_service.dart';

class TransportLineService extends BaseService<TransportLineModel> {
  TransportLineService(AuthService authService)
      : super("transport-lines", authService);

  @override
  TransportLineModel fromJson(Map<String, dynamic> json) {
    return TransportLineModel.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(TransportLineModel model) {
    return model.toJson();
  }

  // =========================
  // GET ALL (PUBLIC)
  // =========================
  @override
  Future<List<TransportLineModel>> getAll({
    Map<String, String>? queryParams,
  }) async {
    final uri = Uri.parse('$baseUrl/$endpoint')
        .replace(queryParameters: queryParams);

    final response = await client.get(uri);

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }

    final data = jsonDecode(response.body);

    if (data is! List) {
      throw ApiException(response.statusCode, 'Formato inválido');
    }

    return data
        .map<TransportLineModel>(
            (e) => fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // =========================
  // GET BY VEHICLE TYPE (PUBLIC)
  // =========================
  Future<List<TransportLineModel>> getByVehicleType(int vehicleTypeId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/$endpoint/vehicle/$vehicleTypeId'),
    );

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }

    final data = jsonDecode(response.body);

    if (data is! List) {
      throw ApiException(response.statusCode, 'Formato inválido');
    }

    return data
        .map<TransportLineModel>(
            (e) => fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // =========================
  // GET ACTIVE WITH ROUTES (PUBLIC APP)
  // =========================
  Future<List<TransportLineModel>> getActiveWithRoutes() async {
    final response = await client.get(
      Uri.parse('$baseUrl/$endpoint/public/active-with-routes'),
    );

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }

    final data = jsonDecode(response.body);

    if (data is! List) {
      throw ApiException(response.statusCode, 'Formato inválido');
    }

    return data
        .map<TransportLineModel>(
          (e) => fromJson(Map<String, dynamic>.from(e)),
        )
        .toList();
  }

  // =========================
  // CREATE (ADMIN)
  // =========================
  Future<TransportLineModel> createLine(TransportLineModel model) async {
    final response = await request(
          () async => client.post(
        Uri.parse('$baseUrl/$endpoint'),
        headers: await headers(),
        body: jsonEncode(model.toJson()),
      ),
    );

    return fromJson(jsonDecode(response.body));
  }

  // =========================
  // UPDATE
  // =========================
  Future<TransportLineModel> updateLine(
      int id,
      Map<String, dynamic> updates,
      ) async {
    final response = await request(
          () async => client.put(
        Uri.parse('$baseUrl/$endpoint/$id'),
        headers: await headers(),
        body: jsonEncode(updates),
      ),
    );

    return fromJson(jsonDecode(response.body));
  }

  // =========================
  // ARCHIVE
  // =========================
  Future<void> archive(int id) async {
    await request(
          () async => client.patch(
        Uri.parse('$baseUrl/$endpoint/$id/archive'),
        headers: await headers(),
      ),
    );
  }

  // =========================
// GET BY IDS (PUBLIC)
// =========================
  Future<List<TransportLineModel>> getByIds(List<int> ids) async {
    if (ids.isEmpty) return [];

    final uri = Uri.parse('$baseUrl/$endpoint/batch').replace(
      queryParameters: {
        'ids': ids.join(','), // 👈 1,2,3
      },
    );

    final response = await client.get(uri);

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }

    final data = jsonDecode(response.body);

    if (data is! List) {
      throw ApiException(response.statusCode, 'Formato inválido');
    }

    return data
        .map<TransportLineModel>(
          (e) => fromJson(Map<String, dynamic>.from(e)),
    )
        .toList();
  }
}
