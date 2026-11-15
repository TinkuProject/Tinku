import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/enums.dart';
import '../../models/payment_model.dart';
import '../../models/payment_request_model.dart';
import '../../models/subscription_plan_model.dart';
import '../../models/user_model.dart';
import '../../services/media_service.dart';
import '../../services/payment_request_service.dart';
import '../../services/payment_service.dart';
import '../../services/stripe_payment_service.dart';
import '../../services/storage_service.dart';
import '../../services/subscription_plan_service.dart';

class SubscriptionsController extends ChangeNotifier {
  SubscriptionsController({
    required this.planService,
    required this.paymentService,
    required this.paymentRequestService,
    required this.storageService,
    required this.mediaService,
    required this.stripePaymentService,
  });

  final SubscriptionPlanService planService;
  final PaymentService paymentService;
  final PaymentRequestService paymentRequestService;
  final StorageService storageService;
  final MediaService mediaService;
  final StripePaymentService stripePaymentService;

  bool loading = false;
  bool saving = false;

  List<SubscriptionPlanModel> plans = [];
  List<SubscriptionPlanModel> visiblePlans = [];

  String? selectedPlanId;
  File? receiptFile;

  final Map<String, String?> _qrCache = {};

  SubscriptionPlanModel? get selectedPlan {
    if (selectedPlanId == null) return null;

    for (final plan in visiblePlans) {
      if (plan.id.toString() == selectedPlanId) return plan;
    }
    return null;
  }

  String? get selectedQrUrl {
    final plan = selectedPlan;
    if (plan == null) return null;
    return _qrCache[plan.id.toString()];
  }

  bool get canSubmit => selectedPlan != null && receiptFile != null && !saving;
  bool get canPayWithStripe => selectedPlan != null && !saving;

  Future<void> loadPlans() async {
    loading = true;
    notifyListeners();

    try {
      plans = await planService.getAll();
      _qrCache.clear();

      plans.sort((a, b) {
        if (_isAnniversary(a)) return -1;
        if (_isAnniversary(b)) return 1;
        return a.price.compareTo(b.price);
      });

      await Future.wait(
        plans.map((plan) async {
          try {
            final mediaList = await mediaService.getByEntity(
              entityId: plan.id.toString(),
              entityType: MediaEntityType.subscription,
            );

            _qrCache[plan.id.toString()] =
            mediaList.isNotEmpty ? mediaList.first.url : null;
          } catch (_) {
            _qrCache[plan.id.toString()] = null;
          }
        }),
      );

      visiblePlans = List<SubscriptionPlanModel>.from(plans);

      selectedPlanId = visiblePlans.isNotEmpty
          ? visiblePlans.first.id.toString()
          : null;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> selectPlan(String planId) async {
    if (selectedPlanId == planId) return;
    selectedPlanId = planId;
    notifyListeners();
  }

  void setReceiptFile(File? file) {
    receiptFile = file;
    notifyListeners();
  }

  void clearReceipt() {
    receiptFile = null;
    notifyListeners();
  }

  Future<void> buy(UserModel user) async {
    final plan = selectedPlan;

    if (plan == null) {
      throw Exception('No hay plan seleccionado.');
    }

    if (receiptFile == null) {
      throw Exception('Debes subir tu comprobante antes de continuar.');
    }

    saving = true;
    notifyListeners();

    try {
      final payment = await paymentService.createPayment(
        CreatePaymentModel(
          amount: plan.price,
          method: PaymentMethod.qr,
          type: PaymentType.subscription,
        ),
      );

      await storageService.uploadSingleFile(
        entityId: payment.id,
        entityType: MediaEntityType.payment,
        file: XFile(receiptFile!.path),
      );

      await paymentRequestService.createRequest(
        PaymentRequestModel(
          id: 0,
          userId: user.id,
          paymentId: payment.id,
          type: PaymentType.subscription,
          targetId: plan.id,
          status: ApprovalStatus.pending,
          createdAt: DateTime.now(),
        ),
      );
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<void> payWithStripe() async {
    final plan = selectedPlan;

    if (plan == null) {
      throw Exception('No hay plan seleccionado.');
    }

    saving = true;
    notifyListeners();

    try {
      await stripePaymentService.pay(
        type: PaymentType.subscription,
        targetId: plan.id,
        merchantDisplayName: 'Tinku',
      );
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  bool _isAnniversary(SubscriptionPlanModel plan) {
    return plan.name.toLowerCase().contains('aniversario');
  }
}
