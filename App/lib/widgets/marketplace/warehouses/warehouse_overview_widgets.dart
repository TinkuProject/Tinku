part of '../../../views/marketplace/warehouses_page.dart';

class _BusinessFulfillmentCard extends StatelessWidget {
  const _BusinessFulfillmentCard({
    required this.business,
    required this.enabled,
    required this.onTap,
  });

  final BusinessModel business;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: enabled ? AppColors.surface : AppColors.surfaceSoft,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        enabled: enabled,
        leading: Icon(
          Icons.storefront_outlined,
          color: enabled ? AppColors.darkBlue : AppColors.textSecondary,
        ),
        title: Text(
          business.name,
          style: TextStyle(
            color: enabled ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          enabled
              ? 'Configurar retiro en tienda y almacenes'
              : 'Pendiente de aprobación',
        ),
        trailing: enabled
            ? const Icon(Icons.chevron_right)
            : Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Pendiente',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
        onTap: onTap,
      ),
    );
  }
}

class _WarehouseCard extends StatelessWidget {
  const _WarehouseCard({
    required this.warehouse,
    required this.isAdmin,
    required this.canManage,
    required this.onInventory,
    required this.onLocations,
    required this.onApprove,
    required this.onReject,
  });

  final WarehouseModel warehouse;
  final bool isAdmin;
  final bool canManage;
  final VoidCallback onInventory;
  final VoidCallback onLocations;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
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
              const Icon(Icons.warehouse_outlined, color: AppColors.darkBlue),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  warehouse.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _WarehouseStatus(warehouse: warehouse),
            ],
          ),
          if (warehouse.address?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(
              warehouse.address!,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 12),
          if (isAdmin && !warehouse.validated)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close),
                    label: const Text('Rechazar'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check),
                    label: const Text('Aprobar'),
                  ),
                ),
              ],
            )
          else if (canManage)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onLocations,
                    icon: const Icon(Icons.view_module_outlined),
                    label: const Text('Ubicaciones'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onInventory,
                    icon: const Icon(Icons.inventory_2_outlined),
                    label: const Text('Inventario'),
                  ),
                ),
              ],
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Almacén asociado para retiro. El inventario lo gestiona su dueño.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
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

class _FulfillmentSheet extends StatefulWidget {
  const _FulfillmentSheet({
    required this.business,
    required this.warehouses,
    required this.current,
    required this.onSave,
  });

  final BusinessModel business;
  final List<WarehouseModel> warehouses;
  final BusinessFulfillmentModel current;
  final Future<void> Function({
    required bool pickupInStore,
    required bool warehouseDelivery,
    required List<int> warehouseIds,
    String? notes,
  }) onSave;

  @override
  State<_FulfillmentSheet> createState() => _FulfillmentSheetState();
}

class _FulfillmentSheetState extends State<_FulfillmentSheet> {
  late bool pickupInStore = widget.current.pickupInStore;
  late bool warehouseDelivery = widget.current.warehouseDelivery;
  late Set<int> selected = widget.current.warehouses.map((e) => e.id).toSet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.business.name,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            SwitchListTile(
              value: pickupInStore,
              onChanged: (v) => setState(() => pickupInStore = v),
              title: const Text('Retiro en tienda'),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              value: warehouseDelivery,
              onChanged: (v) => setState(() => warehouseDelivery = v),
              title: const Text('Entrega por almacén'),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),
            const Text(
              'Almacenes habilitados',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: widget.warehouses.map((warehouse) {
                  return CheckboxListTile(
                    value: selected.contains(warehouse.id),
                    onChanged: warehouseDelivery
                        ? (value) {
                            setState(() {
                              if (value == true) {
                                selected.add(warehouse.id);
                              } else {
                                selected.remove(warehouse.id);
                              }
                            });
                          }
                        : null,
                    title: Text(warehouse.name),
                    subtitle: Text(warehouse.address ?? 'Sin dirección'),
                    contentPadding: EdgeInsets.zero,
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save_outlined),
                label: const Text('Guardar'),
                onPressed: () async {
                  await widget.onSave(
                    pickupInStore: pickupInStore,
                    warehouseDelivery: warehouseDelivery,
                    warehouseIds: selected.toList(),
                  );
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InventorySheet extends StatelessWidget {
  const _InventorySheet({
    required this.warehouse,
    required this.inventory,
    required this.locations,
    required this.onAssignLocation,
  });

  final WarehouseModel warehouse;
  final List<WarehouseInventoryModel> inventory;
  final List<WarehouseLocationModel> locations;
  final Future<void> Function(WarehouseInventoryModel item, int? locationId)
      onAssignLocation;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              warehouse.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            if (inventory.isEmpty)
              const Text(
                'Todavía no hay productos en este almacén.',
                style: TextStyle(color: AppColors.textSecondary),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: inventory.length,
                  itemBuilder: (_, index) {
                    final item = inventory[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.businessName,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _InventoryChip(
                                icon: Icons.inventory_2_outlined,
                                label: '${item.quantity} uds.',
                              ),
                              _InventoryChip(
                                icon: Icons.place_outlined,
                                label: item.locationCode?.trim().isNotEmpty ==
                                        true
                                    ? '${item.locationCode} - ${item.locationName ?? ''}'
                                        .trim()
                                    : 'Sin ubicación',
                              ),
                              TextButton.icon(
                                onPressed: () async {
                                  final locationId = await showDialog<int?>(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (_) => _InventoryLocationDialog(
                                      item: item,
                                      locations: locations,
                                    ),
                                  );
                                  if (!context.mounted || locationId == -1) {
                                    return;
                                  }
                                  await onAssignLocation(item, locationId);
                                },
                                icon: const Icon(
                                    Icons.edit_location_alt_outlined),
                                label: const Text('Ubicar'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InventoryChip extends StatelessWidget {
  const _InventoryChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.sizeOf(context).width - 72;

    return Container(
      constraints: BoxConstraints(
        maxWidth: maxWidth.clamp(120.0, 220.0).toDouble(),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.darkBlue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.darkBlue.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.darkBlue),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.darkBlue,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
