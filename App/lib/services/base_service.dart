import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/config.dart';
import 'api_http_client.dart';
import 'auth_service.dart';

abstract class BaseService<T> {
  final String baseUrl = Config.baseUrl;
  final String endpoint;
  final AuthService authService;
  final http.Client client;

  BaseService(
    this.endpoint,
    this.authService, {
    http.Client? client,
  }) : client = client ?? ApiHttpClient();

  T fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson(T model);

  // =========================
  // HEADERS
  // =========================
  Future<Map<String, String>> headers() async {
    final token = await authService.getValidAccessToken();

    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  void _handleError(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;

    throw ApiException(response.statusCode, response.body);
  }

  Future<http.Response> request(
    Future<http.Response> Function() call,
  ) async {
    final response = await call();
    _handleError(response);
    return response;
  }

  // =========================
  // GET ALL
  // =========================
  Future<List<T>> getAll({Map<String, String>? queryParams}) async {
    final uri =
        Uri.parse('$baseUrl/$endpoint').replace(queryParameters: queryParams);

    final response = await request(
      () async => client.get(uri, headers: await headers()),
    );

    final decoded = jsonDecode(response.body);

    if (decoded is! List) {
      throw ApiException(response.statusCode, 'Formato inválido');
    }

    return decoded
        .map<T>((e) => fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // =========================
  // GET BY ID
  // =========================
  Future<T?> getById(dynamic id) async {
    final response = await client.get(
      Uri.parse('$baseUrl/$endpoint/$id'),
      headers: await headers(),
    );

    if (response.statusCode == 404) return null;
    _handleError(response);

    return fromJson(jsonDecode(response.body));
  }

  // =========================
  // CREATE
  // =========================
  Future<T> create(T model) async {
    final response = await request(
      () async => client.post(
        Uri.parse('$baseUrl/$endpoint'),
        headers: await headers(),
        body: jsonEncode(toJson(model)),
      ),
    );

    final decoded = jsonDecode(response.body);
    return _parseSingle(decoded);
  }

  // =========================
  // UPDATE
  // =========================
  Future<T> update(dynamic id, Map<String, dynamic> updates) async {
    final response = await request(
      () async => client.put(
        Uri.parse('$baseUrl/$endpoint/$id'),
        headers: await headers(),
        body: jsonEncode(updates),
      ),
    );

    final decoded = jsonDecode(response.body);
    return _parseSingle(decoded);
  }

  // =========================
  // DELETE
  // =========================
  Future<void> delete(dynamic id) async {
    await request(
      () async => client.delete(
        Uri.parse('$baseUrl/$endpoint/$id'),
        headers: await headers(),
      ),
    );
  }

  // =========================
  // DELETE ALL
  // =========================
  Future<void> deleteAll({Map<String, String>? queryParams}) async {
    final uri =
        Uri.parse('$baseUrl/$endpoint').replace(queryParameters: queryParams);

    await request(
      () async => client.delete(uri, headers: await headers()),
    );
  }

  // =========================
  // HELPER
  // =========================
  T _parseSingle(dynamic decoded) {
    if (decoded is List && decoded.isNotEmpty) {
      return fromJson(Map<String, dynamic>.from(decoded[0]));
    }

    if (decoded is Map<String, dynamic>) {
      return fromJson(decoded);
    }

    throw ApiException(500, 'Formato inválido');
  }
}
