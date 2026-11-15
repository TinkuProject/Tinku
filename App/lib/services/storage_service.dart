import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:tinkuapp/core/enums.dart';

import '../config/config.dart';
import 'api_http_client.dart';
import 'auth_service.dart';

class StorageService {
  final String baseUrl = Config.baseUrl;
  final AuthService authService;

  StorageService(this.authService);

  // =========================
  // UPLOAD FILES
  // =========================
  Future<List<String>> uploadFiles({
    required MediaEntityType entityType,
    required dynamic entityId,
    required List<XFile> files,
    required String uploadMode, // direct | storage_only
  }) async {
    final uri = Uri.parse('$baseUrl/storage/upload');
    final request = http.MultipartRequest('POST', uri);

    final token = await authService.getValidAccessToken();

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.headers[ApiHttpClient.timeoutSecondsHeader] = '90';

    request.fields['entityType'] = mediaEntityTypeToString(entityType);
    request.fields['entityId'] = entityId.toString();
    request.fields['uploadMode'] = uploadMode;

    for (final file in files) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'files',
          file.path,
          filename: file.name,
        ),
      );
    }

    final streamedResponse = await authService.client.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 201) {
      throw ApiException(response.statusCode, response.body);
    }

    final data = jsonDecode(response.body);
    return List<String>.from(data['urls']);
  }

  // =========================
  // SINGLE FILE
  // =========================
  Future<String> uploadSingleFile({
    required MediaEntityType entityType,
    required dynamic entityId,
    required XFile file,
    String uploadMode = 'direct',
  }) async {
    final urls = await uploadFiles(
      entityType: entityType,
      entityId: entityId,
      files: [file],
      uploadMode: uploadMode,
    );
    return urls.first;
  }

  // =========================
  // DELETE FILE
  // =========================
  Future<void> deleteFile(int mediaId) async {
    final token = await authService.getValidAccessToken();

    final response = await authService.client.delete(
      Uri.parse('$baseUrl/storage/delete'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'mediaId': mediaId}),
    );

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
  }

  // =========================
  // DELETE ENTITY MEDIA
  // =========================
  Future<void> deleteEntityMedia({
    required MediaEntityType entityType,
    required dynamic entityId,
  }) async {
    final token = await authService.getValidAccessToken();

    final response = await authService.client.delete(
      Uri.parse('$baseUrl/storage/entity'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'entityType': mediaEntityTypeToString(entityType),
        'entityId': entityId,
      }),
    );

    if (response.statusCode != 200) {
      throw ApiException(
        response.statusCode,
        response.body,
      );
    }
  }
}
