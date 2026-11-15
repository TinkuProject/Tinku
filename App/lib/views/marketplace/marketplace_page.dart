import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/utils.dart';
import '../../controllers/marketplace/marketplace_controller.dart';
import '../../helpers/error_message_helper.dart';
import '../../models/marketplace_model.dart';
import '../../models/warehouse_model.dart';
import '../../providers/user_provider.dart';
import '../../services/marketplace_service.dart';
import '../../services/business_service.dart';
import '../../services/product_service.dart';
import '../../services/warehouse_service.dart';
import '../../ui/themes/colors.dart';
import '../../widgets/common/loaders/app_loader.dart';
import '../../widgets/common/empty/app_empty.dart';
import '../../widgets/common/network_image_with_loader.dart';
import '../../widgets/common/navigation/custom_app_bar.dart';

class MarketplacePage extends StatefulWidget {
  const MarketplacePage({super.key});

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  late MarketplaceController c;
  late MarketplaceService marketplaceService;
  late WarehouseService warehouseService;

  @override
  void initState() {
    super.initState();
    final auth = context.read<UserProvider>().authService;
    marketplaceService = MarketplaceService(auth);
    warehouseService = WarehouseService(auth);
    c = MarketplaceController(
      marketplaceService,
      ProductService(auth),
      BusinessService(auth),
    )..addListener(_rebuild);
    Future.microtask(c.loadPublic);
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

  Future<void> _search() async {
    await c.loadPublic();
  }

  Future<void> _openFilters() async {
    var availability = c.availability;
    var volume = c.volume;
    var sort = c.sort;
    final minController =
        TextEditingController(text: c.minTinkus?.toString() ?? '');
    final maxController =
        TextEditingController(text: c.maxTinkus?.toString() ?? '');
    final result = await showModalBottomSheet<
        ({
          String availability,
          String? volume,
          int? min,
          int? max,
          String sort
        })>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, update) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 4, 20, MediaQuery.viewInsetsOf(sheetContext).bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Filtrar productos',
                    style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: availability,
                  decoration: const InputDecoration(
                      labelText: 'Disponibilidad',
                      border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Todos')),
                    DropdownMenuItem(
                        value: 'available', child: Text('Disponibles')),
                    DropdownMenuItem(
                        value: 'sold_out', child: Text('Agotados')),
                  ],
                  onChanged: (value) =>
                      update(() => availability = value ?? 'all'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: volume ?? 'all',
                  decoration: const InputDecoration(
                      labelText: 'Volumen', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Todos')),
                    DropdownMenuItem(value: 'small', child: Text('Pequeño')),
                    DropdownMenuItem(value: 'medium', child: Text('Mediano')),
                    DropdownMenuItem(value: 'large', child: Text('Grande')),
                  ],
                  onChanged: (value) =>
                      update(() => volume = value == 'all' ? null : value),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                      child: TextField(
                    controller: minController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Mín. Tinkus', border: OutlineInputBorder()),
                  )),
                  const SizedBox(width: 12),
                  Expanded(
                      child: TextField(
                    controller: maxController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Máx. Tinkus', border: OutlineInputBorder()),
                  )),
                ]),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: sort,
                  decoration: const InputDecoration(
                      labelText: 'Ordenar por', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(
                        value: 'newest', child: Text('Más recientes')),
                    DropdownMenuItem(
                        value: 'price_asc', child: Text('Menor precio')),
                    DropdownMenuItem(
                        value: 'price_desc', child: Text('Mayor precio')),
                    DropdownMenuItem(value: 'name', child: Text('Nombre')),
                  ],
                  onChanged: (value) => update(() => sort = value ?? 'newest'),
                ),
                const SizedBox(height: 16),
                Row(children: [
                  TextButton(
                    onPressed: () => Navigator.pop(sheetContext, (
                      availability: 'all',
                      volume: null,
                      min: null,
                      max: null,
                      sort: 'newest'
                    )),
                    child: const Text('Limpiar'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () {
                      final min = int.tryParse(minController.text.trim());
                      final max = int.tryParse(maxController.text.trim());
                      if ((minController.text.trim().isNotEmpty &&
                              min == null) ||
                          (maxController.text.trim().isNotEmpty &&
                              max == null) ||
                          (min != null && min < 0) ||
                          (max != null && max < 0) ||
                          (min != null && max != null && min > max)) {
                        ScaffoldMessenger.of(sheetContext).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Revisa el rango de precios en Tinkus')),
                        );
                        return;
                      }
                      Navigator.pop(sheetContext, (
                        availability: availability,
                        volume: volume,
                        min: min,
                        max: max,
                        sort: sort
                      ));
                    },
                    child: const Text('Aplicar'),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
    minController.dispose();
    maxController.dispose();
    if (!mounted || result == null) return;
    await c.setPublicFilters(
      availability: result.availability,
      volume: result.volume,
      minTinkus: result.min,
      maxTinkus: result.max,
      sort: result.sort,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<UserProvider>().user?.id;

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Marketplace',
        subtitle: 'Productos publicados en Tinku',
      ),
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: TextField(
                  onChanged: c.setSearch,
                  onSubmitted: (_) => _search(),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Buscar productos o negocios',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: _search,
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: _openFilters,
                    icon: Icon(
                        c.hasPublicFilters ? Icons.filter_alt : Icons.tune),
                    label: Text(
                        c.hasPublicFilters ? 'Filtros activos' : 'Filtros'),
                  ),
                ),
              ),
              Expanded(
                child: c.error != null && c.publications.isEmpty
                    ? _ErrorState(message: c.error!, onRetry: c.loadPublic)
                    : c.publications.isEmpty && !c.loading
                        ? _EmptyState(search: c.search)
                        : RefreshIndicator(
                            onRefresh: c.refreshPublic,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                              itemCount: c.publications.length +
                                  (c.hasMorePublications ? 1 : 0),
                              itemBuilder: (_, index) {
                                if (index == c.publications.length) {
                                  return Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: c.loadingMore
                                          ? const CircularProgressIndicator()
                                          : TextButton.icon(
                                              onPressed: c.loadMorePublic,
                                              icon:
                                                  const Icon(Icons.expand_more),
                                              label: Text(c.error ??
                                                  'Cargar más productos'),
                                            ),
                                    ),
                                  );
                                }
                                final item = c.publications[index];
                                return _PublicationCard(
                                  publication: item,
                                  onTap: () async {
                                    await c.registerView(item.businessId);
                                    if (!context.mounted) return;
                                    showModalBottomSheet(
                                      context: context,
                                      showDragHandle: true,
                                      isScrollControlled: true,
                                      backgroundColor: AppColors.surface,
                                      builder: (_) => _PublicationDetail(
                                        item: item,
                                        marketplaceService: marketplaceService,
                                        warehouseService: warehouseService,
                                        currentUserId: currentUserId,
                                        onOrderChanged: c.refreshPublic,
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
          if (c.loading) const AppLoader(message: 'Cargando marketplace...'),
        ],
      ),
    );
  }
}

class _PublicationCard extends StatelessWidget {
  const _PublicationCard({
    required this.publication,
    this.onTap,
  });

  final MarketplacePublicationModel publication;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isSoldOut =
        publication.status == 'sold_out' || publication.publishedStock <= 0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NetworkImageWithLoader(
              imageUrl: publication.productImageUrl,
              width: 96,
              height: 96,
              borderRadius: BorderRadius.circular(16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    publication.productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    publication.businessName,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                    ),
                  ),
                  if (publication.productDescription?.trim().isNotEmpty ==
                      true) ...[
                    const SizedBox(height: 5),
                    Text(
                      publication.productDescription!.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                        height: 1.25,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoChip(
                        icon: Icons.inventory_outlined,
                        label: isSoldOut
                            ? 'Agotado'
                            : '${publication.publishedStock} disponibles',
                      ),
                      if (publication.displayUnitTinkuPrice != null)
                        _InfoChip(
                          icon: Icons.toll_outlined,
                          label: '${publication.displayUnitTinkuPrice} Tinkus',
                        ),
                      _InfoChip(
                        icon: Icons.inventory_2_outlined,
                        label: _volumeTierLabel(publication.productVolumeTier),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _volumeTierLabel(String value) {
  switch (value) {
    case 'large':
      return 'Volumen grande';
    case 'medium':
      return 'Volumen mediano';
    default:
      return 'Volumen pequeño';
  }
}

class _PublicationDetail extends StatelessWidget {
  const _PublicationDetail({
    required this.item,
    required this.marketplaceService,
    required this.warehouseService,
    required this.onOrderChanged,
    this.currentUserId,
  });

  final MarketplacePublicationModel item;
  final MarketplaceService marketplaceService;
  final WarehouseService warehouseService;
  final Future<void> Function() onOrderChanged;
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    final isOwnPublication =
        currentUserId != null && item.businessOwnerId == currentUserId;
    final isSoldOut = item.status == 'sold_out' || item.publishedStock <= 0;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.productName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item.businessName,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            if (item.productDescription?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 14),
              Text(
                item.productDescription!,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  height: 1.35,
                ),
              ),
            ],
            const SizedBox(height: 16),
            _PublicationCard(publication: item),
            const SizedBox(height: 8),
            if (currentUserId == null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.login,
                          color: AppColors.darkBlue,
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Necesitas una cuenta para comprar y gestionar el retiro.',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final navigator = Navigator.of(context);
                          navigator.pop();
                          navigator.pushNamed('/login');
                        },
                        child: const Text('Inicia sesión para comprar'),
                      ),
                    ),
                  ],
                ),
              )
            else if (isOwnPublication)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.darkBlue,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'No puedes comprar productos publicados por tu negocio.',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (isSoldOut)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      color: AppColors.darkBlue,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Este producto está agotado por el momento.',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openOrderSheet(context),
                  icon: const Icon(Icons.shopping_bag_outlined),
                  label: const Text('Comprar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkBlue,
                    foregroundColor: AppColors.pureWhite,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openOrderSheet(BuildContext context) async {
    late final BusinessFulfillmentModel fulfillment;

    try {
      fulfillment = await warehouseService.getBusinessFulfillment(
        item.businessId,
      );
      if (!context.mounted) return;
    } catch (_) {
      showSnackbar(
        'No se pudieron cargar las opciones de entrega.',
        isError: true,
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (_) => _OrderSheet(
        item: item,
        fulfillment: fulfillment,
        marketplaceService: marketplaceService,
        onOrderChanged: onOrderChanged,
      ),
    );
  }
}

class _OrderSheet extends StatefulWidget {
  const _OrderSheet({
    required this.item,
    required this.fulfillment,
    required this.marketplaceService,
    required this.onOrderChanged,
  });

  final MarketplacePublicationModel item;
  final BusinessFulfillmentModel fulfillment;
  final MarketplaceService marketplaceService;
  final Future<void> Function() onOrderChanged;

  @override
  State<_OrderSheet> createState() => _OrderSheetState();
}

class _OrderSheetState extends State<_OrderSheet> {
  int quantity = 1;
  String? method;
  int? warehouseId;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.fulfillment.pickupInStore) {
      method = 'pickup';
    } else if (widget.fulfillment.warehouseDelivery &&
        widget.fulfillment.warehouses.isNotEmpty) {
      method = 'warehouse_delivery';
      warehouseId = widget.fulfillment.warehouses.first.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final max = widget.item.publishedStock;
    final productTotalTinkus =
        (widget.item.displayUnitTinkuPrice ?? 0) * quantity;
    final warehouseFeeTinkus = method == 'warehouse_delivery'
        ? widget.item.warehouseDeliveryRewardTinkus * quantity
        : 0;
    final totalTinkus = productTotalTinkus + warehouseFeeTinkus;
    WarehouseModel? selectedWarehouse;
    for (final warehouse in widget.fulfillment.warehouses) {
      if (warehouse.id == warehouseId) {
        selectedWarehouse = warehouse;
        break;
      }
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Confirmar pedido',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.item.productName,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  IconButton(
                    onPressed:
                        quantity > 1 ? () => setState(() => quantity--) : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text(
                    '$quantity',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  IconButton(
                    onPressed: quantity < max
                        ? () => setState(() => quantity++)
                        : null,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                  const Spacer(),
                  Text(
                    '$max disponibles',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Zona de retiro',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              if (widget.fulfillment.pickupInStore)
                _DeliveryOptionTile(
                  selected: method == 'pickup',
                  title: 'Retiro en tienda',
                  subtitle: _pickupSubtitle(
                    widget.item.businessName,
                    widget.item.businessAddress,
                  ),
                  icon: Icons.storefront_outlined,
                  onTap: () => setState(() => method = 'pickup'),
                ),
              if (widget.fulfillment.warehouseDelivery &&
                  widget.fulfillment.warehouses.isNotEmpty)
                _DeliveryOptionTile(
                  selected: method == 'warehouse_delivery',
                  title: 'Retiro en almacén',
                  subtitle: selectedWarehouse == null
                      ? 'Selecciona un almacén habilitado'
                      : _pickupSubtitle(
                          selectedWarehouse.name,
                          selectedWarehouse.address,
                        ),
                  icon: Icons.warehouse_outlined,
                  onTap: () {
                    setState(() {
                      method = 'warehouse_delivery';
                      warehouseId ??= widget.fulfillment.warehouses.first.id;
                    });
                  },
                ),
              if (method == 'warehouse_delivery')
                DropdownButtonFormField<int>(
                  initialValue: warehouseId,
                  decoration: const InputDecoration(
                    labelText: 'Almacén de retiro',
                  ),
                  items: widget.fulfillment.warehouses
                      .map(
                        (warehouse) => DropdownMenuItem(
                          value: warehouse.id,
                          child: Text(
                            warehouse.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => warehouseId = value),
                ),
              if (method == 'warehouse_delivery' &&
                  selectedWarehouse?.address?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 8),
                _PickupAddressNote(
                  icon: Icons.place_outlined,
                  text: selectedWarehouse!.address!.trim(),
                ),
              ],
              const SizedBox(height: 12),
              const Text(
                'Pago',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              _DeliveryOptionTile(
                selected: true,
                title: 'Pagar con Tinkus',
                subtitle:
                    'El cobro se descuenta automáticamente de tu monedero.',
                icon: Icons.toll_outlined,
                onTap: () {},
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total estimado',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$totalTinkus Tinkus',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    _TotalLine(
                      label: 'Productos',
                      value: '$productTotalTinkus Tinkus',
                    ),
                    if (warehouseFeeTinkus > 0)
                      _TotalLine(
                        label: 'Cargo de almacén',
                        value: '$warehouseFeeTinkus Tinkus',
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: saving ||
                          method == null ||
                          (method == 'warehouse_delivery' &&
                              warehouseId == null)
                      ? null
                      : _submit,
                  icon: saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: const Text(
                    'Confirmar compra',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => saving = true);

    try {
      await widget.marketplaceService.createOrder(
        publicationId: widget.item.id,
        quantity: quantity,
        paymentMethod: 'tinkus',
        fulfillment: method!,
        pickupBusinessId: method == 'pickup' ? widget.item.businessId : null,
        warehouseId: method == 'warehouse_delivery' ? warehouseId : null,
      );
      if (!mounted) return;
      await widget.onOrderChanged();
      if (!mounted) return;
      final navigator = Navigator.of(context);
      navigator.pop();
      navigator.pop();
      showSnackbar('Pedido creado correctamente.');
      navigator.pushNamed('/myMarketplaceOrders');
    } catch (e) {
      if (mounted) {
        showSnackbar(userFacingError(e), isError: true);
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
}

class _TotalLine extends StatelessWidget {
  const _TotalLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryOptionTile extends StatelessWidget {
  const _DeliveryOptionTile({
    required this.selected,
    required this.title,
    required this.icon,
    required this.onTap,
    this.subtitle,
  });

  final bool selected;
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.darkBlue.withValues(alpha: 0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.darkBlue : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.darkBlue, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? AppColors.darkBlue : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _PickupAddressNote extends StatelessWidget {
  const _PickupAddressNote({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.darkBlue, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _pickupSubtitle(String name, String? address) {
  final cleanAddress = address?.trim();
  if (cleanAddress == null || cleanAddress.isEmpty) {
    return name;
  }
  return '$name · $cleanAddress';
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.darkBlue),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.search});

  final String search;

  @override
  Widget build(BuildContext context) {
    final hasSearch = search.trim().isNotEmpty;

    return Center(
      child: AppEmptyState(
        icon:
            hasSearch ? Icons.manage_search_rounded : Icons.storefront_outlined,
        title: hasSearch
            ? 'Sin productos para "$search"'
            : 'Sin productos publicados',
        subtitle: hasSearch
            ? 'Prueba con otro producto, negocio o categoría.'
            : 'Cuando los comercios publiquen productos, aparecerán aquí.',
        iconColor: AppColors.darkBlue,
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message,
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
