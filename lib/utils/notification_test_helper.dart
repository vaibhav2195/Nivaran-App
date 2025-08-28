import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationTestHelper {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Test local notification display
  static Future<void> testLocalNotification() async {
    try {
      await _localNotifications.show(
        999, // Test notification ID
        'Test Notification',
        'This is a test notification to verify the system is working correctly.',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'nivaran_default_channel',
            'General Notifications',
            channelDescription: 'Test notification',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: '/notifications|test',
      );

      log(
        'Test local notification sent successfully',
        name: 'NotificationTestHelper',
      );
    } catch (e) {
      log(
        'Error sending test local notification: $e',
        name: 'NotificationTestHelper',
      );
    }
  }

  /// Get current FCM token for manual testing
  static Future<String?> getCurrentFCMToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        log('Current FCM Token: $token', name: 'NotificationTestHelper');
        log('Token length: ${token.length}', name: 'NotificationTestHelper');
        log(
          'First 20 chars: ${token.substring(0, 20)}...',
          name: 'NotificationTestHelper',
        );
      }
      return token;
    } catch (e) {
      log('Error getting FCM token: $e', name: 'NotificationTestHelper');
      return null;
    }
  }

  /// Test notification with different types
  static Future<void> testNotificationTypes() async {
    final types = [
      {
        'type': 'new_comment',
        'title': 'New Comment Test',
        'body': 'Someone commented on your issue',
      },
      {
        'type': 'status_update',
        'title': 'Status Update Test',
        'body': 'Your issue status has been updated',
      },
      {
        'type': 'urgent',
        'title': 'Urgent Test',
        'body': 'This is an urgent notification',
      },
    ];

    for (int i = 0; i < types.length; i++) {
      final type = types[i];
      await _localNotifications.show(
        1000 + i,
        type['title']!,
        type['body']!,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _getChannelId(type['type']!),
            _getChannelName(type['type']!),
            channelDescription: 'Test ${type['type']} notification',
            importance:
                type['type'] == 'urgent' ? Importance.max : Importance.high,
            priority: type['type'] == 'urgent' ? Priority.max : Priority.high,
            icon: '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            subtitle: type['type'] == 'urgent' ? 'Urgent' : null,
          ),
        ),
        payload: '/notifications|test_${type['type']}',
      );

      // Wait a bit between notifications
      await Future.delayed(const Duration(seconds: 2));
    }

    log('All test notifications sent', name: 'NotificationTestHelper');
  }

  static String _getChannelId(String type) {
    switch (type.toLowerCase()) {
      case 'new_comment':
      case 'status_update':
        return 'nivaran_comments_channel';
      case 'urgent':
        return 'nivaran_urgent_channel';
      default:
        return 'nivaran_default_channel';
    }
  }

  static String _getChannelName(String type) {
    switch (type.toLowerCase()) {
      case 'new_comment':
      case 'status_update':
        return 'Comments & Updates';
      case 'urgent':
        return 'Urgent Notifications';
      default:
        return 'General Notifications';
    }
  }

  /// Print notification permission status
  static Future<void> checkNotificationPermissions() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.getNotificationSettings();

      log(
        '=== Notification Permissions Status ===',
        name: 'NotificationTestHelper',
      );
      log(
        'Authorization Status: ${settings.authorizationStatus}',
        name: 'NotificationTestHelper',
      );
      log('Alert Setting: ${settings.alert}', name: 'NotificationTestHelper');
      log('Badge Setting: ${settings.badge}', name: 'NotificationTestHelper');
      log('Sound Setting: ${settings.sound}', name: 'NotificationTestHelper');
      log(
        '======================================',
        name: 'NotificationTestHelper',
      );
    } catch (e) {
      log(
        'Error checking notification permissions: $e',
        name: 'NotificationTestHelper',
      );
    }
  }
}
