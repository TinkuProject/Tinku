import 'dart:convert';

import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:uuid/uuid.dart';

import '../config/config.dart';
import '../core/enums.dart';
import 'auth_service.dart';

class StripePaymentResult {
  final int paymentId;
  final String paymentIntentId;
  final double amount;
  final String currency;

  StripePaymentResult({
    required this.paymentId,
    required this.paymentIntentId,
    required this.amount,
    required this.currency,
  });
}

class StripePaymentService {
  StripePaymentService(this.authService);

  final AuthService authService;
  final String baseUrl = Config.baseUrl;

  Future<StripePaymentResult> pay({
    required PaymentType type,
    int? targetId,
    required String merchantDisplayName,
  }) async {
    if (Config.stripePublishableKey.isEmpty) {
      throw Exception('Stripe no está configurado en esta versión de la app.');
    }

    final intent = await _createPaymentIntent(
      type: type,
      targetId: targetId,
      clientRequestId: const Uuid().v4(),
    );

    final clientSecret = intent['clientSecret'];
    if (clientSecret is! String || clientSecret.isEmpty) {
      throw Exception('No se pudo iniciar el pago con Stripe.');
    }

    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: merchantDisplayName,
        billingDetails: const BillingDetails(
          address: Address(
            city: null,
            country: 'BO',
            line1: null,
            line2: null,
            postalCode: null,
            state: null,
          ),
        ),
      ),
    );

    try {
      await Stripe.instance.presentPaymentSheet();
    } catch (e) {
      await _cancelPaymentIntent(intent['paymentIntentId'] as String)
          .catchError((_) {});

      final isUserCancellation =
          e is StripeException && e.error.code.toString().contains('Canceled');
      if (isUserCancellation) {
        throw Exception('Pago cancelado.');
      }

      rethrow;
    }

    final payment = Map<String, dynamic>.from(intent['payment'] as Map);

    return StripePaymentResult(
      paymentId: payment['id'] as int,
      paymentIntentId: intent['paymentIntentId'] as String,
      amount: (intent['amount'] as num).toDouble(),
      currency: intent['currency'] as String,
    );
  }

  Future<Map<String, dynamic>> _createPaymentIntent({
    required PaymentType type,
    int? targetId,
    required String clientRequestId,
  }) async {
    final client = authService.client;
    final token = await authService.getValidAccessToken();

    final body = <String, dynamic>{
      'type': paymentTypeToString(type),
      'clientRequestId': clientRequestId,
      if (targetId != null) 'targetId': targetId,
    };

    final response = await client.post(
      Uri.parse('$baseUrl/stripe/payment-intents'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 201) {
      throw ApiException(response.statusCode, response.body);
    }

    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) {
      throw ApiException(response.statusCode, 'Formato inválido');
    }

    return data;
  }

  Future<void> _cancelPaymentIntent(String paymentIntentId) async {
    final client = authService.client;
    final token = await authService.getValidAccessToken();

    final response = await client.post(
      Uri.parse('$baseUrl/stripe/payment-intents/$paymentIntentId/cancel'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, response.body);
    }
  }
}
