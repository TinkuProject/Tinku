import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/utils.dart';
import '../../core/enums.dart';
import '../../providers/user_provider.dart';

import '../../services/boost_service.dart';
import '../../services/media_service.dart';
import '../../services/product_service.dart';
import '../../services/review_service.dart';
import '../../services/business_service.dart';
import '../../services/event_service.dart';
import '../../services/system_config_service.dart';
import '../../services/tourist_place_service.dart';

import '../../controllers/boost/boost_controller.dart';

import '../../widgets/boost/add_boost_modal.dart';
import '../../widgets/bars/filter_bar_boosts.dart';
import '../../widgets/common/actions/confirm_delete_action.dart';
import '../../widgets/common/info/manage_period_cost_info.dart';
import '../../widgets/common/navigation/custom_app_bar.dart';
import '../../widgets/common/loaders/app_loader.dart';
import '../../widgets/common/filtered_empty.dart';
import '../../widgets/common/initial_empty_state.dart';
import '../../widgets/common/actions/app_fab.dart';
import '../../widgets/common/entity_manage/entity_manage_card.dart';

import '../../widgets/selectors/business_selector_dialog.dart';
import '../../utils/status/promotion_status_ui.dart';

class ListMyBoostsPage extends StatefulWidget {
  const ListMyBoostsPage({super.key});

  @override
  State<ListMyBoostsPage> createState() => _ListMyBoostsPageState();
}

class _ListMyBoostsPageState extends State<ListMyBoostsPage> {
  late BoostController c;

  bool _initialized = false;
  String? _loadedUserId;

  String filterStatus = "todos";
  String sortOrder = "desc";

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final userProvider = context.watch<UserProvider>();
    final userId = userProvider.user?.id;
    if (_initialized && _loadedUserId == userId) return;

    if (_initialized) {
      c.removeListener(_rebuild);
      c.resetMine();
    }

    final auth = userProvider.authService;

    c = BoostController(
      boostService: BoostService(auth),
      mediaService: MediaService(auth),
      businessService: BusinessService(auth),
      eventService: EventService(auth),
      productService: ProductService(auth),
      reviewService: ReviewService(auth),
      touristPlaceService: TouristPlaceService(auth),
      systemConfigService: SystemConfigService(auth),
    );

    c.addListener(_rebuild);
    _loadedUserId = userId;
    filterStatus = "todos";
    sortOrder = "desc";

    Future.microtask(() async {
      await c.loadMine();
      if (mounted) setState(() {});
    });

    _initialized = true;
  }

  @override
  void dispose() {
    if (_initialized) {
      c.removeListener(_rebuild);
      c.resetMine();
    }
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  Future<void> _createBoost() async {
    if (!c.hasBusinesses) {
      await c.loadMine();
    }

    if (!c.hasBusinesses) {
      showSnackbar("No tienes negocios para impulsar.");
      return;
    }

    if (!mounted) return;

    final selected = await showBusinessSelectorDialog(
      context: context,
      businessItems: c.businessSelectorItems,
      disabledIds: c.disabledBusinessSelectorIds,
      disabledLabel: 'Pendiente',
    );

    if (selected == null) {
      return;
    }

    if (c.dailyCost <= 0) {
      await c.loadBoostCost();
    }

    if (!mounted) return;

    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddBoostModal(
        entityType: VisitEntity.business,
        entityId: selected,
        dailyCost: c.dailyCost,
      ),
    );

    if (result == true) {
      await c.loadMine();
    }
  }

  Future<void> _deleteBoost(int id) async {
    await confirmAndDelete(
      context: context,
      title: '¿Eliminar impulso?',
      message: 'Esta acción no se puede deshacer.',
      onDelete: () => c.boostService.softDelete(id),
      onAfterDelete: () => c.loadMine(),
      successMessage: "Impulso eliminado",
      errorMessage: "Error al eliminar impulso",
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = c.loading;
    final all = c.allBoosts;

    final filtered = all.where((b) {
      switch (filterStatus) {
        case "activo":
          return b.status == PromotionStatus.active;
        case "inactivo":
          return b.status == PromotionStatus.inactive;
        case "cancelado":
          return b.status == PromotionStatus.cancelled;
        default:
          return true;
      }
    }).toList();

    filtered.sort(
          (a, b) => sortOrder == "desc"
          ? b.startDate.compareTo(a.startDate)
          : a.startDate.compareTo(b.startDate),
    );

    final hasData = all.isNotEmpty;
    final isFilteredEmpty = filtered.isEmpty && hasData;

    return Scaffold(
      appBar: const CustomAppBar(title: "Mis impulsos"),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: FilterBarBoosts(
                  status: filterStatus,
                  order: sortOrder,
                  onStatus: (v) => setState(() => filterStatus = v),
                  onOrder: (v) => setState(() => sortOrder = v),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: filtered.isEmpty
                    ? isFilteredEmpty
                    ? FilteredEmptyState(
                  title: "No hay resultados",
                  subtitle: "Prueba cambiando los filtros",
                  onAction: () {
                    setState(() {
                      filterStatus = "todos";
                      sortOrder = "desc";
                    });
                  },
                )
                    : InitialEmptyState(
                  icon: Icons.campaign,
                  title: "No tienes impulsos",
                  description:
                  "Crea tu primer impulso para destacar tu negocio o evento.",
                  actionLabel: "Crear impulso",
                  onCreate: _createBoost,
                )
                    : RefreshIndicator(
                  onRefresh: c.loadMine,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 90),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final boost = filtered[i];
                      final amount = c.getEstimatedAmount(boost);
                      final data = c.getCardData(boost.id);

                      final title = (data?['title'] as String?) ?? 'Impulso';
                      final image = (data?['image'] as String?) ?? '';

                      final canDelete = boost.status == PromotionStatus.active;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: EntityManageCard(
                          title: title,
                          imageUrl: image,
                          category: "Impulso",
                          location: null,
                          organizer: null,
                          statusLabel: promotionStatusLabel(boost.status),
                          statusColor: promotionStatusColor(boost.status),
                          statusIcon: promotionStatusIcon(boost.status),
                          statusSubtitle: null,
                          extraContent: ManagePeriodCostInfo(
                            startDate: boost.startDate,
                            endDate: boost.endDate,
                            amount: amount,
                            amountSuffix: "Tinkus",
                          ),
                          onTap: null,
                          onEdit: null,
                          onDelete: canDelete
                              ? () => _deleteBoost(boost.id)
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
            const AppLoader(message: "Cargando tus impulsos..."),
        ],
      ),
      floatingActionButton: filtered.isEmpty
          ? null
          : AppFAB(
        icon: Icons.add,
        label: "Crear impulso",
        onPressed: _createBoost,
      ),
    );
  }
}
