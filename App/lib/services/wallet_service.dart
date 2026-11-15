import 'dart:convert';
import '../../models/wallet_model.dart';
import 'base_service.dart';
import 'auth_service.dart';

class WalletService extends BaseService<WalletModel> {
  WalletService(AuthService authService)
      : super("wallets", authService);

  @override
  WalletModel fromJson(Map<String, dynamic> json) {
    return WalletModel.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(WalletModel model) {
    return model.toJson();
  }

  // =========================
  // GET MY WALLET
  // =========================
  Future<WalletModel?> getMyWallet() async {
    final response = await request(
          () async => client.get(
        Uri.parse('$baseUrl/$endpoint/me'),
        headers: await headers(),
      ),
    );

    if (response.statusCode == 404) return null;

    return fromJson(jsonDecode(response.body));
  }
}