import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/event_model.dart';
import '../../models/media_model.dart';
import '../../providers/user_provider.dart';
import '../../controllers/event/my_calendar_controller.dart';
import '../../views/event/event_detail.dart';
import 'event_card.dart';

class CalendarEventsListSection extends StatelessWidget {
  final MyCalendarController controller;
  final List<EventModel> events;

  const CalendarEventsListSection({
    super.key,
    required this.controller,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId =
        context.read<UserProvider>().user!.id;

    return SliverList.builder(
      itemCount: events.length,
      itemBuilder: (context, i) {
        final e = events[i];
        final isMulti = controller.isMultiDay(e);

        final medias = controller.mediaByEvent[e.id] ?? <MediaModel>[];
        final imageUrl =
        medias.isNotEmpty ? medias.first.url : null;

        return EventCard(
          event: e,
          isMulti: isMulti,
          imageUrl: imageUrl,
          currentUserId: currentUserId,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EventDetailPage(event: e),
              ),
            );
          },
        );
      },
    );
  }
}