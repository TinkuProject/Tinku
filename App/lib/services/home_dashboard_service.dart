import 'dart:convert';

import '../config/config.dart';
import '../models/home_dashboard_model.dart';
import 'auth_service.dart';

class HomeDashboardService {
  HomeDashboardService(this.authService);

  final AuthService authService;

  Future<HomeDashboardModel> getSummary() async {
    final token = await authService.getValidAccessToken();
    final response = await authService.client.get(
      Uri.parse('${Config.baseUrl}/home-dashboard'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(response.statusCode, response.body);
    }

    return HomeDashboardModel.fromJson(
      Map<String, dynamic>.from(jsonDecode(response.body) as Map),
    );
  }
}
