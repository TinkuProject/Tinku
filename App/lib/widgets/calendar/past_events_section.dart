import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/event_model.dart';
import '../../models/media_model.dart';
import '../../providers/user_provider.dart';
import '../../controllers/event/my_calendar_controller.dart';
import '../../views/event/event_detail.dart';
import 'past_event_card.dart';

class PastEventsSection extends StatelessWidget {
  final MyCalendarController controller;
  final List<EventModel> pastEvents;

  const PastEventsSection({
    super.key,
    required this.controller,
    required this.pastEvents,
  });

  @override
  Widget build(BuildContext context) {
    if (pastEvents.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final currentUserId =
        context.read<UserProvider>().user!.id;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Eventos anteriores",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              height: 240,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: pastEvents.length,
                separatorBuilder: (_, __) =>
                const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final e = pastEvents[i];

                  final medias =
                      controller.mediaByEvent[e.id] ?? <MediaModel>[];
                  final imageUrl =
                  medias.isNotEmpty ? medias.first.url : null;

                  final isMulti = controller.isMultiDay(e);

                  return PastEventCard(
                    event: e,
                    imageUrl: imageUrl,
                    isMulti: isMulti,
                    currentUserId: currentUserId,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              EventDetailPage(event: e),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}