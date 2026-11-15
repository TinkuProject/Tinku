import 'package:flutter/material.dart';

import '../../core/enums.dart';
import '../../models/business_model.dart';
import '../../models/discount_model.dart';
import '../../models/media_model.dart';
import '../../services/business_service.dart';
import '../../services/discount_service.dart';
import '../../services/media_service.dart';
import '../../services/system_config_service.dart';

class DiscountController extends ChangeNotifier {
  DiscountController({
    required this.discountService,
    required this.businessService,
    required this.systemConfigService,
    required this.mediaService,
  });

  final DiscountService discountService;
  final BusinessService businessService;
  final SystemConfigService systemConfigService;
  final MediaService mediaService;

  // =========================
  // STATE
  // =========================
  List<DiscountModel> activeDiscounts = [];
  List<DiscountModel> allDiscounts = [];
  List<BusinessModel> businesses = [];

  bool loading = false;

  int? selectedBusinessId;
  int _filterOrder = 0;

  double discountCreateCost = 0;
  final Map<int, Map<String, dynamic>> _cache = {};

  int get filterOrder => _filterOrder;
  Map<String, dynamic>? getCardData(int discountId) {
    return _cache[discountId];
  }

  Future<Map<String, dynamic>> _buildCardDataInternal(
    DiscountModel discount,
  ) async {
    String? imageUrl;

    try {
      final media = await mediaService.getByEntity(
        entityId: discount.id.toString(),
        entityType: MediaEntityType.discount,
      );

      if (media.isNotEmpty) {
        imageUrl = media.first.url;
      }
    } catch (_) {}

    final businessName = getBusinessName(discount.businessId);

    return {
      'image': imageUrl,
      'title': businessName,
      'businessName': businessName,
    };
  }

  Future<void> _loadBusinessesForDiscounts(
      List<DiscountModel> discounts) async {
    final ids =
        discounts.map((discount) => discount.businessId).toSet().toList();
    if (ids.isEmpty) return;

    final loaded = await businessService.getByIds(ids);
    final existing = {for (final business in businesses) business.id: business};

    for (final business in loaded) {
      existing[business.id] = business;
    }

    businesses = existing.values.toList();
  }

  void setFilterOrder(int value) {
    if (_filterOrder == value) return;
    _filterOrder = value;
    notifyListeners();
  }

  void resetFilters() {
    _filterOrder = 0;
    selectedBusinessId = 0;
    notifyListeners();
  }

  void setSelectedBusiness(int value) {
    if (selectedBusinessId == value) return;

    selectedBusinessId = value;
    notifyListeners();
  }

  Future<void> loadDiscountCreateCost() async {
    discountCreateCost = await systemConfigService.getDiscountCreateCost();
    notifyListeners();
  }

  // =========================
  // LOAD INITIAL (MANAGEMENT)
  // =========================
  Future<void> loadMine() async {
    loading = true;
    _clearMineData();
    notifyListeners();

    try {
      selectedBusinessId = 0;

      if (discountCreateCost == 0) {
        try {
          await loadDiscountCreateCost();
        } catch (_) {
          // no rompe la lista si todavía no está configurado el costo
        }
      }

      businesses = await businessService.getMine();
      allDiscounts = await discountService.getMine();

      _cache.clear();
      if (allDiscounts.isNotEmpty) {
        Map<int, List<MediaModel>> mediaByDiscount;
        try {
          mediaByDiscount = await mediaService.getByEntities(
            entityIds: allDiscounts.map((discount) => discount.id).toList(),
            entityType: MediaEntityType.discount,
          );
        } catch (_) {
          mediaByDiscount = {};
        }
        for (final discount in allDiscounts) {
          final media = mediaByDiscount[discount.id];
          _cache[discount.id] = {
            'image': media == null || media.isEmpty ? null : media.first.url,
          };
        }
      }
    } catch (_) {
      _clearMineData();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // =========================
  // LOAD BY BUSINESS
  // =========================
  Future<void> loadAllByBusiness(int businessId) async {
    if (businessId == 0) {
      await loadMine();
      return;
    }

    loading = true;
    notifyListeners();

    try {
      selectedBusinessId = businessId;
      allDiscounts = await discountService.getByBusiness(businessId);
    } catch (_) {
      allDiscounts = [];
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // =========================
  // LOAD ACTIVE (USER VIEW)
  // =========================
  Future<void> loadActiveByBusiness(int businessId) async {
    if (businessId == 0) {
      selectedBusinessId = 0;
      loading = true;
      notifyListeners();

      try {
        activeDiscounts = await discountService.getActive();
        await _loadBusinessesForDiscounts(activeDiscounts);

        _cache.clear();
        for (final discount in activeDiscounts) {
          _cache[discount.id] = await _buildCardDataInternal(discount);
        }
      } catch (_) {
        activeDiscounts = [];
      } finally {
        loading = false;
        notifyListeners();
      }
      return;
    }

    loading = true;
    notifyListeners();

    try {
      selectedBusinessId = businessId;
      activeDiscounts = await discountService.getActiveByBusiness(businessId);
      await _loadBusinessesForDiscounts(activeDiscounts);

      _cache.clear();
      for (final discount in activeDiscounts) {
        _cache[discount.id] = await _buildCardDataInternal(discount);
      }
    } catch (_) {
      activeDiscounts = [];
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // =========================
  // CRUD
  // =========================
  Future<DiscountModel> createDiscount(Map<String, dynamic> data) async {
    loading = true;
    notifyListeners();

    try {
      return discountService.createDiscount(data);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> updateDiscount(
    int id,
    Map<String, dynamic> updates,
  ) async {
    try {
      final updated = await discountService.updateDiscount(id, updates);

      _replaceInList(activeDiscounts, updated);
      _replaceInList(allDiscounts, updated);

      notifyListeners();
    } catch (_) {
      rethrow;
    }
  }

  Future<void> softDelete(int id) async {
    try {
      final updated = await discountService.softDelete(id);

      _replaceInList(activeDiscounts, updated);
      _replaceInList(allDiscounts, updated);

      notifyListeners();
    } catch (_) {
      rethrow;
    }
  }

  // =========================
  // HELPERS
  // =========================
  void _replaceInList(List<DiscountModel> list, DiscountModel updated) {
    final index = list.indexWhere((d) => d.id == updated.id);

    if (index != -1) {
      list[index] = updated;
    }
  }

  List<DiscountModel> get filteredDiscounts {
    final list = allDiscounts.where((d) {
      if (selectedBusinessId != null &&
          selectedBusinessId != 0 &&
          d.businessId != selectedBusinessId) {
        return false;
      }
      return true;
    }).toList();

    if (_filterOrder == 1) {
      list.sort((a, b) => b.discountPercent.compareTo(a.discountPercent));
    } else if (_filterOrder == 2) {
      list.sort((a, b) => a.discountPercent.compareTo(b.discountPercent));
    } else {
      list.sort((a, b) => b.startDate.compareTo(a.startDate));
    }

    return list;
  }

  // =========================
  // SELECTOR
  // =========================
  Map<int, String> get businessSelectorItems {
    return {
      0: "Todos mis negocios",
      for (final b in businesses) b.id: b.name,
    };
  }

  Set<int> get disabledBusinessSelectorIds {
    return businesses
        .where((b) => !b.validated || b.status != BusinessStatus.active)
        .map((b) => b.id)
        .toSet();
  }

  // =========================
  // DERIVED DATA
  // =========================
  List<DiscountModel> get activeValid {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    return activeDiscounts.where((d) {
      return !d.startDate.isAfter(now) && !d.endDate.isBefore(todayStart);
    }).toList();
  }

  List<DiscountModel> get expired {
    final now = DateTime.now();

    return allDiscounts.where((d) {
      return d.endDate.isBefore(now);
    }).toList();
  }

  List<DiscountModel> get upcoming {
    final now = DateTime.now();

    return allDiscounts.where((d) {
      return d.startDate.isAfter(now);
    }).toList();
  }

  int getDays(DiscountModel discount) {
    return discount.endDate.difference(discount.startDate).inDays + 1;
  }

  double getEstimatedAmount(DiscountModel discount) {
    if (discountCreateCost == 0) return 0;
    return getDays(discount) * discountCreateCost;
  }

  String getBusinessName(int businessId) {
    for (final business in businesses) {
      if (business.id == businessId) return business.name;
    }
    return "Negocio";
  }

  bool get hasData => allDiscounts.isNotEmpty || activeDiscounts.isNotEmpty;

  bool get hasBusinesses => businesses.isNotEmpty;

  void _clearMineData() {
    businesses = [];
    allDiscounts = [];
    activeDiscounts = [];
    _cache.clear();
    selectedBusinessId = 0;
  }

  void reset() {
    _clearMineData();
    _filterOrder = 0;
    loading = false;
    notifyListeners();
  }
}
