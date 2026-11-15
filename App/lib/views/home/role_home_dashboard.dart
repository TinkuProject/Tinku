import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/home/home_dashboard_controller.dart';
import '../../models/home_dashboard_model.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../services/home_dashboard_service.dart';
import '../../ui/themes/colors.dart';
import '../../widgets/common/buttons/primary_button.dart';
import '../../widgets/common/empty/app_empty.dart';
import '../../widgets/common/loaders/app_loader.dart';
import '../../widgets/common/navigation/custom_app_bar.dart';

class RoleHomeDashboard extends StatelessWidget {
  final UserModel user;

  const RoleHomeDashboard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => HomeDashboardController(
        HomeDashboardService(context.read<UserProvider>().authService),
      )..load(),
      child: _RoleHomeDashboardView(user: user),
    );
  }
}

class _RoleHomeDashboardView extends StatelessWidget {
  final UserModel user;

  const _RoleHomeDashboardView({required this.user});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HomeDashboardController>();
    final summary = controller.summary;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Inicio'),
      body: summary == null && controller.loading
          ? const AppLoader(message: 'Preparando tu resumen...')
          : summary == null
              ? _InitialError(onRetry: () => controller.load())
              : RefreshIndicator(
                  onRefresh: () => controller.load(refresh: true),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                    children: [
                      _WelcomeHeader(
                        username: user.username,
                        isAdmin: summary.mode == 'admin',
                      ),
                      if (controller.error != null) ...[
                        const SizedBox(height: 12),
                        _RefreshWarning(message: controller.error!),
                      ],
                      const SizedBox(height: 22),
                      if (summary.mode == 'admin' && summary.admin != null)
                        _AdminDashboard(summary: summary.admin!)
                      else ...[
                        if (summary.partner != null)
                          _PartnerDashboard(summary: summary.partner!),
                        if ((summary.warehouse?.owned ?? 0) > 0) ...[
                          const SizedBox(height: 26),
                          _WarehouseDashboard(summary: summary.warehouse!),
                        ],
                      ],
                    ],
                  ),
                ),
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  final String username;
  final bool isAdmin;

  const _WelcomeHeader({required this.username, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.darkBlue, AppColors.mediumBlue],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hola, $username',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isAdmin
                ? 'Revisa lo que necesita atención en Tinku.'
                : 'Tus ventas, publicaciones y tareas en un solo lugar.',
            style: const TextStyle(color: Colors.white, height: 1.3),
          ),
        ],
      ),
    );
  }
}

class _PartnerDashboard extends StatelessWidget {
  final PartnerHomeSummary summary;

  const _PartnerDashboard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          title: 'Tu actividad comercial',
          subtitle: 'Resumen actualizado de tus negocios',
        ),
        const SizedBox(height: 12),
        _MetricGrid(
          items: [
            _MetricData(
              label: 'Ventas activas',
              value: summary.activeSales,
              icon: Icons.shopping_bag_outlined,
              color: AppColors.darkBlue,
            ),
            _MetricData(
              label: 'Publicaciones activas',
              value: summary.activePublications,
              icon: Icons.storefront_outlined,
              color: AppColors.emerald,
            ),
            _MetricData(
              label: 'Tareas pendientes',
              value: summary.pendingTasks,
              icon: Icons.task_alt_outlined,
              color: AppColors.mustard,
            ),
            _MetricData(
              label: 'Ventas entregadas',
              value: summary.deliveredSales,
              icon: Icons.inventory_2_outlined,
              color: AppColors.mediumBlue,
            ),
          ],
        ),
        const SizedBox(height: 18),
        _DashboardAction(
          icon: Icons.point_of_sale_outlined,
          title: 'Ventas y publicaciones',
          subtitle:
              '${summary.totalSales} ventas registradas · ${summary.soldOutPublications} publicaciones sin stock',
          onTap: () => Navigator.pushNamed(context, '/myMarketplace'),
        ),
        const SizedBox(height: 10),
        _DashboardAction(
          icon: Icons.business_center_outlined,
          title: 'Gestionar servicios',
          subtitle: 'Revisa negocios, eventos, productos y tareas pendientes.',
          onTap: () => Navigator.pushNamed(context, '/profile'),
        ),
      ],
    );
  }
}

class _WarehouseDashboard extends StatelessWidget {
  final WarehouseHomeSummary summary;

  const _WarehouseDashboard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          title: 'Operación de almacenes',
          subtitle: 'Recepciones y entregas que requieren seguimiento',
        ),
        const SizedBox(height: 12),
        _MetricGrid(
          items: [
            _MetricData(
              label: 'Solicitudes recibidas',
              value: summary.pendingReceptions,
              icon: Icons.move_to_inbox_outlined,
              color: AppColors.darkBlue,
            ),
            _MetricData(
              label: 'En camino',
              value: summary.incomingShipments,
              icon: Icons.local_shipping_outlined,
              color: AppColors.mustard,
            ),
            _MetricData(
              label: 'Entregas pendientes',
              value: summary.pendingDeliveries,
              icon: Icons.inventory_2_outlined,
              color: AppColors.emerald,
            ),
          ],
        ),
        const SizedBox(height: 18),
        PrimaryButton(
          label: 'Gestionar almacenes',
          icon: Icons.warehouse_outlined,
          onTap: () => Navigator.pushNamed(context, '/warehouses'),
        ),
      ],
    );
  }
}

class _AdminDashboard extends StatelessWidget {
  final AdminHomeSummary summary;

  const _AdminDashboard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final items = [
      _ApprovalData(
        label: 'Negocios',
        count: summary.businesses,
        icon: Icons.storefront_outlined,
        route: '/adminPendingBusinesses',
      ),
      _ApprovalData(
        label: 'Eventos',
        count: summary.events,
        icon: Icons.event_outlined,
        route: '/adminPendingEvents',
      ),
      _ApprovalData(
        label: 'Almacenes',
        count: summary.warehouses,
        icon: Icons.warehouse_outlined,
        route: '/adminPendingWarehouses',
      ),
      _ApprovalData(
        label: 'Reclamos de negocios',
        count: summary.claims,
        icon: Icons.assignment_turned_in_outlined,
        route: '/adminBusinessClaims',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: 'Pendientes de aprobación',
          subtitle: summary.total == 0
              ? 'No hay elementos esperando revisión.'
              : '${summary.total} elementos necesitan atención',
        ),
        const SizedBox(height: 12),
        if (summary.total == 0)
          const AppEmptyState(
            icon: Icons.verified_outlined,
            title: 'Todo está al día',
            subtitle: 'Las nuevas solicitudes aparecerán en esta sección.',
            iconColor: AppColors.emerald,
          )
        else
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ApprovalAction(
                data: item,
                onTap: () => Navigator.pushNamed(context, item.route),
              ),
            ),
          ),
      ],
    );
  }
}

class _MetricGrid extends StatelessWidget {
  final List<_MetricData> items;

  const _MetricGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final singleColumn = constraints.maxWidth < 300 || textScale > 1.6;
        const gap = 10.0;
        final width = singleColumn
            ? constraints.maxWidth
            : (constraints.maxWidth - gap) / 2;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: items
              .map(
                (item) => SizedBox(
                  width: width,
                  child: _MetricCard(data: item),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final _MetricData data;

  const _MetricCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(data.icon, color: data.color),
          const SizedBox(height: 10),
          Text(
            '${data.value}',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.label,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _DashboardAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DashboardAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: title,
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(icon, color: AppColors.darkBlue),
                const SizedBox(width: 12),
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
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ApprovalAction extends StatelessWidget {
  final _ApprovalData data;
  final VoidCallback onTap;

  const _ApprovalAction({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _DashboardAction(
      icon: data.icon,
      title: data.label,
      subtitle: data.count == 1
          ? '1 elemento esperando revisión'
          : '${data.count} elementos esperando revisión',
      onTap: onTap,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(subtitle, style: const TextStyle(color: AppColors.textSecondary)),
      ],
    );
  }
}

class _RefreshWarning extends StatelessWidget {
  final String message;

  const _RefreshWarning({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.mustard.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.mustard),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.textPrimary),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

class _InitialError extends StatelessWidget {
  final VoidCallback onRetry;

  const _InitialError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppEmptyState(
              icon: Icons.dashboard_outlined,
              title: 'No pudimos cargar tu resumen',
              subtitle: 'Comprueba tu conexión y vuelve a intentarlo.',
              iconColor: AppColors.darkBlue,
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'Reintentar',
              icon: Icons.refresh,
              onTap: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricData {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _MetricData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _ApprovalData {
  final String label;
  final int count;
  final IconData icon;
  final String route;

  const _ApprovalData({
    required this.label,
    required this.count,
    required this.icon,
    required this.route,
  });
}
