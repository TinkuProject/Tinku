import 'dart:convert';
import '../../models/tourist_place_model.dart';
import 'base_service.dart';
import 'auth_service.dart';

class TouristPlaceService extends BaseService<TouristPlaceModel> {
  TouristPlaceService(AuthService authService)
      : super("tourist-places", authService);

  @override
  TouristPlaceModel fromJson(Map<String, dynamic> json) {
    return TouristPlaceModel.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(TouristPlaceModel model) {
    return model.toJson();
  }

  // =========================
  // GET ALL (PUBLIC)
  // =========================
  @override
  Future<List<TouristPlaceModel>> getAll({
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
        .map<TouristPlaceModel>(
            (e) => fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // =========================
  // GET BY CATEGORY (PUBLIC)
  // =========================
  Future<List<TouristPlaceModel>> getByCategory(int categoryId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/$endpoint/category/$categoryId'),
    );

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }

    final data = jsonDecode(response.body);

    if (data is! List) {
      throw ApiException(response.statusCode, 'Formato inválido');
    }

    return data
        .map<TouristPlaceModel>(
            (e) => fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<TouristPlaceModel>> getPreviewList({
    int limit = 20,
    int offset = 0,
  }) async {
    final uri = Uri.parse('$baseUrl/$endpoint/list').replace(
      queryParameters: {
        'limit': '$limit',
        'offset': '$offset',
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
        .map<TouristPlaceModel>((e) => fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<TouristPlaceModel>> getMine({
    int limit = 20,
    int offset = 0,
  }) async {
    final uri = Uri.parse('$baseUrl/$endpoint/mine').replace(
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
        .map<TouristPlaceModel>((e) => fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // =========================
  // GET BY IDS (BATCH)
  // =========================
  Future<List<TouristPlaceModel>> getByIds(List<int> ids) async {
    if (ids.isEmpty) return [];

    final uri = Uri.parse('$baseUrl/$endpoint/batch').replace(
      queryParameters: {
        'ids': ids.join(','),
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
        .map<TouristPlaceModel>((e) => fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // =========================
  // CREATE (ADMIN)
  // =========================
  Future<TouristPlaceModel> createPlace(TouristPlaceModel model) async {
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
  // UPDATE (ADMIN)
  // =========================
  Future<TouristPlaceModel> updatePlace(
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
  // ARCHIVE (SOFT DELETE)
  // =========================
  Future<void> archive(int id) async {
    await request(
          () async => client.patch(
        Uri.parse('$baseUrl/$endpoint/$id/archive'),
        headers: await headers(),
      ),
    );
  }
}
