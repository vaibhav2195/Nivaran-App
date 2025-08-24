// test/unsynced_issues_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:modern_auth_app/screens/profile/unsynced_issues_screen.dart';
import 'package:modern_auth_app/services/local_data_service.dart';
import 'package:modern_auth_app/services/user_profile_service.dart';
import 'package:modern_auth_app/models/local_issue_model.dart';
import 'package:modern_auth_app/models/issue_model.dart';
import 'package:modern_auth_app/models/app_user_model.dart';

// Mock services
class MockLocalDataService {
  List<LocalIssue> _unsyncedIssues = [];
  
  void setMockUnsyncedIssues(List<LocalIssue> issues) {
    _unsyncedIssues = issues;
  }
  
  Future<List<LocalIssue>> getUnsyncedIssues() async {
    return _unsyncedIssues;
  }
  
  Future<void> deleteLocalIssue(String localId) async {
    _unsyncedIssues.removeWhere((issue) => issue.localId == localId);
  }
}

class MockUserProfileService {
  AppUser? _currentUser;
  
  void setMockUser(AppUser? user) {
    _currentUser = user;
  }
  
  AppUser? get currentUserProfile => _currentUser;
}

void main() {
  group('UnsyncedIssuesScreen Tests', () {
    late MockLocalDataService mockLocalDataService;
    late MockUserProfileService mockUserProfileService;
    
    setUp(() {
      mockLocalDataService = MockLocalDataService();
      mockUserProfileService = MockUserProfileService();
    });
    
    Widget createTestWidget() {
      return MultiProvider(
        providers: [
          Provider<LocalDataService>.value(value: mockLocalDataService),
          Provider<UserProfileService>.value(value: mockUserProfileService),
        ],
        child: const MaterialApp(
          home: UnsyncedIssuesScreen(),
        ),
      );
    }
    
    testWidgets('should show "No unsynced issues" message when list is empty', (WidgetTester tester) async {
      // Arrange
      mockUserProfileService.setMockUser(AppUser(
        uid: 'test-user-123',
        email: 'test@example.com',
        username: 'testuser',
        fullName: 'Test User',
      ));
      mockLocalDataService.setMockUnsyncedIssues([]);
      
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      
      // Assert
      expect(find.text('No unsynced issues'), findsOneWidget);
      expect(find.text('All your issues have been synced successfully.'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });
    
    testWidgets('should display basic issue information (description, category, timestamp)', (WidgetTester tester) async {
      // Arrange
      final testUser = AppUser(
        uid: 'test-user-123',
        email: 'test@example.com',
        username: 'testuser',
        fullName: 'Test User',
      );
      mockUserProfileService.setMockUser(testUser);
      
      final testIssue = LocalIssue(
        localId: 'local-123',
        description: 'Test unsynced issue description',
        category: 'Infrastructure',
        urgency: 'Medium',
        timestamp: DateTime(2024, 1, 15, 10, 30),
        location: LocationModel(
          latitude: 12.9716,
          longitude: 77.5946,
          address: 'Test Address',
        ),
        userId: 'test-user-123',
        username: 'testuser',
        tags: ['test', 'offline'],
      );
      
      mockLocalDataService.setMockUnsyncedIssues([testIssue]);
      
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      
      // Assert
      expect(find.text('Test unsynced issue description'), findsOneWidget);
      expect(find.text('Infrastructure'), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget);
      expect(find.textContaining('Created: Jan 15, 2024'), findsOneWidget);
      expect(find.text('1 issue waiting to sync'), findsOneWidget);
    });
    
    testWidgets('should show delete functionality with confirmation dialog', (WidgetTester tester) async {
      // Arrange
      final testUser = AppUser(
        uid: 'test-user-123',
        email: 'test@example.com',
        username: 'testuser',
        fullName: 'Test User',
      );
      mockUserProfileService.setMockUser(testUser);
      
      final testIssue = LocalIssue(
        localId: 'local-123',
        description: 'Test issue to delete',
        category: 'Infrastructure',
        urgency: 'Medium',
        timestamp: DateTime.now(),
        location: LocationModel(
          latitude: 12.9716,
          longitude: 77.5946,
          address: 'Test Address',
        ),
        userId: 'test-user-123',
        username: 'testuser',
      );
      
      mockLocalDataService.setMockUnsyncedIssues([testIssue]);
      
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      
      // Find and tap delete button
      expect(find.text('Delete'), findsOneWidget);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      
      // Assert - confirmation dialog should appear
      expect(find.text('Delete Issue'), findsOneWidget);
      expect(find.text('Are you sure you want to delete this unsynced issue?'), findsOneWidget);
      expect(find.text('Test issue to delete'), findsOneWidget);
      expect(find.text('This action cannot be undone.'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsNWidgets(2)); // One in dialog, one in card
    });
    
    testWidgets('should delete issue when confirmed in dialog', (WidgetTester tester) async {
      // Arrange
      final testUser = AppUser(
        uid: 'test-user-123',
        email: 'test@example.com',
        username: 'testuser',
        fullName: 'Test User',
      );
      mockUserProfileService.setMockUser(testUser);
      
      final testIssue = LocalIssue(
        localId: 'local-123',
        description: 'Test issue to delete',
        category: 'Infrastructure',
        urgency: 'Medium',
        timestamp: DateTime.now(),
        location: LocationModel(
          latitude: 12.9716,
          longitude: 77.5946,
          address: 'Test Address',
        ),
        userId: 'test-user-123',
        username: 'testuser',
      );
      
      mockLocalDataService.setMockUnsyncedIssues([testIssue]);
      
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      
      // Tap delete button
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      
      // Confirm deletion in dialog
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();
      
      // Assert - issue should be deleted and success message shown
      expect(find.text('Issue deleted successfully'), findsOneWidget);
      expect(find.text('No unsynced issues'), findsOneWidget);
    });
    
    testWidgets('should cancel deletion when Cancel is pressed', (WidgetTester tester) async {
      // Arrange
      final testUser = AppUser(
        uid: 'test-user-123',
        email: 'test@example.com',
        username: 'testuser',
        fullName: 'Test User',
      );
      mockUserProfileService.setMockUser(testUser);
      
      final testIssue = LocalIssue(
        localId: 'local-123',
        description: 'Test issue to keep',
        category: 'Infrastructure',
        urgency: 'Medium',
        timestamp: DateTime.now(),
        location: LocationModel(
          latitude: 12.9716,
          longitude: 77.5946,
          address: 'Test Address',
        ),
        userId: 'test-user-123',
        username: 'testuser',
      );
      
      mockLocalDataService.setMockUnsyncedIssues([testIssue]);
      
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      
      // Tap delete button
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      
      // Cancel deletion in dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      
      // Assert - issue should still be there
      expect(find.text('Test issue to keep'), findsOneWidget);
      expect(find.text('1 issue waiting to sync'), findsOneWidget);
    });
    
    testWidgets('should show View button and display issue details', (WidgetTester tester) async {
      // Arrange
      final testUser = AppUser(
        uid: 'test-user-123',
        email: 'test@example.com',
        username: 'testuser',
        fullName: 'Test User',
      );
      mockUserProfileService.setMockUser(testUser);
      
      final testIssue = LocalIssue(
        localId: 'local-123',
        description: 'Detailed test issue',
        category: 'Infrastructure',
        urgency: 'High',
        timestamp: DateTime(2024, 1, 15, 10, 30),
        location: LocationModel(
          latitude: 12.9716,
          longitude: 77.5946,
          address: 'Detailed Test Address',
        ),
        userId: 'test-user-123',
        username: 'testuser',
        tags: ['urgent', 'road'],
        status: 'Reported',
      );
      
      mockLocalDataService.setMockUnsyncedIssues([testIssue]);
      
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      
      // Tap View button
      await tester.tap(find.text('View'));
      await tester.pumpAndSettle();
      
      // Assert - details dialog should appear
      expect(find.text('Issue Details'), findsOneWidget);
      expect(find.text('Detailed test issue'), findsNWidgets(2)); // In card and dialog
      expect(find.text('Infrastructure'), findsNWidgets(2)); // In card and dialog
      expect(find.text('High'), findsNWidgets(2)); // In card and dialog
      expect(find.text('Reported'), findsOneWidget);
      expect(find.text('Detailed Test Address'), findsOneWidget);
      expect(find.text('urgent, road'), findsOneWidget);
    });
    
    testWidgets('should display multiple unsynced issues correctly', (WidgetTester tester) async {
      // Arrange
      final testUser = AppUser(
        uid: 'test-user-123',
        email: 'test@example.com',
        username: 'testuser',
        fullName: 'Test User',
      );
      mockUserProfileService.setMockUser(testUser);
      
      final issues = [
        LocalIssue(
          localId: 'local-1',
          description: 'First unsynced issue',
          category: 'Infrastructure',
          urgency: 'High',
          timestamp: DateTime.now(),
          location: LocationModel(latitude: 12.9716, longitude: 77.5946, address: 'Address 1'),
          userId: 'test-user-123',
          username: 'testuser',
        ),
        LocalIssue(
          localId: 'local-2',
          description: 'Second unsynced issue',
          category: 'Environment',
          urgency: 'Medium',
          timestamp: DateTime.now(),
          location: LocationModel(latitude: 12.9716, longitude: 77.5946, address: 'Address 2'),
          userId: 'test-user-123',
          username: 'testuser',
        ),
      ];
      
      mockLocalDataService.setMockUnsyncedIssues(issues);
      
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      
      // Assert
      expect(find.text('2 issues waiting to sync'), findsOneWidget);
      expect(find.text('First unsynced issue'), findsOneWidget);
      expect(find.text('Second unsynced issue'), findsOneWidget);
      expect(find.text('Infrastructure'), findsOneWidget);
      expect(find.text('Environment'), findsOneWidget);
      expect(find.text('High'), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget);
    });
    
    testWidgets('should show refresh button and handle refresh', (WidgetTester tester) async {
      // Arrange
      final testUser = AppUser(
        uid: 'test-user-123',
        email: 'test@example.com',
        username: 'testuser',
        fullName: 'Test User',
      );
      mockUserProfileService.setMockUser(testUser);
      mockLocalDataService.setMockUnsyncedIssues([]);
      
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      
      // Assert - refresh button should be present
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      
      // Tap refresh button
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();
      
      // Should still show no unsynced issues
      expect(find.text('No unsynced issues'), findsOneWidget);
    });
    
    testWidgets('should handle sync error display', (WidgetTester tester) async {
      // Arrange
      final testUser = AppUser(
        uid: 'test-user-123',
        email: 'test@example.com',
        username: 'testuser',
        fullName: 'Test User',
      );
      mockUserProfileService.setMockUser(testUser);
      
      final testIssue = LocalIssue(
        localId: 'local-123',
        description: 'Issue with sync error',
        category: 'Infrastructure',
        urgency: 'Medium',
        timestamp: DateTime.now(),
        location: LocationModel(
          latitude: 12.9716,
          longitude: 77.5946,
          address: 'Test Address',
        ),
        userId: 'test-user-123',
        username: 'testuser',
        syncError: 'Network timeout',
      );
      
      mockLocalDataService.setMockUnsyncedIssues([testIssue]);
      
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      
      // Assert - sync error should be displayed
      expect(find.text('Sync failed'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });
  });
}