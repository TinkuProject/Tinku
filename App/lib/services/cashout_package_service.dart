import 'dart:convert';
import '../../models/cashout_package_model.dart';
import 'base_service.dart';
import 'auth_service.dart';

class CashoutPackageService extends BaseService<CashoutPackageModel> {
  CashoutPackageService(AuthService authService)
      : super("cashout-packages", authService);

  @override
  CashoutPackageModel fromJson(Map<String, dynamic> json) {
    return CashoutPackageModel.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(CashoutPackageModel model) {
    return model.toJson();
  }

  // =========================
  // GET ACTIVE BY ID (PUBLIC)
  // =========================
  Future<CashoutPackageModel?> getActiveById(int id) async {
    final response = await client.get(
      Uri.parse('$baseUrl/$endpoint/$id/active'),
    );

    if (response.statusCode == 404) return null;

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }

    return fromJson(jsonDecode(response.body));
  }

  // =========================
  // ADMIN - GET ALL
  // =========================
  Future<List<CashoutPackageModel>> getAllAdmin() async {
    final response = await request(
          () async => client.get(
        Uri.parse('$baseUrl/$endpoint/admin'),
        headers: await headers(),
      ),
    );

    final data = jsonDecode(response.body);

    if (data is! List) {
      throw ApiException(response.statusCode, 'Formato inválido');
    }

    return data
        .map<CashoutPackageModel>(
            (e) => fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // =========================
  // ACTIVATE / DEACTIVATE
  // =========================
  Future<void> activate(int id) async {
    await request(
          () async => client.patch(
        Uri.parse('$baseUrl/$endpoint/$id/activate'),
        headers: await headers(),
      ),
    );
  }

  Future<void> deactivate(int id) async {
    await request(
          () async => client.patch(
        Uri.parse('$baseUrl/$endpoint/$id/deactivate'),
        headers: await headers(),
      ),
    );
  }

  Future<void> softDelete(int id) async {
    await request(
          () async => client.patch(
        Uri.parse('$baseUrl/$endpoint/$id/softDelete'),
        headers: await headers(),
      ),
    );
  }
}