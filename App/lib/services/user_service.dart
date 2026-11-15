import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../../models/user_model.dart';
import 'api_http_client.dart';
import 'base_service.dart';
import 'auth_service.dart';

class UserService extends BaseService<UserModel> {
  UserService(AuthService authService) : super("users", authService);

  @override
  UserModel fromJson(Map<String, dynamic> json) {
    return UserModel.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(UserModel model) {
    return model.toJson();
  }

  Future<Map<String, UserModel>> getByIds(List<String> ids) async {
    if (ids.isEmpty) return {};

    final uniqueIds = ids.toSet().toList();
    final uri = Uri.parse('$baseUrl/$endpoint/batch').replace(
      queryParameters: {
        'ids': uniqueIds.join(','),
      },
    );

    final response = await request(
      () async => client.get(uri, headers: await headers()),
    );

    final data = jsonDecode(response.body);

    if (data is! List) {
      throw ApiException(response.statusCode, 'Formato inválido');
    }

    final users = data
        .map<UserModel>((e) => fromJson(Map<String, dynamic>.from(e)))
        .toList();

    return {for (final user in users) user.id: user};
  }

  // =========================
  // PROFILE PICTURE (GET)
  // =========================
  Future<String?> getProfilePicture() async {
    final response = await request(
      () async => client.get(
        Uri.parse('$baseUrl/$endpoint/me/profile-picture'),
        headers: await headers(),
      ),
    );

    final data = jsonDecode(response.body);
    return data['url'];
  }

  // =========================
  // PROFILE PICTURE (UPLOAD)
  // =========================
  Future<String> uploadProfilePicture(File file) async {
    final uri = Uri.parse('$baseUrl/$endpoint/me/profile-picture');

    final request = http.MultipartRequest("POST", uri);

    request.files.add(
      await http.MultipartFile.fromPath('file', file.path),
    );

    final authHeaders = await headers();
    request.headers.addAll(authHeaders);
    request.headers[ApiHttpClient.timeoutSecondsHeader] = '90';

    final response = await client.send(request);
    final respStr = await response.stream.bytesToString();

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException(response.statusCode, respStr);
    }

    final data = jsonDecode(respStr);
    return data['url'];
  }

  Future<UserModel> updateMe(Map<String, dynamic> updates) async {
    final response = await request(
      () async => client.put(
        Uri.parse('$baseUrl/$endpoint/me'),
        headers: await headers(),
        body: jsonEncode(updates),
      ),
    );

    return fromJson(jsonDecode(response.body));
  }

  // =========================
  // FETCH CURRENT USER
  // =========================
  Future<UserModel> fetchById(String userId) async {
    final response = await request(
      () async => client.get(
        Uri.parse('$baseUrl/$endpoint/$userId'),
        headers: await headers(),
      ),
    );

    return fromJson(jsonDecode(response.body));
  }
}
