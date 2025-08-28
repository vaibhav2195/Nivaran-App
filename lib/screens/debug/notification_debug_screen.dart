import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:modern_auth_app/utils/notification_test_helper.dart';
import 'package:modern_auth_app/services/fcm_token_service.dart';
import 'package:modern_auth_app/services/notification_debug_service.dart';

class NotificationDebugScreen extends StatefulWidget {
  const NotificationDebugScreen({super.key});

  @override
  State<NotificationDebugScreen> createState() =>
      _NotificationDebugScreenState();
}

class _NotificationDebugScreenState extends State<NotificationDebugScreen> {
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
        title: const Text('Notification Debug'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                            fontSize: 12,
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
                              content: Text('Test notification sent'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.notifications),
                      label: const Text('Send Test Notification'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await NotificationTestHelper.testNotificationTypes();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('All test notifications sent'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.notifications_active),
                      label: const Text('Test All Notification Types'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await NotificationTestHelper.checkNotificationPermissions();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Check console for permission status',
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.security),
                      label: const Text('Check Permissions'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'FCM Token Management',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await FCMTokenService.registerToken();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('FCM token registered'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.app_registration),
                      label: const Text('Register FCM Token'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await FCMTokenService.unregisterToken();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('FCM token unregistered'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.app_registration_outlined),
                      label: const Text('Unregister FCM Token'),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How to test with Firebase Console:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('1. Copy the FCM token above'),
                  Text('2. Go to Firebase Console > Cloud Messaging'),
                  Text('3. Create a new message'),
                  Text('4. Paste the token in "Send test message"'),
                  Text('5. Add data: type="new_comment", issueId="test123"'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
