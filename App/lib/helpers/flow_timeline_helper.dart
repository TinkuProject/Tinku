import 'package:flutter/material.dart';

import '../core/enums.dart';
import '../models/marketplace_model.dart';
import '../models/warehouse_model.dart';
import '../widgets/common/flow_timeline.dart';

class FlowTimelineHelper {
  const FlowTimelineHelper._();

  static List<FlowTimelineStep> marketplaceOrder(
    MarketplaceOrderModel order,
  ) {
    final isCancelled = order.status == 'cancelled';
    if (isCancelled) {
      return [
        FlowTimelineStep(
          label: 'Pedido creado',
          state: FlowTimelineStepState.completed,
          occurredAt: order.createdAt,
        ),
        FlowTimelineStep(
          label: 'Pedido cancelado',
          state: FlowTimelineStepState.error,
          occurredAt: order.updatedAt,
          icon: Icons.cancel_outlined,
        ),
      ];
    }

    final labels = order.fulfillment == 'warehouse_delivery'
        ? const [
            'Pedido creado',
            'Pago confirmado',
            'En preparación',
            'En camino al punto de retiro',
            'Listo para retirar',
            'Entregado',
          ]
        : const [
            'Pedido creado',
            'Pago confirmado',
            'En preparación',
            'Listo para retirar',
            'Entregado',
          ];
    final currentIndex = _orderIndex(order, labels.length);

    return List.generate(labels.length, (index) {
      final completedAll = order.status == 'delivered';
      final state = completedAll || index < currentIndex
          ? FlowTimelineStepState.completed
          : index == currentIndex
              ? FlowTimelineStepState.current
              : FlowTimelineStepState.upcoming;
      DateTime? occurredAt;
      if (index == 0) occurredAt = order.createdAt;
      if (completedAll && index == labels.length - 1) {
        occurredAt = order.updatedAt;
      }

      return FlowTimelineStep(
        label: labels[index],
        state: state,
        occurredAt: occurredAt,
      );
    });
  }

  static int _orderIndex(MarketplaceOrderModel order, int length) {
    final warehouseOffset = order.fulfillment == 'warehouse_delivery';
    return switch (order.status) {
      'pending' => 0,
      'paid' => 1,
      'preparing' => 2,
      'in_delivery' => warehouseOffset ? 3 : 2,
      'ready_for_pickup' => warehouseOffset ? 4 : 3,
      'delivered' => length - 1,
      _ => 0,
    };
  }

  static List<FlowTimelineStep> warehouseStockRequest(
    WarehouseStockRequestModel request,
  ) {
    if (request.status == 'rejected' || request.status == 'cancelled') {
      return [
        FlowTimelineStep(
          label: 'Solicitud creada',
          state: FlowTimelineStepState.completed,
          occurredAt: request.createdAt,
        ),
        FlowTimelineStep(
          label: request.status == 'rejected'
              ? 'Solicitud rechazada'
              : 'Solicitud cancelada',
          state: FlowTimelineStepState.error,
          occurredAt: request.processedAt,
        ),
      ];
    }

    const labels = [
      'Solicitud creada',
      'Aprobada por el almacén',
      'Productos enviados',
      'Productos recibidos',
    ];
    final currentIndex = switch (request.status) {
      'approved' => 1,
      'sent' => 2,
      'received' => 3,
      _ => 0,
    };

    return List.generate(labels.length, (index) {
      final completedAll = request.status == 'received';
      final state = completedAll || index < currentIndex
          ? FlowTimelineStepState.completed
          : index == currentIndex
              ? FlowTimelineStepState.current
              : FlowTimelineStepState.upcoming;
      final occurredAt = switch (index) {
        0 => request.createdAt,
        1 => request.processedAt,
        2 => request.sentAt,
        3 => request.receivedAt,
        _ => null,
      };

      return FlowTimelineStep(
        label: labels[index],
        state: state,
        occurredAt: occurredAt,
      );
    });
  }

  static List<FlowTimelineStep> approval({
    required ApprovalStatus status,
    DateTime? createdAt,
    DateTime? reviewedAt,
    String submittedLabel = 'Solicitud enviada',
  }) {
    if (status == ApprovalStatus.rejected) {
      return [
        FlowTimelineStep(
          label: submittedLabel,
          state: FlowTimelineStepState.completed,
          occurredAt: createdAt,
        ),
        const FlowTimelineStep(
          label: 'Revisión administrativa',
          state: FlowTimelineStepState.completed,
        ),
        FlowTimelineStep(
          label: 'Solicitud rechazada',
          state: FlowTimelineStepState.error,
          occurredAt: reviewedAt,
        ),
      ];
    }

    final approved = status == ApprovalStatus.approved;
    return [
      FlowTimelineStep(
        label: submittedLabel,
        state: FlowTimelineStepState.completed,
        occurredAt: createdAt,
      ),
      FlowTimelineStep(
        label: 'Revisión administrativa',
        state: approved
            ? FlowTimelineStepState.completed
            : FlowTimelineStepState.current,
      ),
      FlowTimelineStep(
        label: 'Solicitud aprobada',
        state: approved
            ? FlowTimelineStepState.completed
            : FlowTimelineStepState.upcoming,
        occurredAt: approved ? reviewedAt : null,
      ),
    ];
  }
}
