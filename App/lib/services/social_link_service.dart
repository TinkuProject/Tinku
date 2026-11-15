import 'dart:convert';
import '../../models/social_link_model.dart';
import 'base_service.dart';
import 'auth_service.dart';

class SocialLinkService extends BaseService<SocialLinkModel> {
  SocialLinkService(AuthService authService)
      : super("social-links", authService);

  @override
  SocialLinkModel fromJson(Map<String, dynamic> json) {
    return SocialLinkModel.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(SocialLinkModel model) {
    return model.toJson();
  }

  // =========================
  // GET BY BUSINESS
  // =========================
  Future<List<SocialLinkModel>> getByBusiness(int businessId) async {
    final response = await request(
          () async => client.get(
        Uri.parse('$baseUrl/$endpoint/business/$businessId'),
        headers: await headers(),
      ),
    );

    final data = jsonDecode(response.body);

    if (data is! List) {
      throw ApiException(response.statusCode, 'Formato inválido');
    }

    return data
        .map<SocialLinkModel>(
            (e) => fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Map<int, List<SocialLinkModel>>> getByBusinesses(
    List<int> businessIds,
  ) async {
    if (businessIds.isEmpty) return {};

    final uniqueIds = businessIds.toSet().toList();
    final uri = Uri.parse('$baseUrl/$endpoint/businesses').replace(
      queryParameters: {
        'business_ids': uniqueIds.join(','),
      },
    );

    final response = await request(
      () async => client.get(uri, headers: await headers()),
    );

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
  // UPDATE
  // =========================
  Future<SocialLinkModel> updateLink(
      int id,
      Map<String, dynamic> updates,
      ) async {
    final response = await request(
          () async => client.patch(
        Uri.parse('$baseUrl/$endpoint/$id'),
        headers: await headers(),
        body: jsonEncode(updates),
      ),
    );

    return fromJson(jsonDecode(response.body));
  }

  // =========================
  // DELETE
  // =========================
  Future<void> deleteLink(int id) async {
    await request(
          () async => client.delete(
        Uri.parse('$baseUrl/$endpoint/$id'),
        headers: await headers(),
      ),
    );
  }
}
