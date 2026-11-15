import 'package:flutter/material.dart';

import '../../core/enums.dart';
import '../../models/discount_model.dart';
import '../../models/media_target.dart';

import '../shared/media/media_controller.dart';
import 'discount_controller.dart';

class DiscountFormController extends ChangeNotifier {
  DiscountFormController(
    this._discountController,
    this.mediaController,
  );

  final DiscountController _discountController;
  final MediaController mediaController;

  // =========================
  // FORM
  // =========================
  final formKey = GlobalKey<FormState>();

  final descriptionCtrl = TextEditingController();
  final percentCtrl = TextEditingController();

  DateTime? startDate;
  DateTime? endDate;

  bool active = true;
  bool loading = false;
  double createCostPerDay = 0;

  DiscountModel? _discount;

  bool get editing => _discount != null;

  int get selectedDays {
    if (startDate == null || endDate == null) return 0;

    final start = DateTime(startDate!.year, startDate!.month, startDate!.day);
    final end = DateTime(endDate!.year, endDate!.month, endDate!.day);
    return end.difference(start).inDays + 1;
  }

  double get estimatedCreateCost => selectedDays * createCostPerDay;

  // =========================
  // INIT
  // =========================
  Future<void> init({
    required int businessId,
    DiscountModel? discount,
  }) async {
    _discount = discount;

    try {
      await _discountController.loadDiscountCreateCost();
      createCostPerDay = _discountController.discountCreateCost;
    } catch (_) {
      createCostPerDay = 0;
    }

    if (discount == null) {
      notifyListeners();
      return;
    }

    descriptionCtrl.text = discount.description ?? '';
    percentCtrl.text = discount.discountPercent.toStringAsFixed(0);

    startDate = discount.startDate;
    endDate = discount.endDate;

    active = discount.status == PromotionStatus.active;

    await mediaController.load(
      target: EntityMediaTarget(
        entityId: discount.id,
        entityType: MediaEntityType.discount,
      ),
    );

    notifyListeners();
  }

  // =========================
  // DATE HELPERS
  // =========================
  Future<void> pickStartDate(BuildContext context) async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );

    if (picked != null) {
      setStartDate(picked);
    }
  }

  Future<void> pickEndDate(BuildContext context) async {
    final minEnd = startDate ?? DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: endDate ?? minEnd,
      firstDate: minEnd,
      lastDate: DateTime(minEnd.year + 5),
    );

    if (picked != null) {
      setEndDate(picked);
    }
  }

  void setStartDate(DateTime value) {
    startDate = value;

    if (endDate != null && endDate!.isBefore(startDate!)) {
      endDate = startDate;
    }

    notifyListeners();
  }

  void setEndDate(DateTime value) {
    endDate = value;
    notifyListeners();
  }

  void setActive(bool value) {
    active = value;
    notifyListeners();
  }

  bool validateDateRange() {
    if (startDate == null || endDate == null) {
      return false;
    }

    return !endDate!.isBefore(startDate!);
  }

  // =========================
  // MEDIA
  // =========================
  Future<void> pickImages(BuildContext context) async {
    await mediaController.pickImagesFromGallery(context);
    notifyListeners();
  }

  // =========================
  // SUBMIT
  // =========================
  Future<bool> submit({
    required int businessId,
  }) async {
    if (loading) return false;

    if (!formKey.currentState!.validate()) {
      return false;
    }

    if (!validateDateRange()) {
      throw Exception(
        "La fecha final debe ser mayor o igual a la inicial",
      );
    }

    loading = true;
    notifyListeners();

    try {
      final percent = double.parse(
        percentCtrl.text.replaceAll(',', '.'),
      );

      final start = DateTime(
        startDate!.year,
        startDate!.month,
        startDate!.day,
      ).toUtc();

      final end = DateTime(
        endDate!.year,
        endDate!.month,
        endDate!.day,
        23,
        59,
        59,
        999,
      ).toUtc();

      final data = {
        "business_id": businessId,
        "description": descriptionCtrl.text.trim(),
        "discount_percent": percent,
        "start_date": start.toIso8601String(),
        "end_date": end.toIso8601String(),
        "status": active ? "active" : "inactive",
      };

      int discountId;

      if (editing) {
        discountId = _discount!.id;

        await _discountController.updateDiscount(
          discountId,
          data,
        );
      } else {
        final created = await _discountController.createDiscount(data);

        discountId = created.id;
      }

      await mediaController.saveDirect(
        target: EntityMediaTarget(
          entityId: discountId,
          entityType: MediaEntityType.discount,
        ),
      );

      return true;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // =========================
  // CLEANUP
  // =========================
  @override
  void dispose() {
    descriptionCtrl.dispose();
    percentCtrl.dispose();

    mediaController.reset();

    super.dispose();
  }
}
