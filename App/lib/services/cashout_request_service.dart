import 'dart:convert';

import '../config/config.dart';
import '../models/cashout_request_model.dart';
import 'auth_service.dart';

class CashoutRequestService {
  CashoutRequestService(this.authService);

  final AuthService authService;
  final String baseUrl = Config.baseUrl;

  Future<Map<String, String>> headers() async => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await authService.getValidAccessToken()}',
      };

  Future<List<CashoutRequestModel>> getMine() => _get('/cashout-requests/me');

  Future<List<CashoutRequestModel>> getPending() =>
      _get('/cashout-requests/pending');

  Future<CashoutRequestModel> create(int packageId, {String? comment}) async {
    final response = await authService.client.post(
      Uri.parse('$baseUrl/cashout-requests'),
      headers: await headers(),
      body: jsonEncode({
        'cashout_package_id': packageId,
        if (comment?.trim().isNotEmpty == true) 'comment': comment!.trim(),
      }),
    );
    _handle(response);
    return CashoutRequestModel.fromJson(jsonDecode(response.body));
  }

  Future<CashoutRequestModel> review(
    int id, {
    required bool approve,
    required String comment,
  }) async {
    final response = await authService.client.patch(
      Uri.parse(
        '$baseUrl/cashout-requests/$id/${approve ? 'approve' : 'reject'}',
      ),
      headers: await headers(),
      body: jsonEncode({'comment': comment.trim()}),
    );
    _handle(response);
    return CashoutRequestModel.fromJson(jsonDecode(response.body));
  }

  Future<List<CashoutRequestModel>> _get(String path) async {
    final response = await authService.client.get(
      Uri.parse('$baseUrl$path'),
      headers: await headers(),
    );
    _handle(response);
    return (jsonDecode(response.body) as List)
        .map((e) => CashoutRequestModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  void _handle(dynamic response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw ApiException(response.statusCode, response.body);
  }
}
