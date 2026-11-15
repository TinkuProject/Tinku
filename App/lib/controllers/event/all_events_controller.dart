import 'package:flutter/material.dart';
import '../../core/enums.dart';
import '../../models/event_model.dart';
import '../../models/media_model.dart';
import '../../services/event_service.dart';
import '../../services/media_service.dart';

class AllEventsController extends ChangeNotifier {
  AllEventsController(this._eventService, this._mediaService);

  static const pageSize = 20;

  final EventService _eventService;
  final MediaService _mediaService;

  bool loading = false;
  bool loadingMore = false;
  bool hasMore = false;
  String? error;
  String? moreError;
  int _offset = 0;
  int _requestVersion = 0;
  bool _disposed = false;
  List<EventModel> events = [];
  Map<int, List<MediaModel>> mediaByEvent = {};

  Future<void> load() async {
    final version = ++_requestVersion;
    loading = true;
    loadingMore = false;
    error = null;
    moreError = null;
    notifyListeners();

    try {
      final page = await _eventService.getPage(limit: pageSize);
      if (_disposed || version != _requestVersion) return;
      events = page.items;
      _offset = page.offset + page.items.length;
      hasMore = page.hasMore;
      mediaByEvent = {};
      await _loadMedia(page.items, version);
    } catch (_) {
      if (_disposed || version != _requestVersion) return;
      error = 'No se pudieron cargar los eventos';
    } finally {
      if (!_disposed && version == _requestVersion) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMore() async {
    if (loading || loadingMore || !hasMore) return;
    final version = _requestVersion;
    loadingMore = true;
    moreError = null;
    notifyListeners();

    try {
      final page =
          await _eventService.getPage(limit: pageSize, offset: _offset);
      if (_disposed || version != _requestVersion) return;
      _offset = page.offset + page.items.length;
      hasMore = page.hasMore;
      final existingIds = events.map((event) => event.id).toSet();
      events.addAll(page.items.where((event) => existingIds.add(event.id)));
      await _loadMedia(page.items, version);
    } catch (_) {
      if (_disposed || version != _requestVersion) return;
      moreError = 'No se pudieron cargar más eventos';
    } finally {
      if (!_disposed && version == _requestVersion) {
        loadingMore = false;
        notifyListeners();
      }
    }
  }

  Future<void> _loadMedia(List<EventModel> page, int version) async {
    if (page.isEmpty) return;
    try {
      final media = await _mediaService.getByEntities(
        entityIds: page.map((event) => event.id).toList(),
        entityType: MediaEntityType.event,
      );
      if (!_disposed && version == _requestVersion) mediaByEvent.addAll(media);
    } catch (_) {
      // Events remain available even if their images cannot be loaded.
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _requestVersion++;
    super.dispose();
  }
}
