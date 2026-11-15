import '../core/enums.dart';
import '../models/media_model.dart';

class MediaHelper {

  static String? getPrimaryUrl(List<MediaModel> media) {
    if (media.isEmpty) return null;

    final primary = media.firstWhere(
          (m) => m.isPrimary,
      orElse: () => media.first,
    );

    return primary.url;
  }

  static List<String> getAllUrls(List<MediaModel> media) {
    return media.map((m) => m.url).toList();
  }

  static List<MediaModel> filterImages(List<MediaModel> media) {
    return media.where((m) => m.type == MediaType.image).toList();
  }

  static List<String> getImageUrls(List<MediaModel> media) {
    final images = filterImages(media);

    images.sort((a, b) {
      final aOrder = a.displayOrder;
      final bOrder = b.displayOrder;
      return aOrder.compareTo(bOrder);
    });

    return images.map((e) => e.url).toList();
  }
}