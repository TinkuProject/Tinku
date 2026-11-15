import 'package:flutter/material.dart';

import '../core/enums.dart';
import '../models/notification_model.dart';

enum NotificationHistorySection { today, thisWeek, older }

extension NotificationHistorySectionLabel on NotificationHistorySection {
  String get label => switch (this) {
        NotificationHistorySection.today => 'Hoy',
        NotificationHistorySection.thisWeek => 'Esta semana',
        NotificationHistorySection.older => 'Anteriores',
      };
}

class NotificationDirectAction {
  final String label;
  final String route;
  final IconData icon;

  const NotificationDirectAction({
    required this.label,
    required this.route,
    required this.icon,
  });
}

class NotificationHistoryHelper {
  const NotificationHistoryHelper._();

  static NotificationHistorySection sectionFor(
    DateTime value, {
    DateTime? now,
  }) {
    final localValue = value.toLocal();
    final localNow = (now ?? DateTime.now()).toLocal();
    final day = DateTime(localValue.year, localValue.month, localValue.day);
    final today = DateTime(localNow.year, localNow.month, localNow.day);
    final ageInDays = today.difference(day).inDays;

    if (ageInDays <= 0) return NotificationHistorySection.today;
    if (ageInDays < 7) return NotificationHistorySection.thisWeek;
    return NotificationHistorySection.older;
  }

  static NotificationDirectAction? actionFor(
    NotificationModel notification,
    UserRole role,
  ) {
    final directRoute = notification.route?.trim();
    if (directRoute != null && directRoute.startsWith('/')) {
      return NotificationDirectAction(
        label: _labelForType(notification.type),
        route: directRoute,
        icon: _iconForType(notification.type),
      );
    }

    final text =
        '${notification.title ?? ''} ${notification.message}'.toLowerCase();
    final isAdmin = role == UserRole.admin || role == UserRole.master;

    if (text.contains('reseña')) {
      if (text.contains('nueva reseña')) {
        return const NotificationDirectAction(
          label: 'Responder reseña',
          route: '/manageReviews',
          icon: Icons.reply_outlined,
        );
      }
      return null;
    }

    if (text.contains('pedido')) {
      return const NotificationDirectAction(
        label: 'Ver pedido',
        route: '/myMarketplaceOrders',
        icon: Icons.receipt_long_outlined,
      );
    }

    if (text.contains('reclamo')) {
      return NotificationDirectAction(
        label: isAdmin ? 'Revisar solicitud' : 'Ver reclamo',
        route: isAdmin ? '/adminBusinessClaims' : '/claimBusiness',
        icon: Icons.fact_check_outlined,
      );
    }

    if (text.contains('solicitud de almacén') ||
        text.contains('solicitud de almacen') ||
        text.contains('productos enviados al almacén') ||
        text.contains('productos enviados al almacen') ||
        text.contains('productos recibidos por el almacén') ||
        text.contains('productos recibidos por el almacen')) {
      return const NotificationDirectAction(
        label: 'Revisar solicitud',
        route: '/warehouses',
        icon: Icons.warehouse_outlined,
      );
    }

    if (text.contains('almacén') || text.contains('almacen')) {
      return NotificationDirectAction(
        label: isAdmin ? 'Revisar almacén' : 'Ver almacén',
        route: isAdmin ? '/adminPendingWarehouses' : '/warehouses',
        icon: Icons.warehouse_outlined,
      );
    }

    if (text.contains('reserva')) {
      return const NotificationDirectAction(
        label: 'Ver calendario',
        route: '/myCalendar',
        icon: Icons.calendar_month_outlined,
      );
    }

    if (text.contains('publicación') || text.contains('publicacion')) {
      return const NotificationDirectAction(
        label: 'Ver publicación',
        route: '/myMarketplace',
        icon: Icons.storefront_outlined,
      );
    }

    if (text.contains('evento')) {
      return NotificationDirectAction(
        label: isAdmin ? 'Revisar evento' : 'Ver mis eventos',
        route: isAdmin ? '/adminPendingEvents' : '/myEvents',
        icon: Icons.event_outlined,
      );
    }

    if (text.contains('negocio') || text.contains('servicio')) {
      return NotificationDirectAction(
        label: isAdmin ? 'Revisar negocio' : 'Ver mis negocios',
        route: isAdmin ? '/adminPendingBusinesses' : '/myBusinesses',
        icon: Icons.storefront_outlined,
      );
    }

    if (text.contains('pago') ||
        text.contains('tinku') ||
        text.contains('moneda')) {
      return const NotificationDirectAction(
        label: 'Ver monedero',
        route: '/walletBalance',
        icon: Icons.account_balance_wallet_outlined,
      );
    }

    return null;
  }

  static String _labelForType(String? type) => switch (type) {
        'marketplace_order' => 'Ver pedido',
        'review' => 'Ver reseña',
        'business_claim' => 'Ver reclamo',
        'warehouse' => 'Ver almacén',
        'event' => 'Ver evento',
        'cashout' => 'Ver retiro',
        'payment' => 'Ver monedero',
        _ => 'Ver detalle',
      };

  static IconData _iconForType(String? type) => switch (type) {
        'marketplace_order' => Icons.receipt_long_outlined,
        'review' => Icons.reviews_outlined,
        'business_claim' => Icons.fact_check_outlined,
        'warehouse' => Icons.warehouse_outlined,
        'event' => Icons.event_outlined,
        'cashout' => Icons.currency_exchange,
        'payment' => Icons.account_balance_wallet_outlined,
        _ => Icons.open_in_new,
      };
}
