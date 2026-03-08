import '../../domain/entities/notification_entity.dart';

class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.id,
    required super.userId,
    required super.message,
    required super.type,
    super.deepLink,
    required super.createdAt,
    super.readAt,
    required super.status,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      message: json['message'] as String,
      type: _parseType(json['type'] as String),
      deepLink: json['deep_link'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at'] as String) : null,
      status: _parseStatus(json['status'] as String),
    );
  }

  static NotificationType _parseType(String type) {
    return switch (type) {
      'bet_won' => NotificationType.betWon,
      'bet_lost' => NotificationType.betLost,
      'bet_received' => NotificationType.betReceived,
      'checkin_reminder' => NotificationType.checkinReminder,
      'new_follower' => NotificationType.newFollower,
      _ => NotificationType.checkinReminder,
    };
  }

  static NotificationStatus _parseStatus(String status) {
    return switch (status) {
      'read' => NotificationStatus.read,
      _ => NotificationStatus.pending,
    };
  }
}
