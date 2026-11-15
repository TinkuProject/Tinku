import 'package:flutter/material.dart';

import '../controllers/business/my_businesses_controller.dart';
import '../controllers/event/events_list_controller.dart';
import '../models/business_model.dart';
import '../models/entity_manage_data.dart';
import '../models/event_model.dart';
import '../utils/date/date_formatter.dart';

class EntityManageMapper {
  static EntityManageData fromBusiness(
    BusinessModel b,
    MyBusinessesController c,
    ({String label, Color color, IconData icon}) meta,
  ) {
    return EntityManageData(
      title: b.name,
      category: c.categoryLabel(b.categoryId),
      location: b.address,
      imageUrl:
          c.mediaUrlsFor(b.id).isNotEmpty ? c.mediaUrlsFor(b.id).first : '',
      organizer: null,
      views: c.getViews(b.id),
      rating: c.getRating(b.id),
      date: DateFormatter.formatDate(b.createdAt),
    );
  }

  static EntityManageData fromEvent(
    EventModel ev,
    EventsListController c,
  ) {
    final medias = c.mediaByEvent[ev.id] ?? [];

    return EntityManageData(
      title: ev.name,
      category: c.categoryLabel(ev.categoryId),
      location: ev.address,
      imageUrl: medias.isNotEmpty ? medias.first : '',
      organizer: c.organizerLabel(ev.id),
      views: null,
      rating: c.getRating(ev.id),
      date: DateFormatter.eventRange(ev.startDate, ev.endDate),
    );
  }
}
