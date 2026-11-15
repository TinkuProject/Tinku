import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../../models/business_claim_request_model.dart';
import '../../core/enums.dart';
import 'api_http_client.dart';
import 'base_service.dart';
import 'auth_service.dart';

class BusinessClaimRequestService
    extends BaseService<BusinessClaimRequestModel> {

  BusinessClaimRequestService(AuthService authService)
      : super("business-claim-requests", authService);

  @override
  BusinessClaimRequestModel fromJson(Map<String, dynamic> json) {
    return BusinessClaimRequestModel.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(BusinessClaimRequestModel model) {
    return model.toJson();
  }

  // =========================
  // GET MINE
  // =========================
  Future<List<BusinessClaimRequestModel>> getMine() async {
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
        .map<BusinessClaimRequestModel>(
            (e) => fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // =========================
  // GET PENDING (ADMIN)
  // =========================
  Future<List<BusinessClaimRequestModel>> getPending() async {
    final response = await request(
          () async => client.get(
        Uri.parse('$baseUrl/$endpoint/pending'),
        headers: await headers(),
      ),
    );

    final data = jsonDecode(response.body);

    if (data is! List) {
      throw ApiException(response.statusCode, 'Formato inválido');
    }

    return data
        .map<BusinessClaimRequestModel>(
            (e) => fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<BusinessClaimRequestModel>> getAllAdmin() async {
    final response = await request(
      () async => client.get(
        Uri.parse('$baseUrl/$endpoint'),
        headers: await headers(),
      ),
    );

    final data = jsonDecode(response.body);

    if (data is! List) {
      throw ApiException(response.statusCode, 'Formato inválido');
    }

    return data
        .map<BusinessClaimRequestModel>(
          (e) => fromJson(Map<String, dynamic>.from(e)),
        )
        .toList();
  }

  // =========================
  // UPLOAD DOCUMENTS (PARTNER)
  // =========================
  Future<List<String>> uploadDocuments(List<PlatformFile> files) async {
    final uri = Uri.parse('$baseUrl/$endpoint/documents');
    final request = http.MultipartRequest('POST', uri);
    final token = await authService.getValidAccessToken();

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.headers[ApiHttpClient.timeoutSecondsHeader] = '90';

    for (final file in files) {
      if (file.path == null) continue;

      request.files.add(
        await http.MultipartFile.fromPath(
          'files',
          file.path!,
          filename: file.name,
        ),
      );
    }

    final streamedResponse = await client.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 201) {
      throw ApiException(response.statusCode, response.body);
    }

    final data = jsonDecode(response.body);
    return List<String>.from(data['urls'] ?? []);
  }

  // =========================
  // CREATE CLAIM (PARTNER)
  // =========================
  Future<BusinessClaimRequestModel> createClaim({
    required int businessId,
    required List<String> documents,
    String? comment,
  }) async {
    final response = await request(
          () async => client.post(
        Uri.parse('$baseUrl/$endpoint'),
        headers: await headers(),
        body: jsonEncode({
          'business_id': businessId,
          'documents': documents,
          if (comment?.trim().isNotEmpty == true)
            'comment': comment!.trim(),
        }),
      ),
    );

    return fromJson(jsonDecode(response.body));
  }

  // =========================
  // REVIEW
  // =========================
  Future<void> review(
      int id,
      ApprovalStatus status, {
        String? comment,
      }) async {
    await request(
          () async => client.patch(
        Uri.parse('$baseUrl/$endpoint/$id/review'),
        headers: await headers(),
        body: jsonEncode({
          "status": approvalStatusToString(status),
          "comment": comment,
        }),
      ),
    );
  }
}
