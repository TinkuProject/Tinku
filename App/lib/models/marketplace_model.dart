class MarketplacePublicationModel {
  final int id;
  final int productId;
  final int businessId;
  final String? businessOwnerId;
  final String productName;
  final String? productDescription;
  final String? productImageUrl;
  final String productVolumeTier;
  final int warehouseDeliveryRewardTinkus;
  final String businessName;
  final String? businessAddress;
  final int publishedStock;
  final double? unitPrice;
  final int? unitTinkuPrice;
  final double? displayUnitPrice;
  final int? displayUnitTinkuPrice;
  final double serviceFeeRate;
  final String paymentMode;
  final int calculatedCostTinkus;
  final int chargedTinkus;
  final String status;

  MarketplacePublicationModel({
    required this.id,
    required this.productId,
    required this.businessId,
    this.businessOwnerId,
    required this.productName,
    this.productDescription,
    this.productImageUrl,
    required this.productVolumeTier,
    required this.warehouseDeliveryRewardTinkus,
    required this.businessName,
    this.businessAddress,
    required this.publishedStock,
    this.unitPrice,
    this.unitTinkuPrice,
    this.displayUnitPrice,
    this.displayUnitTinkuPrice,
    required this.serviceFeeRate,
    required this.paymentMode,
    required this.calculatedCostTinkus,
    required this.chargedTinkus,
    required this.status,
  });

  factory MarketplacePublicationModel.fromJson(Map<String, dynamic> json) {
    return MarketplacePublicationModel(
      id: _int(json['id']),
      productId: _int(json['product_id']),
      businessId: _int(json['business_id']),
      businessOwnerId: json['business_owner_id']?.toString(),
      productName: json['product_name']?.toString() ??
          json['name']?.toString() ??
          'Producto',
      productDescription: json['product_description']?.toString() ??
          json['description']?.toString(),
      productImageUrl: json['product_image_url']?.toString(),
      productVolumeTier: json['product_volume_tier']?.toString() ?? 'small',
      warehouseDeliveryRewardTinkus:
          _int(json['warehouse_delivery_reward_tinkus']),
      businessName: json['business_name']?.toString() ?? 'Negocio',
      businessAddress: json['business_address']?.toString(),
      publishedStock: _int(json['published_stock']),
      unitPrice: _double(json['unit_price']),
      unitTinkuPrice: json['unit_tinku_price'] == null
          ? null
          : _int(json['unit_tinku_price']),
      displayUnitPrice: _double(json['display_unit_price']),
      displayUnitTinkuPrice: json['display_unit_tinku_price'] == null
          ? null
          : _int(json['display_unit_tinku_price']),
      serviceFeeRate: _double(json['marketplace_service_fee_rate']) ?? 0,
      paymentMode: json['payment_mode']?.toString() ?? 'tinkus',
      calculatedCostTinkus: _int(json['calculated_cost_tinkus']),
      chargedTinkus: _int(json['charged_tinkus']),
      status: json['status']?.toString() ?? 'active',
    );
  }
}

class MarketplacePublicationEstimateModel {
  final int costTinkus;
  final double serviceFeeRate;
  final double? displayUnitPrice;
  final int? displayUnitTinkuPrice;

  MarketplacePublicationEstimateModel({
    required this.costTinkus,
    required this.serviceFeeRate,
    this.displayUnitPrice,
    this.displayUnitTinkuPrice,
  });

  factory MarketplacePublicationEstimateModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return MarketplacePublicationEstimateModel(
      costTinkus: _int(json['cost_tinkus']),
      serviceFeeRate: _double(json['service_fee_rate']) ?? 0,
      displayUnitPrice: _double(json['display_unit_price']),
      displayUnitTinkuPrice: json['display_unit_tinku_price'] == null
          ? null
          : _int(json['display_unit_tinku_price']),
    );
  }
}

class MarketplaceOrderModel {
  final int id;
  final String status;
  final String paymentMethod;
  final String? pickupCode;
  final double totalAmount;
  final int totalTinkus;
  final int warehouseDeliveryFeeTinkus;
  final String fulfillment;
  final String? pickupBusinessName;
  final String? pickupBusinessAddress;
  final String? warehouseName;
  final String? warehouseAddress;
  final String? buyerName;
  final String? buyerUsername;
  final int sellerAmountTinkus;
  final DateTime? settledAt;
  final DateTime? pickupExpiresAt;
  final String? cancellationReason;
  final DateTime? cancelledAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<MarketplaceOrderItemModel> items;
  final List<MarketplaceDeliveryModel> deliveries;

  MarketplaceOrderModel({
    required this.id,
    required this.status,
    required this.paymentMethod,
    this.pickupCode,
    required this.totalAmount,
    required this.totalTinkus,
    required this.warehouseDeliveryFeeTinkus,
    required this.fulfillment,
    this.pickupBusinessName,
    this.pickupBusinessAddress,
    this.warehouseName,
    this.warehouseAddress,
    this.buyerName,
    this.buyerUsername,
    this.sellerAmountTinkus = 0,
    this.settledAt,
    this.pickupExpiresAt,
    this.cancellationReason,
    this.cancelledAt,
    this.createdAt,
    this.updatedAt,
    this.items = const [],
    this.deliveries = const [],
  });

  factory MarketplaceOrderModel.fromJson(Map<String, dynamic> json) {
    return MarketplaceOrderModel(
      id: _int(json['id']),
      status: json['status']?.toString() ?? 'pending',
      paymentMethod: json['payment_method']?.toString() ?? 'tinkus',
      pickupCode: json['pickup_code']?.toString(),
      totalAmount: _double(json['total_amount']) ?? 0,
      totalTinkus: _int(json['total_tinkus']),
      warehouseDeliveryFeeTinkus: _int(json['warehouse_delivery_fee_tinkus']),
      fulfillment: json['fulfillment']?.toString() ?? 'pickup',
      pickupBusinessName: json['pickup_business_name']?.toString(),
      pickupBusinessAddress: json['pickup_business_address']?.toString(),
      warehouseName: json['warehouse_name']?.toString(),
      warehouseAddress: json['warehouse_address']?.toString(),
      buyerName: json['buyer_name']?.toString(),
      buyerUsername: json['buyer_username']?.toString(),
      sellerAmountTinkus: _int(json['seller_amount_tinkus']),
      settledAt: DateTime.tryParse(json['settled_at']?.toString() ?? ''),
      pickupExpiresAt:
          DateTime.tryParse(json['pickup_expires_at']?.toString() ?? ''),
      cancellationReason: json['cancellation_reason']?.toString(),
      cancelledAt: DateTime.tryParse(json['cancelled_at']?.toString() ?? ''),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
      items: (json['items'] as List? ?? [])
          .map(
            (e) => MarketplaceOrderItemModel.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList(),
      deliveries: (json['deliveries'] as List? ?? [])
          .map(
            (e) => MarketplaceDeliveryModel.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList(),
    );
  }
}

class MarketplaceOrderItemModel {
  final int id;
  final String productName;
  final String businessName;
  final int quantity;
  final double? unitPrice;
  final int? unitTinkuPrice;
  final double subtotalAmount;
  final int subtotalTinkus;
  final int warehouseRewardTinkus;

  MarketplaceOrderItemModel({
    required this.id,
    required this.productName,
    required this.businessName,
    required this.quantity,
    this.unitPrice,
    this.unitTinkuPrice,
    required this.subtotalAmount,
    required this.subtotalTinkus,
    required this.warehouseRewardTinkus,
  });

  factory MarketplaceOrderItemModel.fromJson(Map<String, dynamic> json) {
    return MarketplaceOrderItemModel(
      id: _int(json['id']),
      productName: json['product_name']?.toString() ?? 'Producto',
      businessName: json['business_name']?.toString() ?? 'Negocio',
      quantity: _int(json['quantity']),
      unitPrice: _double(json['unit_price']),
      unitTinkuPrice: json['unit_tinku_price'] == null
          ? null
          : _int(json['unit_tinku_price']),
      subtotalAmount: _double(json['subtotal_amount']) ?? 0,
      subtotalTinkus: _int(json['subtotal_tinkus']),
      warehouseRewardTinkus: _int(json['warehouse_reward_tinkus']),
    );
  }
}

class MarketplaceDeliveryModel {
  final int id;
  final int warehouseId;
  final String status;
  final int rewardTinkus;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MarketplaceDeliveryModel({
    required this.id,
    required this.warehouseId,
    required this.status,
    required this.rewardTinkus,
    this.pickedUpAt,
    this.deliveredAt,
    this.createdAt,
    this.updatedAt,
  });

  factory MarketplaceDeliveryModel.fromJson(Map<String, dynamic> json) {
    return MarketplaceDeliveryModel(
      id: _int(json['id']),
      warehouseId: _int(json['warehouse_id']),
      status: json['status']?.toString() ?? 'pending',
      rewardTinkus: _int(json['reward_tinkus']),
      pickedUpAt: DateTime.tryParse(json['picked_up_at']?.toString() ?? ''),
      deliveredAt: DateTime.tryParse(json['delivered_at']?.toString() ?? ''),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
    );
  }
}

class BusinessViewStatsModel {
  final int total;
  final DateTime? lastViewedAt;
  final List<BusinessViewDailyModel> daily;

  BusinessViewStatsModel({
    required this.total,
    required this.daily,
    this.lastViewedAt,
  });

  factory BusinessViewStatsModel.fromJson(Map<String, dynamic> json) {
    return BusinessViewStatsModel(
      total: _int(json['total']),
      lastViewedAt: json['last_viewed_at'] == null
          ? null
          : DateTime.tryParse(json['last_viewed_at'].toString()),
      daily: (json['daily'] as List? ?? [])
          .map(
            (e) => BusinessViewDailyModel.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList(),
    );
  }
}

class BusinessViewDailyModel {
  final DateTime day;
  final int viewsCount;

  BusinessViewDailyModel({
    required this.day,
    required this.viewsCount,
  });

  factory BusinessViewDailyModel.fromJson(Map<String, dynamic> json) {
    return BusinessViewDailyModel(
      day: DateTime.tryParse(json['day']?.toString() ?? '') ?? DateTime.now(),
      viewsCount: _int(json['views_count']),
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
