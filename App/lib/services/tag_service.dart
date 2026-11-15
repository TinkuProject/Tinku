import 'dart:convert';
import '../../models/tag_model.dart';
import 'base_service.dart';
import 'auth_service.dart';

class TagService extends BaseService<TagModel> {
  TagService(AuthService authService)
      : super("tags", authService);

  @override
  TagModel fromJson(Map<String, dynamic> json) {
    return TagModel.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(TagModel model) {
    return model.toJson();
  }

  // =========================
  // GET BY ID (PUBLIC)
  // =========================
  @override
  Future<TagModel?> getById(dynamic id) async {
    final response = await client.get(
      Uri.parse('$baseUrl/$endpoint/$id'),
    );

    if (response.statusCode == 404) return null;

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }

    return fromJson(jsonDecode(response.body));
  }

  // =========================
  // UPDATE (PUT)
  // =========================
  Future<TagModel> updateTag(
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
  // SOFT DELETE
  // =========================
  Future<void> softDelete(int id) async {
    await request(
          () async => client.put(
        Uri.parse('$baseUrl/$endpoint/$id/soft-delete'),
        headers: await headers(),
      ),
    );
  }
}