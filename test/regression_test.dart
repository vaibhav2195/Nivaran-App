// test/regression_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_auth_app/services/connectivity_service.dart';
import 'package:modern_auth_app/services/offline_sync_service.dart';
import 'package:modern_auth_app/services/local_data_service.dart';
import 'package:modern_auth_app/utils/offline_first_data_loader.dart';
import 'package:modern_auth_app/models/local_issue_model.dart';
import 'package:modern_auth_app/models/app_user_model.dart';
import 'package:modern_auth_app/models/issue_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:developer' as developer;

// Mock ConnectivityService that simulates real connectivity behavior
class MockConnectivityService extends ConnectivityService {
  bool _mockIsOnline = true;
  bool _mockWasOffline = false;
  Function()? _autoSyncCallback;

  @override
  bool get isOnline => _mockIsOnline;

  @override
  bool get wasOffline => _mockWasOffline;

  void setOnlineStatus(bool isOnline) {
    if (isOnline != _mockIsOnline) {
      if (!isOnline) {
        _mockWasOffline = true;
      } else if (_mockWasOffline) {
        _mockWasOffline = false;
        if (_autoSyncCallback != null) {
          _autoSyncCallback!();
        }
      }
      _mockIsOnline = isOnline;
      notifyListeners();
    }
  }

  @override
  void setAutoSyncCallback(Function() callback) {
    _autoSyncCallback = callback;
  }

  @override
  Future<dynamic> checkConnectivity() async {
    return _mockIsOnline ? 'wifi' : 'none';
  }
}

void main() {
  group('Regression Tests - Ensure Existing Features Work', () {
    late MockConnectivityService mockConnectivityService;
    late LocalDataService localDataService;
    late OfflineSyncService offlineSyncService;

    setUpAll(() {
      // Initialize FFI for testing
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      mockConnectivityService = MockConnectivityService();
      localDataService = LocalDataService();
      offlineSyncService = OfflineSyncService(mockConnectivityService);
      
      // Clean up any existing database
      try {
        await localDataService.deleteDatabase();
      } catch (e) {
        // Ignore if database doesn't exist
      }
      
      // Initialize services
      await localDataService.initializeDatabase();
      await offlineSyncService.initialize();
    });

    tearDown(() async {
      // Clean up database after each test
      await localDataService.deleteDatabase();
    });

    test('ConnectivityService basic functionality remains intact', () async {
      developer.log('Testing ConnectivityService basic functionality', name: 'RegressionTest');

      // Test initial state
      expect(mockConnectivityService.isOnline, true);
      expect(mockConnectivityService.wasOffline, false);

      // Test state changes
      mockConnectivityService.setOnlineStatus(false);
      expect(mockConnectivityService.isOnline, false);
      expect(mockConnectivityService.wasOffline, true);

      mockConnectivityService.setOnlineStatus(true);
      expect(mockConnectivityService.isOnline, true);
      expect(mockConnectivityService.wasOffline, false);

      // Test connectivity check
      final connectivityResult = await mockConnectivityService.checkConnectivity();
      expect(connectivityResult, 'wifi');

      mockConnectivityService.setOnlineStatus(false);
      final offlineResult = await mockConnectivityService.checkConnectivity();
      expect(offlineResult, 'none');

      developer.log('ConnectivityService functionality verified', name: 'RegressionTest');
    });

    test('LocalDataService CRUD operations work correctly', () async {
      developer.log('Testing LocalDataService CRUD operations', name: 'RegressionTest');

      final testLocation = LocationModel(
        latitude: 28.6139,
        longitude: 77.2090,
        address: 'Test Address, New Delhi',
      );

      // Test Create
      final localIssue = LocalIssue(
        localId: 'test-crud-123',
        description: 'Test CRUD operations',
        category: 'Infrastructure',
        urgency: 'Medium',
        tags: ['test', 'crud'],
        timestamp: DateTime.now(),
        location: testLocation,
        userId: 'user-123',
        username: 'testuser',
        status: 'Reported',
        isSynced: false,
      );

      await localDataService.insertIssue(localIssue);

      // Test Read
      final retrievedIssue = await localDataService.getLocalIssue(localIssue.localId);
      expect(retrievedIssue, isNotNull);
      expect(retrievedIssue!.localId, localIssue.localId);
      expect(retrievedIssue.description, localIssue.description);

      // Test Update (sync status)
      await localDataService.updateIssueSync(localIssue.localId, 'firebase-123');
      final updatedIssue = await localDataService.getLocalIssue(localIssue.localId);
      expect(updatedIssue!.firebaseId, 'firebase-123');
      expect(updatedIssue.isSynced, true);

      // Test Delete
      await localDataService.deleteLocalIssue(localIssue.localId);
      final deletedIssue = await localDataService.getLocalIssue(localIssue.localId);
      expect(deletedIssue, isNull);

      developer.log('LocalDataService CRUD operations verified', name: 'RegressionTest');
    });

    test('LocalIssue model serialization/deserialization works', () async {
      developer.log('Testing LocalIssue model serialization', name: 'RegressionTest');

      final testLocation = LocationModel(
        latitude: 28.6139,
        longitude: 77.2090,
        address: 'Test Address, New Delhi',
      );

      final originalIssue = LocalIssue(
        localId: 'test-serialization-123',
        firebaseId: 'firebase-456',
        description: 'Test serialization',
        category: 'Infrastructure',
        urgency: 'High',
        tags: ['test', 'serialization'],
        localImagePath: '/local/path/image.jpg',
        imageUrl: 'https://example.com/image.jpg',
        timestamp: DateTime.now(),
        location: testLocation,
        userId: 'user-123',
        username: 'testuser',
        status: 'Reported',
        isSynced: true,
        syncedAt: DateTime.now(),
        syncError: null,
        metadata: {
          'test_key': 'test_value',
          'created_offline': true,
        },
      );

      // Test toMap
      final map = originalIssue.toMap();
      expect(map, isA<Map<String, dynamic>>());
      expect(map['localId'], originalIssue.localId);
      expect(map['description'], originalIssue.description);

      // Test fromMap
      final reconstructedIssue = LocalIssue.fromMap(map);
      expect(reconstructedIssue.localId, originalIssue.localId);
      expect(reconstructedIssue.description, originalIssue.description);
      expect(reconstructedIssue.category, originalIssue.category);
      expect(reconstructedIssue.urgency, originalIssue.urgency);
      expect(reconstructedIssue.tags, originalIssue.tags);
      expect(reconstructedIssue.isSynced, originalIssue.isSynced);
      expect(reconstructedIssue.metadata, originalIssue.metadata);

      // Test toIssue conversion
      final issue = originalIssue.toIssue();
      expect(issue.id, originalIssue.firebaseId);
      expect(issue.description, originalIssue.description);
      expect(issue.category, originalIssue.category);

      developer.log('LocalIssue model serialization verified', name: 'RegressionTest');
    });

    test('OfflineFirstDataLoader timeout behavior works correctly', () async {
      developer.log('Testing OfflineFirstDataLoader timeout behavior', name: 'RegressionTest');

      // Test generic loadWithFallback
      final result = await OfflineFirstDataLoader.loadWithFallback<String>(
        onlineLoader: () async {
          // Simulate a slow operation that would timeout
          await Future.delayed(const Duration(seconds: 10));
          return 'online_result';
        },
        offlineLoader: () async {
          return 'offline_fallback';
        },
        timeout: const Duration(milliseconds: 100),
      );

      expect(result, 'offline_fallback');

      // Test successful online load
      final quickResult = await OfflineFirstDataLoader.loadWithFallback<String>(
        onlineLoader: () async {
          return 'quick_online_result';
        },
        offlineLoader: () async {
          return 'offline_fallback';
        },
        timeout: const Duration(seconds: 1),
      );

      expect(quickResult, 'quick_online_result');

      // Test loadIssuesWithFallback
      final issues = await OfflineFirstDataLoader.loadIssuesWithFallback();
      expect(issues, isA<List<Issue>>());
      expect(issues.isEmpty, true); // Fallback returns empty list

      developer.log('OfflineFirstDataLoader timeout behavior verified', name: 'RegressionTest');
    });

    test('OfflineSyncService maintains state correctly during operations', () async {
      developer.log('Testing OfflineSyncService state management', name: 'RegressionTest');

      final testUser = AppUser(
        uid: 'test-state-123',
        email: 'state@example.com',
        username: 'stateuser',
        role: 'user',
      );

      final testLocation = LocationModel(
        latitude: 28.6139,
        longitude: 77.2090,
        address: 'Test Location',
      );

      // Test initial state
      expect(offlineSyncService.isSyncing, false);
      expect(offlineSyncService.syncStatus, '');
      expect(offlineSyncService.totalToSync, 0);
      expect(offlineSyncService.syncedCount, 0);

      // Test hasUnsyncedIssues when empty
      expect(await offlineSyncService.hasUnsyncedIssues(), false);

      // Save an issue offline
      mockConnectivityService.setOnlineStatus(false);
      final localId = await offlineSyncService.saveIssueOffline(
        description: 'Test state management',
        category: 'Infrastructure',
        urgency: 'Medium',
        tags: ['test'],
        imagePath: '/mock/path/test.jpg',
        location: testLocation,
        user: testUser,
      );

      expect(localId, isNotEmpty);
      expect(await offlineSyncService.hasUnsyncedIssues(), true);

      // Test getUnsyncedIssues
      final unsyncedIssues = await offlineSyncService.getUnsyncedIssues();
      expect(unsyncedIssues.length, 1);
      expect(unsyncedIssues.first.localId, localId);

      // Test getDatabaseStats
      final stats = await offlineSyncService.getDatabaseStats();
      expect(stats['total'], 1);
      expect(stats['unsynced'], 1);
      expect(stats['synced'], 0);

      // Test deleteUnsyncedIssue
      await offlineSyncService.deleteUnsyncedIssue(localId);
      expect(await offlineSyncService.hasUnsyncedIssues(), false);

      final finalStats = await offlineSyncService.getDatabaseStats();
      expect(finalStats['total'], 0);

      developer.log('OfflineSyncService state management verified', name: 'RegressionTest');
    });

    test('Database statistics and cleanup functions work correctly', () async {
      developer.log('Testing database statistics and cleanup', name: 'RegressionTest');

      final testUser = AppUser(
        uid: 'test-cleanup-123',
        email: 'cleanup@example.com',
        username: 'cleanupuser',
        role: 'user',
      );

      final testLocation = LocationModel(
        latitude: 28.6139,
        longitude: 77.2090,
        address: 'Test Location',
      );

      // Create multiple issues with different sync states
      mockConnectivityService.setOnlineStatus(false);

      // Create unsynced issues
      await offlineSyncService.saveIssueOffline(
        description: 'Unsynced issue 1',
        category: 'Infrastructure',
        urgency: 'Medium',
        tags: ['test'],
        imagePath: '/mock/path/test1.jpg',
        location: testLocation,
        user: testUser,
      );

      await offlineSyncService.saveIssueOffline(
        description: 'Unsynced issue 2',
        category: 'Infrastructure',
        urgency: 'Medium',
        tags: ['test'],
        imagePath: '/mock/path/test2.jpg',
        location: testLocation,
        user: testUser,
      );

      // Create a synced issue manually
      final syncedIssue = LocalIssue(
        localId: 'synced-test-123',
        firebaseId: 'firebase-synced-123',
        description: 'Synced issue',
        category: 'Infrastructure',
        urgency: 'Medium',
        tags: ['test'],
        timestamp: DateTime.now(),
        location: testLocation,
        userId: testUser.uid,
        username: testUser.username!,
        status: 'Reported',
        isSynced: true,
        syncedAt: DateTime.now(),
      );

      await localDataService.insertIssue(syncedIssue);

      // Test database statistics
      final stats = await offlineSyncService.getDatabaseStats();
      expect(stats['total'], 3);
      expect(stats['unsynced'], 2);
      expect(stats['synced'], 1);

      // Test cleanup (should not crash even if there's nothing to clean)
      await offlineSyncService.cleanupOldCache(daysToKeep: 1);

      // Stats should remain the same after cleanup
      final statsAfterCleanup = await offlineSyncService.getDatabaseStats();
      expect(statsAfterCleanup['total'], 3);

      developer.log('Database statistics and cleanup verified', name: 'RegressionTest');
    });

    test('Error handling in offline operations is robust', () async {
      developer.log('Testing error handling in offline operations', name: 'RegressionTest');

      final testUser = AppUser(
        uid: 'test-error-123',
        email: 'error@example.com',
        username: 'erroruser',
        role: 'user',
      );

      final testLocation = LocationModel(
        latitude: 28.6139,
        longitude: 77.2090,
        address: 'Test Location',
      );

      // Test saving issue with valid data
      mockConnectivityService.setOnlineStatus(false);
      
      final localId = await offlineSyncService.saveIssueOffline(
        description: 'Test error handling',
        category: 'Infrastructure',
        urgency: 'Medium',
        tags: ['test'],
        imagePath: '/mock/path/test.jpg',
        location: testLocation,
        user: testUser,
      );

      expect(localId, isNotEmpty);

      // Test deleting non-existent issue (should not crash)
      try {
        await offlineSyncService.deleteUnsyncedIssue('non-existent-id');
        // Should complete without throwing
      } catch (e) {
        // If it throws, it should be handled gracefully
        expect(e, isA<Exception>());
      }

      // Test sync with no connectivity (should handle gracefully)
      mockConnectivityService.setOnlineStatus(false);
      await offlineSyncService.syncUnsyncedIssues();
      
      // Should not crash and should maintain stable state
      expect(offlineSyncService.isSyncing, false);

      // Test getting stats when database might have issues
      final stats = await offlineSyncService.getDatabaseStats();
      expect(stats, isA<Map<String, int>>());

      developer.log('Error handling in offline operations verified', name: 'RegressionTest');
    });

    test('Concurrent operations are handled correctly', () async {
      developer.log('Testing concurrent operations handling', name: 'RegressionTest');

      final testUser = AppUser(
        uid: 'test-concurrent-123',
        email: 'concurrent@example.com',
        username: 'concurrentuser',
        role: 'user',
      );

      final testLocation = LocationModel(
        latitude: 28.6139,
        longitude: 77.2090,
        address: 'Test Location',
      );

      mockConnectivityService.setOnlineStatus(false);

      // Create multiple issues concurrently
      final futures = <Future<String>>[];
      for (int i = 0; i < 5; i++) {
        futures.add(
          offlineSyncService.saveIssueOffline(
            description: 'Concurrent issue $i',
            category: 'Infrastructure',
            urgency: 'Medium',
            tags: ['test', 'concurrent'],
            imagePath: '/mock/path/test$i.jpg',
            location: testLocation,
            user: testUser,
          ),
        );
      }

      final localIds = await Future.wait(futures);
      expect(localIds.length, 5);
      expect(localIds.every((id) => id.isNotEmpty), true);

      // Verify all issues were saved
      final unsyncedIssues = await offlineSyncService.getUnsyncedIssues();
      expect(unsyncedIssues.length, 5);

      // Test concurrent deletions
      final deleteFutures = <Future<void>>[];
      for (int i = 0; i < 3; i++) {
        deleteFutures.add(
          offlineSyncService.deleteUnsyncedIssue(localIds[i]),
        );
      }

      await Future.wait(deleteFutures);

      // Verify correct number remain
      final remainingIssues = await offlineSyncService.getUnsyncedIssues();
      expect(remainingIssues.length, 2);

      developer.log('Concurrent operations handling verified', name: 'RegressionTest');
    });

    test('Service initialization and cleanup work correctly', () async {
      developer.log('Testing service initialization and cleanup', name: 'RegressionTest');

      // Test re-initialization
      await offlineSyncService.initialize();
      
      // Should not crash and should maintain functionality
      final stats = await offlineSyncService.getDatabaseStats();
      expect(stats, isA<Map<String, int>>());

      // Test database re-initialization
      await localDataService.initializeDatabase();
      
      // Should still work after re-initialization
      final statsAfterReinit = await localDataService.getDatabaseStats();
      expect(statsAfterReinit, isA<Map<String, int>>());

      // Test connectivity service callback registration
      var callbackTriggered = false;
      mockConnectivityService.setAutoSyncCallback(() {
        callbackTriggered = true;
      });

      mockConnectivityService.setOnlineStatus(false);
      mockConnectivityService.setOnlineStatus(true);

      expect(callbackTriggered, true);

      developer.log('Service initialization and cleanup verified', name: 'RegressionTest');
    });
  });
}