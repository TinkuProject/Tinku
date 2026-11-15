import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tinkuapp/core/enums.dart';
import 'package:tinkuapp/services/media_service.dart';

import '../../../components/utils.dart';
import '../../../controllers/discount/discount_controller.dart';
import '../../../providers/user_provider.dart';
import '../../../services/business_service.dart';
import '../../../services/discount_service.dart';
import '../../../services/system_config_service.dart';
import '../../../widgets/common/actions/app_fab.dart';
import '../../../widgets/common/actions/confirm_delete_action.dart';
import '../../../widgets/bars/filter_bar_discounts.dart';
import '../../../widgets/common/filtered_empty.dart';
import '../../../widgets/common/info/manage_period_cost_info.dart';
import '../../../widgets/common/initial_empty_state.dart';
import '../../../widgets/common/loaders/app_loader.dart';
import '../../../widgets/common/navigation/custom_app_bar.dart';
import '../../../widgets/common/entity_manage/entity_manage_card.dart';
import '../../../widgets/selectors/business_selector_dialog.dart';
import '../../../utils/status/promotion_status_ui.dart';

import 'discount_form.dart';

class MyDiscountsListPage extends StatefulWidget {
  const MyDiscountsListPage({super.key});

  @override
  State<MyDiscountsListPage> createState() => _MyDiscountsListPageState();
}

class _MyDiscountsListPageState extends State<MyDiscountsListPage> {
  late DiscountController c;

  bool _initialized = false;
  String? _loadedUserId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final userProvider = context.watch<UserProvider>();
    final userId = userProvider.user?.id;
    if (_initialized && _loadedUserId == userId) return;

    if (_initialized) {
      c.removeListener(_rebuild);
      c.reset();
    }

    final auth = userProvider.authService;

    c = DiscountController(
        discountService: DiscountService(auth),
        businessService: BusinessService(auth),
        systemConfigService: SystemConfigService(auth),
        mediaService: MediaService(auth));

    c.addListener(_rebuild);
    _loadedUserId = userId;

    Future.microtask(() async {
      await c.loadMine();
    });

    _initialized = true;
  }

  @override
  void dispose() {
    if (_initialized) {
      c.removeListener(_rebuild);
      c.reset();
      c.dispose();
    }
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  Future<void> _openCreateDiscount() async {
    if (!c.hasBusinesses) {
      showSnackbar("No tienes negocios disponibles.");
      return;
    }

    final businessItems = Map<int, String>.from(c.businessSelectorItems)
      ..remove(0);

    final selected = await showBusinessSelectorDialog(
      context: context,
      businessItems: businessItems,
      disabledIds: c.disabledBusinessSelectorIds,
      disabledLabel: 'Pendiente',
      title: "Seleccionar negocio",
    );

    if (!mounted || selected == null) {
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DiscountFormPage(
          businessId: selected,
        ),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      showSnackbar("Promoción creada correctamente.");
      await c.loadMine();
    }
  }

  Future<void> _deleteDiscount(int id) async {
    await confirmAndDelete(
      context: context,
      title: '¿Eliminar promoción?',
      message: 'Esta acción no se puede deshacer.',
      onDelete: () => c.softDelete(id),
      onAfterDelete: () => c.loadMine(),
      successMessage: "Promoción eliminada",
      errorMessage: "Error al eliminar la promoción",
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = c.loading;
    final all = c.allDiscounts;
    final filtered = c.filteredDiscounts;
    final hasData = c.hasData;
    final isFilteredEmpty = filtered.isEmpty && hasData;

    return Scaffold(
      appBar: const CustomAppBar(title: "Mis promociones"),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: FilterBarDiscounts(
                  order: c.filterOrder,
                  business: c.selectedBusinessId ?? 0,
                  businessItems: c.businessSelectorItems,
                  onOrder: c.setFilterOrder,
                  onBusiness: c.setSelectedBusiness,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: isLoading
                    ? const SizedBox.shrink()
                    : all.isEmpty
                        ? InitialEmptyState(
                            icon: Icons.local_offer,
                            title: "No tienes promociones",
                            description:
                                "Crea una promoción para atraer clientes.",
                            actionLabel: "Crear promoción",
                            onCreate: _openCreateDiscount,
                          )
                        : isFilteredEmpty
                            ? FilteredEmptyState(
                                title: "No hay promociones",
                                subtitle: "Prueba cambiando los filtros",
                                onAction: () {
                                  c.resetFilters();
                                },
                              )
                            : RefreshIndicator(
                                onRefresh: c.loadMine,
                                child: ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(
                                    12,
                                    0,
                                    12,
                                    90,
                                  ),
                                  itemCount: filtered.length,
                                  itemBuilder: (_, i) {
                                    final promo = filtered[i];
                                    final amount = c.getEstimatedAmount(promo);
                                    final businessName =
                                        c.getBusinessName(promo.businessId);

                                    final data = c.getCardData(promo.id);
                                    final image =
                                        (data?['image'] as String?) ?? '';

                                    final canDelete =
                                        promo.status == PromotionStatus.active;
                                    final displayStatus = promo.status ==
                                                PromotionStatus.active &&
                                            promo.endDate
                                                .isBefore(DateTime.now())
                                        ? PromotionStatus.inactive
                                        : promo.status;

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 6,
                                      ),
                                      child: EntityManageCard(
                                        title: "-${promo.discountPercent}%",
                                        imageUrl: image,
                                        category: "Promoción",
                                        location: null,
                                        organizer: businessName,
                                        statusLabel:
                                            promotionStatusLabel(displayStatus),
                                        statusColor:
                                            promotionStatusColor(displayStatus),
                                        statusIcon:
                                            promotionStatusIcon(displayStatus),
                                        statusSubtitle: null,
                                        extraContent: ManagePeriodCostInfo(
                                          startDate: promo.startDate,
                                          endDate: promo.endDate,
                                          amount: amount,
                                          amountSuffix: "T",
                                        ),
                                        onTap: null,
                                        onEdit: null,
                                        onDelete: canDelete
                                            ? () => _deleteDiscount(promo.id)
                                            : null,
                                      ),
                                    );
                                  },
                                ),
                              ),
              ),
            ],
          ),
          if (isLoading)
            const AppLoader(message: "Cargando tus promociones..."),
        ],
      ),
      floatingActionButton: !hasData
          ? null
          : AppFAB(
              icon: Icons.add,
              label: "Crear promoción",
              onPressed: _openCreateDiscount,
            ),
    );
  }
}
