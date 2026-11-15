part of '../../../views/marketplace/warehouses_page.dart';

class _WarehouseDialog extends StatefulWidget {
  const _WarehouseDialog({
    this.createCost,
  });

  final double? createCost;

  @override
  State<_WarehouseDialog> createState() => _WarehouseDialogState();
}

class _WarehouseDialogState extends State<_WarehouseDialog> {
  final name = TextEditingController();
  final description = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final locC = LocationController();
  bool mapError = false;

  @override
  void dispose() {
    name.dispose();
    description.dispose();
    phone.dispose();
    email.dispose();
    locC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Crear almacén'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: AnimatedBuilder(
            animation: locC,
            builder: (context, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.createCost != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.darkBlue.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.darkBlue.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Text(
                        widget.createCost! > 0
                            ? 'Crear un almacén cuesta ${widget.createCost!.toStringAsFixed(0)} Tinkus y quedará pendiente de aprobación.'
                            : 'Crear un almacén quedará pendiente de aprobación.',
                        style: const TextStyle(
                          color: AppColors.darkBlue,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'Nombre *'),
                  ),
                  TextField(
                    controller: description,
                    decoration: const InputDecoration(labelText: 'Descripción'),
                  ),
                  TextField(
                    controller: phone,
                    decoration: const InputDecoration(labelText: 'Teléfono'),
                  ),
                  TextField(
                    controller: email,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  LocationPickerSection(
                    locC: locC,
                    defaultCenter: locC.mapCenter,
                    mapError: mapError,
                    onTap: (latLng) async {
                      await locC.onTap(latLng);
                      if (mounted) setState(() => mapError = false);
                    },
                  ),
                  if (locC.address.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        locC.address,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (name.text.trim().isEmpty) return;
            if (locC.selected == null) {
              setState(() => mapError = true);
              return;
            }

            final normalizedAddress = locC.address.trim();
            Navigator.pop(
              context,
              _WarehouseFormData(
                name: name.text.trim(),
                description: _nullableText(description.text),
                phone: _nullableText(phone.text),
                email: _nullableText(email.text),
                address: normalizedAddress.isEmpty ? null : normalizedAddress,
                latitude: locC.selected!.latitude,
                longitude: locC.selected!.longitude,
              ),
            );
          },
          child: const Text('Crear'),
        ),
      ],
    );
  }
}

class _WarehouseFormData {
  final String name;
  final String? description;
  final String? phone;
  final String? email;
  final String? address;
  final double latitude;
  final double longitude;

  _WarehouseFormData({
    required this.name,
    this.description,
    this.phone,
    this.email,
    this.address,
    required this.latitude,
    required this.longitude,
  });
}

String? _nullableText(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
