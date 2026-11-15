import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../helpers/error_message_helper.dart';
import '../../models/cashout_request_model.dart';
import '../../providers/user_provider.dart';
import '../../services/cashout_request_service.dart';
import '../../ui/themes/colors.dart';
import '../../widgets/common/empty/app_empty.dart';
import '../../widgets/common/loaders/app_loader.dart';
import '../../widgets/common/navigation/custom_app_bar.dart';

class AdminCashoutRequestsPage extends StatefulWidget {
  const AdminCashoutRequestsPage({super.key});

  @override
  State<AdminCashoutRequestsPage> createState() =>
      _AdminCashoutRequestsPageState();
}

class _AdminCashoutRequestsPageState extends State<AdminCashoutRequestsPage> {
  late final CashoutRequestService service;
  List<CashoutRequestModel> requests = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    service = CashoutRequestService(context.read<UserProvider>().authService);
    Future.microtask(load);
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await service.getPending();
      if (mounted) setState(() => requests = result);
    } catch (e) {
      if (mounted) setState(() => error = userFacingError(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> review(CashoutRequestModel request, bool approve) async {
    final controller = TextEditingController();
    final comment = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(approve ? 'Aprobar retiro' : 'Rechazar retiro'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: approve ? 'Referencia del pago *' : 'Motivo *',
            helperText: approve
                ? 'Confirma primero que el pago externo fue realizado.'
                : 'El usuario recibirá esta explicación.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) Navigator.pop(context, value);
            },
            child: Text(approve ? 'Aprobar' : 'Rechazar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (comment == null) return;
    try {
      await service.review(request.id, approve: approve, comment: comment);
      await load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userFacingError(e)),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Retiros pendientes',
        subtitle: 'Confirmación administrativa de cashout',
      ),
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          if (error != null)
            Center(
              child: AppEmptyState(
                icon: Icons.error_outline,
                title: 'No se pudieron cargar los retiros',
                subtitle: error!,
                iconColor: AppColors.error,
              ),
            )
          else if (!loading && requests.isEmpty)
            const Center(
              child: AppEmptyState(
                icon: Icons.task_alt,
                title: 'No hay retiros pendientes',
                subtitle: 'Las nuevas solicitudes aparecerán acá.',
              ),
            )
          else
            RefreshIndicator(
              onRefresh: load,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: requests.length,
                itemBuilder: (_, index) {
                  final request = requests[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Retiro #${request.id}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${request.tinkusAmount} Tinkus · Bs ${request.cashAmount.toStringAsFixed(2)}',
                          style:
                              const TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => review(request, false),
                                icon: const Icon(Icons.close),
                                label: const Text('Rechazar'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () => review(request, true),
                                icon: const Icon(Icons.check),
                                label: const Text('Aprobar'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          if (loading) const AppLoader(message: 'Cargando retiros...'),
        ],
      ),
    );
  }
}
