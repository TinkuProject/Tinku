import 'dart:convert';
import '../../models/payment_model.dart';
import 'base_service.dart';
import 'auth_service.dart';

class PaymentService extends BaseService<PaymentModel> {
  PaymentService(AuthService authService)
      : super("payments", authService);

  @override
  PaymentModel fromJson(Map<String, dynamic> json) {
    return PaymentModel.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(PaymentModel model) {
    return model.toJson();
  }

  Future<PaymentModel> createPayment(CreatePaymentModel model) async {
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
  // GET MINE
  // =========================
  Future<List<PaymentModel>> getMine() async {
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
        .map<PaymentModel>(
            (e) => fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // =========================
  // SOFT DELETE
  // =========================
  Future<void> softDelete(int id) async {
    await request(
          () async => client.patch(
        Uri.parse('$baseUrl/$endpoint/$id'),
        headers: await headers(),
      ),
    );
  }
}