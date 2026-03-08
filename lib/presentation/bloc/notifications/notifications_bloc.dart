import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../data/repositories/notification_repository.dart';
import 'notifications_event.dart';
import 'notifications_state.dart';
import '../../../domain/entities/notification_entity.dart';

@injectable
class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final NotificationRepository _repository;
  StreamSubscription<int>? _unreadCountSubscription;

  NotificationsBloc(this._repository) : super(const NotificationsInitial()) {
    on<NotificationsFetchRequested>(_onFetchRequested);
    on<NotificationMarkAsReadRequested>(_onMarkAsReadRequested);
    on<NotificationsMarkAllAsReadRequested>(_onMarkAllAsReadRequested);
    on<NotificationsUnreadCountUpdated>(_onUnreadCountUpdated);

    _unreadCountSubscription = _repository.watchUnreadCount().listen(
      (count) => add(NotificationsUnreadCountUpdated(count)),
    );
  }

  Future<void> _onFetchRequested(
    NotificationsFetchRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(const NotificationsLoading());
    try {
      final notifications = await _repository.getNotifications();
      final unreadCount = notifications.where((n) => n.status == NotificationStatus.pending).length;
      emit(NotificationsLoaded(
        notifications: notifications,
        unreadCount: unreadCount,
      ));
    } catch (e) {
      emit(NotificationsError(e.toString()));
    }
  }

  Future<void> _onMarkAsReadRequested(
    NotificationMarkAsReadRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      await _repository.markAsRead(event.id);
      if (state is NotificationsLoaded) {
        final current = state as NotificationsLoaded;
        final updated = current.notifications.map((n) {
          if (n.id == event.id) {
            return NotificationEntity(
              id: n.id,
              userId: n.userId,
              message: n.message,
              type: n.type,
              deepLink: n.deepLink,
              createdAt: n.createdAt,
              status: NotificationStatus.read,
              readAt: DateTime.now(),
            );
          }
          return n;
        }).toList();
        emit(NotificationsLoaded(
          notifications: updated,
          unreadCount: updated.where((n) => n.status == NotificationStatus.pending).length,
        ));
      }
    } catch (e) {
      // Non-fatal
    }
  }

  Future<void> _onMarkAllAsReadRequested(
    NotificationsMarkAllAsReadRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      await _repository.markAllAsRead();
      if (state is NotificationsLoaded) {
        final current = state as NotificationsLoaded;
        final updated = current.notifications.map((n) {
          return NotificationEntity(
            id: n.id,
            userId: n.userId,
            message: n.message,
            type: n.type,
            deepLink: n.deepLink,
            createdAt: n.createdAt,
            status: NotificationStatus.read,
            readAt: n.readAt ?? DateTime.now(),
          );
        }).toList();
        emit(NotificationsLoaded(
          notifications: updated,
          unreadCount: 0,
        ));
      }
    } catch (e) {
      // Non-fatal
    }
  }

  void _onUnreadCountUpdated(
    NotificationsUnreadCountUpdated event,
    Emitter<NotificationsState> emit,
  ) {
    if (state is NotificationsLoaded) {
      final current = state as NotificationsLoaded;
      emit(NotificationsLoaded(
        notifications: current.notifications,
        unreadCount: event.count,
      ));
    } else if (state is NotificationsInitial) {
       // If we haven't fetched yet, we just stay initial but maybe we should trigger a fetch?
       // For now, let's just trigger a fetch if we see unread counts coming in
       add(const NotificationsFetchRequested());
    }
  }

  @override
  Future<void> close() {
    _unreadCountSubscription?.cancel();
    return super.close();
  }
}
