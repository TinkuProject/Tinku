import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/marketplace_model.dart';
import '../../helpers/flow_timeline_helper.dart';
import '../../providers/user_provider.dart';
import '../../services/marketplace_service.dart';
import '../../ui/themes/colors.dart';
import '../../widgets/common/empty/app_empty.dart';
import '../../widgets/common/flow_timeline.dart';
import '../../widgets/common/loaders/app_loader.dart';
import '../../widgets/common/navigation/custom_app_bar.dart';

class MyMarketplaceOrdersPage extends StatefulWidget {
  const MyMarketplaceOrdersPage({super.key});

  @override
  State<MyMarketplaceOrdersPage> createState() =>
      _MyMarketplaceOrdersPageState();
}

class _MyMarketplaceOrdersPageState extends State<MyMarketplaceOrdersPage> {
  late final MarketplaceService marketplaceService;
  final List<MarketplaceOrderModel> orders = [];
  bool loading = true;
  bool loadingMore = false;
  bool hasMore = true;
  String? error;
  int offset = 0;
  Timer? refreshTimer;
  static const int limit = 20;

  @override
  void initState() {
    super.initState();
    final auth = context.read<UserProvider>().authService;
    marketplaceService = MarketplaceService(auth);
    Future.microtask(_load);
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool reset = true, bool silent = false}) async {
    refreshTimer?.cancel();
    if (reset) {
      if (silent) {
        offset = 0;
      } else {
        setState(() {
          loading = true;
          error = null;
          offset = 0;
        });
      }
    } else {
      setState(() => loadingMore = true);
    }

    try {
      final loaded = await marketplaceService.getMyOrders(
        limit: limit,
        offset: reset ? 0 : offset,
      );
      if (!mounted) return;
      setState(() {
        error = null;
        if (reset) {
          final previous = silent
              ? List<MarketplaceOrderModel>.of(orders)
              : <MarketplaceOrderModel>[];
          final receivedIds = loaded.map((order) => order.id).toSet();
          orders
            ..clear()
            ..addAll(loaded)
            ..addAll(
                previous.where((order) => !receivedIds.contains(order.id)));
        } else {
          orders.addAll(loaded);
        }
        offset = orders.length;
        if (!silent) hasMore = loaded.length == limit;
      });
      _scheduleAutoRefresh();
    } catch (_) {
      if (!mounted) return;
      if (silent && orders.isNotEmpty) {
        _scheduleAutoRefresh();
      } else {
        setState(() => error = 'No se pudieron cargar tus compras.');
      }
    } finally {
      if (mounted && (!silent || loadingMore)) {
        setState(() {
          loading = false;
          loadingMore = false;
        });
      }
    }
  }

  void _scheduleAutoRefresh() {
    refreshTimer?.cancel();
    final hasOpenOrders = orders.any(
      (order) => !{'delivered', 'cancelled'}.contains(order.status),
    );
    if (!hasOpenOrders) return;

    refreshTimer = Timer(
      const Duration(seconds: 20),
      () {
        if (mounted) _load(reset: true, silent: true);
      },
    );
  }

  Future<void> _cancelOrder(MarketplaceOrderModel order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar pedido'),
        content: const Text(
          'Se devolverán tus Tinkus y el stock volverá a estar disponible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancelar pedido'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await marketplaceService.cancelOrder(order.id);
      await _load(reset: true, silent: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pedido cancelado y Tinkus devueltos.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo cancelar este pedido.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Mis compras',
        subtitle: 'Pedidos y retiros del marketplace',
      ),
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          if (error != null)
            const Center(
              child: AppEmptyState(
                icon: Icons.error_outline,
                title: 'No se pudieron cargar tus compras',
                subtitle: 'Desliza para reintentar o vuelve a entrar.',
                iconColor: AppColors.error,
              ),
            )
          else if (!loading && orders.isEmpty)
            const Center(
              child: AppEmptyState(
                icon: Icons.shopping_bag_outlined,
                title: 'Todavía no tienes compras',
                subtitle:
                    'Cuando compres productos, verás acá su estado y retiro.',
                iconColor: AppColors.darkBlue,
              ),
            )
          else
            RefreshIndicator(
              onRefresh: () => _load(reset: true),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
                itemCount: orders.length + (hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == orders.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: OutlinedButton(
                        onPressed:
                            loadingMore ? null : () => _load(reset: false),
                        child: Text(
                          loadingMore ? 'Cargando...' : 'Cargar más',
                        ),
                      ),
                    );
                  }

                  return _OrderCard(
                    order: orders[index],
                    onCancel: () => _cancelOrder(orders[index]),
                  );
                },
              ),
            ),
          if (loading) const AppLoader(message: 'Cargando compras...'),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onCancel});

  final MarketplaceOrderModel order;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final date = order.createdAt == null
        ? null
        : DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt!);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Pedido #${order.id}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _StatusPill(label: _statusLabel(order.status)),
            ],
          ),
          if (date != null) ...[
            const SizedBox(height: 4),
            Text(
              date,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 12),
          ...order.items.map((item) => _OrderItemRow(item: item)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Metric(label: 'Pago', value: _paymentLabel(order)),
              _Metric(label: 'Entrega', value: _fulfillmentLabel(order)),
              if (order.warehouseDeliveryFeeTinkus > 0)
                _Metric(
                  label: 'Almacén',
                  value: '${order.warehouseDeliveryFeeTinkus} Tinkus',
                ),
            ],
          ),
          const SizedBox(height: 12),
          FlowTimelinePanel(
            steps: FlowTimelineHelper.marketplaceOrder(order),
            title: 'Seguimiento del pedido',
          ),
          const SizedBox(height: 12),
          _PickupNotice(order: order),
          if (order.status == 'cancelled' &&
              order.cancellationReason?.isNotEmpty == true) ...[
            const SizedBox(height: 10),
            Text(
              'Motivo de cancelación: ${order.cancellationReason}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (_shouldShowPickupPanel(order)) ...[
            const SizedBox(height: 12),
            _PickupCodePanel(order: order),
          ],
          if (order.status == 'paid') ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: onCancel,
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Cancelar pedido'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PickupCodePanel extends StatelessWidget {
  const _PickupCodePanel({required this.order});

  final MarketplaceOrderModel order;

  @override
  Widget build(BuildContext context) {
    final code = order.pickupCode;
    final normalizedCode = code?.trim() ?? '';
    final hasCode = normalizedCode.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.darkBlue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.darkBlue.withValues(alpha: 0.22)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final qr = hasCode
              ? Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: QrImageView(
                    data: normalizedCode,
                    version: QrVersions.auto,
                    size: constraints.maxWidth < 340 ? 96 : 118,
                    backgroundColor: Colors.white,
                  ),
                )
              : const Icon(
                  Icons.qr_code_2,
                  color: AppColors.textSecondary,
                  size: 42,
                );

          final details = Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasCode ? 'Código de retiro' : 'Código pendiente',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasCode
                      ? normalizedCode
                      : 'Esta compra aún no tiene código de retiro. Actualiza en unos segundos.',
                  style: TextStyle(
                    color:
                        hasCode ? AppColors.darkBlue : AppColors.textSecondary,
                    fontSize: hasCode ? 18 : 13,
                    fontWeight: hasCode ? FontWeight.w900 : FontWeight.w600,
                  ),
                ),
                if (hasCode) ...[
                  const SizedBox(height: 6),
                  const Text(
                    'Muestra este QR o menciona el código al retirar tu producto.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.25,
                    ),
                  ),
                ],
              ],
            ),
          );

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              qr,
              const SizedBox(width: 12),
              details,
            ],
          );
        },
      ),
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({required this.item});

  final MarketplaceOrderItemModel item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.darkBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${item.quantity}',
              style: const TextStyle(
                color: AppColors.darkBlue,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  item.businessName,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PickupNotice extends StatelessWidget {
  const _PickupNotice({required this.order});

  final MarketplaceOrderModel order;

  @override
  Widget build(BuildContext context) {
    final delivery = order.deliveries.isEmpty ? null : order.deliveries.first;
    final title = order.fulfillment == 'pickup'
        ? 'Retiro en tienda'
        : 'Retiro en almacén';
    final place = order.fulfillment == 'pickup'
        ? order.pickupBusinessName
        : order.warehouseName;
    final address = order.fulfillment == 'pickup'
        ? order.pickupBusinessAddress
        : order.warehouseAddress;
    final status = delivery?.status ?? order.status;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.location_on_outlined, color: AppColors.darkBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _pickupMessage(order.status, status),
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                if (order.status == 'ready_for_pickup' &&
                    order.pickupExpiresAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    order.pickupExpiresAt!.isAfter(DateTime.now())
                        ? 'Disponible hasta ${DateFormat('dd/MM/yyyy HH:mm').format(order.pickupExpiresAt!.toLocal())}'
                        : 'El plazo de retiro venció. Estamos procesando la devolución de tus Tinkus.',
                    style: const TextStyle(
                      color: AppColors.darkBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                if (place?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 6),
                  Text(
                    place!,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                if (address?.trim().isNotEmpty == true)
                  Text(
                    address!,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.darkBlue.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.darkBlue,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

String _statusLabel(String status) {
  return switch (status) {
    'pending' => 'Pendiente',
    'paid' => 'Pagado',
    'preparing' => 'Preparando',
    'ready_for_pickup' => 'Listo para retiro',
    'in_delivery' => 'En camino',
    'delivered' => 'Entregado',
    'cancelled' => 'Cancelado',
    _ => status,
  };
}

String _paymentLabel(MarketplaceOrderModel order) {
  if (order.paymentMethod == 'stripe') {
    return '${order.totalAmount.toStringAsFixed(2)} Bs';
  }

  return '${order.totalTinkus} Tinkus';
}

bool _shouldShowPickupPanel(MarketplaceOrderModel order) {
  return order.status == 'ready_for_pickup' &&
      order.pickupExpiresAt != null &&
      order.pickupExpiresAt!.isAfter(DateTime.now());
}

String _fulfillmentLabel(MarketplaceOrderModel order) {
  return order.fulfillment == 'warehouse_delivery' ? 'Almacén' : 'Tienda';
}

String _pickupMessage(String orderStatus, String deliveryStatus) {
  if (orderStatus == 'cancelled') return 'Este pedido fue cancelado.';
  if (orderStatus == 'pending') {
    return 'Estamos esperando la confirmación del pago.';
  }
  if (orderStatus == 'paid' || orderStatus == 'preparing') {
    return 'Tu pedido fue pagado. Te avisaremos cuando esté listo para retirar.';
  }
  if (deliveryStatus == 'assigned' || deliveryStatus == 'picked_up') {
    return 'El almacén ya está gestionando tu pedido. Te avisaremos cuando puedas retirarlo.';
  }
  if (orderStatus == 'ready_for_pickup') {
    return 'Ya puedes pasar a retirar tu producto.';
  }
  if (orderStatus == 'delivered' || deliveryStatus == 'delivered') {
    return 'Este pedido ya fue entregado.';
  }

  return 'Sigue el estado de tu pedido desde esta pantalla.';
}
