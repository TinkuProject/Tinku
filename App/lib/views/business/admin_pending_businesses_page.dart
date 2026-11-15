import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/utils.dart';
import '../../core/enums.dart';
import '../../helpers/flow_timeline_helper.dart';
import '../../models/business_model.dart';
import '../../providers/user_provider.dart';
import '../../services/business_service.dart';
import '../../ui/themes/colors.dart';
import '../../widgets/common/empty/app_empty.dart';
import '../../widgets/common/loaders/app_loader.dart';
import '../../widgets/common/flow_timeline.dart';
import '../../widgets/common/navigation/custom_app_bar.dart';

class AdminPendingBusinessesPage extends StatefulWidget {
  const AdminPendingBusinessesPage({super.key});

  @override
  State<AdminPendingBusinessesPage> createState() =>
      _AdminPendingBusinessesPageState();
}

class _AdminPendingBusinessesPageState
    extends State<AdminPendingBusinessesPage> {
  late final BusinessService _service;
  List<BusinessModel> _businesses = [];
  bool _loading = true;
  int? _processingId;

  @override
  void initState() {
    super.initState();
    final auth = context.read<UserProvider>().authService;
    _service = BusinessService(auth);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _service.getByStatus(BusinessStatus.pending);
      if (!mounted) return;
      setState(() => _businesses = data);
    } catch (_) {
      if (!mounted) return;
      showSnackbar('No se pudieron cargar los negocios pendientes',
          isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _approve(BusinessModel business) async {
    final ok = await _confirm(
      title: 'Aprobar negocio',
      message: 'El negocio "${business.name}" quedará visible en Tinku.',
      action: 'Aprobar',
    );
    if (ok != true) return;

    setState(() => _processingId = business.id);
    try {
      await _service.validateBusiness(business.id);
      if (!mounted) return;
      showSnackbar('Negocio aprobado');
      await _load();
    } catch (_) {
      if (!mounted) return;
      showSnackbar('No se pudo aprobar el negocio', isError: true);
    } finally {
      if (mounted) setState(() => _processingId = null);
    }
  }

  Future<void> _reject(BusinessModel business) async {
    final controller = TextEditingController();
    String? validationError;
    final message = await showDialog<String?>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Rechazar negocio'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'El negocio "${business.name}" dejará la lista de pendientes.',
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

    setState(() => _processingId = business.id);
    try {
      await _service.rejectBusiness(business.id, message: message);
      if (!mounted) return;
      showSnackbar('Negocio rechazado');
      await _load();
    } catch (_) {
      if (!mounted) return;
      showSnackbar('No se pudo rechazar el negocio', isError: true);
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
        title: 'Negocios pendientes',
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
                if (!_loading && _businesses.isEmpty)
                  const AppEmptyState(
                    icon: Icons.fact_check_outlined,
                    title: 'No hay negocios pendientes',
                    subtitle:
                        'Cuando un socio registre un negocio para revisión, aparecerá aquí.',
                    iconColor: AppColors.darkBlue,
                  )
                else
                  ..._businesses.map(
                    (business) => _PendingBusinessCard(
                      business: business,
                      processing: _processingId == business.id,
                      onApprove: () => _approve(business),
                      onReject: () => _reject(business),
                    ),
                  ),
              ],
            ),
          ),
          if (_loading)
            const AppLoader(message: 'Cargando negocios pendientes...'),
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
              'Revisa los negocios enviados por socios antes de que se muestren públicamente. Puedes aprobarlos o rechazarlos con un comentario.',
              style: TextStyle(
                color: AppColors.textPrimary,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingBusinessCard extends StatelessWidget {
  const _PendingBusinessCard({
    required this.business,
    required this.processing,
    required this.onApprove,
    required this.onReject,
  });

  final BusinessModel business;
  final bool processing;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final typeLabel =
        business.businessType == BusinessType.service ? 'Servicio' : 'Negocio';

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.darkBlue.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.storefront_outlined,
                  color: AppColors.darkBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      business.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      typeLabel,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const _PendingPill(),
            ],
          ),
          if ((business.description ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              business.description!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                height: 1.3,
              ),
            ),
          ],
          const SizedBox(height: 10),
          _InfoLine(icon: Icons.place_outlined, text: business.address),
          if ((business.phone ?? '').trim().isNotEmpty)
            _InfoLine(icon: Icons.phone_outlined, text: business.phone!),
          if ((business.email ?? '').trim().isNotEmpty)
            _InfoLine(icon: Icons.mail_outline, text: business.email!),
          const SizedBox(height: 12),
          FlowTimelinePanel(
            steps: FlowTimelineHelper.approval(
              status: ApprovalStatus.pending,
              createdAt: business.createdAt,
              submittedLabel: 'Negocio registrado',
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

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
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
