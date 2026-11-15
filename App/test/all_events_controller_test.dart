import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tinkuapp/controllers/event/all_events_controller.dart';
import 'package:tinkuapp/core/enums.dart';
import 'package:tinkuapp/models/event_model.dart';
import 'package:tinkuapp/models/media_model.dart';
import 'package:tinkuapp/models/paginated_result.dart';
import 'package:tinkuapp/services/auth_service.dart';
import 'package:tinkuapp/services/event_service.dart';
import 'package:tinkuapp/services/media_service.dart';

EventModel _event(int id) => EventModel(
      id: id,
      creatorId: 'owner',
      categoryId: 1,
      name: 'Evento $id',
      startDate: DateTime(2026, 9, 25),
      endDate: DateTime(2026, 9, 25, 12),
      address: 'Dirección',
      latitude: -17.39,
      longitude: -66.15,
      status: EventStatus.active,
      createdAt: DateTime(2026, 9, 20),
    );

PaginatedResult<EventModel> _page(List<int> ids, int offset, int total) {
  return PaginatedResult(
    items: ids.map(_event).toList(),
    total: total,
    limit: 20,
    offset: offset,
    hasMore: offset + ids.length < total,
  );
}

class _EventService extends EventService {
  _EventService() : super(AuthService());

  final Map<int, PaginatedResult<EventModel>> pages = {};
  Completer<PaginatedResult<EventModel>>? pendingMore;

  @override
  Future<PaginatedResult<EventModel>> getPage({
    int limit = 20,
    int offset = 0,
  }) async {
    if (offset > 0 && pendingMore != null) return pendingMore!.future;
    return pages[offset]!;
  }
}

class _MediaService extends MediaService {
  _MediaService() : super(AuthService());

  @override
  Future<Map<int, List<MediaModel>>> getByEntities({
    required List<int> entityIds,
    required MediaEntityType entityType,
  }) async =>
      {};
}

void main() {
  test('carga páginas de eventos sin duplicar y permite refrescar', () async {
    final service = _EventService()
      ..pages[0] = _page([1, 2], 0, 3)
      ..pages[2] = _page([2, 3], 2, 3);
    final controller = AllEventsController(service, _MediaService());

    await controller.load();
    expect(controller.events.map((event) => event.id), [1, 2]);
    expect(controller.hasMore, isTrue);

    await controller.loadMore();
    expect(controller.events.map((event) => event.id), [1, 2, 3]);
    expect(controller.hasMore, isFalse);

    service.pages[0] = _page([4], 0, 1);
    await controller.load();
    expect(controller.events.map((event) => event.id), [4]);
    controller.dispose();
  });

  test('ignora una página anterior que termina después del refresco', () async {
    final service = _EventService()
      ..pages[0] = _page([1], 0, 2)
      ..pendingMore = Completer<PaginatedResult<EventModel>>();
    final controller = AllEventsController(service, _MediaService());
    await controller.load();

    final oldPage = controller.loadMore();
    service.pages[0] = _page([3], 0, 1);
    await controller.load();
    service.pendingMore!.complete(_page([2], 1, 2));
    await oldPage;

    expect(controller.events.map((event) => event.id), [3]);
    expect(controller.loadingMore, isFalse);
    controller.dispose();
  });
}
