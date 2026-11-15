import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:tinkuapp/services/review_service.dart';

import '../../controllers/business/my_businesses_controller.dart';
import '../../core/enums.dart';
import '../../services/business_service.dart';
import '../../services/category_service.dart';
import '../../services/media_service.dart';
import '../../services/marketplace_service.dart';
import '../../providers/user_provider.dart';
import '../../widgets/bars/filter_bar_businesses.dart';
import '../../models/business_model.dart';
import '../../views/business/business_detail.dart';
import '../../widgets/common/actions/app_fab.dart';
import '../../widgets/common/actions/confirm_delete_action.dart';
import '../../widgets/common/loaders/app_loader.dart';
import '../../widgets/common/navigation/custom_app_bar.dart';
import '../../widgets/common/entity_manage/entity_manage_card.dart';
import '../../widgets/common/filtered_empty.dart';
import '../../widgets/common/empty/app_empty.dart';
import '../../widgets/common/initial_empty_state.dart';
import 'business_form.dart';

import '../../mappers/entity_manage_mapper.dart';

class MyBusinessesPage extends StatefulWidget {
  final String type; // 'business' o 'service'
  const MyBusinessesPage({super.key, required this.type});

  @override
  State<MyBusinessesPage> createState() => _MyBusinessesPageState();
}

class _MyBusinessesPageState extends State<MyBusinessesPage> {
  late MyBusinessesController c;
  String filterStatus = "todos";
  String sortOrder = "desc"; // por defecto más reciente arriba
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

    c = MyBusinessesController(
      BusinessService(auth),
      CategoryService(auth),
      MediaService(auth),
      ReviewService(auth),
      MarketplaceService(auth),
    );

    c.addListener(_rebuild);
    _loadedUserId = userId;
    filterStatus = "todos";
    sortOrder = "desc";

    Future.microtask(() async {
      await c.load();
      if (mounted) setState(() {});
    });

    _initialized = true;
  }

  @override
  void dispose() {
    if (_initialized) {
      c.removeListener(_rebuild);
      c.reset();
    }
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  // ------------------------------------
  @override
  Widget build(BuildContext context) {
    final isLoading = c.loading;
    final all = c.businesses;
    final selectedType = businessTypeFromString(widget.type);
    List<BusinessModel> list =
        all.where((b) => (b.businessType) == selectedType).toList();

    // FILTRO POR ESTADO
    list = list.where((b) {
      int displayStatus;
      if (b.status == BusinessStatus.suspended) {
        displayStatus = 3;
      } else if (b.validated == true) {
        displayStatus = 1;
      } else if (b.validated == false && b.status == BusinessStatus.pending) {
        displayStatus = 2;
      } else {
        displayStatus = 0;
      }

      switch (filterStatus) {
        case "activo":
          return displayStatus == 1;
        case "pendiente":
          return displayStatus == 2;
        case "rechazado":
          return displayStatus == 3;
        case "inactivo":
          return displayStatus == 0;
        default:
          return true;
      }
    }).toList();

    // ORDEN ASC / DESC
    list.sort((a, b) =>
        sortOrder == "desc" ? b.id.compareTo(a.id) : a.id.compareTo(b.id));

    final isService = widget.type.toLowerCase() == 'service';
    final title = isService ? 'Servicios' : 'Negocios';
    final emptyIcon =
        isService ? FontAwesomeIcons.briefcase : FontAwesomeIcons.store;
    final emptyText = isService
        ? 'Aún no tienes servicios creados'
        : 'Aún no tienes negocios creados';
    final emptyDesc = isService
        ? 'Crea tu primer servicio y compártelo con la comunidad.'
        : 'Crea tu primer negocio y muéstralo a la comunidad.';

    final hasData =
        all.where((b) => (b.businessType) == selectedType).isNotEmpty;

    final isFilteredEmpty = list.isEmpty && hasData;

    return Scaffold(
      appBar: CustomAppBar(title: title),
      body: Stack(
        children: [
          // 👇 contenido SIEMPRE presente
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: FilterBarBusinesses(
                  status: filterStatus,
                  order: sortOrder,
                  onStatus: (v) => setState(() => filterStatus = v),
                  onOrder: (v) => setState(() => sortOrder = v),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: c.error != null && all.isEmpty
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AppEmptyState(
                            icon: Icons.error_outline,
                            title: c.error!,
                            subtitle:
                                'Verifica tu conexión e inténtalo de nuevo.',
                          ),
                          TextButton.icon(
                            onPressed: c.load,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reintentar'),
                          ),
                        ],
                      )
                    : list.isEmpty
                        ? isFilteredEmpty
                            ? FilteredEmptyState(
                                title: "No hay resultados con estos filtros",
                                subtitle:
                                    "Prueba cambiando los filtros o limpiándolos",
                                onAction: () {
                                  setState(() {
                                    filterStatus = "todos";
                                    sortOrder = "desc";
                                  });
                                },
                              )
                            : InitialEmptyState(
                                icon: emptyIcon,
                                title: emptyText,
                                description: emptyDesc,
                                actionLabel: isService
                                    ? 'Crear servicio'
                                    : 'Crear negocio',
                                onCreate: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          BusinessFormPage(type: widget.type),
                                    ),
                                  );
                                  if (!context.mounted) return;
                                  c.load();
                                },
                              )
                        : RefreshIndicator(
                            onRefresh: c.load,
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 90),
                              itemCount: list.length,
                              itemBuilder: (context, index) {
                                final b = list[index];
                                final meta = c.statusMeta(b);

                                final data =
                                    EntityManageMapper.fromBusiness(b, c, meta);

                                final canManage = c.canManageBusiness(b);

                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  child: EntityManageCard(
                                    title: data.title,
                                    category: data.category,
                                    location: data.location,
                                    imageUrl: data.imageUrl,
                                    statusLabel: meta.label,
                                    statusColor: meta.color,
                                    statusIcon: meta.icon,
                                    views: data.views,
                                    rating: data.rating,
                                    date: data.date,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              BusinessDetailPage(business: b),
                                        ),
                                      );
                                    },
                                    onEdit: canManage
                                        ? () async {
                                            final updated =
                                                await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    BusinessFormPage(
                                                  type: widget.type,
                                                  business: b,
                                                ),
                                              ),
                                            );

                                            if (updated == true) {
                                              await c.load();
                                            }
                                          }
                                        : null,
                                    onDelete: canManage
                                        ? () async {
                                            await confirmAndDelete(
                                              context: context,
                                              title:
                                                  '¿Eliminar ${widget.type == 'service' ? 'servicio' : 'negocio'}?',
                                              message:
                                                  '¿Seguro que deseas eliminar "${b.name}"? Esta acción no se puede deshacer.',
                                              onDelete: () =>
                                                  c.softDeleteBusiness(b),
                                              successMessage:
                                                  '${widget.type == 'service' ? 'Servicio' : 'Negocio'} eliminado exitosamente',
                                              errorMessage:
                                                  'No se pudo eliminar',
                                            );
                                          }
                                        : null,
                                  ),
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),

          // LOADER
          if (isLoading)
            AppLoader(
              message: isService
                  ? "Cargando tus servicios..."
                  : "Cargando tus negocios...",
            ),
        ],
      ),
      floatingActionButton: list.isEmpty
          ? null
          : AppFAB(
              icon: FontAwesomeIcons.plus,
              label: isService ? 'Agregar servicio' : 'Agregar negocio',
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BusinessFormPage(type: widget.type),
                  ),
                );
                if (!context.mounted) return;
                c.load();
              },
            ),
    );
  }
}
