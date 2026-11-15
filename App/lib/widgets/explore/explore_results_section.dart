import 'package:flutter/material.dart';

import '../../models/business_model.dart';
import '../../models/tourist_place_model.dart';
import '../../models/event_model.dart';

import '../business/business_card_compact.dart';
import '../tourist_places/tourist_place_card_compact.dart';
import '../events/event_card_compact.dart';

class ExploreResultsSection extends StatelessWidget {
  final List<BusinessModel> businesses;
  final List<TouristPlaceModel> touristPlaces;
  final List<EventModel> events;

  final String? Function(int) getBusinessImage;
  final String? Function(int) getTouristImage;
  final String? Function(int) getEventImage;

  final String Function(int) getCategory;

  final double? Function(int) getRating;
  final double? Function(int) getPrice;

  final void Function(BusinessModel) onBusinessTap;
  final void Function(TouristPlaceModel) onTouristTap;
  final void Function(EventModel) onEventTap;

  const ExploreResultsSection({
    super.key,
    required this.businesses,
    required this.touristPlaces,
    required this.events,
    required this.getBusinessImage,
    required this.getTouristImage,
    required this.getEventImage,
    required this.getCategory,
    required this.getRating,
    required this.getPrice,
    required this.onBusinessTap,
    required this.onTouristTap,
    required this.onEventTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

        /// 🏢 BUSINESSES
        ...businesses.map((b) => BusinessCardCompact(
          business: b,
          imageUrl: getBusinessImage(b.id),
          rating: getRating(b.id),
          price: getPrice(b.id),
          category: getCategory(b.categoryId),
          onTap: () => onBusinessTap(b),
        )),

        /// 📍 TOURIST
        ...touristPlaces.map((p) => TouristPlaceCardCompact(
          place: p,
          imageUrl: getTouristImage(p.id),
          onTap: () => onTouristTap(p),
        )),

        /// 🎉 EVENTS
        ...events.map((e) => EventCardCompact(
          event: e,
          imageUrl: getEventImage(e.id),
          onTap: () => onEventTap(e),
        )),
      ],
    );
  }
}