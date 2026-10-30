import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String channelId = 'sync_service';
  static const String channelName = 'Payment Auto-Approver Service';

  Future<void> init() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await flutterLocalNotificationsPlugin.initialize(initSettings);

    final androidImplementation = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidImplementation?.createNotificationChannel(
      const AndroidNotificationChannel(
        channelId,
        channelName,
        description: 'Payment Auto-Approver Background Service Notifications',
        importance: Importance.low,
      ),
    );
  }

  Future<void> showSessionExpiredNotification() async {
    const androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    await flutterLocalNotificationsPlugin.show(
      888,
      'Session Expired',
      'Admin session expired. Please log in again to resume payment approvals.',
      details,
    );
  }
}
