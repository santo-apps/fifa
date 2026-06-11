import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_10y.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    try {
      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          // Handle notification tap if needed
        },
      );

      // Create Android Channel if on Android
      if (Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            _notificationsPlugin.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        if (androidImplementation != null) {
          await androidImplementation.createNotificationChannel(
            const AndroidNotificationChannel(
              'fifa_2026_matches',
              'Match Reminders',
              description: 'Notifications for upcoming and live FIFA matches',
              importance: Importance.max,
              playSound: true,
              enableVibration: true,
            ),
          );
        }
      }
    } catch (e) {
      // Gracefully handle error in environment
      print("Notification init failed: $e");
    }
  }

  static Future<void> requestPermissions() async {
    try {
      if (Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            _notificationsPlugin.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        if (androidImplementation != null) {
          await androidImplementation.requestNotificationsPermission();
        }
      } else if (Platform.isIOS) {
        final IOSFlutterLocalNotificationsPlugin? iosImplementation =
            _notificationsPlugin.resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();
        if (iosImplementation != null) {
          await iosImplementation.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
        }
      }
    } catch (e) {
      print("Request permissions error: $e");
    }
  }

  static Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'fifa_2026_matches',
      'Match Reminders',
      channelDescription: 'Notifications for upcoming and live FIFA matches',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    try {
      await _notificationsPlugin.show(id, title, body, details);
    } catch (e) {
      print("Show notification error: $e");
    }
  }

  static Future<void> scheduleMatchReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'fifa_2026_matches',
      'Match Reminders',
      channelDescription: 'Notifications for upcoming and live FIFA matches',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    // Schedule 15 minutes before the match kickoff
    final reminderTime = scheduledTime.subtract(const Duration(minutes: 15));
    if (reminderTime.isBefore(DateTime.now())) {
      // If the reminder time is in the past, don't schedule it
      return;
    }

    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(reminderTime, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      print("Schedule notification error: $e");
    }
  }

  static Future<void> cancelNotification(int id) async {
    try {
      await _notificationsPlugin.cancel(id);
    } catch (e) {
      print("Cancel notification error: $e");
    }
  }

  static Future<void> cancelAllNotifications() async {
    try {
      await _notificationsPlugin.cancelAll();
    } catch (e) {
      print("Cancel all notifications error: $e");
    }
  }
}
