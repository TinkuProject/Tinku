import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/event/all_events_controller.dart';
import '../../models/event_model.dart';
import '../../providers/user_provider.dart';
import '../../services/event_service.dart';
import '../../services/media_service.dart';
import '../../ui/themes/colors.dart';
import '../../widgets/common/loaders/app_loader.dart';
import '../../widgets/common/navigation/custom_app_bar.dart';
import '../../widgets/common/network_image_with_loader.dart';
import 'event_detail.dart';

class AllEventsPage extends StatefulWidget {
  const AllEventsPage({super.key});

  @override
  State<AllEventsPage> createState() => _AllEventsPageState();
}

class _AllEventsPageState extends State<AllEventsPage> {
  late AllEventsController c;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;

    final auth = context.read<UserProvider>().authService;

    c = AllEventsController(
      EventService(auth),
      MediaService(auth),
    )..addListener(_rebuild);

    Future.microtask(() => c.load());

    _initialized = true;
  }

  @override
  void dispose() {
    c.removeListener(_rebuild);
    c.dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _goToDetail(EventModel event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventDetailPage(event: event),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    final yyyy = dt.year.toString();
    final hh = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return "$dd/$mm/$yyyy • $hh:$min";
  }

  @override
  Widget build(BuildContext context) {
    final loading = c.loading;
    final error = c.error;
    final events = c.events;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Eventos Disponibles'),
      body: loading
          ? const AppLoader(message: 'Cargando eventos...')
          : error != null && events.isEmpty
              ? Center(
                  child: TextButton.icon(
                  onPressed: c.load,
                  icon: const Icon(Icons.refresh),
                  label: Text(error),
                ))
              : events.isEmpty
                  ? const Center(child: Text('No hay eventos disponibles'))
                  : RefreshIndicator(
                      onRefresh: () => c.load(),
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: events.length + (c.hasMore ? 1 : 0),
                        padding: const EdgeInsets.all(12),
                        itemBuilder: (context, index) {
                          if (index == events.length) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: c.loadingMore
                                    ? const CircularProgressIndicator()
                                    : TextButton.icon(
                                        onPressed: c.loadMore,
                                        icon: const Icon(Icons.expand_more),
                                        label: Text(c.moreError ??
                                            'Cargar más eventos'),
                                      ),
                              ),
                            );
                          }
                          final event = events[index];

                          final medias = c.mediaByEvent[event.id] ?? [];
                          final image = medias.isNotEmpty ? medias.first : null;

                          return GestureDetector(
                            onTap: () => _goToDetail(event),
                            child: Card(
                              elevation: 6,
                              margin: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(16),
                                    ),
                                    child: NetworkImageWithLoader(
                                      imageUrl: image?.url,
                                      width: double.infinity,
                                      height: 180,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          event.name,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          'Inicio: ${_formatDateTime(event.startDate)}',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.darkBlue,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Fin: ${_formatDateTime(event.endDate)}',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.darkBlue,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        if ((event.description ?? '')
                                            .isNotEmpty) ...[
                                          Text(
                                            event.description!,
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                        ],
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.location_on,
                                              color: Colors.grey,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                event.address,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.black54,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
