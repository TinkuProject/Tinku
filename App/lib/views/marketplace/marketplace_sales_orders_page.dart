import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../helpers/error_message_helper.dart';
import '../../models/marketplace_model.dart';
import '../../providers/user_provider.dart';
import '../../services/marketplace_service.dart';
import '../../ui/themes/colors.dart';
import '../../widgets/common/empty/app_empty.dart';
import '../../widgets/common/loaders/app_loader.dart';
import '../../widgets/common/navigation/custom_app_bar.dart';
import '../../widgets/marketplace/marketplace_pickup_scanner_page.dart';

class MarketplaceSalesOrdersPage extends StatefulWidget {
  const MarketplaceSalesOrdersPage({super.key, this.warehouseOrders = false});
  final bool warehouseOrders;

  @override
  State<MarketplaceSalesOrdersPage> createState() =>
      _MarketplaceSalesOrdersPageState();
}

class _MarketplaceSalesOrdersPageState
    extends State<MarketplaceSalesOrdersPage> {
  late final MarketplaceService service;
  final List<MarketplaceOrderModel> orders = [];
  bool loading = true;
  bool saving = false;
  bool loadingMore = false;
  bool hasMore = true;
  static const pageSize = 20;
  String? error;

  @override
  void initState() {
    super.initState();
    service = MarketplaceService(context.read<UserProvider>().authService);
    Future.microtask(load);
  }

  Future<void> load({bool reset = true}) async {
    if (loadingMore) return;
    setState(() {
      if (reset) { loading = true; } else { loadingMore = true; }
      error = null;
    });
    try {
      final offset = reset ? 0 : orders.length;
      final data = widget.warehouseOrders
          ? await service.getWarehouseOrders(limit: pageSize, offset: offset)
          : await service.getSalesOrders(limit: pageSize, offset: offset);
      if (!mounted) return;
      setState(() {
        if (reset) orders.clear();
        final existing = orders.map((order) => order.id).toSet();
        orders.addAll(data.where((order) => !existing.contains(order.id)));
        hasMore = data.length == pageSize;
      });
    } catch (e) {
      if (mounted) setState(() => error = userFacingError(e));
    } finally {
      if (mounted) setState(() { loading = false; loadingMore = false; });
    }
  }

  Future<void> changeStatus(MarketplaceOrderModel order, String status) async {
    setState(() => saving = true);
    try {
      if (widget.warehouseOrders) {
        await service.markWarehouseOrderReady(order.id);
      } else {
        await service.updateSalesOrderStatus(order.id, status);
      }
      await load();
      if (mounted) showMessage('Pedido actualizado.');
    } catch (e) {
      if (mounted) showMessage(userFacingError(e), error: true);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> rejectOrder(MarketplaceOrderModel order) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('No puedo completar el pedido'),
        content: TextField(
          controller: controller,
          minLines: 3,
          maxLines: 5,
          maxLength: 500,
          decoration: const InputDecoration(
            labelText: 'Motivo *',
            hintText: 'Explica por qué no puedes completar esta venta',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Volver'),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, value, __) => FilledButton(
              onPressed: value.text.trim().length < 10
                  ? null
                  : () => Navigator.pop(dialogContext, value.text.trim()),
              child: const Text('Cancelar y devolver'),
            ),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null || !mounted) return;

    setState(() => saving = true);
    try {
      await service.rejectSalesOrder(order.id, reason);
      await load();
      if (mounted) showMessage('Pedido cancelado y Tinkus devueltos.');
    } catch (e) {
      if (mounted) showMessage(userFacingError(e), error: true);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> openValidation() async {
    final mode = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Validar entrega',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Escanea el QR o ingresa la clave que muestra el comprador.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context, 'scan'),
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Escanear QR'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context, 'code'),
                icon: const Icon(Icons.password_outlined),
                label: const Text('Ingresar clave'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || mode == null) return;

    String? code;
    if (mode == 'scan') {
      code = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (_) => const MarketplacePickupScannerPage(),
        ),
      );
    } else {
      code = await askCode();
    }
    if (code == null || code.trim().isEmpty) return;
    await validate(code);
  }

  Future<String?> askCode() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clave de retiro'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Clave',
            hintText: 'TK-XXXXXXXX',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Validar'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> validate(String code) async {
    setState(() => saving = true);
    try {
      await service.validatePickupCode(code);
      await load();
      if (mounted) showMessage('Entrega validada correctamente.');
    } catch (e) {
      if (mounted) showMessage(userFacingError(e), error: true);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  void showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              error ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: error ? AppColors.error : AppColors.darkBlue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.warehouseOrders ? 'Retiros del almacén' : 'Pedidos recibidos',
        subtitle: widget.warehouseOrders ? 'Pedidos y entregas a compradores' : 'Preparación y entrega de tus ventas',
        actions: [
          IconButton(
            tooltip: 'Validar retiro',
            onPressed: saving ? null : openValidation,
            icon: const Icon(Icons.qr_code_scanner),
          ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          if (error != null && orders.isEmpty)
            Center(
              child: AppEmptyState(
                icon: Icons.error_outline,
                title: 'No se pudieron cargar los pedidos',
                subtitle: error!,
                iconColor: AppColors.error,
              ),
            )
          else if (!loading && orders.isEmpty)
            const Center(
              child: AppEmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Todavía no recibiste pedidos',
                subtitle: 'Las compras de tus publicaciones aparecerán acá.',
                iconColor: AppColors.darkBlue,
              ),
            )
          else
            RefreshIndicator(
              onRefresh: load,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
                itemCount: orders.length + (hasMore ? 1 : 0),
                itemBuilder: (_, index) => index == orders.length
                  ? Center(child: TextButton.icon(onPressed: loadingMore ? null : () => load(reset: false),
                      icon: const Icon(Icons.expand_more), label: Text(loadingMore ? 'Cargando...' : 'Cargar más')))
                  : _SalesOrderCard(
                  order: orders[index],
                  warehouseOrders: widget.warehouseOrders,
                  onStatus: (status) => changeStatus(orders[index], status),
                  onReject: () => rejectOrder(orders[index]),
                ),
              ),
            ),
          if (loading || saving)
            AppLoader(
              message:
                  saving ? 'Actualizando pedido...' : 'Cargando pedidos...',
            ),
        ],
      ),
    );
  }
}

class _SalesOrderCard extends StatelessWidget {
  const _SalesOrderCard({
    required this.order,
    required this.onStatus,
    required this.onReject,
    this.warehouseOrders = false,
  });
  final bool warehouseOrders;

  final MarketplaceOrderModel order;
  final ValueChanged<String> onStatus;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final buyer = order.buyerName?.trim().isNotEmpty == true
        ? order.buyerName!
        : '@${order.buyerUsername ?? 'usuario'}';
    final date = order.createdAt == null
        ? ''
        : DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt!.toLocal());
    final nextStatus = warehouseOrders && {'paid', 'preparing', 'in_delivery'}.contains(order.status)
        ? 'ready_for_pickup'
        : warehouseOrders ? null : order.status == 'paid'
        ? 'preparing'
        : order.status == 'preparing' && order.fulfillment == 'pickup'
            ? 'ready_for_pickup'
            : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
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
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                _salesStatusLabel(order.status),
                style: const TextStyle(
                  color: AppColors.darkBlue,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$buyer${date.isEmpty ? '' : ' · $date'}',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          if (order.status != 'delivered' && order.status != 'cancelled') ...[
            const SizedBox(height: 8),
            const Text(
              'Los Tinkus de la venta se acreditan cuando se confirma la entrega.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
          const Divider(height: 24),
          ...order.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.productName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${item.quantity} x ${item.unitTinkuPrice ?? 0} T',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          Text(
            order.fulfillment == 'pickup'
                ? 'Retiro en ${order.pickupBusinessName ?? 'tienda'}'
                : 'Entrega mediante ${order.warehouseName ?? 'almacén'}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          if (nextStatus != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => onStatus(nextStatus),
                icon: Icon(
                  nextStatus == 'preparing'
                      ? Icons.inventory_2_outlined
                      : Icons.storefront_outlined,
                ),
                label: Text(
                  nextStatus == 'preparing'
                      ? 'Comenzar preparación'
                      : 'Marcar listo para retirar',
                ),
              ),
            ),
          ],
          if (!warehouseOrders && (order.status == 'paid' || order.status == 'preparing')) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: onReject,
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('No puedo completar el pedido'),
              ),
            ),
          ],
          if (order.status == 'cancelled' &&
              order.cancellationReason?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(
              'Motivo: ${order.cancellationReason}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

String _salesStatusLabel(String status) => switch (status) {
      'paid' => 'Pagado',
      'preparing' => 'Preparando',
      'ready_for_pickup' => 'Listo',
      'in_delivery' => 'En camino',
      'delivered' => 'Entregado',
      'cancelled' => 'Cancelado',
      _ => 'Pendiente',
    };
