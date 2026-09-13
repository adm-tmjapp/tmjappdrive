import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../features/dashboard/domain/dashboard_models.dart';

class RideAlertNotificationService {
  RideAlertNotificationService._();

  static const String channelId = 'tmj_new_rides';
  static const String channelName = 'Novas corridas';

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await _plugin.initialize(settings: initializationSettings);

    final android =
        _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        channelId,
        channelName,
        description: 'Alertas sonoros para novas corridas disponíveis.',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      ),
    );

    _initialized = true;
  }

  static Future<void> showNewRide(RideCardItem ride) async {
    await initialize();

    final id = _notificationId(ride.id);
    final details = NotificationDetails(
      android: const AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: 'Alertas sonoros para novas corridas disponíveis.',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
        category: AndroidNotificationCategory.call,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _plugin.show(
      id: id,
      title: 'Nova corrida disponível',
      body:
          ride.pickupAddress.trim().isEmpty
              ? 'Você tem uma nova corrida próxima.'
              : ride.pickupAddress,
      notificationDetails: details,
      payload: ride.id,
    );
  }

  static int _notificationId(String rideId) {
    final hash = rideId.hashCode & 0x7fffffff;
    return hash == 0 ? 1 : hash;
  }
}
