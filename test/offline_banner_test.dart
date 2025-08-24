import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:modern_auth_app/widgets/offline_banner.dart';
import 'package:modern_auth_app/services/connectivity_service.dart';
import 'package:modern_auth_app/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// Mock ConnectivityService for testing
class MockConnectivityService extends ConnectivityService {
  bool _mockIsOnline = true;

  @override
  bool get isOnline => _mockIsOnline;

  void setOnlineStatus(bool isOnline) {
    _mockIsOnline = isOnline;
    notifyListeners();
  }
}

void main() {
  group('OfflineBanner Widget Tests', () {
    late MockConnectivityService mockConnectivityService;

    setUp(() {
      mockConnectivityService = MockConnectivityService();
    });

    Widget createTestWidget({required bool isOnline}) {
      mockConnectivityService.setOnlineStatus(isOnline);
      
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
          child: const Scaffold(
            body: Column(
              children: [
                OfflineBanner(),
                Expanded(
                  child: Center(
                    child: Text('Test Content'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    testWidgets('should show offline banner when offline', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(isOnline: false));
      await tester.pumpAndSettle();

      // Verify offline banner is visible
      expect(find.byType(OfflineBanner), findsOneWidget);
      expect(find.text('Offline Mode'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
    });

    testWidgets('should hide offline banner when online', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(isOnline: true));
      await tester.pumpAndSettle();

      // Verify offline banner is not visible (SizedBox.shrink)
      expect(find.text('Offline Mode'), findsNothing);
      expect(find.byIcon(Icons.wifi_off), findsNothing);
    });

    testWidgets('should toggle banner visibility when connectivity changes', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(isOnline: true));
      await tester.pumpAndSettle();

      // Initially online - no banner
      expect(find.text('Offline Mode'), findsNothing);

      // Go offline
      mockConnectivityService.setOnlineStatus(false);
      await tester.pumpAndSettle();

      // Banner should appear
      expect(find.text('Offline Mode'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off), findsOneWidget);

      // Go back online
      mockConnectivityService.setOnlineStatus(true);
      await tester.pumpAndSettle();

      // Banner should disappear
      expect(find.text('Offline Mode'), findsNothing);
    });
  });
}