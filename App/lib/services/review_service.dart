import 'dart:convert';
import '../../models/review_model.dart';
import '../../core/enums.dart';
import 'base_service.dart';
import 'auth_service.dart';

class ReviewService extends BaseService<ReviewModel> {
  ReviewService(AuthService authService)
      : super("reviews", authService);

  @override
  ReviewModel fromJson(Map<String, dynamic> json) {
    return ReviewModel.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(ReviewModel model) {
    return model.toJson();
  }

  // =========================
  // GET BY ENTITY (PUBLIC)
  // =========================
  Future<List<ReviewModel>> getByEntity({
    required ReviewEntityType entityType,
    required int entityId,
  }) async {
    final response = await client.get(
      Uri.parse(
        '$baseUrl/$endpoint/entity/${reviewEntityTypeToString(entityType)}/$entityId',
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
        .map<ReviewModel>(
            (e) => fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // =========================
  // GET BY ENTITIES (BATCH)
  // =========================
  Future<Map<int, List<ReviewModel>>> getByEntities({
    required ReviewEntityType entityType,
    required List<int> entityIds,
  }) async {
    if (entityIds.isEmpty) return {};

    final uri = Uri.parse('$baseUrl/$endpoint/entities').replace(
      queryParameters: {
        'entity_type': reviewEntityTypeToString(entityType),
        'entity_ids': entityIds.join(','), // "1,2,3"
      },
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
  // GET MINE
  // =========================
  Future<List<ReviewModel>> getMine() async {
    final response = await request(
          () async => client.get(
        Uri.parse('$baseUrl/$endpoint/my'),
        headers: await headers(),
      ),
    );

    final data = jsonDecode(response.body);

    if (data is! List) {
      throw ApiException(response.statusCode, 'Formato inválido');
    }

    return data
        .map<ReviewModel>(
            (e) => fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<ReviewModel>> getManaged() async {
    final response = await request(
      () async => client.get(
        Uri.parse('$baseUrl/$endpoint/managed'),
        headers: await headers(),
      ),
    );

    final data = jsonDecode(response.body);

    if (data is! List) {
      throw ApiException(response.statusCode, 'Formato inválido');
    }

    return data
        .map<ReviewModel>((e) => fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<ReviewModel> replyToReview({
    required int reviewId,
    required String reply,
  }) async {
    final response = await request(
      () async => client.patch(
        Uri.parse('$baseUrl/$endpoint/$reviewId/reply'),
        headers: await headers(),
        body: jsonEncode({'reply': reply}),
      ),
    );

    return fromJson(jsonDecode(response.body));
  }

  // =========================
  // UPDATE
  // =========================
  Future<ReviewModel> updateReview(
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
  // DELETE (SOFT)
  // =========================
  Future<void> deleteReview(int id) async {
    await request(
          () async => client.delete(
        Uri.parse('$baseUrl/$endpoint/$id'),
        headers: await headers(),
      ),
    );
  }
}
