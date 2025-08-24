import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:modern_auth_app/services/connectivity_service.dart';
import 'package:modern_auth_app/widgets/offline_banner.dart';
import 'package:modern_auth_app/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// Mock ConnectivityService for testing
class MockConnectivityService extends ConnectivityService {
  bool _mockIsOnline = true;
  bool _mockWasOffline = false;

  @override
  bool get isOnline => _mockIsOnline;

  @override
  bool get wasOffline => _mockWasOffline;

  void setOnlineStatus(bool isOnline) {
    if (isOnline != _mockIsOnline) {
      if (!isOnline) {
        _mockWasOffline = true;
      } else if (_mockWasOffline) {
        // Coming back online after being offline
        _mockWasOffline = false;
      }
      _mockIsOnline = isOnline;
      notifyListeners();
    }
  }

  void simulateOfflineTransition() {
    _mockWasOffline = true;
    _mockIsOnline = false;
    notifyListeners();
  }

  void simulateOnlineTransition() {
    _mockIsOnline = true;
    // Keep _mockWasOffline true to simulate that we were offline before
    notifyListeners();
  }
}

void main() {
  group('Connectivity Integration Tests', () {
    late MockConnectivityService mockConnectivityService;

    setUp(() {
      mockConnectivityService = MockConnectivityService();
    });

    Widget createTestApp() {
      return MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('hi'),
        ],
        home: ChangeNotifierProvider<ConnectivityService>.value(
          value: mockConnectivityService,
          child: Scaffold(
            body: Column(
              children: [
                const OfflineBanner(),
                Expanded(
                  child: Consumer<ConnectivityService>(
                    builder: (context, connectivityService, child) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Connection Status: ${connectivityService.isOnline ? "Online" : "Offline"}',
                              style: const TextStyle(fontSize: 18),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Was Offline: ${connectivityService.wasOffline ? "Yes" : "No"}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    testWidgets('should properly track offline/online state transitions', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Initially online
      expect(find.text('Connection Status: Online'), findsOneWidget);
      expect(find.text('Was Offline: No'), findsOneWidget);
      expect(find.text('Offline Mode'), findsNothing);

      // Go offline
      mockConnectivityService.simulateOfflineTransition();
      await tester.pumpAndSettle();

      // Should show offline banner and update status
      expect(find.text('Connection Status: Offline'), findsOneWidget);
      expect(find.text('Was Offline: Yes'), findsOneWidget);
      expect(find.text('Offline Mode'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off), findsOneWidget);

      // Go back online
      mockConnectivityService.simulateOnlineTransition();
      await tester.pumpAndSettle();

      // Should hide offline banner but remember we were offline
      expect(find.text('Connection Status: Online'), findsOneWidget);
      expect(find.text('Was Offline: Yes'), findsOneWidget);
      expect(find.text('Offline Mode'), findsNothing);
    });

    testWidgets('should handle multiple connectivity state changes', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Start online
      expect(find.text('Offline Mode'), findsNothing);

      // Go offline
      mockConnectivityService.setOnlineStatus(false);
      await tester.pumpAndSettle();
      expect(find.text('Offline Mode'), findsOneWidget);

      // Go online
      mockConnectivityService.setOnlineStatus(true);
      await tester.pumpAndSettle();
      expect(find.text('Offline Mode'), findsNothing);

      // Go offline again
      mockConnectivityService.setOnlineStatus(false);
      await tester.pumpAndSettle();
      expect(find.text('Offline Mode'), findsOneWidget);

      // Go online again
      mockConnectivityService.setOnlineStatus(true);
      await tester.pumpAndSettle();
      expect(find.text('Offline Mode'), findsNothing);
    });
  });
}