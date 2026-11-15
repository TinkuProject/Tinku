import 'dart:convert';
import '../../models/payment_request_model.dart';
import 'base_service.dart';
import 'auth_service.dart';

class PaymentRequestService extends BaseService<PaymentRequestModel> {
  PaymentRequestService(AuthService authService)
      : super("payment-requests", authService);

  @override
  PaymentRequestModel fromJson(Map<String, dynamic> json) {
    return PaymentRequestModel.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(PaymentRequestModel model) {
    return model.toJson();
  }

  // =========================
  // CREATE (USER)
  // =========================
  Future<void> createRequest(PaymentRequestModel model) async {
    await request(
      () async => client.post(
        Uri.parse('$baseUrl/$endpoint'),
        headers: await headers(),
        body: jsonEncode(model.toJson()),
      ),
    );
  }

  // =========================
  // GET MINE
  // =========================
  Future<List<PaymentRequestModel>> getMine() async {
    final response = await request(
      () async => client.get(
        Uri.parse('$baseUrl/$endpoint/me'),
        headers: await headers(),
      ),
    );

    final data = jsonDecode(response.body);

    if (data is! List) {
      throw ApiException(response.statusCode, 'Formato inválido');
    }

    return data
        .map<PaymentRequestModel>(
          (e) => fromJson(Map<String, dynamic>.from(e)),
        )
        .toList();
  }

  // =========================
  // HAS PENDING PARTNER UPGRADE
  // =========================
  Future<bool> hasPendingPartnerUpgrade() async {
    final response = await request(
      () async => client.get(
        Uri.parse('$baseUrl/$endpoint/mine/partner-upgrade/pending'),
        headers: await headers(),
      ),
    );

    final data = jsonDecode(response.body);

    if (data is! Map<String, dynamic>) {
      throw ApiException(response.statusCode, 'Formato inválido');
    }

    return data['hasPending'] == true;
  }

  // =========================
  // APPROVE
  // =========================
  Future<void> approve(int id) async {
    await request(
      () async => client.patch(
        Uri.parse('$baseUrl/$endpoint/$id/approve'),
        headers: await headers(),
      ),
    );
  }

  // =========================
  // REJECT
  // =========================
  Future<void> reject(int id, {String? comment}) async {
    await request(
      () async => client.patch(
        Uri.parse('$baseUrl/$endpoint/$id/reject'),
        headers: await headers(),
        body: jsonEncode({
          if (comment != null) "comment": comment,
        }),
      ),
    );
  }
}
