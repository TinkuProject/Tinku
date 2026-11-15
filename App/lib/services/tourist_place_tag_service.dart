import 'dart:convert';
import '../../models/tourist_place_tag_model.dart';
import '../models/tag_model.dart';
import 'base_service.dart';
import 'auth_service.dart';

class TouristPlaceTagService
    extends BaseService<TouristPlaceTagModel> {
  TouristPlaceTagService(AuthService authService)
      : super("tourist-place-tags", authService);

  @override
  TouristPlaceTagModel fromJson(Map<String, dynamic> json) {
    return TouristPlaceTagModel.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(TouristPlaceTagModel model) {
    return model.toJson();
  }

  // =========================
  // GET BY PLACE (PUBLIC)
  // =========================
  Future<List<TagModel>> getByPlace(int placeId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/$endpoint/place/$placeId'),
    );

    final data = jsonDecode(response.body);

    return data
        .map<TagModel>((e) => TagModel.fromJson(e))
        .toList();
  }

  // =========================
  // GET BY TAG (PUBLIC)
  // =========================
  Future<List<TouristPlaceTagModel>> getByTag(int tagId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/$endpoint/tag/$tagId'),
    );

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }

    final data = jsonDecode(response.body);

    if (data is! List) {
      throw ApiException(response.statusCode, 'Formato inválido');
    }

    return data
        .map<TouristPlaceTagModel>(
            (e) => fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // =========================
  // CREATE
  // =========================
  Future<void> createTag(TouristPlaceTagModel model) async {
    await request(
          () async => client.post(
        Uri.parse('$baseUrl/$endpoint'),
        headers: await headers(),
        body: jsonEncode(model.toJson()),
      ),
    );
  }

  // =========================
  // REPLACE ALL TAGS
  // =========================
  Future<void> replaceTags(
      int placeId,
      List<int> tagIds,
      ) async {
    await request(
          () async => client.put(
        Uri.parse('$baseUrl/$endpoint/place/$placeId'),
        headers: await headers(),
        body: jsonEncode({
          "tag_ids": tagIds,
        }),
      ),
    );
  }

  // =========================
  // DELETE ONE
  // =========================
  Future<void> deleteTag({
    required int placeId,
    required int tagId,
  }) async {
    await request(
          () async => client.delete(
        Uri.parse('$baseUrl/$endpoint/$placeId/$tagId'),
        headers: await headers(),
      ),
    );
  }
}