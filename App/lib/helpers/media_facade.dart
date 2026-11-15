import '../services/media_service.dart';
import '../core/enums.dart';
import '../models/media_model.dart';
import 'media_helper.dart';

class MediaFacade {
  final MediaService service;

  MediaFacade(this.service);

  // =========================
  // BASE FETCH (privado)
  // =========================
  Future<List<MediaModel>> _fetchMedia({
    required String entityId,
    required MediaEntityType entityType,
  }) async {
    return service.getByEntity(
      entityId: entityId,
      entityType: entityType,
    );
  }

  // =========================
  // PRIMARY IMAGE
  // =========================
  Future<String?> getPrimaryImage({
    required String entityId,
    required MediaEntityType entityType,
  }) async {
    final media = await _fetchMedia(
      entityId: entityId,
      entityType: entityType,
    );

    return MediaHelper.getPrimaryUrl(media);
  }

  // =========================
  // ALL IMAGES
  // =========================
  Future<List<String>> getImages({
    required String entityId,
    required MediaEntityType entityType,
  }) async {
    final media = await _fetchMedia(
      entityId: entityId,
      entityType: entityType,
    );

    return MediaHelper.getImageUrls(media);
  }

  // =========================
  // BOTH (OPTIMIZADO)
  // =========================
  Future<({String? primary, List<String> images})> getAll({
    required String entityId,
    required MediaEntityType entityType,
  }) async {
    final media = await _fetchMedia(
      entityId: entityId,
      entityType: entityType,
    );

    return (
      primary: MediaHelper.getPrimaryUrl(media),
      images: MediaHelper.getImageUrls(media),
    );
  }
}
