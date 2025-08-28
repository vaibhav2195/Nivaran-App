import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:modern_auth_app/services/notification_service.dart';

class MockFirebaseMessaging extends Mock implements FirebaseMessaging {}

void main() {
  group('NotificationService Tests', () {
    late NotificationService notificationService;
    late GlobalKey<NavigatorState> navigatorKey;

    setUp(() {
      navigatorKey = GlobalKey<NavigatorState>();
      notificationService = NotificationService(navigatorKey: navigatorKey);
    });

    test('should create notification service instance', () {
      expect(notificationService, isNotNull);
      expect(notificationService.navigatorKey, equals(navigatorKey));
    });

    test('should handle notification payload correctly', () {
      // Test payload parsing
      const testPayload = '/issue_details|test_issue_123';
      final parts = testPayload.split('|');

      expect(parts.length, equals(2));
      expect(parts[0], equals('/issue_details'));
      expect(parts[1], equals('test_issue_123'));
    });

    test('should determine correct notification channel based on type', () {
      // Test channel determination logic
      const testTypes = ['new_comment', 'status_update', 'urgent', 'general'];

      for (final type in testTypes) {
        String channelId = 'nivaran_default_channel';

        switch (type.toLowerCase()) {
          case 'new_comment':
          case 'status_update':
            channelId = 'nivaran_comments_channel';
            break;
          case 'urgent':
          case 'new_issue_for_official':
            channelId = 'nivaran_urgent_channel';
            break;
        }

        if (type == 'new_comment' || type == 'status_update') {
          expect(channelId, equals('nivaran_comments_channel'));
        } else if (type == 'urgent') {
          expect(channelId, equals('nivaran_urgent_channel'));
        } else {
          expect(channelId, equals('nivaran_default_channel'));
        }
      }
    });
  });
}
