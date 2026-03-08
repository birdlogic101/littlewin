import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/notification_entity.dart';
import '../models/notification_model.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class NotificationRemoteDataSource {
  final SupabaseClient _client;

  NotificationRemoteDataSource(this._client);

  Future<List<NotificationEntity>> fetchNotifications() async {
    final response = await _client
        .from('notifications')
        .select()
        .eq('user_id', _client.auth.currentUser!.id)
        .order('created_at', ascending: false);

    return (response as List).map((json) => NotificationModel.fromJson(json)).toList();
  }

  Future<void> markAsRead(String id) async {
    await _client
        .from('notifications')
        .update({
          'status': 'read',
          'read_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id);
  }

  Future<void> markAllAsRead() async {
    await _client
        .from('notifications')
        .update({
          'status': 'read',
          'read_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('user_id', _client.auth.currentUser!.id)
        .eq('status', 'pending');
  }

  Stream<int> streamUnreadCount() {
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', _client.auth.currentUser!.id)
        .map((rows) => rows.where((row) => row['status'] == 'pending').length);
  }
}
