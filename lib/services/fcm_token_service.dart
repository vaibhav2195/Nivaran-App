import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FCMTokenService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Register the current device's FCM token with the user's document
  static Future<void> registerToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        log(
          'No authenticated user found for token registration',
          name: 'FCMTokenService',
        );
        return;
      }

      final token = await _messaging.getToken();
      if (token == null) {
        log('Failed to get FCM token', name: 'FCMTokenService');
        return;
      }

      log(
        'Registering FCM token: ${token.substring(0, 20)}...',
        name: 'FCMTokenService',
      );

      // Add token to user's document (using arrayUnion to avoid duplicates)
      await _firestore.collection('users').doc(user.uid).update({
        'notificationTokens': FieldValue.arrayUnion([token]),
      });

      log('FCM token registered successfully', name: 'FCMTokenService');
    } catch (e) {
      log('Error registering FCM token: $e', name: 'FCMTokenService');
    }
  }

  /// Remove the current device's FCM token from the user's document
  static Future<void> unregisterToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        log(
          'No authenticated user found for token unregistration',
          name: 'FCMTokenService',
        );
        return;
      }

      final token = await _messaging.getToken();
      if (token == null) {
        log(
          'Failed to get FCM token for unregistration',
          name: 'FCMTokenService',
        );
        return;
      }

      log(
        'Unregistering FCM token: ${token.substring(0, 20)}...',
        name: 'FCMTokenService',
      );

      // Remove token from user's document
      await _firestore.collection('users').doc(user.uid).update({
        'notificationTokens': FieldValue.arrayRemove([token]),
      });

      log('FCM token unregistered successfully', name: 'FCMTokenService');
    } catch (e) {
      log('Error unregistering FCM token: $e', name: 'FCMTokenService');
    }
  }

  /// Handle token refresh - remove old token and add new one
  static Future<void> handleTokenRefresh(String newToken) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        log(
          'No authenticated user found for token refresh',
          name: 'FCMTokenService',
        );
        return;
      }

      log(
        'Handling FCM token refresh: ${newToken.substring(0, 20)}...',
        name: 'FCMTokenService',
      );

      // Get current tokens to find and remove old ones if needed
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final currentTokens =
          userDoc.data()?['notificationTokens'] as List<dynamic>?;

      if (currentTokens != null && currentTokens.isNotEmpty) {
        // Remove all existing tokens and add the new one
        await _firestore.collection('users').doc(user.uid).update({
          'notificationTokens': [newToken],
        });
      } else {
        // Just add the new token
        await _firestore.collection('users').doc(user.uid).update({
          'notificationTokens': FieldValue.arrayUnion([newToken]),
        });
      }

      log('FCM token refresh handled successfully', name: 'FCMTokenService');
    } catch (e) {
      log('Error handling FCM token refresh: $e', name: 'FCMTokenService');
    }
  }

  /// Subscribe to notification topics based on user role and preferences
  static Future<void> subscribeToTopics(
    String userRole, {
    String? department,
  }) async {
    try {
      // Subscribe to general topics
      await _messaging.subscribeToTopic('all_users');

      // Subscribe to role-specific topics
      if (userRole == 'citizen') {
        await _messaging.subscribeToTopic('citizens');
      } else if (userRole == 'official') {
        await _messaging.subscribeToTopic('officials');
        if (department != null && department.isNotEmpty) {
          await _messaging.subscribeToTopic('dept_$department');
        }
      }

      log('Subscribed to topics for role: $userRole', name: 'FCMTokenService');
    } catch (e) {
      log('Error subscribing to topics: $e', name: 'FCMTokenService');
    }
  }

  /// Unsubscribe from notification topics
  static Future<void> unsubscribeFromTopics(
    String userRole, {
    String? department,
  }) async {
    try {
      // Unsubscribe from general topics
      await _messaging.unsubscribeFromTopic('all_users');

      // Unsubscribe from role-specific topics
      if (userRole == 'citizen') {
        await _messaging.unsubscribeFromTopic('citizens');
      } else if (userRole == 'official') {
        await _messaging.unsubscribeFromTopic('officials');
        if (department != null && department.isNotEmpty) {
          await _messaging.unsubscribeFromTopic('dept_$department');
        }
      }

      log(
        'Unsubscribed from topics for role: $userRole',
        name: 'FCMTokenService',
      );
    } catch (e) {
      log('Error unsubscribing from topics: $e', name: 'FCMTokenService');
    }
  }

  /// Initialize FCM token handling - call this when user logs in
  static Future<void> initialize() async {
    try {
      // Register current token
      await registerToken();

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        log('FCM token refreshed', name: 'FCMTokenService');
        handleTokenRefresh(newToken);
      });

      log('FCM token service initialized', name: 'FCMTokenService');
    } catch (e) {
      log('Error initializing FCM token service: $e', name: 'FCMTokenService');
    }
  }
}
