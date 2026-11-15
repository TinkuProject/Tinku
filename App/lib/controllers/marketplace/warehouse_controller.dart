import 'package:flutter/material.dart';

import '../../models/business_model.dart';
import '../../models/warehouse_model.dart';
import '../../services/business_service.dart';
import '../../services/warehouse_service.dart';

class WarehouseController extends ChangeNotifier {
  WarehouseController(this._warehouseService, this._businessService);

  final WarehouseService _warehouseService;
  final BusinessService _businessService;

  bool loading = false;
  bool saving = false;
  String? error;
  int selectedBusinessId = 0;

  List<WarehouseModel> warehouses = [];
  List<WarehouseModel> allWarehouses = [];
  List<BusinessModel> businesses = [];
  List<WarehouseInventoryModel> inventory = [];
  List<WarehouseLocationModel> locations = [];
  List<WarehouseStockRequestModel> receivedRequests = [];
  List<WarehouseStockRequestModel> sentRequests = [];
  final Map<int, BusinessFulfillmentModel> fulfillmentsByBusiness = {};

  List<BusinessModel> get visibleBusinesses {
    if (selectedBusinessId == 0) return List.of(businesses);
    return businesses
        .where((business) => business.id == selectedBusinessId)
        .toList();
  }

  List<WarehouseModel> get visibleWarehouses {
    if (selectedBusinessId == 0) return List.of(warehouses);
    return fulfillmentsByBusiness[selectedBusinessId]?.warehouses ?? [];
  }

  Map<int, String> get businessSelectorItems => {
        0: 'Todos mis negocios',
        for (final business in businesses) business.id: business.name,
      };

  void setSelectedBusiness(int value) {
    selectedBusinessId = value;
    notifyListeners();
  }

  Future<void> loadMine({bool admin = false}) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final loadedActiveWarehouses = await _warehouseService.getActive();
      final loadedBusinesses = await _businessService.getMine();
      final loadedWarehouses = admin
          ? await _warehouseService.getAdmin()
          : await _warehouseService.getMine();
      final requestLists = await Future.wait([
        _warehouseService.getReceivedStockRequests(),
        _warehouseService.getSentStockRequests(),
      ]);
      final loadedFulfillments = Map<int, BusinessFulfillmentModel>.fromEntries(
        await Future.wait(
          loadedBusinesses.map((business) async {
            BusinessFulfillmentModel fulfillment;
            try {
              fulfillment =
                  await _warehouseService.getBusinessFulfillment(business.id);
            } catch (_) {
              fulfillment = BusinessFulfillmentModel(
                pickupInStore: false,
                warehouseDelivery: false,
                warehouses: const [],
              );
            }
            return MapEntry(business.id, fulfillment);
          }),
        ),
      );

      allWarehouses = loadedActiveWarehouses;
      businesses = loadedBusinesses;
      warehouses = loadedWarehouses;
      receivedRequests = requestLists[0];
      sentRequests = requestLists[1];
      fulfillmentsByBusiness
        ..clear()
        ..addAll(loadedFulfillments);
    } catch (_) {
      error = 'No se pudieron cargar los almacenes';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> createWarehouse({
    required String name,
    bool admin = false,
    String? description,
    String? phone,
    String? email,
    String? address,
    double? latitude,
    double? longitude,
  }) async {
    saving = true;
    notifyListeners();

    try {
      await _warehouseService.create(
        name: name,
        description: description,
        phone: phone,
        email: email,
        address: address,
        latitude: latitude,
        longitude: longitude,
      );
      await loadMine(admin: admin);
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<void> approveWarehouse(WarehouseModel warehouse) async {
    saving = true;
    notifyListeners();

    try {
      await _warehouseService.approveWarehouse(warehouse.id);
      await loadMine(admin: true);
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<void> rejectWarehouse(
    WarehouseModel warehouse, {
    required String message,
  }) async {
    saving = true;
    notifyListeners();

    try {
      await _warehouseService.rejectWarehouse(
        warehouse.id,
        message: message,
      );
      await loadMine(admin: true);
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<void> loadInventory(int warehouseId) async {
    loading = true;
    notifyListeners();

    try {
      inventory = await _warehouseService.getInventory(warehouseId);
      locations = await _warehouseService.getLocations(warehouseId);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> loadLocations(int warehouseId) async {
    loading = true;
    notifyListeners();

    try {
      locations = await _warehouseService.getLocations(warehouseId);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> saveLocation({
    required int warehouseId,
    WarehouseLocationModel? location,
    int? parentId,
    required String name,
    required String code,
    String? description,
    int sortOrder = 0,
  }) async {
    saving = true;
    notifyListeners();

    try {
      if (location == null) {
        await _warehouseService.createLocation(
          warehouseId: warehouseId,
          parentId: parentId,
          name: name,
          code: code,
          description: description,
          sortOrder: sortOrder,
        );
      } else {
        await _warehouseService.updateLocation(
          warehouseId: warehouseId,
          locationId: location.id,
          parentId: parentId,
          name: name,
          code: code,
          description: description,
          status: location.status,
          sortOrder: sortOrder,
        );
      }
      locations = await _warehouseService.getLocations(warehouseId);
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<void> archiveLocation({
    required int warehouseId,
    required WarehouseLocationModel location,
  }) async {
    saving = true;
    notifyListeners();

    try {
      await _warehouseService.archiveLocation(
        warehouseId: warehouseId,
        locationId: location.id,
      );
      locations = await _warehouseService.getLocations(warehouseId);
      inventory = await _warehouseService.getInventory(warehouseId);
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<void> setInventoryLocation({
    required int warehouseId,
    required WarehouseInventoryModel item,
    int? locationId,
  }) async {
    saving = true;
    notifyListeners();

    try {
      await _warehouseService.setInventoryLocation(
        warehouseId: warehouseId,
        inventoryId: item.id,
        locationId: locationId,
      );
      inventory = await _warehouseService.getInventory(warehouseId);
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<BusinessFulfillmentModel> getFulfillment(int businessId) {
    return _warehouseService.getBusinessFulfillment(businessId);
  }

  Future<void> saveFulfillment({
    required int businessId,
    required bool pickupInStore,
    required bool warehouseDelivery,
    required List<int> warehouseIds,
    String? notes,
  }) async {
    saving = true;
    notifyListeners();

    try {
      final updated = await _warehouseService.setBusinessFulfillment(
        businessId: businessId,
        pickupInStore: pickupInStore,
        warehouseDelivery: warehouseDelivery,
        warehouseIds: warehouseIds,
        notes: notes,
      );
      fulfillmentsByBusiness[businessId] = updated;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<void> createStockRequest({
    required int businessId,
    required int warehouseId,
    required int productId,
    required int quantity,
    String? notes,
    bool admin = false,
  }) async {
    saving = true;
    notifyListeners();

    try {
      await _warehouseService.createStockRequest(
        businessId: businessId,
        warehouseId: warehouseId,
        productId: productId,
        quantity: quantity,
        notes: notes,
      );
      await loadMine(admin: admin);
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<void> approveStockRequest(
    WarehouseStockRequestModel request, {
    bool admin = false,
    int? locationId,
  }) async {
    saving = true;
    notifyListeners();

    try {
      await _warehouseService.approveStockRequest(
        request.id,
        locationId: locationId,
      );
      await loadMine(admin: admin);
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<void> markStockRequestSent(
    WarehouseStockRequestModel request, {
    bool admin = false,
  }) async {
    saving = true;
    notifyListeners();

    try {
      await _warehouseService.markStockRequestSent(request.id);
      await loadMine(admin: admin);
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<void> receiveStockRequest(
    WarehouseStockRequestModel request, {
    bool admin = false,
    int? locationId,
  }) async {
    saving = true;
    notifyListeners();

    try {
      await _warehouseService.receiveStockRequest(
        request.id,
        locationId: locationId,
      );
      await loadMine(admin: admin);
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<void> rejectStockRequest(
    WarehouseStockRequestModel request, {
    required String message,
    bool admin = false,
  }) async {
    saving = true;
    notifyListeners();

    try {
      await _warehouseService.rejectStockRequest(
        request.id,
        message: message,
      );
      await loadMine(admin: admin);
    } finally {
      saving = false;
      notifyListeners();
    }
  }
}
