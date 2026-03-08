import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:injectable/injectable.dart';
import '../../data/datasources/auth_remote_datasource.dart';

@lazySingleton
class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final AuthRemoteDataSource _authRemoteDataSource;

  NotificationService(this._authRemoteDataSource);

  Future<void> initialize() async {
    // Handling background messages is done in main.dart or here via onBackgroundMessage
    
    // Listen for token refreshes
    _fcm.onTokenRefresh.listen((newToken) {
      _authRemoteDataSource.updateFcmToken(newToken);
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // For now, we'll just let the system handle notifications if they have a notification payload.
      // Or we can show a local notification/snackbar if needed.
    });

    // Handle opening app from notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Handle deep links or navigation logic here
    });
  }

  Future<void> requestPermissions() async {
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      final token = await _fcm.getToken();
      await _authRemoteDataSource.updateFcmToken(token);
    }
  }

  Future<void> deleteToken() async {
    await _fcm.deleteToken();
    await _authRemoteDataSource.updateFcmToken(null);
  }
}
