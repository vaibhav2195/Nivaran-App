import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationDebugService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Comprehensive debug check for push notifications
  static Future<Map<String, dynamic>> debugPushNotifications() async {
    final results = <String, dynamic>{};

    try {
      // 1. Check if user is authenticated
      final user = _auth.currentUser;
      results['user_authenticated'] = user != null;
      results['user_id'] = user?.uid ?? 'null';

      // 2. Check FCM token
      final token = await _messaging.getToken();
      results['fcm_token_exists'] = token != null;
      results['fcm_token_length'] = token?.length ?? 0;
      results['fcm_token_preview'] =
          token != null ? '${token.substring(0, 20)}...' : 'null';

      // 3. Check notification permissions
      final settings = await _messaging.getNotificationSettings();
      results['notification_permission'] =
          settings.authorizationStatus.toString();
      results['alert_permission'] = settings.alert.toString();
      results['badge_permission'] = settings.badge.toString();
      results['sound_permission'] = settings.sound.toString();

      // 4. Check if token is registered in Firestore
      if (user != null && token != null) {
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final userData = userDoc.data();
          final tokens = userData?['notificationTokens'] as List<dynamic>?;
          results['firestore_doc_exists'] = true;
          results['tokens_in_firestore'] = tokens?.length ?? 0;
          results['current_token_registered'] =
              tokens?.contains(token) ?? false;
          results['all_tokens'] =
              tokens
                  ?.map((t) => '${t.toString().substring(0, 20)}...')
                  .toList() ??
              [];
        } else {
          results['firestore_doc_exists'] = false;
        }
      }

      // 5. Test topic subscriptions
      try {
        await _messaging.subscribeToTopic('test_topic');
        results['topic_subscription_works'] = true;
        await _messaging.unsubscribeFromTopic('test_topic');
      } catch (e) {
        results['topic_subscription_works'] = false;
        results['topic_subscription_error'] = e.toString();
      }

      log('=== PUSH NOTIFICATION DEBUG RESULTS ===', name: 'NotificationDebug');
      results.forEach((key, value) {
        log('$key: $value', name: 'NotificationDebug');
      });
      log('=======================================', name: 'NotificationDebug');
    } catch (e) {
      results['error'] = e.toString();
      log('Error in debug check: $e', name: 'NotificationDebug');
    }

    return results;
  }

  /// Force register FCM token
  static Future<bool> forceRegisterToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        log(
          'No authenticated user for token registration',
          name: 'NotificationDebug',
        );
        return false;
      }

      final token = await _messaging.getToken();
      if (token == null) {
        log('Failed to get FCM token', name: 'NotificationDebug');
        return false;
      }

      log(
        'Force registering token: ${token.substring(0, 20)}...',
        name: 'NotificationDebug',
      );

      // Force update the token in Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'notificationTokens': FieldValue.arrayUnion([token]),
      }, SetOptions(merge: true));

      log('Token force registered successfully', name: 'NotificationDebug');
      return true;
    } catch (e) {
      log('Error force registering token: $e', name: 'NotificationDebug');
      return false;
    }
  }

  /// Test sending a notification via Cloud Function
  static Future<bool> testCloudFunctionNotification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Create a test notification document that should trigger our Cloud Function
      await _firestore.collection('test_notifications').add({
        'userId': user.uid,
        'title': 'Test Notification',
        'body': 'This is a test notification from debug service',
        'type': 'test',
        'timestamp': FieldValue.serverTimestamp(),
      });

      log('Test notification document created', name: 'NotificationDebug');
      return true;
    } catch (e) {
      log('Error creating test notification: $e', name: 'NotificationDebug');
      return false;
    }
  }

  /// Check if background message handler is working
  static Future<void> testBackgroundHandler() async {
    try {
      // This will test if the background handler is properly registered
      final initialMessage = await _messaging.getInitialMessage();
      log(
        'Initial message: ${initialMessage?.messageId ?? 'null'}',
        name: 'NotificationDebug',
      );

      // Check if we can get the current registration token
      final token = await _messaging.getToken();
      log(
        'Current registration token available: ${token != null}',
        name: 'NotificationDebug',
      );
    } catch (e) {
      log('Error testing background handler: $e', name: 'NotificationDebug');
    }
  }

  /// Request permissions explicitly
  static Future<bool> requestPermissionsExplicitly() async {
    try {
      log('Requesting notification permissions...', name: 'NotificationDebug');

      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      log(
        'Permission result: ${settings.authorizationStatus}',
        name: 'NotificationDebug',
      );

      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      log('Error requesting permissions: $e', name: 'NotificationDebug');
      return false;
    }
  }
}
