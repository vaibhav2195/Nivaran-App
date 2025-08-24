// test/unsynced_issues_integration_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_auth_app/services/local_data_service.dart';
import 'package:modern_auth_app/models/local_issue_model.dart';
import 'package:modern_auth_app/models/issue_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  group('Unsynced Issues Integration Tests', () {
    late LocalDataService localDataService;
    
    setUpAll(() {
      // Initialize FFI for testing
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });
    
    setUp(() async {
      localDataService = LocalDataService();
      // Delete any existing test database
      try {
        await localDataService.deleteDatabase();
      } catch (e) {
        // Ignore if database doesn't exist
      }
      await localDataService.initializeDatabase();
      
      // Clean up any existing test data
      final allIssues = await localDataService.getUnsyncedIssues();
      for (final issue in allIssues) {
        await localDataService.deleteLocalIssue(issue.localId);
      }
    });
    
    tearDown(() async {
      await localDataService.close();
    });
    
    test('should store and retrieve unsynced issues', () async {
      // Arrange
      final testIssue = LocalIssue(
        localId: 'test-local-123',
        description: 'Test unsynced issue',
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
        tags: ['test'],
      );
      
      // Act
      await localDataService.insertIssue(testIssue);
      final unsyncedIssues = await localDataService.getUnsyncedIssues();
      
      // Assert
      expect(unsyncedIssues.length, equals(1));
      expect(unsyncedIssues.first.description, equals('Test unsynced issue'));
      expect(unsyncedIssues.first.category, equals('Infrastructure'));
      expect(unsyncedIssues.first.urgency, equals('Medium'));
      expect(unsyncedIssues.first.isSynced, equals(false));
    });
    
    test('should delete unsynced issues', () async {
      // Arrange
      final testIssue = LocalIssue(
        localId: 'test-local-456',
        description: 'Issue to delete',
        category: 'Environment',
        urgency: 'High',
        timestamp: DateTime.now(),
        location: LocationModel(
          latitude: 12.9716,
          longitude: 77.5946,
          address: 'Test Address',
        ),
        userId: 'test-user-123',
        username: 'testuser',
      );
      
      await localDataService.insertIssue(testIssue);
      
      // Act
      await localDataService.deleteLocalIssue('test-local-456');
      final unsyncedIssues = await localDataService.getUnsyncedIssues();
      
      // Assert
      expect(unsyncedIssues.length, equals(0));
    });
    
    test('should filter unsynced issues by user', () async {
      // Arrange
      final user1Issue = LocalIssue(
        localId: 'user1-issue',
        description: 'User 1 issue',
        category: 'Infrastructure',
        urgency: 'Medium',
        timestamp: DateTime.now(),
        location: LocationModel(
          latitude: 12.9716,
          longitude: 77.5946,
          address: 'Test Address',
        ),
        userId: 'user-1',
        username: 'user1',
      );
      
      final user2Issue = LocalIssue(
        localId: 'user2-issue',
        description: 'User 2 issue',
        category: 'Environment',
        urgency: 'High',
        timestamp: DateTime.now(),
        location: LocationModel(
          latitude: 12.9716,
          longitude: 77.5946,
          address: 'Test Address',
        ),
        userId: 'user-2',
        username: 'user2',
      );
      
      await localDataService.insertIssue(user1Issue);
      await localDataService.insertIssue(user2Issue);
      
      // Act
      final user1Issues = await localDataService.getIssuesByUser('user-1');
      final user2Issues = await localDataService.getIssuesByUser('user-2');
      
      // Assert
      expect(user1Issues.length, equals(1));
      expect(user1Issues.first.description, equals('User 1 issue'));
      expect(user2Issues.length, equals(1));
      expect(user2Issues.first.description, equals('User 2 issue'));
    });
    
    test('should handle multiple unsynced issues correctly', () async {
      // Arrange
      final issues = [
        LocalIssue(
          localId: 'issue-1',
          description: 'First issue',
          category: 'Infrastructure',
          urgency: 'High',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          location: LocationModel(latitude: 12.9716, longitude: 77.5946, address: 'Address 1'),
          userId: 'test-user',
          username: 'testuser',
        ),
        LocalIssue(
          localId: 'issue-2',
          description: 'Second issue',
          category: 'Environment',
          urgency: 'Medium',
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
          location: LocationModel(latitude: 12.9716, longitude: 77.5946, address: 'Address 2'),
          userId: 'test-user',
          username: 'testuser',
        ),
        LocalIssue(
          localId: 'issue-3',
          description: 'Third issue',
          category: 'Safety',
          urgency: 'Low',
          timestamp: DateTime.now(),
          location: LocationModel(latitude: 12.9716, longitude: 77.5946, address: 'Address 3'),
          userId: 'test-user',
          username: 'testuser',
        ),
      ];
      
      // Act
      for (final issue in issues) {
        await localDataService.insertIssue(issue);
      }
      
      final unsyncedIssues = await localDataService.getUnsyncedIssues();
      
      // Assert
      expect(unsyncedIssues.length, equals(3));
      
      // Should be ordered by timestamp DESC (newest first)
      expect(unsyncedIssues[0].description, equals('Third issue'));
      expect(unsyncedIssues[1].description, equals('Second issue'));
      expect(unsyncedIssues[2].description, equals('First issue'));
    });
    
    test('should handle sync error information', () async {
      // Arrange
      final testIssue = LocalIssue(
        localId: 'error-issue',
        description: 'Issue with sync error',
        category: 'Infrastructure',
        urgency: 'Medium',
        timestamp: DateTime.now(),
        location: LocationModel(
          latitude: 12.9716,
          longitude: 77.5946,
          address: 'Test Address',
        ),
        userId: 'test-user',
        username: 'testuser',
        syncError: 'Network timeout error',
      );
      
      // Act
      await localDataService.insertIssue(testIssue);
      await localDataService.updateIssueSyncError('error-issue', 'Updated error message');
      
      final unsyncedIssues = await localDataService.getUnsyncedIssues();
      
      // Assert
      expect(unsyncedIssues.length, equals(1));
      expect(unsyncedIssues.first.syncError, equals('Updated error message'));
    });
    
    test('should get database statistics correctly', () async {
      // Arrange
      final unsyncedIssue = LocalIssue(
        localId: 'unsynced-issue',
        description: 'Unsynced issue',
        category: 'Infrastructure',
        urgency: 'Medium',
        timestamp: DateTime.now(),
        location: LocationModel(
          latitude: 12.9716,
          longitude: 77.5946,
          address: 'Test Address',
        ),
        userId: 'test-user',
        username: 'testuser',
        isSynced: false,
      );
      
      final syncedIssue = LocalIssue(
        localId: 'synced-issue',
        description: 'Synced issue',
        category: 'Environment',
        urgency: 'High',
        timestamp: DateTime.now(),
        location: LocationModel(
          latitude: 12.9716,
          longitude: 77.5946,
          address: 'Test Address',
        ),
        userId: 'test-user',
        username: 'testuser',
        isSynced: true,
        firebaseId: 'firebase-123',
        syncedAt: DateTime.now(),
      );
      
      // Act
      await localDataService.insertIssue(unsyncedIssue);
      await localDataService.insertIssue(syncedIssue);
      
      final stats = await localDataService.getDatabaseStats();
      
      // Assert
      expect(stats['total'], equals(2));
      expect(stats['unsynced'], equals(1));
      expect(stats['synced'], equals(1));
    });
  });
}