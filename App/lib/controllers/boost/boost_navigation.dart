import 'package:flutter/material.dart';

import '../../../models/boost_model.dart';
import '../../../core/enums.dart';

import '../../../services/business_service.dart';
import '../../../services/event_service.dart';
import '../../../services/tourist_place_service.dart';

import '../../../views/business/business_detail.dart';
import '../../../views/event/event_detail.dart';
import '../../../views/touristPlaces/tourist_place_detail.dart';

class BoostNavigation {
  final BusinessService businessService;
  final EventService eventService;
  final TouristPlaceService touristPlaceService;

  BoostNavigation({
    required this.businessService,
    required this.eventService,
    required this.touristPlaceService,
  });

  Future<void> open(BuildContext context, BoostModel boost) async {
    final navigator = Navigator.of(context);

    switch (boost.entityType) {
      case VisitEntity.business:
        final b = await businessService.getById(boost.entityId);
        if (b != null && navigator.mounted) {
          navigator.push(
            MaterialPageRoute(
              builder: (_) => BusinessDetailPage(business: b),
            ),
          );
        }
        break;

      case VisitEntity.event:
        final e = await eventService.getById(boost.entityId);
        if (e != null && navigator.mounted) {
          navigator.push(
            MaterialPageRoute(
              builder: (_) => EventDetailPage(event: e),
            ),
          );
        }
        break;

      case VisitEntity.tourist_place:
        final p = await touristPlaceService.getById(boost.entityId);
        if (p != null && navigator.mounted) {
          navigator.push(
            MaterialPageRoute(
              builder: (_) => TouristPlaceDetail(place: p),
            ),
          );
        }
        break;
    }
  }
}