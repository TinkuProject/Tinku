part of '../../../views/marketplace/warehouses_page.dart';

class _LocationsSheet extends StatefulWidget {
  const _LocationsSheet({
    required this.warehouse,
    required this.locations,
    required this.onSave,
    required this.onArchive,
  });

  final WarehouseModel warehouse;
  final List<WarehouseLocationModel> locations;
  final Future<List<WarehouseLocationModel>> Function({
    WarehouseLocationModel? location,
    int? parentId,
    required String name,
    required String code,
    String? description,
    required int sortOrder,
  }) onSave;
  final Future<void> Function(WarehouseLocationModel location) onArchive;

  @override
  State<_LocationsSheet> createState() => _LocationsSheetState();
}

class _LocationsSheetState extends State<_LocationsSheet> {
  late List<WarehouseLocationModel> locations = List.of(widget.locations);

  Future<void> _openForm([WarehouseLocationModel? location]) async {
    final result = await showDialog<_LocationFormData>(
      context: context,
      builder: (_) => _LocationFormDialog(
        locations: locations,
        current: location,
      ),
    );
    if (result == null) return;

    final updated = await widget.onSave(
      location: location,
      parentId: result.parentId,
      name: result.name,
      code: result.code,
      description: result.description,
      sortOrder: result.sortOrder,
    );
    if (!mounted) return;
    setState(() {
      locations = List.of(updated);
    });
  }

  @override
  Widget build(BuildContext context) {
    final active = locations.where((item) => item.status == 'active').toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Ubicaciones de ${widget.warehouse.name}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _openForm(),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Crea códigos como E1, E2 o Zona Frágil para representar espacios físicos del almacén.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            if (active.isEmpty)
              const _InlineEmpty(
                icon: Icons.view_module_outlined,
                title: 'No hay ubicaciones',
                subtitle: 'Crea la primera sección física del almacén.',
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: active.length,
                  itemBuilder: (_, index) {
                    final location = active[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.view_module_outlined,
                        color: AppColors.darkBlue,
                      ),
                      title: Text(location.label(active)),
                      subtitle: location.description?.trim().isNotEmpty == true
                          ? Text(location.description!)
                          : null,
                      trailing: Wrap(
                        spacing: 4,
                        children: [
                          IconButton(
                            tooltip: 'Editar',
                            onPressed: () => _openForm(location),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            tooltip: 'Desactivar',
                            onPressed: () async {
                              await widget.onArchive(location);
                              if (!mounted) return;
                              setState(() {
                                locations = locations
                                    .map((item) => item.id == location.id
                                        ? WarehouseLocationModel(
                                            id: item.id,
                                            warehouseId: item.warehouseId,
                                            parentId: item.parentId,
                                            name: item.name,
                                            code: item.code,
                                            description: item.description,
                                            status: 'inactive',
                                            sortOrder: item.sortOrder,
                                          )
                                        : item)
                                    .toList();
                              });
                            },
                            icon: const Icon(Icons.archive_outlined),
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

class _LocationFormData {
  const _LocationFormData({
    this.parentId,
    required this.name,
    required this.code,
    this.description,
    required this.sortOrder,
  });

  final int? parentId;
  final String name;
  final String code;
  final String? description;
  final int sortOrder;
}

class _LocationFormDialog extends StatefulWidget {
  const _LocationFormDialog({
    required this.locations,
    this.current,
  });

  final List<WarehouseLocationModel> locations;
  final WarehouseLocationModel? current;

  @override
  State<_LocationFormDialog> createState() => _LocationFormDialogState();
}

class _LocationFormDialogState extends State<_LocationFormDialog> {
  late final TextEditingController name;
  late final TextEditingController code;
  late final TextEditingController description;
  late final TextEditingController sortOrder;
  int? parentId;

  @override
  void initState() {
    super.initState();
    final current = widget.current;
    name = TextEditingController(text: current?.name ?? '');
    code = TextEditingController(text: current?.code ?? '');
    description = TextEditingController(text: current?.description ?? '');
    sortOrder = TextEditingController(text: '${current?.sortOrder ?? 0}');
    parentId = current?.parentId;
  }

  @override
  void dispose() {
    name.dispose();
    code.dispose();
    description.dispose();
    sortOrder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final parentOptions = widget.locations
        .where(
            (item) => item.status == 'active' && item.id != widget.current?.id)
        .toList();
    final selectedParent =
        parentOptions.any((item) => item.id == parentId) ? parentId : null;

    return AlertDialog(
      title:
          Text(widget.current == null ? 'Nueva ubicación' : 'Editar ubicación'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: code,
              decoration: const InputDecoration(labelText: 'Código *'),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Nombre *'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<int?>(
              initialValue: selectedParent,
              decoration: const InputDecoration(labelText: 'Ubicación padre'),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Sin ubicación padre'),
                ),
                ...parentOptions.map(
                  (item) => DropdownMenuItem<int?>(
                    value: item.id,
                    child: Text(item.label(parentOptions)),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => parentId = value),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: sortOrder,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Orden'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: description,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Descripción'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            final codeText = code.text.trim().toUpperCase();
            final nameText = name.text.trim();
            if (codeText.isEmpty || nameText.isEmpty) return;
            Navigator.pop(
              context,
              _LocationFormData(
                parentId: parentOptions.any((item) => item.id == parentId)
                    ? parentId
                    : null,
                name: nameText,
                code: codeText,
                description: description.text.trim().isEmpty
                    ? null
                    : description.text.trim(),
                sortOrder: int.tryParse(sortOrder.text.trim()) ?? 0,
              ),
            );
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _InventoryLocationDialog extends StatefulWidget {
  const _InventoryLocationDialog({
    required this.item,
    required this.locations,
  });

  final WarehouseInventoryModel item;
  final List<WarehouseLocationModel> locations;

  @override
  State<_InventoryLocationDialog> createState() =>
      _InventoryLocationDialogState();
}

class _InventoryLocationDialogState extends State<_InventoryLocationDialog> {
  late int? locationId = widget.item.locationId;

  @override
  Widget build(BuildContext context) {
    final active =
        widget.locations.where((item) => item.status == 'active').toList();
    final selectedLocation =
        active.any((item) => item.id == locationId) ? locationId : null;

    return AlertDialog(
      title: const Text('Asignar ubicación'),
      content: DropdownButtonFormField<int?>(
        initialValue: selectedLocation,
        decoration: const InputDecoration(labelText: 'Ubicación interna'),
        items: [
          const DropdownMenuItem<int?>(
            value: null,
            child: _WarehouseLocationMenuText('Sin ubicación asignada'),
          ),
          ...active.map(
            (item) => DropdownMenuItem<int?>(
              value: item.id,
              child: _WarehouseLocationMenuText(item.label(active)),
            ),
          ),
        ],
        onChanged: (value) => setState(() => locationId = value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, -1),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(
            context,
            active.any((item) => item.id == locationId) ? locationId : null,
          ),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _ApproveStockRequestDialog extends StatefulWidget {
  const _ApproveStockRequestDialog({
    required this.request,
    required this.locations,
    this.title = 'Aprobar solicitud',
    this.actionLabel = 'Aprobar',
  });

  final WarehouseStockRequestModel request;
  final List<WarehouseLocationModel> locations;
  final String title;
  final String actionLabel;

  @override
  State<_ApproveStockRequestDialog> createState() =>
      _ApproveStockRequestDialogState();
}

class _ApproveStockRequestDialogState
    extends State<_ApproveStockRequestDialog> {
  int? locationId;

  @override
  Widget build(BuildContext context) {
    final active =
        widget.locations.where((item) => item.status == 'active').toList();

    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.request.quantity} uds. de ${widget.request.productName}',
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int?>(
            initialValue: locationId,
            decoration: const InputDecoration(
              labelText: 'Ubicación interna opcional',
            ),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: _WarehouseLocationMenuText('Sin ubicación por ahora'),
              ),
              ...active.map(
                (item) => DropdownMenuItem<int?>(
                  value: item.id,
                  child: _WarehouseLocationMenuText(item.label(active)),
                ),
              ),
            ],
            onChanged: (value) => setState(() => locationId = value),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, -1),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, locationId),
          child: Text(widget.actionLabel),
        ),
      ],
    );
  }
}

class _WarehouseLocationMenuText extends StatelessWidget {
  const _WarehouseLocationMenuText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 200),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
