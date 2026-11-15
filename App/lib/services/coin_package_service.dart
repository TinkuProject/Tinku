import 'dart:convert';
import '../../models/coin_package_model.dart';
import 'base_service.dart';
import 'auth_service.dart';

class CoinPackageService extends BaseService<CoinPackageModel> {
  CoinPackageService(AuthService authService)
      : super("coin-packages", authService);

  @override
  CoinPackageModel fromJson(Map<String, dynamic> json) {
    return CoinPackageModel.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(CoinPackageModel model) {
    return model.toJson();
  }

  // =========================
  // GET ACTIVE BY ID (PUBLIC)
  // =========================
  Future<CoinPackageModel?> getActiveById(int id) async {
    final response = await client.get(
      Uri.parse('$baseUrl/$endpoint/$id/active'),
    );

    if (response.statusCode == 404) return null;

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }

    return fromJson(jsonDecode(response.body));
  }

  Future<CoinPackageModel?> getBasic() async {
    final response = await client.get(
      Uri.parse('$baseUrl/$endpoint/basic'),
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
  Future<List<CoinPackageModel>> getAllAdmin() async {
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
        .map<CoinPackageModel>(
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