import 'package:flutter/material.dart';

import '../../core/enums.dart';

String promotionStatusLabel(PromotionStatus status) {
  switch (status) {
    case PromotionStatus.active:
      return "Activo";

    case PromotionStatus.inactive:
      return "Finalizado";

    case PromotionStatus.cancelled:
      return "Cancelado";
  }
}

Color promotionStatusColor(PromotionStatus status) {
  switch (status) {
    case PromotionStatus.active:
      return Colors.green;

    case PromotionStatus.cancelled:
      return Colors.orange;

    case PromotionStatus.inactive:
      return Colors.grey;
  }
}

IconData promotionStatusIcon(PromotionStatus status) {
  switch (status) {
    case PromotionStatus.active:
      return Icons.check_circle;

    case PromotionStatus.inactive:
      return Icons.schedule;

    case PromotionStatus.cancelled:
      return Icons.cancel;
  }
}