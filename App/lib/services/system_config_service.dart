import 'dart:convert';
import '../models/system_config_model.dart';
import 'auth_service.dart';
import 'base_service.dart';

class SystemConfigService extends BaseService<SystemConfigModel> {
  SystemConfigService(AuthService authService)
      : super("system-config", authService);

  @override
  SystemConfigModel fromJson(Map<String, dynamic> json) {
    return SystemConfigModel.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(SystemConfigModel model) {
    return model.toJson();
  }

  Future<double> getNumberByKey(String key) async {
    final response = await request(
          () async => client.get(
        Uri.parse('$baseUrl/$endpoint/public/$key'),
        headers: await headers(),
      ),
    );

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }

    final data = fromJson(jsonDecode(response.body));

    if (data.value == null) {
      throw ApiException(
        response.statusCode,
        'Config not found',
      );
    }

    if (data.value is num) {
      return (data.value as num).toDouble();
    }

    return double.parse(data.value.toString());
  }

  Future<double> getBoostCreateCost() {
    return getNumberByKey('boost_create_cost');
  }

  Future<double> getDiscountCreateCost() {
    return getNumberByKey('discount_create_cost');
  }

  Future<double> getBusinessCreateCost() {
    return getNumberByKey('business_create_cost');
  }
}
