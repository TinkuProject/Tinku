class PriceLevelHelper {
  static const double affordableMax = 50;
  static const double moderateMax = 150;

  static int level(double? averagePrice) {
    if (averagePrice == null || averagePrice <= 0) return 0;
    if (averagePrice <= affordableMax) return 1;
    if (averagePrice <= moderateMax) return 2;
    return 3;
  }

  static String label(double? averagePrice) {
    final resolvedLevel = level(averagePrice);
    if (resolvedLevel == 0) return '';
    return List.filled(resolvedLevel, r'$').join();
  }

  static String description(double? averagePrice) {
    switch (level(averagePrice)) {
      case 1:
        return 'Precio bajo';
      case 2:
        return 'Precio medio';
      case 3:
        return 'Precio alto';
      default:
        return 'Sin rango de precio';
    }
  }
}
