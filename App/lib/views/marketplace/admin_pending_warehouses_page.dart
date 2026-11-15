import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/utils.dart';
import '../../core/enums.dart';
import '../../helpers/flow_timeline_helper.dart';
import '../../models/warehouse_model.dart';
import '../../providers/user_provider.dart';
import '../../services/warehouse_service.dart';
import '../../ui/themes/colors.dart';
import '../../widgets/common/empty/app_empty.dart';
import '../../widgets/common/loaders/app_loader.dart';
import '../../widgets/common/flow_timeline.dart';
import '../../widgets/common/navigation/custom_app_bar.dart';

class AdminPendingWarehousesPage extends StatefulWidget {
  const AdminPendingWarehousesPage({super.key});

  @override
  State<AdminPendingWarehousesPage> createState() =>
      _AdminPendingWarehousesPageState();
}

class _AdminPendingWarehousesPageState
    extends State<AdminPendingWarehousesPage> {
  late final WarehouseService _service;
  List<WarehouseModel> _warehouses = [];
  bool _loading = true;
  int? _processingId;

  @override
  void initState() {
    super.initState();
    final auth = context.read<UserProvider>().authService;
    _service = WarehouseService(auth);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _service.getAdmin(status: 'pending');
      if (!mounted) return;
      setState(() => _warehouses = data);
    } catch (_) {
      if (!mounted) return;
      showSnackbar('No se pudieron cargar los almacenes pendientes',
          isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _approve(WarehouseModel warehouse) async {
    final ok = await _confirm(
      title: 'Aprobar almacén',
      message: 'El almacén "${warehouse.name}" quedará disponible en Tinku.',
      action: 'Aprobar',
    );
    if (ok != true) return;

    setState(() => _processingId = warehouse.id);
    try {
      await _service.approveWarehouse(warehouse.id);
      if (!mounted) return;
      showSnackbar('Almacén aprobado');
      await _load();
    } catch (_) {
      if (!mounted) return;
      showSnackbar('No se pudo aprobar el almacén', isError: true);
    } finally {
      if (mounted) setState(() => _processingId = null);
    }
  }

  Future<void> _reject(WarehouseModel warehouse) async {
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

    setState(() => _processingId = warehouse.id);
    try {
      await _service.rejectWarehouse(warehouse.id, message: message);
      if (!mounted) return;
      showSnackbar('Almacén rechazado');
      await _load();
    } catch (_) {
      if (!mounted) return;
      showSnackbar('No se pudo rechazar el almacén', isError: true);
    } finally {
      if (mounted) setState(() => _processingId = null);
    }
  }

  Future<bool?> _confirm({
    required String title,
    required String message,
    required String action,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Almacenes pendientes',
        subtitle: 'Aprobación administrativa',
      ),
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          RefreshIndicator(
            color: AppColors.darkBlue,
            onRefresh: _load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: [
                const _InfoCard(),
                const SizedBox(height: 12),
                if (!_loading && _warehouses.isEmpty)
                  const AppEmptyState(
                    icon: Icons.warehouse_outlined,
                    title: 'No hay almacenes pendientes',
                    subtitle:
                        'Cuando un socio registre un almacén para revisión, aparecerá aquí.',
                    iconColor: AppColors.darkBlue,
                  )
                else
                  ..._warehouses.map(
                    (warehouse) => _PendingWarehouseCard(
                      warehouse: warehouse,
                      processing: _processingId == warehouse.id,
                      onApprove: () => _approve(warehouse),
                      onReject: () => _reject(warehouse),
                    ),
                  ),
              ],
            ),
          ),
          if (_loading)
            const AppLoader(message: 'Cargando almacenes pendientes...'),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppColors.darkBlue),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Revisa los almacenes enviados por socios antes de habilitarlos como puntos de retiro.',
              style: TextStyle(color: AppColors.textPrimary, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingWarehouseCard extends StatelessWidget {
  const _PendingWarehouseCard({
    required this.warehouse,
    required this.processing,
    required this.onApprove,
    required this.onReject,
  });

  final WarehouseModel warehouse;
  final bool processing;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
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
              const Icon(Icons.warehouse_outlined, color: AppColors.darkBlue),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  warehouse.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const _PendingPill(),
            ],
          ),
          if (warehouse.address?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(
              warehouse.address!,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
          if (warehouse.description?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 10),
            Text(
              warehouse.description!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textPrimary, height: 1.3),
            ),
          ],
          const SizedBox(height: 12),
          FlowTimelinePanel(
            steps: FlowTimelineHelper.approval(
              status: ApprovalStatus.pending,
              submittedLabel: 'Almacén registrado',
            ),
            title: 'Proceso de aprobación',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: processing ? null : onReject,
                  icon: const Icon(Icons.close),
                  label: const Text('Rechazar'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: processing ? null : onApprove,
                  icon: processing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: const Text('Aprobar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PendingPill extends StatelessWidget {
  const _PendingPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.mustard.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'Pendiente',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
