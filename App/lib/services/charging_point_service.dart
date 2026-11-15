import 'dart:convert';
import '../../models/charging_point_model.dart';
import 'base_service.dart';
import 'auth_service.dart';

class ChargingPointService extends BaseService<ChargingPointModel> {
  ChargingPointService(AuthService authService)
      : super("charging-points", authService);

  @override
  ChargingPointModel fromJson(Map<String, dynamic> json) {
    return ChargingPointModel.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(ChargingPointModel model) {
    return model.toJson();
  }

  // =========================
  // GET ACTIVE (PUBLIC)
  // =========================
  Future<List<ChargingPointModel>> getActive() async {
    final response = await client.get(
      Uri.parse('$baseUrl/$endpoint/active'),
    );

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }

    final data = jsonDecode(response.body);

    if (data is! List) {
      throw ApiException(response.statusCode, 'Formato inválido');
    }

    return data
        .map<ChargingPointModel>(
            (e) => fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // =========================
  // UPDATE (ADMIN)
  // =========================
  Future<ChargingPointModel> patchChargingPoint(
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
  // SOFT DELETE
  // =========================
  Future<void> softDelete(int id) async {
    await request(
          () async => client.patch(
        Uri.parse('$baseUrl/$endpoint/$id/softDelete'),
        headers: await headers(),
      ),
    );
  }
}