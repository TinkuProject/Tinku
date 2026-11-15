import 'package:flutter_test/flutter_test.dart';
import 'package:tinkuapp/controllers/event/my_calendar_controller.dart';
import 'package:tinkuapp/core/enums.dart';
import 'package:tinkuapp/models/event_model.dart';
import 'package:tinkuapp/services/auth_service.dart';
import 'package:tinkuapp/services/event_service.dart';
import 'package:tinkuapp/services/media_service.dart';
import 'package:tinkuapp/services/reservation_service.dart';

EventModel event(int id, DateTime start, DateTime end) => EventModel(
      id: id,
      creatorId: 'owner',
      categoryId: 1,
      name: 'Evento $id',
      startDate: start,
      endDate: end,
      address: 'Dirección',
      latitude: -17.39,
      longitude: -66.15,
      status: EventStatus.active,
      createdAt: start,
    );

void main() {
  test('elige el próximo evento por inicio y omite los terminados', () {
    final auth = AuthService();
    final controller = MyCalendarController(
      EventService(auth),
      ReservationService(auth),
      MediaService(auth),
    );
    final now = DateTime(2026, 9, 21, 10);
    controller.all = [
      event(3, DateTime(2026, 9, 30), DateTime(2026, 9, 30, 12)),
      event(1, DateTime(2026, 9, 20), DateTime(2026, 9, 20, 12)),
      event(2, DateTime(2026, 9, 24), DateTime(2026, 9, 24, 12)),
    ];

    expect(controller.nextEventAfter(DateTime(2026, 9, 21), now: now)?.id, 2);
    expect(controller.nextEventAfter(DateTime(2026, 9, 25), now: now)?.id, 3);
    expect(controller.nextEventAfter(DateTime(2026, 10, 1), now: now), isNull);

    controller.dispose();
  });
}
