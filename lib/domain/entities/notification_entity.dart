import 'package:equatable/equatable.dart';

enum NotificationType {
  betWon,
  betLost,
  betReceived,
  checkinReminder,
  newFollower,
}

enum NotificationStatus {
  pending,
  read,
}

class NotificationEntity extends Equatable {
  final String id;
  final String userId;
  final String message;
  final NotificationType type;
  final String? deepLink;
  final DateTime createdAt;
  final DateTime? readAt;
  final NotificationStatus status;

  const NotificationEntity({
    required this.id,
    required this.userId,
    required this.message,
    required this.type,
    this.deepLink,
    required this.createdAt,
    this.readAt,
    required this.status,
  });

  @override
  List<Object?> get props => [id, userId, message, type, deepLink, createdAt, readAt, status];
}
