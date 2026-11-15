import 'dart:convert';
import '../../models/user_subscription_model.dart';
import 'base_service.dart';
import 'auth_service.dart';

class UserSubscriptionService extends BaseService<UserSubscriptionModel> {
  UserSubscriptionService(AuthService authService)
      : super("user-subscriptions", authService);

  @override
  UserSubscriptionModel fromJson(Map<String, dynamic> json) {
    return UserSubscriptionModel.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(UserSubscriptionModel model) {
    return model.toJson();
  }

  // =========================
  // GET BY USER
  // =========================
  Future<List<UserSubscriptionModel>> getByUser(String userId) async {
    final response = await request(
          () async => client.get(
        Uri.parse('$baseUrl/$endpoint/user/$userId'),
        headers: await headers(),
      ),
    );

    final data = jsonDecode(response.body);

    return (data as List)
        .map((e) => fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<UserSubscriptionModel?> getCurrent() async {
    final response = await request(
          () async => client.get(
        Uri.parse('$baseUrl/$endpoint/me/current'),
        headers: await headers(),
      ),
    );

    if (response.statusCode == 204) return null;

    return fromJson(jsonDecode(response.body));
  }

  // =========================
  // CANCEL
  // =========================
  Future<void> cancel(int id) async {
    await request(
          () async => client.patch(
        Uri.parse('$baseUrl/$endpoint/$id/cancel'),
        headers: await headers(),
      ),
    );
  }

  // =========================
  // UPDATE
  // =========================
  Future<UserSubscriptionModel> updateSubscription(
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
}