import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/enums.dart';
import '../../helpers/error_message_helper.dart';
import '../../models/cashout_package_model.dart';
import '../../models/cashout_request_model.dart';
import '../../providers/user_provider.dart';
import '../../services/cashout_package_service.dart';
import '../../services/cashout_request_service.dart';
import '../../ui/themes/colors.dart';
import '../../widgets/common/empty/app_empty.dart';
import '../../widgets/common/loaders/app_loader.dart';
import '../../widgets/common/navigation/custom_app_bar.dart';

class CashoutPage extends StatefulWidget {
  const CashoutPage({super.key});

  @override
  State<CashoutPage> createState() => _CashoutPageState();
}

class _CashoutPageState extends State<CashoutPage> {
  late final CashoutPackageService packageService;
  late final CashoutRequestService requestService;
  List<CashoutPackageModel> packages = [];
  List<CashoutRequestModel> requests = [];
  bool loading = true;
  bool saving = false;
  String? error;

  @override
  void initState() {
    super.initState();
    final auth = context.read<UserProvider>().authService;
    packageService = CashoutPackageService(auth);
    requestService = CashoutRequestService(auth);
    Future.microtask(load);
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await Future.wait([
        packageService.getAll(),
        requestService.getMine(),
      ]);
      if (!mounted) return;
      setState(() {
        packages = (result[0] as List<CashoutPackageModel>)
            .where((item) => item.status == BasicStatus.active)
            .toList();
        requests = result[1] as List<CashoutRequestModel>;
      });
    } catch (e) {
      if (mounted) setState(() => error = userFacingError(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> requestCashout(CashoutPackageModel package) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Solicitar retiro'),
        content: Text(
          'Se revisará el retiro de ${package.tinkusAmount} Tinkus por Bs ${package.cashAmount.toStringAsFixed(2)}. Los Tinkus se descontarán al aprobarse.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Solicitar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => saving = true);
    try {
      await requestService.create(package.id);
      await load();
      if (mounted) _message('Solicitud enviada.');
    } catch (e) {
      if (mounted) _message(userFacingError(e), isError: true);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  void _message(String value, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value),
        backgroundColor: isError ? AppColors.error : AppColors.darkBlue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Retirar Tinkus',
        subtitle: 'Solicitudes e historial',
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
          else
            RefreshIndicator(
              onRefresh: load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
                children: [
                  const _CashoutInfo(),
                  const SizedBox(height: 18),
                  const _SectionTitle('Paquetes disponibles'),
                  if (packages.isEmpty && !loading)
                    const AppEmptyState(
                      icon: Icons.currency_exchange,
                      title: 'No hay retiros disponibles',
                      subtitle: 'Vuelve a revisar más adelante.',
                    )
                  else
                    ...packages.map(
                      (item) => _CashoutPackageTile(
                        package: item,
                        onTap: () => requestCashout(item),
                      ),
                    ),
                  const SizedBox(height: 18),
                  const _SectionTitle('Historial'),
                  if (requests.isEmpty && !loading)
                    const AppEmptyState(
                      icon: Icons.history,
                      title: 'Sin solicitudes todavía',
                      subtitle: 'Tus retiros aparecerán en este historial.',
                    )
                  else
                    ...requests.map(_CashoutRequestTile.new),
                ],
              ),
            ),
          if (loading || saving)
            AppLoader(
              message: saving ? 'Enviando solicitud...' : 'Cargando retiros...',
            ),
        ],
      ),
    );
  }
}

class _CashoutInfo extends StatelessWidget {
  const _CashoutInfo();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkBlue.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBlue.withValues(alpha: 0.18)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppColors.darkBlue),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'La solicitud será revisada por Tinku. El administrador confirmará el medio de entrega del dinero antes de aprobarla.',
              style: TextStyle(color: AppColors.textPrimary, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.value);
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
}

class _CashoutPackageTile extends StatelessWidget {
  const _CashoutPackageTile({required this.package, required this.onTap});
  final CashoutPackageModel package;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.currency_exchange, color: AppColors.darkBlue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    package.name,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    '${package.tinkusAmount} Tinkus · Bs ${package.cashAmount.toStringAsFixed(2)}',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            FilledButton(onPressed: onTap, child: const Text('Solicitar')),
          ],
        ),
      );
}

class _CashoutRequestTile extends StatelessWidget {
  const _CashoutRequestTile(this.request);
  final CashoutRequestModel request;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        leading: Icon(
          request.status == ApprovalStatus.approved
              ? Icons.check_circle_outline
              : request.status == ApprovalStatus.rejected
                  ? Icons.cancel_outlined
                  : Icons.schedule,
          color: request.status == ApprovalStatus.rejected
              ? AppColors.error
              : AppColors.darkBlue,
        ),
        title: Text('${request.tinkusAmount} Tinkus'),
        subtitle: Text(
          '${DateFormat('dd/MM/yyyy HH:mm').format(request.createdAt)}${request.comment?.trim().isNotEmpty == true ? '\n${request.comment}' : ''}',
        ),
        trailing: Text(
          switch (request.status) {
            ApprovalStatus.approved => 'Aprobado',
            ApprovalStatus.rejected => 'Rechazado',
            ApprovalStatus.pending => 'Pendiente',
          },
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      );
}
