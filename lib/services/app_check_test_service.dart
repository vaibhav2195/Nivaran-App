// lib/services/app_check_test_service.dart
import 'package:firebase_app_check/firebase_app_check.dart';
import 'dart:developer' as developer;

class AppCheckTestService {
  static Future<void> testAppCheckToken() async {
    try {
      // Get the current App Check token
      final token = await FirebaseAppCheck.instance.getToken();

      if (token != null) {
        developer.log(
          'App Check token obtained successfully. Token length: ${token.length}',
          name: 'AppCheckTest',
        );
        developer.log(
          'App Check is working correctly with debug token',
          name: 'AppCheckTest',
        );
      } else {
        developer.log(
          'App Check token is null - this may indicate a configuration issue',
          name: 'AppCheckTest',
        );
      }
    } catch (e) {
      developer.log(
        'Error getting App Check token: $e',
        name: 'AppCheckTest',
        error: e,
      );
    }
  }

  static Future<bool> isAppCheckWorking() async {
    try {
      final token = await FirebaseAppCheck.instance.getToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      developer.log(
        'App Check test failed: $e',
        name: 'AppCheckTest',
        error: e,
      );
      return false;
    }
  }
}
