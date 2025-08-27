import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final GlobalKey<NavigatorState> navigatorKey;

  NotificationService({required this.navigatorKey});

  Future<void> initialize() async {
    // Create notification channels for different types
    await _createNotificationChannels();

    // Initialize local notifications with tap handling
    await _initializeLocalNotifications();

    // Request permissions
    await requestPermissions();

    // Get and log FCM token
    final fcmToken = await _firebaseMessaging.getToken();
    log('FCM Token: $fcmToken', name: 'NotificationService');

    // Handle app launch from terminated state
    RemoteMessage? initialMessage =
        await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      log(
        'App launched from notification: ${initialMessage.messageId}',
        name: 'NotificationService',
      );
      _handleMessage(initialMessage);
    }

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log(
        'Notification tapped (background): ${message.messageId}',
        name: 'NotificationService',
      );
      _handleMessage(message);
    });

    // Handle foreground messages - show local notification
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log(
        'Foreground message received: ${message.messageId}',
        name: 'NotificationService',
      );
      _showLocalNotification(message);
    });
  }

  Future<void> _createNotificationChannels() async {
    final androidImplementation =
        _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidImplementation != null) {
      // Default channel for general notifications
      const defaultChannel = AndroidNotificationChannel(
        'nivaran_default_channel',
        'General Notifications',
        description: 'General app notifications',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      // High priority channel for urgent notifications
      const urgentChannel = AndroidNotificationChannel(
        'nivaran_urgent_channel',
        'Urgent Notifications',
        description: 'Urgent notifications requiring immediate attention',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
      );

      // Comments channel
      const commentsChannel = AndroidNotificationChannel(
        'nivaran_comments_channel',
        'Comments & Updates',
        description: 'New comments and status updates on your issues',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      await androidImplementation.createNotificationChannel(defaultChannel);
      await androidImplementation.createNotificationChannel(urgentChannel);
      await androidImplementation.createNotificationChannel(commentsChannel);
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    log(
      'Local notification tapped: ${response.payload}',
      name: 'NotificationService',
    );

    if (response.payload != null) {
      final parts = response.payload!.split('|');
      if (parts.length >= 2) {
        final navigateTo = parts[0];
        final issueId = parts.length > 1 ? parts[1] : null;
        _navigateToScreen(navigateTo, issueId);
      }
    }
  }

  void _handleMessage(RemoteMessage message) {
    log('Handling message: ${message.messageId}', name: 'NotificationService');
    log('Message data: ${message.data}', name: 'NotificationService');

    final navigateTo = message.data['navigateTo'] ?? '/notifications';
    final issueId = message.data['issueId'];

    _navigateToScreen(navigateTo, issueId);
  }

  void _navigateToScreen(String navigateTo, String? issueId) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      log('Navigator not available', name: 'NotificationService');
      return;
    }

    log(
      'Navigating to: $navigateTo with issueId: $issueId',
      name: 'NotificationService',
    );

    switch (navigateTo) {
      case '/issue_details':
        if (issueId != null && issueId.isNotEmpty) {
          navigator.pushNamed('/issue_details', arguments: issueId);
        } else {
          navigator.pushNamed('/notifications');
        }
        break;
      case '/app':
        navigator.pushNamedAndRemoveUntil('/app', (route) => false);
        break;
      case '/notifications':
        navigator.pushNamed('/notifications');
        break;
      default:
        navigator.pushNamed(navigateTo);
        break;
    }
  }

  void _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final notificationType = message.data['type'] ?? 'general';
    final issueId = message.data['issueId'];
    final navigateTo = message.data['navigateTo'] ?? '/notifications';

    // Create payload for navigation
    final payload = '$navigateTo|${issueId ?? ''}';

    // Determine notification channel and icon based on type
    String channelId = 'nivaran_default_channel';
    String channelName = 'General Notifications';
    IconData iconData = Icons.notifications;

    switch (notificationType.toLowerCase()) {
      case 'status_update':
        channelId = 'nivaran_comments_channel';
        channelName = 'Comments & Updates';
        iconData = Icons.flag_circle;
        break;
      case 'new_comment':
        channelId = 'nivaran_comments_channel';
        channelName = 'Comments & Updates';
        iconData = Icons.chat_bubble;
        break;
      case 'urgent':
      case 'new_issue_for_official':
        channelId = 'nivaran_urgent_channel';
        channelName = 'Urgent Notifications';
        iconData = Icons.priority_high;
        break;
      case 'admin_message':
        channelId = 'nivaran_default_channel';
        channelName = 'General Notifications';
        iconData = Icons.admin_panel_settings;
        break;
    }

    await _flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: 'Nivaran app notifications',
          importance:
              channelId == 'nivaran_urgent_channel'
                  ? Importance.max
                  : Importance.high,
          priority:
              channelId == 'nivaran_urgent_channel'
                  ? Priority.max
                  : Priority.high,
          icon: '@mipmap/ic_launcher',
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          styleInformation: BigTextStyleInformation(
            notification.body ?? '',
            contentTitle: notification.title,
            summaryText: 'Nivaran',
          ),
          playSound: true,
          enableVibration: true,
          enableLights: true,
          ledColor: const Color(0xFF00BCD4),
          ledOnMs: 1000,
          ledOffMs: 500,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'default',
          subtitle: _getSubtitleForType(notificationType),
          threadIdentifier: notificationType,
        ),
      ),
      payload: payload,
    );

    log(
      'Local notification shown: ${notification.title}',
      name: 'NotificationService',
    );
  }

  String _getSubtitleForType(String type) {
    switch (type.toLowerCase()) {
      case 'status_update':
        return 'Issue Update';
      case 'new_comment':
        return 'New Comment';
      case 'admin_message':
        return 'Admin Message';
      case 'new_issue_for_official':
        return 'New Issue';
      default:
        return 'Nivaran';
    }
  }

  Future<void> requestPermissions() async {
    // Request FCM permissions
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    log(
      'FCM Permission Status: ${settings.authorizationStatus}',
      name: 'NotificationService',
    );

    // Request local notification permissions for Android 13+
    final androidImplementation =
        _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidImplementation != null) {
      final granted =
          await androidImplementation.requestNotificationsPermission();
      log(
        'Local Notification Permission: $granted',
        name: 'NotificationService',
      );
    }
  }

  // Method to get current FCM token
  Future<String?> getFCMToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      log('Error getting FCM token: $e', name: 'NotificationService');
      return null;
    }
  }

  // Method to subscribe to topic (for future use)
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      log('Subscribed to topic: $topic', name: 'NotificationService');
    } catch (e) {
      log('Error subscribing to topic $topic: $e', name: 'NotificationService');
    }
  }

  // Method to unsubscribe from topic (for future use)
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      log('Unsubscribed from topic: $topic', name: 'NotificationService');
    } catch (e) {
      log(
        'Error unsubscribing from topic $topic: $e',
        name: 'NotificationService',
      );
    }
  }
}
