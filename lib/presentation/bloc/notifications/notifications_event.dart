import 'package:equatable/equatable.dart';

abstract class NotificationsEvent extends Equatable {
  const NotificationsEvent();

  @override
  List<Object?> get props => [];
}

class NotificationsFetchRequested extends NotificationsEvent {
  const NotificationsFetchRequested();
}

class NotificationMarkAsReadRequested extends NotificationsEvent {
  final String id;
  const NotificationMarkAsReadRequested(this.id);

  @override
  List<Object?> get props => [id];
}

class NotificationsMarkAllAsReadRequested extends NotificationsEvent {
  const NotificationsMarkAllAsReadRequested();
}

class NotificationsUnreadCountUpdated extends NotificationsEvent {
  final int count;
  const NotificationsUnreadCountUpdated(this.count);

  @override
  List<Object?> get props => [count];
}
