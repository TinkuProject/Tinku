class WarehouseModel {
  final int id;
  final String? ownerId;
  final String name;
  final String? description;
  final String? phone;
  final String? email;
  final String? address;
  final double? latitude;
  final double? longitude;
  final bool validated;
  final String status;

  WarehouseModel({
    required this.id,
    this.ownerId,
    required this.name,
    this.description,
    this.phone,
    this.email,
    this.address,
    this.latitude,
    this.longitude,
    required this.validated,
    required this.status,
  });

  factory WarehouseModel.fromJson(Map<String, dynamic> json) {
    final location = json['location'];
    double? latitude;
    double? longitude;

    if (location is Map) {
      final coordinates = location['coordinates'];
      if (coordinates is List && coordinates.length == 2) {
        longitude = _double(coordinates[0]);
        latitude = _double(coordinates[1]);
      } else {
        latitude = _double(location['latitude']);
        longitude = _double(location['longitude']);
      }
    }

    return WarehouseModel(
      id: _int(json['id']),
      ownerId: json['owner_id']?.toString(),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      address: json['address']?.toString(),
      latitude: latitude,
      longitude: longitude,
      validated: json['validated'] == true,
      status: json['status']?.toString() ?? 'pending',
    );
  }
}

class WarehouseInventoryModel {
  final int id;
  final int warehouseId;
  final int productId;
  final int? locationId;
  final String productName;
  final String businessName;
  final String? locationName;
  final String? locationCode;
  final int quantity;
  final int reservedQuantity;
  final String status;

  WarehouseInventoryModel({
    required this.id,
    required this.warehouseId,
    required this.productId,
    this.locationId,
    required this.productName,
    required this.businessName,
    this.locationName,
    this.locationCode,
    required this.quantity,
    required this.reservedQuantity,
    required this.status,
  });

  factory WarehouseInventoryModel.fromJson(Map<String, dynamic> json) {
    return WarehouseInventoryModel(
      id: _int(json['id']),
      warehouseId: _int(json['warehouse_id']),
      productId: _int(json['product_id']),
      locationId:
          json['location_id'] == null ? null : _int(json['location_id']),
      productName: json['product_name']?.toString() ?? 'Producto',
      businessName: json['business_name']?.toString() ?? 'Negocio',
      locationName: json['location_name']?.toString(),
      locationCode: json['location_code']?.toString(),
      quantity: _int(json['quantity']),
      reservedQuantity: _int(json['reserved_quantity']),
      status: json['status']?.toString() ?? 'available',
    );
  }
}

class WarehouseLocationModel {
  final int id;
  final int warehouseId;
  final int? parentId;
  final String name;
  final String code;
  final String? description;
  final String status;
  final int sortOrder;

  WarehouseLocationModel({
    required this.id,
    required this.warehouseId,
    this.parentId,
    required this.name,
    required this.code,
    this.description,
    required this.status,
    required this.sortOrder,
  });

  factory WarehouseLocationModel.fromJson(Map<String, dynamic> json) {
    return WarehouseLocationModel(
      id: _int(json['id']),
      warehouseId: _int(json['warehouse_id']),
      parentId: json['parent_id'] == null ? null : _int(json['parent_id']),
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      description: json['description']?.toString(),
      status: json['status']?.toString() ?? 'active',
      sortOrder: _int(json['sort_order']),
    );
  }

  String label(List<WarehouseLocationModel> all) {
    if (parentId == null) return '$code - $name';
    WarehouseLocationModel? parent;
    for (final item in all) {
      if (item.id == parentId) {
        parent = item;
        break;
      }
    }
    if (parent == null) return '$code - $name';
    return '${parent.code}/$code - $name';
  }
}

class BusinessFulfillmentModel {
  final bool pickupInStore;
  final bool warehouseDelivery;
  final String? notes;
  final List<WarehouseModel> warehouses;

  BusinessFulfillmentModel({
    required this.pickupInStore,
    required this.warehouseDelivery,
    required this.warehouses,
    this.notes,
  });

  factory BusinessFulfillmentModel.fromJson(Map<String, dynamic> json) {
    final options = Map<String, dynamic>.from(json['options'] ?? {});
    final warehouses = (json['warehouses'] as List? ?? [])
        .map((e) => WarehouseModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    return BusinessFulfillmentModel(
      pickupInStore: options['pickup_in_store'] == true,
      warehouseDelivery: options['warehouse_delivery'] == true,
      notes: options['notes']?.toString(),
      warehouses: warehouses,
    );
  }
}

class WarehouseStockRequestModel {
  final int id;
  final int businessId;
  final int warehouseId;
  final int productId;
  final String requestedBy;
  final String? processedBy;
  final String? receivedBy;
  final int quantity;
  final String status;
  final int? locationId;
  final String? notes;
  final String? responseMessage;
  final String businessName;
  final String warehouseName;
  final String productName;
  final String? requestedByUsername;
  final String? processedByUsername;
  final String? receivedByUsername;
  final String? locationName;
  final String? locationCode;
  final DateTime createdAt;
  final DateTime? processedAt;
  final DateTime? sentAt;
  final DateTime? receivedAt;

  WarehouseStockRequestModel({
    required this.id,
    required this.businessId,
    required this.warehouseId,
    required this.productId,
    required this.requestedBy,
    this.processedBy,
    this.receivedBy,
    required this.quantity,
    required this.status,
    this.locationId,
    this.notes,
    this.responseMessage,
    required this.businessName,
    required this.warehouseName,
    required this.productName,
    this.requestedByUsername,
    this.processedByUsername,
    this.receivedByUsername,
    this.locationName,
    this.locationCode,
    required this.createdAt,
    this.processedAt,
    this.sentAt,
    this.receivedAt,
  });

  factory WarehouseStockRequestModel.fromJson(Map<String, dynamic> json) {
    return WarehouseStockRequestModel(
      id: _int(json['id']),
      businessId: _int(json['business_id']),
      warehouseId: _int(json['warehouse_id']),
      productId: _int(json['product_id']),
      requestedBy: json['requested_by']?.toString() ?? '',
      processedBy: json['processed_by']?.toString(),
      receivedBy: json['received_by']?.toString(),
      quantity: _int(json['quantity']),
      status: json['status']?.toString() ?? 'pending',
      locationId:
          json['location_id'] == null ? null : _int(json['location_id']),
      notes: json['notes']?.toString(),
      responseMessage: json['response_message']?.toString(),
      businessName: json['business_name']?.toString() ?? 'Negocio',
      warehouseName: json['warehouse_name']?.toString() ?? 'Almacén',
      productName: json['product_name']?.toString() ?? 'Producto',
      requestedByUsername: json['requested_by_username']?.toString(),
      processedByUsername: json['processed_by_username']?.toString(),
      receivedByUsername: json['received_by_username']?.toString(),
      locationName: json['location_name']?.toString(),
      locationCode: json['location_code']?.toString(),
      createdAt: DateTime.parse(json['created_at']).toLocal(),
      processedAt: json['processed_at'] != null
          ? DateTime.tryParse(json['processed_at'])?.toLocal()
          : null,
      sentAt: json['sent_at'] != null
          ? DateTime.tryParse(json['sent_at'])?.toLocal()
          : null,
      receivedAt: json['received_at'] != null
          ? DateTime.tryParse(json['received_at'])?.toLocal()
          : null,
    );
  }
}

int _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double? _double(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
