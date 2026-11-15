import '../../core/enums.dart';

class ProductModel {
  final int id;
  final int businessId;
  final int categoryId;
  final String name;
  final String? description;
  final double? price;
  final double? tinkuPrice;
  final int? stock;
  final String volumeTier;
  final ProductStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ProductModel({
    required this.id,
    required this.businessId,
    required this.categoryId,
    required this.name,
    this.description,
    this.price,
    this.tinkuPrice,
    this.stock,
    this.volumeTier = 'small',
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      businessId: json['business_id'],
      categoryId: json['category_id'],
      name: json['name'],
      description: json['description'],
      price: json['price'] != null
          ? (json['price'] as num).toDouble()
          : null,
      tinkuPrice: json['tinku_price'] != null
          ? (json['tinku_price'] as num).toDouble()
          : null,
      stock: json['stock'],
      volumeTier: json['volume_tier']?.toString() ?? 'small',
      status: productStatusFromString(json['status']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final data = {
      'business_id': businessId,
      'category_id': categoryId,
      'name': name,
      'description': description,
      'status': productStatusToString(status),
    };

    if (price != null) data['price'] = price;
    if (tinkuPrice != null) data['tinku_price'] = tinkuPrice;
    if (stock != null) data['stock'] = stock;
    data['volume_tier'] = volumeTier;

    return data;
  }
}
