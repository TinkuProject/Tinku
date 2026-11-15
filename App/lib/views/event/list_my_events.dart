import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:tinkuapp/providers/user_provider.dart';
import 'package:tinkuapp/services/category_service.dart';
import 'package:tinkuapp/services/review_service.dart';

import '../../controllers/event/events_list_controller.dart';
import '../../mappers/entity_manage_mapper.dart';
import '../../services/event_service.dart';
import '../../services/business_service.dart';
import '../../services/media_service.dart';

import '../../ui/enums/event_filters.dart';
import '../../widgets/common/actions/app_fab.dart';
import '../../widgets/common/actions/confirm_delete_action.dart';
import '../../widgets/common/initial_empty_state.dart';
import '../../widgets/common/loaders/app_loader.dart';
import '../../widgets/common/navigation/custom_app_bar.dart';
import '../../widgets/bars/filter_bar_events.dart';
import '../../widgets/common/entity_manage/entity_manage_card.dart';
import '../../widgets/common/filtered_empty.dart';
import 'event_detail.dart';
import 'event_form.dart';

class EventsListPage extends StatefulWidget {
  const EventsListPage({super.key});

  @override
  State<EventsListPage> createState() => _EventsListPageState();
}

class _EventsListPageState extends State<EventsListPage> {
  late EventsListController c;
  bool _initialized = false;
  String? _loadedUserId;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final userProvider = context.watch<UserProvider>();
    final userId = userProvider.user?.id;
    if (_initialized && _loadedUserId == userId) return;

    if (_initialized) {
      c.removeListener(_rebuild);
      c.reset();
      c.dispose();
    }

    final auth = userProvider.authService;

    c = EventsListController(
      EventService(auth),
      BusinessService(auth),
      MediaService(auth),
      CategoryService(auth),
      ReviewService(auth),
    );

    c.addListener(_rebuild);
    _initialized = true;
    _loadedUserId = userId;

    _init();
  }

  Future<void> _init() async {
    await c.init();

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    if (_initialized) {
      c.removeListener(_rebuild);
      c.dispose();
    }
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Eventos'),
      body: Stack(
        children: [
          // 👇 CONTENIDO SIEMPRE VISIBLE
          Builder(
            builder: (_) {
              if (c.error != null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.redAccent),
                        const SizedBox(height: 12),
                        Text("Ocurrió un error: ${c.error}",
                            textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: c.refresh,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (c.all.isEmpty) {
                return InitialEmptyState(
                  icon: FontAwesomeIcons.calendarCheck,
                  title: "Aún no tienes eventos creados",
                  description:
                  "Crea tu primer evento y compártelo con tu comunidad.",
                  actionLabel: 'Crear evento',
                  onCreate: () async {
                    final result =
                    await Navigator.pushNamed(context, '/addEvent');
                    if (result == true) c.refresh();
                  },
                );
              }

              final events = c.filtered;

              if (events.isEmpty) {
                final isFiltered =
                    c.filterStatus != EventFilterStatus.all ||
                        c.filterOrder != EventOrder.newest ||
                        c.filterPrice != EventPriceFilter.all;

                if (isFiltered) {
                  return FilteredEmptyState(
                    title: "No hay eventos con estos filtros",
                    subtitle:
                    "Prueba cambiando los filtros o limpiándolos",
                    onAction: () {
                      c.setFilterStatus(EventFilterStatus.all);
                      c.setFilterOrder(EventOrder.newest);
                      c.setFilterPrice(EventPriceFilter.all);
                    },
                  );
                }

                return const Center(child: Text("No hay eventos disponibles"));
              }

              return RefreshIndicator(
                onRefresh: c.refresh,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                  itemCount: events.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: FilterBarEvents(
                          status: c.filterStatus,
                          order: c.filterOrder,
                          price: c.filterPrice,
                          onStatus: c.setFilterStatus,
                          onOrder: c.setFilterOrder,
                          onPrice: c.setFilterPrice,
                        ),
                      );
                    }

                    final ev = events[index - 1];
                    final data = EntityManageMapper.fromEvent(ev, c);
                    final meta = c.statusMeta(ev);

                    final canManage = c.canManageEvent(ev);

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: EntityManageCard(
                        title: data.title,
                        category: data.category,
                        location: data.location,
                        imageUrl: data.imageUrl,
                        statusSubtitle: "Organiza: ${data.organizer ?? '—'}",
                        statusLabel: meta.label,
                        statusColor: meta.color,
                        statusIcon: meta.icon,
                        views: data.views,
                        rating: data.rating,
                        date: data.date,
                        onTap: () async {
                          final updated = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EventDetailPage(event: ev),
                            ),
                          );
                          if (updated == true) c.refresh();
                        },
                        onEdit: canManage
                            ? () async {
                          final updated = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EventFormPage(
                                editing: true,
                                event: ev,
                              ),
                            ),
                          );

                          if (updated == true) {
                            await c.refresh();
                          }
                        }
                            : null,

                        onDelete: canManage
                            ? () async {
                          await confirmAndDelete(
                            context: context,
                            title: '¿Eliminar evento?',
                            message: '¿Seguro que deseas eliminar "${ev.name}"? Esta acción no se puede deshacer.',
                            onDelete: () => c.softDeleteEvent(ev.id),
                            successMessage: 'Evento eliminado exitosamente',
                            errorMessage: 'No se pudo eliminar',
                          );
                        }
                            : null,
                      ),
                    );
                  },
                ),
              );
            },
          ),

          // LOADER
          if (c.loading)
            const AppLoader(
              message: "Cargando tus eventos...",
            ),
        ],
      ),
      floatingActionButton: c.all.isEmpty
          ? null
          : AppFAB(
        icon: FontAwesomeIcons.plus,
        label: 'Agregar evento',
        onPressed: () async {
          final result =
          await Navigator.pushNamed(context, '/addEvent');
          if (result == true) c.refresh();
        },
      ),
    );
  }
}
