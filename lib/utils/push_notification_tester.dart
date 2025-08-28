import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class PushNotificationTester {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Complete setup and test of push notifications
  static Future<bool> setupAndTestPushNotifications() async {
    try {
      log('🚀 Starting push notification setup...', name: 'PushTester');

      // Step 1: Request permissions
      log('📱 Requesting permissions...', name: 'PushTester');
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        log('❌ Permissions denied', name: 'PushTester');
        return false;
      }
      log('✅ Permissions granted', name: 'PushTester');

      // Step 2: Get FCM token
      log('🔑 Getting FCM token...', name: 'PushTester');
      final token = await _messaging.getToken();
      if (token == null) {
        log('❌ Failed to get FCM token', name: 'PushTester');
        return false;
      }
      log(
        '✅ FCM token obtained: ${token.substring(0, 20)}...',
        name: 'PushTester',
      );

      // Step 3: Register token in Firestore
      final user = _auth.currentUser;
      if (user == null) {
        log('❌ No authenticated user', name: 'PushTester');
        return false;
      }

      log('💾 Registering token in Firestore...', name: 'PushTester');
      await _firestore.collection('users').doc(user.uid).set({
        'notificationTokens': FieldValue.arrayUnion([token]),
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      log('✅ Token registered in Firestore', name: 'PushTester');

      // Step 4: Initialize local notifications
      log('🔔 Initializing local notifications...', name: 'PushTester');
      await _initializeLocalNotifications();
      log('✅ Local notifications initialized', name: 'PushTester');

      // Step 5: Test local notification
      log('🧪 Testing local notification...', name: 'PushTester');
      await _testLocalNotification();
      log('✅ Local notification sent', name: 'PushTester');

      // Step 6: Subscribe to test topic
      log('📡 Subscribing to test topic...', name: 'PushTester');
      await _messaging.subscribeToTopic('test_notifications');
      log('✅ Subscribed to test topic', name: 'PushTester');

      log(
        '🎉 Push notification setup completed successfully!',
        name: 'PushTester',
      );
      return true;
    } catch (e) {
      log('❌ Error in push notification setup: $e', name: 'PushTester');
      return false;
    }
  }

  static Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(initSettings);

    // Create notification channels
    final androidPlugin =
        _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'nivaran_default_channel',
          'General Notifications',
          description: 'General app notifications',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
      );

      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'nivaran_comments_channel',
          'Comments & Updates',
          description: 'New comments and status updates',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
      );

      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'nivaran_urgent_channel',
          'Urgent Notifications',
          description: 'Urgent notifications',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
      );
    }
  }

  static Future<void> _testLocalNotification() async {
    await _localNotifications.show(
      999,
      '🧪 Push Notification Test',
      'If you see this, local notifications are working! Now test FCM from Firebase Console.',
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
          ticker: 'Push Notification Test',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  /// Get current status for debugging
  static Future<Map<String, dynamic>> getStatus() async {
    final status = <String, dynamic>{};

    try {
      // Check user
      final user = _auth.currentUser;
      status['user_authenticated'] = user != null;
      status['user_id'] = user?.uid;

      // Check token
      final token = await _messaging.getToken();
      status['fcm_token_exists'] = token != null;
      status['fcm_token'] = token;

      // Check permissions
      final settings = await _messaging.getNotificationSettings();
      status['permissions'] = settings.authorizationStatus.toString();

      // Check Firestore registration
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data();
          final tokens = data?['notificationTokens'] as List<dynamic>?;
          status['tokens_in_firestore'] = tokens?.length ?? 0;
          status['current_token_registered'] = tokens?.contains(token) ?? false;
        }
      }
    } catch (e) {
      status['error'] = e.toString();
    }

    return status;
  }

  /// Send a test message to Firebase Console format
  static String getFirebaseConsoleTestMessage(String fcmToken) {
    return '''
🔥 Firebase Console Test Message:

1. Go to Firebase Console > Cloud Messaging
2. Click "Send your first message"
3. Enter:
   - Title: Test Push Notification
   - Text: This is a test from Firebase Console

4. Click "Send test message"
5. Paste this token: $fcmToken

6. Add these custom data fields:
   - type: new_comment
   - issueId: test123
   - navigateTo: /notifications

7. Click "Test" button

If you don't receive the notification:
- Check device notification settings
- Ensure app is not in battery optimization
- Try with app in background/foreground/closed states
''';
  }
}
