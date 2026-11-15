import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tinkuapp/core/enums.dart';
import 'package:provider/provider.dart';
import 'package:tinkuapp/services/storage_service.dart';
import 'package:tinkuapp/services/transport_route_service.dart';

import '../../controllers/event/event_detail_controller.dart';
import '../../controllers/shared/review/reviews_controller.dart';
import '../../controllers/shared/transport/entity_transport_controller.dart';
import '../../models/event_model.dart';
import '../../providers/user_provider.dart';
import '../../services/event_service.dart';
import '../../services/business_service.dart';
import '../../services/entity_transport_relation_service.dart';
import '../../services/transport_line_service.dart';
import '../../services/review_service.dart';
import '../../services/user_service.dart';
import '../../services/reservation_service.dart';
import '../../services/media_service.dart';
import '../../services/event_ticket_service.dart';

import '../../widgets/common/app_tabs.dart';
import '../../widgets/common/loaders/app_loader.dart';
import '../../widgets/events/detail/event_description_tab.dart';
import '../../widgets/events/detail/event_attendees_tab.dart';
import '../../widgets/events/detail/event_hero.dart';
import '../../widgets/events/detail/event_organizer.dart';
import '../../widgets/reviews/reviews_section.dart';
import '../../widgets/transport/transport_section.dart';

class EventDetailPage extends StatefulWidget {
  final EventModel event;

  const EventDetailPage({super.key, required this.event});

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage>
    with TickerProviderStateMixin {
  late EventDetailController c;
  late TabController _tabController;
  Timer? _carouselTimer;
  bool _initialLoading = true;

  @override
  void initState() {
    super.initState();

    final userProvider = context.read<UserProvider>();
    final auth = userProvider.authService;

    final reviewsC = ReviewsController(
      ReviewService(auth),
      UserService(auth),
      MediaService(auth),
      StorageService(auth),
      userProvider,
    );

    final transportC = EntityTransportController(
      TransportLineService(auth),
      EntityTransportRelationService(auth),
      TransportRouteService(auth),
    );

    c = EventDetailController(
      EventService(auth),
      BusinessService(auth),
      ReservationService(auth),
      MediaService(auth),
      EventTicketService(auth),
      UserService(auth),
      userProvider,
      reviewsC,
      transportC,
    );

    c.addListener(_rebuild);

    final uid = userProvider.user?.id;

    _tabController = TabController(length: 3, vsync: this)
      ..addListener(_rebuild);

    _carouselTimer = Timer.periodic(
      const Duration(seconds: 3),
          (_) {
        if (!mounted) return;
        c.advanceCarousel();
      },
    );

    Future.microtask(() async {
      await c.init(
        widget.event,
        currentUserId: uid,
      );

      if (!mounted) return;

      if (c.canManageEvent && _tabController.length != 4) {
        _tabController
          ..removeListener(_rebuild)
          ..dispose();

        _tabController = TabController(length: 4, vsync: this)
          ..addListener(_rebuild);
      }

      setState(() {
        _initialLoading = false;
      });
    });
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _tabController.dispose();

    c.removeListener(_rebuild);
    c.dispose();

    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_initialLoading) {
      return const Scaffold(
        body: Center(
          child: AppLoader(),
        ),
      );
    }

    final e = c.event;
    final medias = c.media;
    final tabs = [
      "Descripción",
      "Reseñas",
      "Transporte",
      if (c.canManageEvent) "Asistentes",
    ];
    final tabChildren = [
      EventDescriptionTab(event: e, controller: c),
      ReviewsSection(
        controller: c.reviewsController,
        targetId: e.id,
        targetType: ReviewEntityType.event,
        ownerUserId: c.business?.ownerId ?? e.creatorId,
        canWriteReview: c.canReviewEvent,
        blockedMessage:
            "Solo quienes reservaron este evento pueden escribir una reseña.",
      ),
      TransportSection(
        latitude: e.latitude,
        longitude: e.longitude,
        placeName: e.name,
        controller: c.transportC,
      ),
      if (c.canManageEvent) EventAttendeesTab(controller: c),
    ];

    return Scaffold(
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(
              child: Stack(
                children: [
                  EventHero(
                    title: e.name,
                    medias: medias,
                    isLoading: c.loadingMedia,
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: SafeArea(
                      child: Material(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: const CircleBorder(),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    EventOrganizer(
                      business: c.business,
                      organizer: c.organizer,
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ],
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppTabs(
              controller: _tabController,
              tabs: tabs,
              children: tabChildren,
            ),
          ),
        ),
      ),
    );
  }
}
