part of '../../../views/marketplace/warehouses_page.dart';

class _StockRequestSheet extends StatefulWidget {
  const _StockRequestSheet({
    required this.businesses,
    required this.warehouses,
    required this.products,
  });

  final List<BusinessModel> businesses;
  final List<WarehouseModel> warehouses;
  final List<ProductModel> products;

  @override
  State<_StockRequestSheet> createState() => _StockRequestSheetState();
}

class _StockRequestSheetState extends State<_StockRequestSheet> {
  final quantity = TextEditingController();
  final notes = TextEditingController();
  int? businessId;
  int? productId;
  int? warehouseId;

  @override
  void initState() {
    super.initState();
    if (widget.businesses.isNotEmpty) {
      businessId = widget.businesses.first.id;
    }
    final availableProducts = _productsForBusiness(businessId);
    if (availableProducts.isNotEmpty) {
      productId = availableProducts.first.id;
    }
    if (widget.warehouses.isNotEmpty) {
      warehouseId = widget.warehouses.first.id;
    }
  }

  @override
  void dispose() {
    quantity.dispose();
    notes.dispose();
    super.dispose();
  }

  List<ProductModel> _productsForBusiness(int? id) {
    return widget.products
        .where((product) =>
            product.businessId == id && product.status == ProductStatus.active)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final availableProducts = _productsForBusiness(businessId);
    final canSubmit = businessId != null &&
        productId != null &&
        warehouseId != null &&
        (int.tryParse(quantity.text.trim()) ?? 0) > 0;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          0,
          18,
          MediaQuery.of(context).viewInsets.bottom + 22,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enviar productos a almacén',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'El dueño del almacén debe aprobar la solicitud antes de que se cree el inventario.',
                style: TextStyle(color: AppColors.textSecondary, height: 1.3),
              ),
              const SizedBox(height: 14),
              if (widget.businesses.isEmpty ||
                  widget.warehouses.isEmpty ||
                  widget.products.isEmpty)
                const _InlineEmpty(
                  icon: Icons.inventory_2_outlined,
                  title: 'Faltan datos para enviar',
                  subtitle:
                      'Necesitas un negocio aprobado, productos activos y almacenes disponibles.',
                )
              else ...[
                DropdownButtonFormField<int>(
                  initialValue: businessId,
                  decoration: const InputDecoration(labelText: 'Negocio'),
                  items: widget.businesses
                      .map(
                        (business) => DropdownMenuItem(
                          value: business.id,
                          child: Text(business.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      businessId = value;
                      final products = _productsForBusiness(value);
                      productId =
                          products.isNotEmpty ? products.first.id : null;
                    });
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  initialValue: availableProducts
                          .any((product) => product.id == productId)
                      ? productId
                      : null,
                  decoration: const InputDecoration(labelText: 'Producto'),
                  items: availableProducts
                      .map(
                        (product) => DropdownMenuItem(
                          value: product.id,
                          child: Text(product.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => productId = value),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  initialValue: warehouseId,
                  decoration: const InputDecoration(labelText: 'Almacén'),
                  items: widget.warehouses
                      .map(
                        (warehouse) => DropdownMenuItem(
                          value: warehouse.id,
                          child: Text(warehouse.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => warehouseId = value),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: quantity,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Cantidad *'),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: notes,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Nota para el almacén',
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: canSubmit
                        ? () {
                            Navigator.pop(
                              context,
                              _StockRequestFormData(
                                businessId: businessId!,
                                warehouseId: warehouseId!,
                                productId: productId!,
                                quantity: int.parse(quantity.text.trim()),
                                notes: notes.text.trim().isEmpty
                                    ? null
                                    : notes.text.trim(),
                              ),
                            );
                          }
                        : null,
                    icon: const Icon(Icons.send_outlined),
                    label: const Text('Enviar solicitud'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StockRequestCard extends StatelessWidget {
  const _StockRequestCard({
    required this.request,
    required this.received,
    this.onApprove,
    this.onMarkSent,
    this.onReceive,
    this.onReject,
  });

  final WarehouseStockRequestModel request;
  final bool received;
  final VoidCallback? onApprove;
  final VoidCallback? onMarkSent;
  final VoidCallback? onReceive;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final color = switch (request.status) {
      'approved' => AppColors.emerald,
      'sent' => AppColors.darkBlue,
      'received' => AppColors.emerald,
      'rejected' => Colors.redAccent,
      'cancelled' => AppColors.textSecondary,
      _ => AppColors.mustard,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
              Icon(
                received ? Icons.move_to_inbox_outlined : Icons.outbox_outlined,
                color: AppColors.darkBlue,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  request.productName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _SmallPill(
                  label: _requestStatusLabel(request.status), color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            received
                ? _receivedRequestMessage(request)
                : _sentRequestMessage(request),
            style: const TextStyle(color: AppColors.textSecondary, height: 1.3),
          ),
          if (request.locationCode?.trim().isNotEmpty == true ||
              request.locationName?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 6),
            Text(
              'Ubicación: ${[
                request.locationCode,
                request.locationName,
              ].where((item) => item?.trim().isNotEmpty == true).join(' - ')}',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (request.notes?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 6),
            Text(
              request.notes!,
              style: const TextStyle(color: AppColors.textPrimary, height: 1.3),
            ),
          ],
          if (request.responseMessage?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 6),
            Text(
              'Respuesta: ${request.responseMessage}',
              style:
                  const TextStyle(color: AppColors.textSecondary, height: 1.3),
            ),
          ],
          const SizedBox(height: 12),
          FlowTimelinePanel(
            steps: FlowTimelineHelper.warehouseStockRequest(request),
            title: 'Seguimiento del envío',
          ),
          if (onApprove != null ||
              onMarkSent != null ||
              onReceive != null ||
              onReject != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (onReject != null)
                  OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close),
                    label: const Text('Rechazar'),
                  ),
                if (onApprove != null)
                  ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check),
                    label: const Text('Aprobar'),
                  ),
                if (onMarkSent != null)
                  ElevatedButton.icon(
                    onPressed: onMarkSent,
                    icon: const Icon(Icons.local_shipping_outlined),
                    label: const Text('Marcar enviado'),
                  ),
                if (onReceive != null)
                  ElevatedButton.icon(
                    onPressed: onReceive,
                    icon: const Icon(Icons.inventory_2_outlined),
                    label: const Text('Recibir'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _requestStatusLabel(String status) {
    return switch (status) {
      'approved' => 'Aprobada',
      'sent' => 'En camino',
      'received' => 'Recibida',
      'rejected' => 'Rechazada',
      'cancelled' => 'Cancelada',
      _ => 'Pendiente',
    };
  }

  String _sentRequestMessage(WarehouseStockRequestModel request) {
    return switch (request.status) {
      'approved' =>
        '${request.warehouseName} aceptó recibir ${request.quantity} uds. Marca el envío cuando las lleves al almacén.',
      'sent' =>
        '${request.quantity} uds. en camino a ${request.warehouseName}. El almacén debe confirmar recepción.',
      'received' =>
        '${request.warehouseName} recibió ${request.quantity} uds. y ya forman parte del inventario.',
      _ =>
        '${request.quantity} uds. solicitadas para ${request.warehouseName}.',
    };
  }

  String _receivedRequestMessage(WarehouseStockRequestModel request) {
    return switch (request.status) {
      'pending' =>
        '${request.businessName} quiere enviar ${request.quantity} uds. a ${request.warehouseName}.',
      'approved' =>
        'Aceptaste recibir ${request.quantity} uds. de ${request.productName}. Esperando envío del negocio.',
      'sent' =>
        '${request.businessName} marcó ${request.quantity} uds. como enviadas. Confirma la recepción cuando lleguen.',
      'received' =>
        'Recibiste ${request.quantity} uds. de ${request.productName}. Ya están en inventario.',
      _ => '${request.quantity} uds. de ${request.productName}.',
    };
  }
}

class _InlineEmpty extends StatelessWidget {
  const _InlineEmpty({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.darkBlue),
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
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.3,
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

class _SmallPill extends StatelessWidget {
  const _SmallPill({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StockRequestFormData {
  const _StockRequestFormData({
    required this.businessId,
    required this.warehouseId,
    required this.productId,
    required this.quantity,
    this.notes,
  });

  final int businessId;
  final int warehouseId;
  final int productId;
  final int quantity;
  final String? notes;
}

class _WarehouseStatus extends StatelessWidget {
  const _WarehouseStatus({required this.warehouse});

  final WarehouseModel warehouse;

  @override
  Widget build(BuildContext context) {
    final pending = !warehouse.validated || warehouse.status == 'pending';
    final label = pending ? 'Pendiente' : _statusLabel(warehouse.status);
    final color = pending ? AppColors.textSecondary : AppColors.darkBlue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    return switch (status) {
      'active' => 'Activo',
      'inactive' => 'Inactivo',
      'archived' => 'Archivado',
      'pending' => 'Pendiente',
      _ => status,
    };
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
