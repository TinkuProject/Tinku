import '../core/enums.dart';

abstract class MediaTarget {
  MediaEntityType get type;
  dynamic get id;
}

class UserMediaTarget implements MediaTarget {
  final String userId;

  UserMediaTarget(this.userId);

  @override
  MediaEntityType get type => MediaEntityType.user;

  @override
  String get id => userId;
}

class EntityMediaTarget implements MediaTarget {
  final int entityId;
  final MediaEntityType entityType;

  EntityMediaTarget({
    required this.entityId,
    required this.entityType,
  }) {
    if (entityType == MediaEntityType.user) {
      throw Exception('User debe usar UserMediaTarget');
    }
  }

  @override
  MediaEntityType get type => entityType;

  @override
  int get id => entityId;
}