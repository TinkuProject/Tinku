import '../models/review_model.dart';
import '../helpers/media_helper.dart';

extension ReviewExtension on ReviewModel {
  String? get imageUrl =>
      MediaHelper.getPrimaryUrl(media ?? []);
}