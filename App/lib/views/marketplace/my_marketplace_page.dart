import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/utils.dart';
import '../../controllers/marketplace/marketplace_controller.dart';
import '../../core/enums.dart';
import '../../helpers/error_message_helper.dart';
import '../../models/marketplace_model.dart';
import '../../models/product_model.dart';
import '../../providers/user_provider.dart';
import '../../services/business_service.dart';
import '../../services/marketplace_service.dart';
import '../../services/product_service.dart';
import '../../services/warehouse_service.dart';
import '../../ui/themes/colors.dart';
import '../../widgets/common/empty/app_empty.dart';
import '../../widgets/common/loaders/app_loader.dart';
import '../../widgets/common/navigation/custom_app_bar.dart';
import '../../widgets/selectors/business_filter_select.dart';

class MyMarketplacePage extends StatefulWidget {
  const MyMarketplacePage({super.key});

  @override
  State<MyMarketplacePage> createState() => _MyMarketplacePageState();
}

class _MyMarketplacePageState extends State<MyMarketplacePage> {
  late MarketplaceController c;
  late WarehouseService warehouseService;

  @override
  void initState() {
    super.initState();
    final auth = context.read<UserProvider>().authService;
    warehouseService = WarehouseService(auth);
    c = MarketplaceController(
      MarketplaceService(auth),
      ProductService(auth),
      BusinessService(auth),
    )..addListener(_rebuild);
    Future.microtask(c.loadMine);
  }

  @override
  void dispose() {
    c.removeListener(_rebuild);
    c.dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  Future<void> _openPublishSheet() async {
    final product = await showModalBottomSheet<ProductModel>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (_) => _ProductPicker(products: c.myProducts),
    );

    if (!mounted || product == null) return;
    if (!await _ensureFulfillmentConfigured(product.businessId)) return;

    final data = await _showPublicationEditor(
      title: 'Stock a publicar',
      product: product,
    );
    if (data == null) return;

    final estimate = await _estimateOrNotify(product, data);
    if (estimate == null) return;

    final confirmed = await _confirmPublication(
      title: 'Confirmar publicación',
      data: data,
      estimate: estimate,
      previousCharged: 0,
    );
    if (confirmed != true) return;

    try {
      await c.publishProduct(
        product,
        data.stock,
        unitTinkuPrice: data.unitTinkuPrice,
      );
      showSnackbar('Producto publicado en marketplace.');
    } catch (e) {
      showSnackbar(userFacingError(e), isError: true);
    }
  }

  Future<void> _editStock(MarketplacePublicationModel publication) async {
    final product = ProductModel(
      id: publication.productId,
      businessId: publication.businessId,
      categoryId: 0,
      name: publication.productName,
      price: null,
      tinkuPrice: publication.unitTinkuPrice?.toDouble(),
      stock: null,
      status: ProductStatus.active,
      createdAt: DateTime.now(),
    );
    if (!await _ensureFulfillmentConfigured(product.businessId)) return;

    final data = await _showPublicationEditor(
      title: 'Actualizar publicación',
      product: product,
      initial: _PublicationFormData(
        stock: publication.publishedStock,
        unitTinkuPrice: publication.unitTinkuPrice,
      ),
    );
    if (data == null) return;

    final estimate = await _estimateOrNotify(product, data);
    if (estimate == null) return;

    final confirmed = await _confirmPublication(
      title: 'Confirmar actualización',
      data: data,
      estimate: estimate,
      previousCharged: publication.chargedTinkus,
    );
    if (confirmed != true) return;

    try {
      await c.updateStock(
        publication,
        data.stock,
        unitTinkuPrice: data.unitTinkuPrice,
      );
      showSnackbar('Publicación actualizada.');
    } catch (e) {
      showSnackbar(userFacingError(e), isError: true);
    }
  }

  Future<_PublicationFormData?> _showPublicationEditor({
    required String title,
    required ProductModel product,
    _PublicationFormData? initial,
  }) async {
    return showDialog<_PublicationFormData>(
      context: context,
      builder: (_) => _PublicationEditorDialog(
        key: ValueKey(
          "${product.id}-${initial?.stock ?? 'new'}-${initial?.unitTinkuPrice ?? 'new'}",
        ),
        title: title,
        product: product,
        initial: initial,
      ),
    );
  }

  Future<MarketplacePublicationEstimateModel?> _estimateOrNotify(
    ProductModel product,
    _PublicationFormData data,
  ) async {
    try {
      return await c.estimatePublication(
        product: product,
        stock: data.stock,
        unitTinkuPrice: data.unitTinkuPrice,
      );
    } catch (e) {
      showSnackbar(userFacingError(e), isError: true);
      return null;
    }
  }

  Future<bool> _ensureFulfillmentConfigured(int businessId) async {
    try {
      final fulfillment =
          await warehouseService.getBusinessFulfillment(businessId);
      final hasWarehouse =
          fulfillment.warehouseDelivery && fulfillment.warehouses.isNotEmpty;

      if (fulfillment.pickupInStore || hasWarehouse) return true;

      showSnackbar(
        'Configura retiro en tienda o un almacén antes de publicar productos.',
        isError: true,
      );
      return false;
    } catch (_) {
      showSnackbar(
        'No se pudo revisar la configuración de retiro del negocio.',
        isError: true,
      );
      return false;
    }
  }

  Future<bool?> _confirmPublication({
    required String title,
    required _PublicationFormData data,
    required MarketplacePublicationEstimateModel estimate,
    required int previousCharged,
  }) {
    final additional = estimate.costTinkus > previousCharged
        ? estimate.costTinkus - previousCharged
        : 0;
    final percent = (estimate.serviceFeeRate * 100).toStringAsFixed(0);
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ConfirmRow(label: 'Stock', value: '${data.stock}'),
            if (data.unitTinkuPrice != null)
              _ConfirmRow(
                label: 'Precio ingresado',
                value:
                    '${data.unitTinkuPrice} -> ${estimate.displayUnitTinkuPrice ?? '-'} Tinkus',
              ),
            _ConfirmRow(label: 'Incremento al comprador', value: '$percent%'),
            _ConfirmRow(
              label: 'Costo de publicación',
              value: '${estimate.costTinkus} Tinkus',
            ),
            _ConfirmRow(
              label: 'A descontar ahora',
              value: '$additional Tinkus',
            ),
            const SizedBox(height: 8),
            const Text(
              'El incremento lo paga el comprador. Tu precio base se respeta; este costo corresponde solo a publicar el producto.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 6),
            const Text(
              'Si reduces stock o precio no se devuelve el monto ya invertido.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleMine = c.visibleMine;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Ventas',
        subtitle: 'Publicaciones del marketplace',
        actions: [
          IconButton(
            tooltip: 'Pedidos recibidos',
            icon: const Icon(Icons.receipt_long_outlined),
            onPressed: () => Navigator.pushNamed(
              context,
              '/marketplaceSalesOrders',
            ),
          ),
          IconButton(
            tooltip: 'Publicar producto',
            icon: const Icon(Icons.add),
            onPressed: _openPublishSheet,
          ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          c.error != null
              ? Center(
                  child: AppEmptyState(
                    icon: Icons.error_outline,
                    title: 'No se pudieron cargar ventas',
                    subtitle: c.error!,
                    iconColor: AppColors.error,
                  ),
                )
              : c.mine.isEmpty && !c.loading
                  ? _EmptyManageState(onCreate: _openPublishSheet)
                  : RefreshIndicator(
                      onRefresh: c.refreshMine,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
                        itemCount: visibleMine.isEmpty
                            ? 2 + (c.hasMoreMine ? 1 : 0)
                            : visibleMine.length + 1 + (c.hasMoreMine ? 1 : 0),
                        itemBuilder: (_, index) {
                          if (index == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: BusinessFilterSelect(
                                value: c.selectedBusinessId,
                                items: c.businessSelectorItems,
                                onChanged: c.setSelectedBusiness,
                              ),
                            );
                          }

                          if (visibleMine.isEmpty && index == 1) {
                            return const _FilterEmptyState();
                          }

                          if (index > visibleMine.length) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: c.loadingMoreMine
                                    ? const CircularProgressIndicator()
                                    : TextButton.icon(
                                        onPressed: c.loadMoreMine,
                                        icon: const Icon(Icons.expand_more),
                                        label: Text(c.mineMoreError ??
                                            'Cargar más publicaciones'),
                                      ),
                              ),
                            );
                          }

                          final item = visibleMine[index - 1];
                          return _PublicationManageCard(
                            item: item,
                            onStock: () => _editStock(item),
                            onPause: () => c.updateStatus(
                              item,
                              item.status == 'active' ? 'paused' : 'active',
                            ),
                            onArchive: () => c.updateStatus(item, 'archived'),
                          );
                        },
                      ),
                    ),
          if (c.loading || c.saving)
            const AppLoader(message: 'Actualizando ventas...'),
        ],
      ),
    );
  }
}

class _PublicationManageCard extends StatelessWidget {
  const _PublicationManageCard({
    required this.item,
    required this.onStock,
    required this.onPause,
    required this.onArchive,
  });

  final MarketplacePublicationModel item;
  final VoidCallback onStock;
  final VoidCallback onPause;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final isActive = item.status == 'active';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
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
                  item.productName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _StatusPill(status: item.status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            item.businessName,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Metric(label: 'Stock', value: '${item.publishedStock}'),
              const _Metric(label: 'Pago', value: 'Tinkus'),
              if (item.displayUnitTinkuPrice != null)
                _Metric(
                  label: 'Catálogo',
                  value: '${item.displayUnitTinkuPrice} Tinkus',
                ),
              _Metric(label: 'Cobrado', value: '${item.chargedTinkus} Tinkus'),
              _Metric(
                label: 'Costo actual',
                value: '${item.calculatedCostTinkus} Tinkus',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onStock,
                  icon: const Icon(Icons.inventory_outlined),
                  label: const Text('Stock'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: onPause,
                  child: Text(isActive ? 'Pausar' : 'Activar'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Archivar',
                onPressed: onArchive,
                icon: const Icon(Icons.archive_outlined),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PublicationFormData {
  const _PublicationFormData({
    required this.stock,
    this.unitTinkuPrice,
  });

  final int stock;
  final int? unitTinkuPrice;
}

class _PublicationEditorDialog extends StatefulWidget {
  const _PublicationEditorDialog({
    super.key,
    required this.title,
    required this.product,
    this.initial,
  });

  final String title;
  final ProductModel product;
  final _PublicationFormData? initial;

  @override
  State<_PublicationEditorDialog> createState() =>
      _PublicationEditorDialogState();
}

class _PublicationEditorDialogState extends State<_PublicationEditorDialog> {
  late TextEditingController stockController;
  late TextEditingController tinkuPriceController;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  @override
  void didUpdateWidget(covariant _PublicationEditorDialog oldWidget) {
    super.didUpdateWidget(oldWidget);

    final productChanged = oldWidget.product.id != widget.product.id;
    final initialChanged = oldWidget.initial != widget.initial;
    if (!productChanged && !initialChanged) return;

    stockController.dispose();
    tinkuPriceController.dispose();
    _initControllers();
  }

  @override
  void dispose() {
    stockController.dispose();
    tinkuPriceController.dispose();
    super.dispose();
  }

  void _initControllers() {
    final initial = widget.initial;
    stockController = TextEditingController(
      text: initial?.stock.toString() ?? '',
    );
    tinkuPriceController = TextEditingController(
      text: initial?.unitTinkuPrice?.toString() ??
          _formatOptionalInt(widget.product.tinkuPrice),
    );
  }

  String _formatOptionalInt(double? value) {
    if (value == null || value <= 0) return '';
    return value.toInt().toString();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.product.name,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (widget.product.stock != null) ...[
              const SizedBox(height: 4),
              Text(
                'Stock disponible: ${widget.product.stock}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: 14),
            TextField(
              controller: stockController,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Stock a publicar *'),
            ),
            const SizedBox(height: 12),
            const Text(
              'Pago en marketplace',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.lightBlue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.toll_outlined,
                    color: AppColors.darkBlue,
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Las compras del marketplace se pagan sólo con Tinkus.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: tinkuPriceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Precio en Tinkus *',
              ),
            ),
            if (widget.product.tinkuPrice == null ||
                widget.product.tinkuPrice! <= 0) ...[
              const SizedBox(height: 8),
              const Text(
                'Configura este precio antes de publicar.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Continuar'),
        ),
      ],
    );
  }

  void _submit() {
    final stock = int.tryParse(stockController.text.trim());
    final unitTinkuPrice = int.tryParse(tinkuPriceController.text.trim());

    if (stock == null || stock < 0) return;
    if (widget.product.stock != null && stock > widget.product.stock!) return;
    if (unitTinkuPrice == null || unitTinkuPrice <= 0) return;

    Navigator.pop(
      context,
      _PublicationFormData(
        stock: stock,
        unitTinkuPrice: unitTinkuPrice,
      ),
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  const _ConfirmRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductPicker extends StatelessWidget {
  const _ProductPicker({required this.products});

  final List<ProductModel> products;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        children: [
          const Text(
            'Seleccionar producto',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          ...products.map(
            (product) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(product.name),
              subtitle: Text('Stock: ${product.stock ?? 0}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pop(context, product),
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
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.darkBlue.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: AppColors.darkBlue,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyManageState extends StatelessWidget {
  const _EmptyManageState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.storefront_outlined,
              color: AppColors.darkBlue,
              size: 42,
            ),
            const SizedBox(height: 12),
            const Text(
              'Todavía no tienes publicaciones',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Publica productos activos para probar el marketplace.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Publicar producto'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterEmptyState extends StatelessWidget {
  const _FilterEmptyState();

  @override
  Widget build(BuildContext context) {
    return const AppEmptyState(
      icon: Icons.storefront_outlined,
      title: 'Sin publicaciones',
      subtitle: 'No hay publicaciones para este negocio.',
      iconColor: AppColors.darkBlue,
    );
  }
}
