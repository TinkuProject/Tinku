import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/utils.dart';
import '../../controllers/business/location_controller.dart';
import '../../controllers/marketplace/warehouse_controller.dart';
import '../../core/enums.dart';
import '../../helpers/flow_timeline_helper.dart';
import '../../models/business_model.dart';
import '../../models/product_model.dart';
import '../../models/warehouse_model.dart';
import '../../providers/user_provider.dart';
import '../../services/business_service.dart';
import '../../services/product_service.dart';
import '../../services/system_config_service.dart';
import '../../services/warehouse_service.dart';
import 'marketplace_sales_orders_page.dart';
import '../../ui/themes/colors.dart';
import '../../widgets/common/loaders/app_loader.dart';
import '../../widgets/common/flow_timeline.dart';
import '../../widgets/common/app_tabs.dart';
import '../../widgets/common/navigation/custom_app_bar.dart';
import '../../widgets/shared/location/location_picker_section.dart';

part '../../widgets/marketplace/warehouses/warehouse_overview_widgets.dart';
part '../../widgets/marketplace/warehouses/warehouse_location_widgets.dart';
part '../../widgets/marketplace/warehouses/warehouse_stock_widgets.dart';
part '../../widgets/marketplace/warehouses/warehouse_form_widgets.dart';

class WarehousesPage extends StatefulWidget {
  const WarehousesPage({super.key});

  @override
  State<WarehousesPage> createState() => _WarehousesPageState();
}

class _WarehousesPageState extends State<WarehousesPage>
    with SingleTickerProviderStateMixin {
  late WarehouseController c;
  late final TabController _tabController;
  late SystemConfigService _systemConfigService;
  late ProductService _productService;
  double _warehouseCreateCost = 0;

  bool get _isAdmin {
    final role = context.read<UserProvider>().user?.role;
    return role == UserRole.admin || role == UserRole.master;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final auth = context.read<UserProvider>().authService;
    _systemConfigService = SystemConfigService(auth);
    _productService = ProductService(auth);
    c = WarehouseController(
      WarehouseService(auth),
      BusinessService(auth),
    );
    Future.microtask(() => c.loadMine(admin: _isAdmin));
  }

  @override
  void dispose() {
    _tabController.dispose();
    c.dispose();
    super.dispose();
  }

  Future<void> _createWarehouse() async {
    final isPartner =
        context.read<UserProvider>().user?.role == UserRole.partner;
    if (isPartner && _warehouseCreateCost <= 0) {
      try {
        _warehouseCreateCost =
            await _systemConfigService.getBusinessCreateCost();
      } catch (_) {
        _warehouseCreateCost = 0;
      }
    }

    if (!mounted) return;

    final result = await showDialog<_WarehouseFormData>(
      context: context,
      builder: (_) => _WarehouseDialog(
        createCost: isPartner ? _warehouseCreateCost : null,
      ),
    );
    if (result == null) return;

    try {
      await c.createWarehouse(
        name: result.name,
        admin: _isAdmin,
        description: result.description,
        phone: result.phone,
        email: result.email,
        address: result.address,
        latitude: result.latitude,
        longitude: result.longitude,
      );
      showSnackbar(
        _isAdmin ? 'Almacén creado.' : 'Almacén enviado a revisión.',
      );
    } catch (_) {
      showSnackbar('No se pudo crear el almacén.', isError: true);
    }
  }

  Future<void> _configureBusiness(BusinessModel business) async {
    final current = await c.getFulfillment(business.id);
    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (_) => _FulfillmentSheet(
        business: business,
        warehouses: c.allWarehouses,
        current: current,
        onSave: ({
          required pickupInStore,
          required warehouseDelivery,
          required warehouseIds,
          notes,
        }) async {
          await c.saveFulfillment(
            businessId: business.id,
            pickupInStore: pickupInStore,
            warehouseDelivery: warehouseDelivery,
            warehouseIds: warehouseIds,
            notes: notes,
          );
          if (mounted) {
            showSnackbar('Opciones de entrega actualizadas.');
          }
        },
      ),
    );
  }

  Future<void> _showInventory(WarehouseModel warehouse) async {
    if (!_canManageWarehouse(warehouse)) {
      showSnackbar('Solo el dueño del almacén puede ver su inventario.',
          isError: true);
      return;
    }

    await c.loadInventory(warehouse.id);
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (_) => _InventorySheet(
        warehouse: warehouse,
        inventory: c.inventory,
        locations: c.locations,
        onAssignLocation: (item, locationId) async {
          await c.setInventoryLocation(
            warehouseId: warehouse.id,
            item: item,
            locationId: locationId,
          );
          if (mounted) showSnackbar('Ubicación actualizada.');
        },
      ),
    );
  }

  Future<void> _showLocations(WarehouseModel warehouse) async {
    if (!_canManageWarehouse(warehouse)) {
      showSnackbar('Solo el dueño del almacén puede gestionar ubicaciones.',
          isError: true);
      return;
    }

    await c.loadLocations(warehouse.id);
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (_) => _LocationsSheet(
        warehouse: warehouse,
        locations: c.locations,
        onSave: ({
          location,
          parentId,
          required name,
          required code,
          description,
          required sortOrder,
        }) async {
          await c.saveLocation(
            warehouseId: warehouse.id,
            location: location,
            parentId: parentId,
            name: name,
            code: code,
            description: description,
            sortOrder: sortOrder,
          );
          if (mounted) showSnackbar('Ubicación guardada.');
          return c.locations;
        },
        onArchive: (location) async {
          await c.archiveLocation(
              warehouseId: warehouse.id, location: location);
          if (mounted) showSnackbar('Ubicación desactivada.');
        },
      ),
    );
  }

  Future<void> _requestWarehouseStock() async {
    try {
      final products = await _productService.getMine();
      if (!mounted) return;

      final result = await showModalBottomSheet<_StockRequestFormData>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        backgroundColor: AppColors.surface,
        builder: (_) => _StockRequestSheet(
          businesses: c.businesses
              .where((business) =>
                  business.validated &&
                  business.status == BusinessStatus.active)
              .toList(),
          warehouses: c.allWarehouses,
          products: products,
        ),
      );
      if (result == null) return;

      await c.createStockRequest(
        businessId: result.businessId,
        warehouseId: result.warehouseId,
        productId: result.productId,
        quantity: result.quantity,
        notes: result.notes,
        admin: _isAdmin,
      );
      showSnackbar('Solicitud enviada al almacén.');
    } catch (_) {
      if (!mounted) return;
      showSnackbar('No se pudo enviar la solicitud.', isError: true);
    }
  }

  Future<void> _approveStockRequest(WarehouseStockRequestModel request) async {
    await c.loadLocations(request.warehouseId);
    if (!mounted) return;
    final locationId = await showDialog<int?>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ApproveStockRequestDialog(
        request: request,
        locations: c.locations,
      ),
    );
    if (!mounted || locationId == -1) return;

    try {
      await c.approveStockRequest(
        request,
        admin: _isAdmin,
        locationId: locationId,
      );
      showSnackbar('Solicitud aprobada. Esperando envío del negocio.');
    } catch (_) {
      showSnackbar('No se pudo aprobar la solicitud.', isError: true);
    }
  }

  Future<void> _markStockRequestSent(WarehouseStockRequestModel request) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Marcar como enviado'),
        content: Text(
          'Confirmas que enviaste ${request.quantity} uds. de ${request.productName} a ${request.warehouseName}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await c.markStockRequestSent(request, admin: _isAdmin);
      showSnackbar('Envío marcado. El almacén debe confirmar recepción.');
    } catch (_) {
      showSnackbar('No se pudo marcar como enviado.', isError: true);
    }
  }

  Future<void> _receiveStockRequest(WarehouseStockRequestModel request) async {
    await c.loadLocations(request.warehouseId);
    if (!mounted) return;
    final locationId = await showDialog<int?>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ApproveStockRequestDialog(
        request: request,
        locations: c.locations,
        title: 'Recibir productos',
        actionLabel: 'Recibir',
      ),
    );
    if (!mounted || locationId == -1) return;

    try {
      await c.receiveStockRequest(
        request,
        admin: _isAdmin,
        locationId: locationId,
      );
      showSnackbar('Productos recibidos. Inventario actualizado.');
    } catch (_) {
      showSnackbar('No se pudo recibir la solicitud.', isError: true);
    }
  }

  Future<void> _rejectStockRequest(WarehouseStockRequestModel request) async {
    final controller = TextEditingController();
    String? validationError;
    final message = await showDialog<String?>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Rechazar solicitud'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Se rechazará el envío de ${request.productName}.'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Motivo del rechazo *',
                  errorText: validationError,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isEmpty) {
                  setDialogState(() {
                    validationError = 'Ingresa el motivo del rechazo';
                  });
                  return;
                }
                Navigator.pop(context, text);
              },
              child: const Text('Rechazar'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (message == null) return;

    try {
      await c.rejectStockRequest(request, message: message, admin: _isAdmin);
      showSnackbar('Solicitud rechazada.');
    } catch (_) {
      showSnackbar('No se pudo rechazar la solicitud.', isError: true);
    }
  }

  Future<void> _approveWarehouse(WarehouseModel warehouse) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aprobar almacén'),
        content: Text(
          'El almacén "${warehouse.name}" quedará visible como punto de retiro.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Aprobar'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await c.approveWarehouse(warehouse);
      showSnackbar('Almacén aprobado.');
    } catch (_) {
      showSnackbar('No se pudo aprobar.', isError: true);
    }
  }

  Future<void> _rejectWarehouse(WarehouseModel warehouse) async {
    final controller = TextEditingController();
    String? validationError;
    final message = await showDialog<String?>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Rechazar almacén'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'El almacén "${warehouse.name}" dejará la lista de pendientes.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Motivo del rechazo *',
                  errorText: validationError,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isEmpty) {
                  setDialogState(() {
                    validationError = 'Ingresa el motivo del rechazo';
                  });
                  return;
                }
                Navigator.pop(context, text);
              },
              child: const Text('Rechazar'),
            ),
          ],
        ),
      ),
    );

    controller.dispose();
    if (message == null) return;

    try {
      await c.rejectWarehouse(warehouse, message: message);
      showSnackbar('Almacén rechazado.');
    } catch (_) {
      showSnackbar('No se pudo rechazar.', isError: true);
    }
  }

  bool _canManageWarehouse(WarehouseModel warehouse) {
    if (_isAdmin) return true;
    final userId = context.read<UserProvider>().user?.id;
    return userId != null && warehouse.ownerId == userId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Almacenes',
        subtitle: _isAdmin ? 'Panel administrativo' : 'Logística de productos',
        actions: [
          IconButton(
              tooltip: 'Pedidos para retirar',
              icon: const Icon(Icons.local_shipping_outlined),
              onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                      builder: (_) => const MarketplaceSalesOrdersPage(
                          warehouseOrders: true)))),
          IconButton(
            tooltip: 'Crear almacén',
            icon: const Icon(Icons.add),
            onPressed: _createWarehouse,
          ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: AnimatedBuilder(
        animation: c,
        builder: (context, _) {
          final list = c.warehouses;
          return Stack(
            children: [
              AppTabs(
                controller: _tabController,
                tabs: const ['Almacenes', 'Solicitudes'],
                children: [
                  _warehousesTab(list),
                  _requestsTab(),
                ],
              ),
              if (c.loading || c.saving)
                const AppLoader(message: 'Cargando almacenes...'),
            ],
          );
        },
      ),
    );
  }

  Widget _warehousesTab(List<WarehouseModel> warehouses) {
    return RefreshIndicator(
      onRefresh: () => c.loadMine(admin: _isAdmin),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
        children: [
          if (c.businesses.isNotEmpty) ...[
            const _SectionTitle('Opciones de entrega por negocio'),
            ...c.businesses.map((business) {
              final enabled = business.validated &&
                  business.status == BusinessStatus.active;
              return _BusinessFulfillmentCard(
                business: business,
                enabled: enabled,
                onTap: enabled ? () => _configureBusiness(business) : null,
              );
            }),
            const SizedBox(height: 18),
          ],
          const _SectionTitle('Almacenes'),
          if (c.error != null)
            _InlineEmpty(
              icon: Icons.error_outline,
              title: 'No se pudieron cargar los almacenes',
              subtitle: c.error!,
            )
          else if (warehouses.isEmpty && !c.loading)
            const _InlineEmpty(
              icon: Icons.warehouse_outlined,
              title: 'No hay almacenes para mostrar',
              subtitle:
                  'Crea un almacén o espera que se aprueben tus registros.',
            )
          else
            ...warehouses.map(
              (warehouse) => _WarehouseCard(
                warehouse: warehouse,
                isAdmin: _isAdmin,
                canManage: _canManageWarehouse(warehouse),
                onInventory: () => _showInventory(warehouse),
                onLocations: () => _showLocations(warehouse),
                onApprove: () => _approveWarehouse(warehouse),
                onReject: () => _rejectWarehouse(warehouse),
              ),
            ),
        ],
      ),
    );
  }

  Widget _requestsTab() {
    return RefreshIndicator(
      onRefresh: () => c.loadMine(admin: _isAdmin),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
        children: [
          if (c.businesses.isNotEmpty) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _requestWarehouseStock,
                icon: const Icon(Icons.move_to_inbox_outlined),
                label: const Text('Enviar productos a almacén'),
              ),
            ),
            const SizedBox(height: 18),
          ],
          const _SectionTitle('Solicitudes recibidas'),
          if (c.receivedRequests.isEmpty)
            const _InlineEmpty(
              icon: Icons.inbox_outlined,
              title: 'No hay solicitudes recibidas',
              subtitle:
                  'Cuando un negocio quiera enviar productos a tus almacenes, lo verás aquí.',
            )
          else
            ...c.receivedRequests.map(
              (request) => _StockRequestCard(
                request: request,
                received: true,
                onApprove: request.status == 'pending'
                    ? () => _approveStockRequest(request)
                    : null,
                onReceive:
                    request.status == 'approved' || request.status == 'sent'
                        ? () => _receiveStockRequest(request)
                        : null,
                onReject: request.status == 'pending'
                    ? () => _rejectStockRequest(request)
                    : null,
              ),
            ),
          const SizedBox(height: 18),
          const _SectionTitle('Solicitudes enviadas'),
          if (c.sentRequests.isEmpty)
            const _InlineEmpty(
              icon: Icons.outbox_outlined,
              title: 'No hay solicitudes enviadas',
              subtitle:
                  'Envía productos a un almacén para que el dueño los acepte y se cree su inventario.',
            )
          else
            ...c.sentRequests.map(
              (request) => _StockRequestCard(
                request: request,
                received: false,
                onMarkSent: request.status == 'approved'
                    ? () => _markStockRequestSent(request)
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}
