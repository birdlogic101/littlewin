import '../../domain/entities/notification_entity.dart';
import '../datasources/notification_remote_datasource.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class NotificationRepository {
  final NotificationRemoteDataSource _dataSource;

  NotificationRepository(this._dataSource);

  Future<List<NotificationEntity>> getNotifications() async {
    return _dataSource.fetchNotifications();
  }

  Future<void> markAsRead(String id) async {
    await _dataSource.markAsRead(id);
  }

  Future<void> markAllAsRead() async {
    await _dataSource.markAllAsRead();
  }

  Stream<int> watchUnreadCount() {
    return _dataSource.streamUnreadCount();
  }
}
