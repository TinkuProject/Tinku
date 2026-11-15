import 'dart:convert';
import '../../models/financial_transaction_model.dart';
import 'base_service.dart';
import 'auth_service.dart';

class FinancialTransactionService
    extends BaseService<FinancialTransactionModel> {
  FinancialTransactionService(AuthService authService)
      : super("financial-transactions", authService);

  @override
  FinancialTransactionModel fromJson(Map<String, dynamic> json) {
    return FinancialTransactionModel.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(FinancialTransactionModel model) {
    return model.toJson();
  }

  // =========================
  // GET MINE
  // =========================
  Future<List<FinancialTransactionModel>> getMine() async {
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
        .map<FinancialTransactionModel>(
            (e) => fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<FinancialTransactionModel>> getLatest() async {
    final response = await request(
          () async => client.get(
        Uri.parse('$baseUrl/$endpoint/me/latest'),
        headers: await headers(),
      ),
    );

    final data = jsonDecode(response.body);

    if (data is! List) {
      throw ApiException(response.statusCode, 'Formato inválido');
    }

    return data
        .map<FinancialTransactionModel>(
          (e) => fromJson(Map<String, dynamic>.from(e)),
    )
        .toList();
  }
}