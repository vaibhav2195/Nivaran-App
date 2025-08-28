import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationTestService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Simple test that only creates notifications (no issues)
  static Future<Map<String, dynamic>> testNotificationsOnly() async {
    final results = <String, dynamic>{};

    try {
      final user = _auth.currentUser;
      if (user == null) {
        results['error'] = 'No authenticated user';
        return results;
      }

      log('🧪 Starting simple notification test...', name: 'NotificationTest');

      // Create a simple test notification
      await _firestore.collection('notifications').add({
        'userId': user.uid,
        'title': '🧪 Simple Test Notification',
        'body': 'This is a simple test notification to verify the system works',
        'type': 'test',
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
        'navigateTo': '/notifications',
        'senderName': 'Notification Test Service',
      });

      results['simple_notification_created'] = true;
      results['success'] = true;
      results['message'] =
          'In-app notification created successfully! ⚠️ This does NOT send push notifications. For real push notifications, use the full test or create an issue and have someone comment on it.';
      log(
        '✅ Simple notification created successfully',
        name: 'NotificationTest',
      );

      return results;
    } catch (e, stackTrace) {
      results['error'] = e.toString();
      results['stack_trace'] = stackTrace.toString();
      log('❌ Error in simple notification test: $e', name: 'NotificationTest');
      return results;
    }
  }

  /// Diagnose FCM token storage issues
  static Future<Map<String, dynamic>> diagnoseFCMTokens() async {
    final results = <String, dynamic>{};

    try {
      final user = _auth.currentUser;
      if (user == null) {
        results['error'] = 'No authenticated user';
        return results;
      }

      log('🔍 Diagnosing FCM token storage...', name: 'NotificationTest');

      // Get current FCM token
      final token = await _messaging.getToken();
      results['current_fcm_token'] = token != null;
      results['token_preview'] =
          token != null ? '${token.substring(0, 20)}...' : 'null';

      // Check FCM tokens collection
      final fcmTokensDoc =
          await _firestore.collection('fcmTokens').doc(user.uid).get();
      results['fcm_tokens_collection_exists'] = fcmTokensDoc.exists;

      if (fcmTokensDoc.exists) {
        final data = fcmTokensDoc.data();
        final tokens = data?['tokens'] as List<dynamic>?;
        results['tokens_in_fcm_collection'] = tokens?.length ?? 0;
        results['current_token_in_fcm_collection'] =
            tokens?.contains(token) ?? false;
      }

      // Check user document
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      results['user_document_exists'] = userDoc.exists;

      if (userDoc.exists) {
        final data = userDoc.data();
        final tokens = data?['notificationTokens'] as List<dynamic>?;
        results['tokens_in_user_document'] = tokens?.length ?? 0;
        results['current_token_in_user_document'] =
            tokens?.contains(token) ?? false;
      }

      // Force register token if missing
      if (token != null) {
        if (!fcmTokensDoc.exists ||
            !(fcmTokensDoc.data()?['tokens'] as List<dynamic>?)!.contains(
                  token,
                ) ==
                true) {
          log('🔧 Force registering FCM token...', name: 'NotificationTest');

          await _firestore.collection('fcmTokens').doc(user.uid).set({
            'userId': user.uid,
            'tokens': FieldValue.arrayUnion([token]),
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          results['token_force_registered'] = true;
        }
      }

      results['success'] = true;
      results['message'] =
          'FCM token diagnosis completed. Check results for issues.';

      return results;
    } catch (e, stackTrace) {
      results['error'] = e.toString();
      results['stack_trace'] = stackTrace.toString();
      log('❌ Error in FCM token diagnosis: $e', name: 'NotificationTest');
      return results;
    }
  }

  /// Test push notifications by creating a test issue and comment
  static Future<Map<String, dynamic>> testPushNotifications() async {
    final results = <String, dynamic>{};

    try {
      final user = _auth.currentUser;
      if (user == null) {
        results['error'] = 'No authenticated user';
        return results;
      }

      log('🧪 Starting push notification test...', name: 'NotificationTest');

      // Step 1: Create a test issue
      final issueRef = await _firestore.collection('issues').add({
        'userId': user.uid,
        'username': user.displayName ?? 'Test User',
        'description': 'Test issue for push notification verification',
        'category': 'test',
        'imageUrl': 'https://via.placeholder.com/300x200.png?text=Test+Issue',
        'timestamp': FieldValue.serverTimestamp(),
        'location': {
          'latitude': 0.0,
          'longitude': 0.0,
          'address': 'Test Location',
        },
        'status': 'Reported',
        'assignedDepartment': 'test',
        'upvotes': 0,
        'downvotes': 0,
        'voters': <String, dynamic>{},
        'commentsCount': 0,
        'isUnresolved': true,
        'affectedUserIds': <String>[],
        'affectedUsersCount': 0,
      });

      results['test_issue_created'] = true;
      results['test_issue_id'] = issueRef.id;
      log('✅ Test issue created: ${issueRef.id}', name: 'NotificationTest');

      // Wait a moment for the issue to be fully created
      await Future.delayed(Duration(seconds: 2));

      // Step 2: Create a test comment from a different user perspective
      // This should trigger the push notification
      await _firestore
          .collection('issues')
          .doc(issueRef.id)
          .collection('comments')
          .add({
            'userId': 'test_commenter_id',
            'username': 'Test Commenter',
            'text': 'This is a test comment to trigger push notification',
            'timestamp': FieldValue.serverTimestamp(),
          });

      results['test_comment_created'] = true;
      log('✅ Test comment created', name: 'NotificationTest');

      // Step 3: Update the issue status to trigger status update notification
      await Future.delayed(Duration(seconds: 2));

      await _firestore.collection('issues').doc(issueRef.id).update({
        'status': 'In Progress',
        'lastStatusUpdateBy': 'Test Official',
        'lastStatusUpdateAt': FieldValue.serverTimestamp(),
      });

      results['status_update_triggered'] = true;
      log('✅ Status update triggered', name: 'NotificationTest');

      // Step 4: Create a direct notification document
      await _firestore.collection('notifications').add({
        'userId': user.uid,
        'title': '🧪 Direct Test Notification',
        'body': 'This notification was created directly for testing',
        'type': 'test',
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
        'navigateTo': '/notifications',
        'senderName': 'Notification Test Service',
      });

      results['direct_notification_created'] = true;
      log('✅ Direct notification created', name: 'NotificationTest');

      results['success'] = true;
      results['message'] =
          'Test notifications triggered successfully. Check your device for push notifications.';

      return results;
    } catch (e, stackTrace) {
      results['error'] = e.toString();
      results['stack_trace'] = stackTrace.toString();
      log('❌ Error in notification test: $e', name: 'NotificationTest');
      return results;
    }
  }

  /// Clean up test data
  static Future<void> cleanupTestData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Delete test issues
      final testIssues =
          await _firestore
              .collection('issues')
              .where('userId', isEqualTo: user.uid)
              .where('category', isEqualTo: 'test')
              .get();

      for (final doc in testIssues.docs) {
        // Delete comments first
        final comments = await doc.reference.collection('comments').get();
        for (final comment in comments.docs) {
          await comment.reference.delete();
        }

        // Delete the issue
        await doc.reference.delete();
      }

      // Delete test notifications
      final testNotifications =
          await _firestore
              .collection('notifications')
              .where('userId', isEqualTo: user.uid)
              .where('type', isEqualTo: 'test')
              .get();

      for (final doc in testNotifications.docs) {
        await doc.reference.delete();
      }

      log('✅ Test data cleaned up', name: 'NotificationTest');
    } catch (e) {
      log('❌ Error cleaning up test data: $e', name: 'NotificationTest');
    }
  }

  /// Test push notifications by manually sending FCM message
  static Future<Map<String, dynamic>> testDirectPushNotification() async {
    final results = <String, dynamic>{};

    try {
      final user = _auth.currentUser;
      if (user == null) {
        results['error'] = 'No authenticated user';
        return results;
      }

      log(
        '🎯 Starting direct push notification test...',
        name: 'NotificationTest',
      );

      // Get the FCM token
      final token = await _messaging.getToken();
      if (token == null) {
        results['error'] = 'No FCM token available';
        return results;
      }

      results['fcm_token_available'] = true;
      results['token_preview'] = '${token.substring(0, 20)}...';

      // Create a notification document that should trigger Cloud Function
      // But first, let's create a simple test that doesn't rely on Cloud Functions

      // Subscribe to a test topic
      await _messaging.subscribeToTopic('test_push_notifications');
      results['subscribed_to_topic'] = true;

      // Create notification document
      await _firestore.collection('notifications').add({
        'userId': user.uid,
        'title': '🎯 Direct Push Test',
        'body': 'Testing direct push notification delivery',
        'type': 'test',
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
        'navigateTo': '/notifications',
        'senderName': 'Direct Push Test',
      });

      results['notification_document_created'] = true;
      results['success'] = true;
      results['message'] =
          'Direct push test setup complete! Now send a test message from Firebase Console to your FCM token or to topic "test_push_notifications"';
      results['instructions'] =
          'Go to Firebase Console > Cloud Messaging > Send test message. Use the token above or send to topic "test_push_notifications"';

      return results;
    } catch (e, stackTrace) {
      results['error'] = e.toString();
      results['stack_trace'] = stackTrace.toString();
      log('❌ Error in direct push test: $e', name: 'NotificationTest');
      return results;
    }
  }

  /// Send a test FCM message using topic
  static Future<Map<String, dynamic>> testTopicNotification() async {
    final results = <String, dynamic>{};

    try {
      final user = _auth.currentUser;
      if (user == null) {
        results['error'] = 'No authenticated user';
        return results;
      }

      // Subscribe to test topic
      await _messaging.subscribeToTopic('test_notifications');
      results['subscribed_to_topic'] = true;

      log('✅ Subscribed to test topic', name: 'NotificationTest');

      // Note: Actual topic message sending would need to be done from backend
      // This is just for client-side testing
      results['message'] =
          'Subscribed to test topic. Send a test message from Firebase Console to topic "test_notifications"';
      results['success'] = true;

      return results;
    } catch (e) {
      results['error'] = e.toString();
      log('❌ Error in topic test: $e', name: 'NotificationTest');
      return results;
    }
  }
}
