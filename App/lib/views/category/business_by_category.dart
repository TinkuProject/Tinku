import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../controllers/category/explore_by_category_controller.dart';

import '../../core/enums.dart';
import '../../models/business_model.dart';
import '../../models/event_model.dart';
import '../../models/tourist_place_model.dart';

import '../../providers/user_provider.dart';
import '../../services/business_service.dart';
import '../../services/event_service.dart';
import '../../services/media_service.dart';
import '../../services/tourist_place_service.dart';
import '../../services/review_service.dart';
import '../../services/product_service.dart';
import '../../services/explore_feed_service.dart';

import '../../widgets/business/business_card.dart';
import '../../widgets/events/event_card.dart';
import '../../widgets/tourist_places/tourist_place_card.dart';
import '../../widgets/common/loaders/app_loader.dart';
import '../../widgets/common/navigation/custom_app_bar.dart';
import '../../widgets/map/explore_map.dart';
import '../event/event_detail.dart';
import '../../services/map_marker_service.dart';

class BusinessByCategoryPage extends StatefulWidget {
  final int categoryId;
  final String categoryName;
  final String categoryType;

  const BusinessByCategoryPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.categoryType,
  });

  @override
  State<BusinessByCategoryPage> createState() => _BusinessByCategoryPageState();
}

class _BusinessByCategoryPageState extends State<BusinessByCategoryPage> {
  late ExploreByCategoryController c;
  bool _initialized = false;

  bool showPastEvents = false;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;

    final auth = context.read<UserProvider>().authService;

    c = ExploreByCategoryController(
      BusinessService(auth),
      EventService(auth),
      TouristPlaceService(auth),
      ReviewService(auth),
      ProductService(auth),
      MediaService(auth),
      ExploreFeedService(auth),
    )..addListener(_rebuild);

    c.init(
      id: widget.categoryId,
      type: widget.categoryType,
      name: widget.categoryName,
    );

    _loadMarkers();

    _initialized = true;
  }

  @override
  void dispose() {
    c.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) {
      _loadMarkers();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {

    final filteredItems = c.items.where((item) {
      if (item is EventModel) {
        if (showPastEvents) return true;
        return item.status == EventStatus.active;
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: CustomAppBar(title: widget.categoryName),
      body: c.loading
          ? const AppLoader(message: 'Cargando resultados...')
          : Column(
        children: [

          if (widget.categoryType == "event")
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Mostrar eventos pasados",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Switch(
                    value: showPastEvents,
                    onChanged: (v) {
                      setState(() {
                        showPastEvents = v;
                      });
                      _loadMarkers();
                    },
                  ),
                ],
              ),
            ),

          ExploreMap(markers: _markers),

          Expanded(
            child: filteredItems.isEmpty
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_busy,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    "No se cuenta con eventos activos",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Puedes explorar eventos pasados en el mapa",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: () async => c.load(),
              child: ListView(
                physics:
                const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 12),
                  ...filteredItems.map((item) {
                    if (item is BusinessModel) {
                      final extras = c.extrasFor(item.id);

                      return BusinessCard(
                        business: item,
                        rating: extras?.ratingAvg,
                        price: extras?.priceAvg,
                        category: widget.categoryName,
                      );

                    } else if (item is TouristPlaceModel) {

                      return TouristPlaceCard(
                        place: item,
                        imageUrl:
                        c.touristPlaceImages[item.id],
                      );

                    } else if (item is EventModel) {

                      return EventCard(
                        event: item,
                        imageUrl: c.eventImages[item.id],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  EventDetailPage(event: item),
                            ),
                          );
                        },
                      );

                    } else {
                      return const SizedBox.shrink();
                    }
                  }),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadMarkers() async {
    final businesses = c.items.whereType<BusinessModel>().toList();
    final touristPlaces = c.items.whereType<TouristPlaceModel>().toList();

    final events = c.items
        .whereType<EventModel>()
        .where((e) => showPastEvents ? true : e.status == EventStatus.active)
        .toList();

    final markers = await MapMarkerService.buildMarkers(
      businesses: businesses,
      touristPlaces: touristPlaces,
      events: events,
    );

    if (mounted) {
      setState(() {
        _markers = markers;
      });
    }
  }
}
