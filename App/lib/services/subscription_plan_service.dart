import 'dart:convert';
import '../../models/subscription_plan_model.dart';
import 'base_service.dart';
import 'auth_service.dart';

class SubscriptionPlanService extends BaseService<SubscriptionPlanModel> {
  SubscriptionPlanService(AuthService authService)
      : super("subscription-plans", authService);

  @override
  SubscriptionPlanModel fromJson(Map<String, dynamic> json) {
    return SubscriptionPlanModel.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(SubscriptionPlanModel model) {
    return model.toJson();
  }

  // =========================
  // GET BY ID (PUBLIC)
  // =========================
  @override
  Future<SubscriptionPlanModel?> getById(dynamic id) async {
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
  // UPDATE
  // =========================
  Future<SubscriptionPlanModel> updatePlan(
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