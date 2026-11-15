class NotificationModel {
  final int id;
  final String userId;
  final String? senderId;
  final String? title;
  final String message;
  final String? type;
  final String? entityType;
  final int? entityId;
  final String? route;
  final bool read;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    this.senderId,
    this.title,
    required this.message,
    this.type,
    this.entityType,
    this.entityId,
    this.route,
    required this.read,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      userId: json['user_id'],
      senderId: json['sender_id'],
      title: json['title'],
      message: json['message'],
      type: json['type']?.toString(),
      entityType: json['entity_type']?.toString(),
      entityId: json['entity_id'] is num
          ? (json['entity_id'] as num).toInt()
          : int.tryParse(json['entity_id']?.toString() ?? ''),
      route: json['route']?.toString(),
      read: json['read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'sender_id': senderId,
      'title': title,
      'message': message,
      'type': type,
      'entity_type': entityType,
      'entity_id': entityId,
      'route': route,
      'read': read,
    };
  }

  NotificationModel copyWith({
    int? id,
    String? userId,
    String? senderId,
    String? title,
    String? message,
    String? type,
    String? entityType,
    int? entityId,
    String? route,
    bool? read,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      senderId: senderId ?? this.senderId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      route: route ?? this.route,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
