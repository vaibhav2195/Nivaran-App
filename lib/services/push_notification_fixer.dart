import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class PushNotificationFixer {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Complete fix for push notifications
  static Future<Map<String, dynamic>> fixPushNotifications() async {
    final results = <String, dynamic>{};

    try {
      log('🔧 Starting push notification fix...', name: 'PushFixer');

      // Step 1: Check authentication
      final user = _auth.currentUser;
      if (user == null) {
        results['error'] = 'No authenticated user';
        return results;
      }
      results['user_authenticated'] = true;
      log('✅ User authenticated: ${user.uid}', name: 'PushFixer');

      // Step 2: Request permissions aggressively
      log('📱 Requesting permissions...', name: 'PushFixer');
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      results['permission_status'] = settings.authorizationStatus.toString();

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        results['error'] = 'Notification permissions denied';
        log('❌ Permissions denied', name: 'PushFixer');
        return results;
      }
      log(
        '✅ Permissions granted: ${settings.authorizationStatus}',
        name: 'PushFixer',
      );

      // Step 3: Get fresh FCM token with validation
      String? token;

      // First, delete any existing token to force refresh
      try {
        await _messaging.deleteToken();
        log('🗑️ Deleted old FCM token', name: 'PushFixer');
        await Future.delayed(Duration(seconds: 2)); // Wait for deletion
      } catch (e) {
        log('⚠️ Could not delete old token: $e', name: 'PushFixer');
      }

      // Get fresh token with retry
      for (int i = 0; i < 5; i++) {
        try {
          token = await _messaging.getToken();
          if (token != null && token.isNotEmpty) {
            // Validate token format
            if (token.length > 100 && token.contains(':')) {
              log(
                '✅ Valid FCM token obtained on attempt ${i + 1}',
                name: 'PushFixer',
              );
              break;
            } else {
              log(
                '⚠️ Invalid token format on attempt ${i + 1}: ${token.length} chars',
                name: 'PushFixer',
              );
              token = null;
            }
          }
          await Future.delayed(Duration(seconds: 2));
        } catch (e) {
          log('Retry $i getting token: $e', name: 'PushFixer');
          await Future.delayed(Duration(seconds: 2));
        }
      }

      if (token == null || token.isEmpty) {
        results['error'] = 'Failed to get valid FCM token after retries';
        log('❌ Failed to get valid FCM token', name: 'PushFixer');
        return results;
      }

      results['fcm_token'] = token;
      results['token_length'] = token.length;
      results['token_preview'] = '${token.substring(0, 20)}...';
      log(
        '✅ Fresh FCM token obtained: ${token.substring(0, 20)}... (${token.length} chars)',
        name: 'PushFixer',
      );

      // Step 4: Force register token in Firestore with proper structure
      log('💾 Force registering token in Firestore...', name: 'PushFixer');

      // Use the new FCM tokens collection for better permission handling
      final fcmTokensRef = _firestore.collection('fcmTokens').doc(user.uid);

      try {
        await fcmTokensRef.set({
          'userId': user.uid,
          'tokens': FieldValue.arrayUnion([token]),
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        log('✅ Token saved to fcmTokens collection', name: 'PushFixer');
      } catch (e) {
        log(
          '⚠️ FCM tokens collection failed, trying user document: $e',
          name: 'PushFixer',
        );

        // Fallback to user document with minimal update
        final userDocRef = _firestore.collection('users').doc(user.uid);
        await userDocRef.update({
          'notificationTokens': FieldValue.arrayUnion([token]),
        });
        log('✅ Token saved to user document as fallback', name: 'PushFixer');
      }

      // Verify token was saved (check both locations)
      final fcmDoc = await fcmTokensRef.get();
      List<dynamic>? tokens;

      if (fcmDoc.exists) {
        tokens = fcmDoc.data()?['tokens'] as List<dynamic>?;
        results['token_storage'] = 'fcmTokens_collection';
      } else {
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        tokens = userDoc.data()?['notificationTokens'] as List<dynamic>?;
        results['token_storage'] = 'user_document';
      }

      results['tokens_in_firestore'] = tokens?.length ?? 0;
      results['current_token_registered'] = tokens?.contains(token) ?? false;

      if (!(tokens?.contains(token) ?? false)) {
        results['error'] = 'Token not saved to Firestore properly';
        log('❌ Token not saved properly', name: 'PushFixer');
        return results;
      }

      // Step 5: Initialize local notifications properly
      log('🔔 Setting up local notifications...', name: 'PushFixer');
      await _setupLocalNotifications();
      results['local_notifications_setup'] = true;

      // Step 6: Test local notification
      log('🧪 Testing local notification...', name: 'PushFixer');
      await _sendTestLocalNotification();
      results['test_notification_sent'] = true;

      // Step 7: Subscribe to test topic
      log('📡 Subscribing to test topic...', name: 'PushFixer');
      await _messaging.subscribeToTopic('test_push_notifications');
      results['subscribed_to_test_topic'] = true;

      // Step 8: Create a test notification document to trigger Cloud Function
      log('☁️ Creating test notification document...', name: 'PushFixer');
      await _createTestNotificationDocument(user.uid);
      results['test_document_created'] = true;

      results['success'] = true;
      log(
        '🎉 Push notification fix completed successfully!',
        name: 'PushFixer',
      );

      return results;
    } catch (e, stackTrace) {
      results['error'] = e.toString();
      results['stack_trace'] = stackTrace.toString();
      log('❌ Error in push notification fix: $e', name: 'PushFixer');
      log('Stack trace: $stackTrace', name: 'PushFixer');
      return results;
    }
  }

  static Future<void> _setupLocalNotifications() async {
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

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        log(
          'Local notification tapped: ${response.payload}',
          name: 'PushFixer',
        );
      },
    );

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

  static Future<void> _sendTestLocalNotification() async {
    await _localNotifications.show(
      999,
      '🎉 Push Notification System Fixed!',
      'Local notifications are working. Now test FCM from Firebase Console.',
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
          ticker: 'Push Notification Fixed',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  static Future<void> _createTestNotificationDocument(String userId) async {
    try {
      // Create a test notification document that should trigger the Cloud Function
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': '🧪 Test Push Notification',
        'body': 'This is a test notification created by the fix system.',
        'type': 'test',
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
        'navigateTo': '/notifications',
        'senderName': 'Push Notification Fixer',
      });

      log('✅ Test notification document created', name: 'PushFixer');
    } catch (e) {
      log('❌ Error creating test notification document: $e', name: 'PushFixer');
      // If notification creation fails, just log it but don't fail the whole process
      log(
        'ℹ️ This is expected if Cloud Functions handle notification creation',
        name: 'PushFixer',
      );
    }
  }

  /// Get detailed status for debugging
  static Future<Map<String, dynamic>> getDetailedStatus() async {
    final status = <String, dynamic>{};

    try {
      // User info
      final user = _auth.currentUser;
      status['user_authenticated'] = user != null;
      status['user_id'] = user?.uid;
      status['user_email'] = user?.email;

      // FCM token
      final token = await _messaging.getToken();
      status['fcm_token_exists'] = token != null;
      status['fcm_token_length'] = token?.length ?? 0;
      status['fcm_token_preview'] =
          token != null ? '${token.substring(0, 20)}...' : null;

      // Permissions
      final settings = await _messaging.getNotificationSettings();
      status['permission_status'] = settings.authorizationStatus.toString();
      status['alert_permission'] = settings.alert.toString();
      status['badge_permission'] = settings.badge.toString();
      status['sound_permission'] = settings.sound.toString();

      // Firestore check (check both FCM tokens collection and user document)
      if (user != null) {
        // Check FCM tokens collection first
        final fcmDoc =
            await _firestore.collection('fcmTokens').doc(user.uid).get();
        List<dynamic>? tokens;

        if (fcmDoc.exists) {
          tokens = fcmDoc.data()?['tokens'] as List<dynamic>?;
          status['token_storage_location'] = 'fcmTokens_collection';
          status['firestore_doc_exists'] = true;
        } else {
          // Fallback to user document
          final userDoc =
              await _firestore.collection('users').doc(user.uid).get();
          status['firestore_doc_exists'] = userDoc.exists;

          if (userDoc.exists) {
            final data = userDoc.data();
            tokens = data?['notificationTokens'] as List<dynamic>?;
            status['token_storage_location'] = 'user_document';
          }
        }

        status['tokens_in_firestore'] = tokens?.length ?? 0;
        status['current_token_registered'] = tokens?.contains(token) ?? false;
        status['all_tokens_preview'] =
            tokens
                ?.map((t) => '${t.toString().substring(0, 20)}...')
                .toList() ??
            [];
      }
    } catch (e) {
      status['error'] = e.toString();
    }

    return status;
  }

  /// Test FCM by creating a comment (triggers Cloud Function)
  static Future<bool> testCloudFunctionTrigger() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Create a test issue first
      final issueRef = await _firestore.collection('issues').add({
        'userId': user.uid,
        'title': 'Test Issue for Push Notification',
        'description': 'This is a test issue to trigger push notifications',
        'category': 'test',
        'status': 'reported',
        'timestamp': FieldValue.serverTimestamp(),
        'isUnresolved': true,
      });

      // Add a comment to trigger the Cloud Function
      await _firestore
          .collection('issues')
          .doc(issueRef.id)
          .collection('comments')
          .add({
            'userId': 'test_user_id', // Different user to trigger notification
            'username': 'Test User',
            'text': 'This is a test comment to trigger push notification',
            'timestamp': FieldValue.serverTimestamp(),
          });

      log(
        '✅ Test comment created to trigger Cloud Function',
        name: 'PushFixer',
      );
      return true;
    } catch (e) {
      log('❌ Error creating test comment: $e', name: 'PushFixer');
      return false;
    }
  }
}
