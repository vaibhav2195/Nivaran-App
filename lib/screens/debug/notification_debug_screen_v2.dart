import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:modern_auth_app/utils/notification_test_helper.dart';
import 'package:modern_auth_app/services/notification_debug_service.dart';
import 'package:modern_auth_app/services/push_notification_fixer.dart';
import 'package:modern_auth_app/services/notification_test_service.dart';
import 'package:modern_auth_app/services/fcm_token_refresh_service.dart';

class NotificationDebugScreenV2 extends StatefulWidget {
  const NotificationDebugScreenV2({super.key});

  @override
  State<NotificationDebugScreenV2> createState() =>
      _NotificationDebugScreenV2State();
}

class _NotificationDebugScreenV2State extends State<NotificationDebugScreenV2> {
  String? _fcmToken;
  bool _isLoading = false;
  Map<String, dynamic>? _debugResults;

  @override
  void initState() {
    super.initState();
    _loadFCMToken();
    _runDebugCheck();
  }

  Future<void> _loadFCMToken() async {
    setState(() => _isLoading = true);
    try {
      final token = await NotificationTestHelper.getCurrentFCMToken();
      setState(() => _fcmToken = token);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _runDebugCheck() async {
    try {
      final results = await NotificationDebugService.debugPushNotifications();
      setState(() => _debugResults = results);
    } catch (e) {
      print('Error running debug check: $e');
    }
  }

  Future<void> _copyTokenToClipboard() async {
    if (_fcmToken != null) {
      await Clipboard.setData(ClipboardData(text: _fcmToken!));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('FCM Token copied to clipboard')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Push Notification Debug'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Overview Card
            Card(
              color: Colors.red[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🚨 Push Notification Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_debugResults != null) ...[
                      _buildStatusRow(
                        'User Authenticated',
                        _debugResults!['user_authenticated'] ?? false,
                      ),
                      _buildStatusRow(
                        'FCM Token Exists',
                        _debugResults!['fcm_token_exists'] ?? false,
                      ),
                      _buildStatusRow(
                        'Permissions Granted',
                        _debugResults!['notification_permission'] ==
                            'AuthorizationStatus.authorized',
                      ),
                      _buildStatusRow(
                        'Token in Firestore',
                        _debugResults!['current_token_registered'] ?? false,
                      ),
                      _buildStatusRow(
                        'Firestore Doc Exists',
                        _debugResults!['firestore_doc_exists'] ?? false,
                      ),
                    ] else
                      const CircularProgressIndicator(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // FCM Token Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'FCM Token',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (_fcmToken != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Text(
                          _fcmToken!,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _copyTokenToClipboard,
                            icon: const Icon(Icons.copy),
                            label: const Text('Copy Token'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _loadFCMToken,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh'),
                          ),
                        ],
                      ),
                    ] else
                      const Text('Failed to load FCM token'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Quick Fix Actions
            Card(
              color: Colors.green[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🔧 Quick Fix Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () async {
                        // Show loading dialog
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder:
                              (context) => const AlertDialog(
                                content: Row(
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(width: 16),
                                    Text('Fixing push notifications...'),
                                  ],
                                ),
                              ),
                        );

                        final results =
                            await PushNotificationFixer.fixPushNotifications();

                        if (mounted) {
                          Navigator.pop(context); // Close loading dialog

                          final success = results['success'] == true;
                          final error = results['error'];

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? '🎉 Push notifications fixed! Check your device.'
                                    : '❌ Fix failed: ${error ?? 'Unknown error'}',
                              ),
                              duration: const Duration(seconds: 5),
                              backgroundColor:
                                  success ? Colors.green : Colors.red,
                            ),
                          );

                          // Show detailed results
                          if (!success && error != null) {
                            showDialog(
                              context: context,
                              builder:
                                  (context) => AlertDialog(
                                    title: const Text('Fix Failed'),
                                    content: SingleChildScrollView(
                                      child: Text(
                                        'Error: $error\n\nResults: ${results.toString()}',
                                        style: const TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Close'),
                                      ),
                                    ],
                                  ),
                            );
                          }
                        }

                        await _runDebugCheck();
                        await _loadFCMToken();
                      },
                      icon: const Icon(Icons.build),
                      label: const Text('🔧 FIX PUSH NOTIFICATIONS'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final success =
                            await NotificationDebugService.requestPermissionsExplicitly();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? 'Permissions granted'
                                    : 'Permissions denied',
                              ),
                            ),
                          );
                        }
                        await _runDebugCheck();
                      },
                      icon: const Icon(Icons.security),
                      label: const Text('1. Request Permissions'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final success =
                            await NotificationDebugService.forceRegisterToken();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? 'Token registered'
                                    : 'Failed to register token',
                              ),
                            ),
                          );
                        }
                        await _runDebugCheck();
                      },
                      icon: const Icon(Icons.app_registration),
                      label: const Text('2. Force Register Token'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        // Show loading dialog
                        if (mounted) {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder:
                                (context) => const AlertDialog(
                                  content: Row(
                                    children: [
                                      CircularProgressIndicator(),
                                      SizedBox(width: 16),
                                      Text('Refreshing FCM token...'),
                                    ],
                                  ),
                                ),
                          );
                        }

                        final results =
                            await FCMTokenRefreshService.forceRefreshToken();

                        if (mounted) {
                          Navigator.pop(context); // Close loading dialog

                          final success = results['success'] == true;
                          final error = results['error'];

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? '🎉 FCM token refreshed successfully!'
                                    : '❌ Token refresh failed: ${error ?? 'Unknown error'}',
                              ),
                              duration: const Duration(seconds: 5),
                              backgroundColor:
                                  success ? Colors.green : Colors.red,
                            ),
                          );

                          // Show detailed results if there's an error
                          if (!success) {
                            showDialog(
                              context: context,
                              builder:
                                  (context) => AlertDialog(
                                    title: const Text('Token Refresh Failed'),
                                    content: SingleChildScrollView(
                                      child: Text(
                                        results.toString(),
                                        style: const TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Close'),
                                      ),
                                    ],
                                  ),
                            );
                          }
                        }

                        await _runDebugCheck();
                        await _loadFCMToken();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('🔄 REFRESH FCM TOKEN'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await _runDebugCheck();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Debug check completed'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('3. Refresh Status'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Test Notifications
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Test Notifications',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await NotificationTestHelper.testLocalNotification();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Local test notification sent'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.notifications),
                      label: const Text('Send Local Test Notification'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        // Show loading dialog
                        if (mounted) {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder:
                                (context) => const AlertDialog(
                                  content: Row(
                                    children: [
                                      CircularProgressIndicator(),
                                      SizedBox(width: 16),
                                      Text('Testing push notifications...'),
                                    ],
                                  ),
                                ),
                          );
                        }

                        final results =
                            await NotificationTestService.testNotificationsOnly();

                        if (mounted) {
                          Navigator.pop(context); // Close loading dialog

                          final success = results['success'] == true;
                          final error = results['error'];

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? '🎉 Push notification test completed! Check your device.'
                                    : '❌ Test failed: ${error ?? 'Unknown error'}',
                              ),
                              duration: const Duration(seconds: 5),
                              backgroundColor:
                                  success ? Colors.green : Colors.red,
                            ),
                          );

                          // Show detailed results
                          showDialog(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: Text(
                                    success ? 'Test Results' : 'Test Failed',
                                  ),
                                  content: SingleChildScrollView(
                                    child: Text(
                                      results.toString(),
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Close'),
                                    ),
                                  ],
                                ),
                          );
                        }
                      },
                      icon: const Icon(Icons.rocket_launch),
                      label: const Text('🧪 TEST NOTIFICATIONS (Simple)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        // Show loading dialog
                        if (mounted) {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder:
                                (context) => const AlertDialog(
                                  content: Row(
                                    children: [
                                      CircularProgressIndicator(),
                                      SizedBox(width: 16),
                                      Text(
                                        'Testing REAL push notifications...',
                                      ),
                                    ],
                                  ),
                                ),
                          );
                        }

                        final results =
                            await NotificationTestService.testPushNotifications();

                        if (mounted) {
                          Navigator.pop(context); // Close loading dialog

                          final success = results['success'] == true;
                          final error = results['error'];

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? '🎉 REAL push notification test completed! Check your device.'
                                    : '❌ Test failed: ${error ?? 'Unknown error'}',
                              ),
                              duration: const Duration(seconds: 5),
                              backgroundColor:
                                  success ? Colors.green : Colors.red,
                            ),
                          );

                          // Show detailed results
                          showDialog(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: Text(
                                    success ? 'Test Results' : 'Test Failed',
                                  ),
                                  content: SingleChildScrollView(
                                    child: Text(
                                      results.toString(),
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Close'),
                                    ),
                                  ],
                                ),
                          );
                        }
                      },
                      icon: const Icon(Icons.rocket_launch),
                      label: const Text('🚀 TEST REAL PUSH NOTIFICATIONS'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final results =
                            await NotificationTestService.testTopicNotification();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                results['message'] ?? 'Topic test completed',
                              ),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.topic),
                      label: const Text('Test Topic Subscription'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final results =
                            await NotificationTestService.testDirectPushNotification();
                        if (mounted) {
                          final success = results['success'] == true;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                results['message'] ??
                                    'Direct push test completed',
                              ),
                              duration: const Duration(seconds: 5),
                              backgroundColor:
                                  success ? Colors.blue : Colors.red,
                            ),
                          );

                          // Show detailed results
                          showDialog(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: const Text('Direct Push Test Results'),
                                  content: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(results['message'] ?? ''),
                                        const SizedBox(height: 16),
                                        if (results['token_preview'] !=
                                            null) ...[
                                          const Text(
                                            'FCM Token:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            results['token_preview'],
                                            style: const TextStyle(
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                        ],
                                        if (results['instructions'] !=
                                            null) ...[
                                          const Text(
                                            'Instructions:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(results['instructions']),
                                        ],
                                      ],
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Close'),
                                    ),
                                  ],
                                ),
                          );
                        }
                      },
                      icon: const Icon(Icons.send),
                      label: const Text('🎯 DIRECT PUSH TEST'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final results =
                            await NotificationTestService.diagnoseFCMTokens();
                        if (mounted) {
                          final success = results['success'] == true;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                results['message'] ?? 'FCM diagnosis completed',
                              ),
                              backgroundColor:
                                  success ? Colors.green : Colors.red,
                            ),
                          );

                          // Show detailed results
                          showDialog(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: const Text('FCM Token Diagnosis'),
                                  content: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children:
                                          results.entries.map((entry) {
                                            final isGood =
                                                entry.value == true ||
                                                (entry.value is int &&
                                                    entry.value > 0);
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 2,
                                                  ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    isGood
                                                        ? Icons.check_circle
                                                        : Icons.error,
                                                    color:
                                                        isGood
                                                            ? Colors.green
                                                            : Colors.red,
                                                    size: 16,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      '${entry.key}: ${entry.value}',
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Close'),
                                    ),
                                  ],
                                ),
                          );
                        }
                      },
                      icon: const Icon(Icons.search),
                      label: const Text('🔍 DIAGNOSE FCM TOKENS'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await NotificationTestService.cleanupTestData();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Test data cleaned up'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.cleaning_services),
                      label: const Text('Clean Up Test Data'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Debug Results
            if (_debugResults != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Detailed Debug Results',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._debugResults!.entries.map((entry) {
                        final isError =
                            entry.key.contains('error') ||
                            (entry.value is bool && entry.value == false);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                isError ? Icons.error : Icons.check_circle,
                                color: isError ? Colors.red : Colors.green,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${entry.key}: ${entry.value}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                    color:
                                        isError ? Colors.red : Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),
            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📋 How to test push notifications:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('1. Ensure all status items above are ✅ green'),
                  Text('2. Copy the FCM token above'),
                  Text('3. Go to Firebase Console > Cloud Messaging'),
                  Text('4. Create a new message and paste the token'),
                  Text('5. Add data: type="new_comment", issueId="test123"'),
                  Text('6. Send the message'),
                  SizedBox(height: 8),
                  Text(
                    'If notifications still don\'t work, check device notification settings!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, bool status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            status ? Icons.check_circle : Icons.error,
            color: status ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: status ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
