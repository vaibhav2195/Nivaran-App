import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:modern_auth_app/services/notification_service.dart';

class MockFirebaseMessaging extends Mock implements FirebaseMessaging {}

void main() {
  group('NotificationService Tests', () {
    late NotificationService notificationService;
    late MockFirebaseMessaging mockFirebaseMessaging;
    late GlobalKey<NavigatorState> navigatorKey;

    setUp(() {
      mockFirebaseMessaging = MockFirebaseMessaging();
      navigatorKey = GlobalKey<NavigatorState>();
      notificationService = NotificationService(navigatorKey: navigatorKey);
    });

    test('should initialize and request permissions', () async {
      when(mockFirebaseMessaging.requestPermission()).thenAnswer((_) async => const NotificationSettings(
        authorizationStatus: AuthorizationStatus.authorized,
        alert: AppleNotificationSetting.enabled,
        announcement: AppleNotificationSetting.disabled,
        badge: AppleNotificationSetting.enabled,
        carPlay: AppleNotificationSetting.disabled,
        criticalAlert: AppleNotificationSetting.disabled,
        sound: AppleNotificationSetting.enabled,
        lockScreen: AppleNotificationSetting.enabled,
        notificationCenter: AppleNotificationSetting.enabled,
        showPreviews: AppleShowPreviewSetting.always,
        timeSensitive: AppleNotificationSetting.enabled,
      ));
      when(mockFirebaseMessaging.getToken()).thenAnswer((_) async => 'test_token');

      await notificationService.initialize();

      verify(mockFirebaseMessaging.requestPermission()).called(1);
      verify(mockFirebaseMessaging.getToken()).called(1);
    });
  });
}