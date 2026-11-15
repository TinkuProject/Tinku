import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/enums.dart';
import '../../models/coin_package_model.dart';
import '../../models/payment_model.dart';
import '../../models/payment_request_model.dart';
import '../../models/user_model.dart';
import '../../services/coin_package_service.dart';
import '../../services/media_service.dart';
import '../../services/payment_request_service.dart';
import '../../services/payment_service.dart';
import '../../services/stripe_payment_service.dart';
import '../../services/storage_service.dart';

class BuyCoinsController extends ChangeNotifier {
  final CoinPackageService coinPackageService;
  final PaymentService paymentService;
  final PaymentRequestService paymentRequestService;
  final StorageService storageService;
  final MediaService mediaService;
  final StripePaymentService stripePaymentService;

  BuyCoinsController({
    required this.coinPackageService,
    required this.paymentService,
    required this.paymentRequestService,
    required this.storageService,
    required this.mediaService,
    required this.stripePaymentService,
  });

  bool loading = false;
  bool saving = false;

  List<CoinPackageModel> packs = [];
  List<CoinPackageModel> visiblePacks = [];
  CoinPackageModel? selectedPack;
  File? receiptFile;

  final Map<int, String?> _qrCache = {};

  String? get selectedQrUrl {
    final pack = selectedPack;
    if (pack == null) return null;
    return _qrCache[pack.id];
  }

  bool get canSubmit => selectedPack != null && receiptFile != null && !saving;
  bool get canPayWithStripe => selectedPack != null && !saving;

  Future<void> loadPackages() async {
    loading = true;
    notifyListeners();

    try {
      packs = await coinPackageService.getAll();
      _qrCache.clear();

      await Future.wait(
        packs.map((pack) async {
          try {
            final mediaList = await mediaService.getByEntity(
              entityId: pack.id.toString(),
              entityType: MediaEntityType.coin_package,
            );

            _qrCache[pack.id] = mediaList.isNotEmpty ? mediaList.first.url : null;
          } catch (_) {
            _qrCache[pack.id] = null;
          }
        }),
      );

      visiblePacks = List<CoinPackageModel>.from(packs);

      selectedPack = visiblePacks.isNotEmpty ? visiblePacks.first : null;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> selectPack(CoinPackageModel pack) async {
    if (selectedPack?.id == pack.id) return;
    selectedPack = pack;
    notifyListeners();
  }

  void setReceiptFile(File? file) {
    receiptFile = file;
    notifyListeners();
  }

  // =========================
  // RECEIPT
  // =========================

  void clearReceipt() {
    receiptFile = null;
    notifyListeners();
  }

  // =========================
  // BUY
  // =========================

  Future<void> confirmAndBuy(UserModel user) async {
    final pack = selectedPack;

    if (pack == null) {
      throw Exception('No hay paquete seleccionado.');
    }

    if (receiptFile == null) {
      throw Exception('Debes subir tu comprobante antes de continuar.');
    }

    saving = true;
    notifyListeners();

    try {
      final payment = await paymentService.createPayment(
        CreatePaymentModel(
          amount: pack.cashAmount,
          method: PaymentMethod.qr,
          type: PaymentType.coin_purchase,
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
          type: PaymentType.coin_purchase,
          targetId: pack.id,
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
    final pack = selectedPack;

    if (pack == null) {
      throw Exception('No hay paquete seleccionado.');
    }

    saving = true;
    notifyListeners();

    try {
      await stripePaymentService.pay(
        type: PaymentType.coin_purchase,
        targetId: pack.id,
        merchantDisplayName: 'Tinku',
      );
    } finally {
      saving = false;
      notifyListeners();
    }
  }
}
