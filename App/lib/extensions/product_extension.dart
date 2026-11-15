import '../models/product_model.dart';

extension ProductUI on ProductModel {
  String get formattedPrice {
    final hasBs = price != null && price! > 0;
    final hasTinku = tinkuPrice != null && tinkuPrice! > 0;

    if (hasBs && hasTinku) {
      return '${price!.toStringAsFixed(2)} Bs. • ${tinkuPrice!.toStringAsFixed(2)} Tinku';
    } else if (hasBs) {
      return '${price!.toStringAsFixed(2)} Bs.';
    } else if (hasTinku) {
      return '${tinkuPrice!.toStringAsFixed(2)} Tinku';
    } else {
      return 'Sin precio';
    }
  }
}