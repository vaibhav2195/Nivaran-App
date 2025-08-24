// test/offline_functionality_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_auth_app/services/offline_sync_service.dart';
import 'package:modern_auth_app/services/connectivity_service.dart';
import 'package:modern_auth_app/services/local_data_service.dart';
import 'package:modern_auth_app/models/local_issue_model.dart';
import 'package:modern_auth_app/models/issue_model.dart';
import 'package:modern_auth_app/models/app_user_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  group('Offline Functionality Tests', () {
    late LocalDataService localDataService;
    late OfflineSyncService offlineSyncService;
    late ConnectivityService connectivityService;

    setUpAll(() {
      // Initialize FFI for testing
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      connectivityService = ConnectivityService();
      localDataService = LocalDataService();
      offlineSyncService = OfflineSyncService(connectivityService);
      
      // Initialize database
      await localDataService.initializeDatabase();
    });

    tearDown(() async {
      // Clean up database after each test
      await localDataService.deleteDatabase();
    });

    test('should save issue offline', () async {
      // Create test user
      final testUser = AppUser(
        uid: 'test-user-123',
        email: 'test@example.com',
        username: 'testuser',
        role: 'user',
      );

      // Create test location
      final testLocation = LocationModel(
        latitude: 12.9716,
        longitude: 77.5946,
        address: 'Test Address, Bangalore',
      );

      // Save issue offline
      final localId = await offlineSyncService.saveIssueOffline(
        description: 'Test pothole on main road',
        category: 'Roads',
        urgency: 'Medium',
        tags: ['pothole', 'urgent'],
        imagePath: '/test/path/image.jpg', // Mock path
        location: testLocation,
        user: testUser,
      );

      expect(localId, isNotEmpty);

      // Verify issue was saved
      final unsyncedIssues = await offlineSyncService.getUnsyncedIssues();
      expect(unsyncedIssues.length, 1);
      expect(unsyncedIssues.first.description, 'Test pothole on main road');
      expect(unsyncedIssues.first.category, 'Roads');
      expect(unsyncedIssues.first.urgency, 'Medium');
      expect(unsyncedIssues.first.isSynced, false);
    });

    test('should delete unsynced issue', () async {
      // Create test user
      final testUser = AppUser(
        uid: 'test-user-123',
        email: 'test@example.com',
        username: 'testuser',
        role: 'user',
      );

      // Create test location
      final testLocation = LocationModel(
        latitude: 12.9716,
        longitude: 77.5946,
        address: 'Test Address, Bangalore',
      );

      // Save issue offline
      final localId = await offlineSyncService.saveIssueOffline(
        description: 'Test issue to delete',
        category: 'Water',
        urgency: 'Medium',
        tags: ['test'],
        imagePath: '/test/path/image.jpg',
        location: testLocation,
        user: testUser,
      );

      // Verify issue exists
      var unsyncedIssues = await offlineSyncService.getUnsyncedIssues();
      expect(unsyncedIssues.length, 1);

      // Delete the issue
      await offlineSyncService.deleteUnsyncedIssue(localId);

      // Verify issue was deleted
      unsyncedIssues = await offlineSyncService.getUnsyncedIssues();
      expect(unsyncedIssues.length, 0);
    });

    test('should get database statistics', () async {
      // Create test user
      final testUser = AppUser(
        uid: 'test-user-123',
        email: 'test@example.com',
        username: 'testuser',
        role: 'user',
      );

      // Create test location
      final testLocation = LocationModel(
        latitude: 12.9716,
        longitude: 77.5946,
        address: 'Test Address, Bangalore',
      );

      // Save multiple issues offline
      await offlineSyncService.saveIssueOffline(
        description: 'Test issue 1',
        category: 'Roads',
        urgency: 'Medium',
        tags: ['test1'],
        imagePath: '/test/path/image1.jpg',
        location: testLocation,
        user: testUser,
      );

      await offlineSyncService.saveIssueOffline(
        description: 'Test issue 2',
        category: 'Water',
        urgency: 'Medium',
        tags: ['test2'],
        imagePath: '/test/path/image2.jpg',
        location: testLocation,
        user: testUser,
      );

      // Get database statistics
      final stats = await offlineSyncService.getDatabaseStats();
      expect(stats['total'], 2);
      expect(stats['unsynced'], 2);
      expect(stats['synced'], 0);
    });

    test('should convert LocalIssue to Issue', () async {
      // Create test location
      final testLocation = LocationModel(
        latitude: 12.9716,
        longitude: 77.5946,
        address: 'Test Address, Bangalore',
      );

      // Create LocalIssue
      final localIssue = LocalIssue(
        localId: 'test-local-123',
        description: 'Test description',
        category: 'Roads',
        urgency: 'Medium',
        tags: ['test', 'pothole'],
        timestamp: DateTime.now(),
        location: testLocation,
        userId: 'user-123',
        username: 'testuser',
      );

      // Convert to Issue
      final issue = localIssue.toIssue();
      expect(issue.description, 'Test description');
      expect(issue.category, 'Roads');
      expect(issue.urgency, 'Medium');
      expect(issue.tags, ['test', 'pothole']);
      expect(issue.userId, 'user-123');
      expect(issue.username, 'testuser');
    });
  });
}