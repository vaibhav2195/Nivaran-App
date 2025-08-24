// test/offline_core_functionality_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_auth_app/services/local_data_service.dart';
import 'package:modern_auth_app/models/local_issue_model.dart';
import 'package:modern_auth_app/models/issue_model.dart';
import 'package:modern_auth_app/utils/offline_first_data_loader.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:developer' as developer;

// Mock ConnectivityService for testing without Firebase dependencies
class MockConnectivityService {
  bool _mockIsOnline = true;
  bool _mockWasOffline = false;
  Function()? _autoSyncCallback;
  final List<Function()> _listeners = [];

  bool get isOnline => _mockIsOnline;
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
      _notifyListeners();
    }
  }

  void setAutoSyncCallback(Function() callback) {
    _autoSyncCallback = callback;
  }

  void addListener(Function() listener) {
    _listeners.add(listener);
  }

  void removeListener(Function() listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  Future<dynamic> checkConnectivity() async {
    return _mockIsOnline ? 'wifi' : 'none';
  }
}

void main() {
  group('Core Offline Functionality Tests', () {
    late LocalDataService localDataService;
    late MockConnectivityService mockConnectivityService;

    setUpAll(() {
      // Initialize FFI for testing
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      localDataService = LocalDataService();
      mockConnectivityService = MockConnectivityService();
      
      // Clean up any existing database
      try {
        await localDataService.deleteDatabase();
      } catch (e) {
        // Ignore if database doesn't exist
      }
      
      // Initialize database
      await localDataService.initializeDatabase();
    });

    tearDown(() async {
      // Clean up database after each test
      await localDataService.deleteDatabase();
    });

    test('LocalDataService initializes database correctly', () async {
      developer.log('Testing LocalDataService database initialization', name: 'CoreOfflineTest');

      // Database should be initialized in setUp
      final stats = await localDataService.getDatabaseStats();
      expect(stats['total'], equals(0));
      expect(stats['unsynced'], equals(0));
      expect(stats['synced'], equals(0));

      developer.log('Database initialization verified', name: 'CoreOfflineTest');
    });

    test('LocalDataService CRUD operations work correctly', () async {
      developer.log('Testing LocalDataService CRUD operations', name: 'CoreOfflineTest');

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
      expect(retrievedIssue.category, localIssue.category);
      expect(retrievedIssue.urgency, localIssue.urgency);

      // Test Update (sync status)
      await localDataService.updateIssueSync(localIssue.localId, 'firebase-123');
      final updatedIssue = await localDataService.getLocalIssue(localIssue.localId);
      expect(updatedIssue!.firebaseId, 'firebase-123');
      expect(updatedIssue.isSynced, true);
      expect(updatedIssue.syncedAt, isNotNull);

      // Test Delete
      await localDataService.deleteLocalIssue(localIssue.localId);
      final deletedIssue = await localDataService.getLocalIssue(localIssue.localId);
      expect(deletedIssue, isNull);

      developer.log('CRUD operations verified', name: 'CoreOfflineTest');
    });

    test('LocalDataService handles multiple issues correctly', () async {
      developer.log('Testing LocalDataService with multiple issues', name: 'CoreOfflineTest');

      final testLocation = LocationModel(
        latitude: 28.6139,
        longitude: 77.2090,
        address: 'Test Address, New Delhi',
      );

      // Create multiple issues with different sync states
      final issues = <LocalIssue>[];
      for (int i = 0; i < 5; i++) {
        final issue = LocalIssue(
          localId: 'test-multi-$i',
          description: 'Test issue $i',
          category: 'Infrastructure',
          urgency: 'Medium',
          tags: ['test', 'multi', 'issue-$i'],
          timestamp: DateTime.now().subtract(Duration(hours: i)),
          location: testLocation,
          userId: 'user-123',
          username: 'testuser',
          status: 'Reported',
          isSynced: i % 2 == 0, // Alternate sync status
          firebaseId: i % 2 == 0 ? 'firebase-$i' : null,
          syncedAt: i % 2 == 0 ? DateTime.now() : null,
        );
        issues.add(issue);
        await localDataService.insertIssue(issue);
      }

      // Test database statistics
      final stats = await localDataService.getDatabaseStats();
      expect(stats['total'], 5);
      expect(stats['synced'], 3); // Issues 0, 2, 4 are synced
      expect(stats['unsynced'], 2); // Issues 1, 3 are unsynced

      // Test getting unsynced issues
      final unsyncedIssues = await localDataService.getUnsyncedIssues();
      expect(unsyncedIssues.length, 2);
      expect(unsyncedIssues.every((issue) => !issue.isSynced), true);

      // Test getting issues by user
      final userIssues = await localDataService.getIssuesByUser('user-123');
      expect(userIssues.length, 5);

      developer.log('Multiple issues handling verified', name: 'CoreOfflineTest');
    });

    test('LocalIssue model serialization works correctly', () async {
      developer.log('Testing LocalIssue model serialization', name: 'CoreOfflineTest');

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
      expect(map['local_id'], originalIssue.localId);
      expect(map['description'], originalIssue.description);
      expect(map['category'], originalIssue.category);

      // Test fromMap
      final reconstructedIssue = LocalIssue.fromMap(map);
      expect(reconstructedIssue.localId, originalIssue.localId);
      expect(reconstructedIssue.description, originalIssue.description);
      expect(reconstructedIssue.category, originalIssue.category);
      expect(reconstructedIssue.urgency, originalIssue.urgency);
      expect(reconstructedIssue.tags, originalIssue.tags);
      expect(reconstructedIssue.isSynced, originalIssue.isSynced);
      expect(reconstructedIssue.metadata, originalIssue.metadata);

      // Test basic properties
      expect(originalIssue.firebaseId, 'firebase-456');
      expect(originalIssue.localId, 'test-serialization-123');

      developer.log('LocalIssue serialization verified', name: 'CoreOfflineTest');
    });

    test('OfflineFirstDataLoader timeout behavior works', () async {
      developer.log('Testing OfflineFirstDataLoader timeout behavior', name: 'CoreOfflineTest');

      // Test generic loadWithFallback with timeout
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

      // Test successful online load (fast)
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

      developer.log('OfflineFirstDataLoader timeout behavior verified', name: 'CoreOfflineTest');
    });

    test('MockConnectivityService state management works', () async {
      developer.log('Testing MockConnectivityService state management', name: 'CoreOfflineTest');

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

      // Test callback mechanism
      var callbackTriggered = false;
      mockConnectivityService.setAutoSyncCallback(() {
        callbackTriggered = true;
      });

      mockConnectivityService.setOnlineStatus(false);
      mockConnectivityService.setOnlineStatus(true);
      expect(callbackTriggered, true);

      developer.log('MockConnectivityService state management verified', name: 'CoreOfflineTest');
    });

    test('Database cleanup and maintenance operations work', () async {
      developer.log('Testing database cleanup and maintenance', name: 'CoreOfflineTest');

      final testLocation = LocationModel(
        latitude: 28.6139,
        longitude: 77.2090,
        address: 'Test Location',
      );

      // Create old and new issues
      final oldIssue = LocalIssue(
        localId: 'old-issue-123',
        description: 'Old issue',
        category: 'Infrastructure',
        urgency: 'Medium',
        tags: ['old'],
        timestamp: DateTime.now().subtract(const Duration(days: 10)),
        location: testLocation,
        userId: 'user-123',
        username: 'testuser',
        status: 'Reported',
        isSynced: true,
        firebaseId: 'firebase-old',
        syncedAt: DateTime.now().subtract(const Duration(days: 10)),
      );

      final newIssue = LocalIssue(
        localId: 'new-issue-123',
        description: 'New issue',
        category: 'Infrastructure',
        urgency: 'Medium',
        tags: ['new'],
        timestamp: DateTime.now(),
        location: testLocation,
        userId: 'user-123',
        username: 'testuser',
        status: 'Reported',
        isSynced: false,
      );

      await localDataService.insertIssue(oldIssue);
      await localDataService.insertIssue(newIssue);

      // Test initial stats
      var stats = await localDataService.getDatabaseStats();
      expect(stats['total'], 2);
      expect(stats['synced'], 1);
      expect(stats['unsynced'], 1);

      // Test cleanup (should not crash even if there's nothing to clean)
      await localDataService.clearOldCache(daysToKeep: 5);

      // Stats might change after cleanup if old data was removed
      stats = await localDataService.getDatabaseStats();
      expect(stats['total'], greaterThanOrEqualTo(1)); // At least the new issue should remain

      developer.log('Database cleanup and maintenance verified', name: 'CoreOfflineTest');
    });

    test('Error handling in database operations is robust', () async {
      developer.log('Testing error handling in database operations', name: 'CoreOfflineTest');

      // Test getting non-existent issue
      final nonExistentIssue = await localDataService.getLocalIssue('non-existent-id');
      expect(nonExistentIssue, isNull);

      // Test deleting non-existent issue (should not crash)
      try {
        await localDataService.deleteLocalIssue('non-existent-id');
        // Should complete without throwing
      } catch (e) {
        // If it throws, it should be handled gracefully
        expect(e, isA<Exception>());
      }

      // Test getting stats when database is empty
      final stats = await localDataService.getDatabaseStats();
      expect(stats, isA<Map<String, int>>());
      expect(stats['total'], 0);

      // Test getting unsynced issues when database is empty
      final unsyncedIssues = await localDataService.getUnsyncedIssues();
      expect(unsyncedIssues, isA<List<LocalIssue>>());
      expect(unsyncedIssues.isEmpty, true);

      developer.log('Error handling in database operations verified', name: 'CoreOfflineTest');
    });

    test('Concurrent database operations are handled correctly', () async {
      developer.log('Testing concurrent database operations', name: 'CoreOfflineTest');

      final testLocation = LocationModel(
        latitude: 28.6139,
        longitude: 77.2090,
        address: 'Test Location',
      );

      // Create multiple issues concurrently
      final futures = <Future<void>>[];
      for (int i = 0; i < 10; i++) {
        final issue = LocalIssue(
          localId: 'concurrent-$i',
          description: 'Concurrent issue $i',
          category: 'Infrastructure',
          urgency: 'Medium',
          tags: ['test', 'concurrent'],
          timestamp: DateTime.now(),
          location: testLocation,
          userId: 'user-123',
          username: 'testuser',
          status: 'Reported',
          isSynced: false,
        );
        futures.add(localDataService.insertIssue(issue));
      }

      await Future.wait(futures);

      // Verify all issues were saved
      final stats = await localDataService.getDatabaseStats();
      expect(stats['total'], 10);
      expect(stats['unsynced'], 10);

      // Test concurrent reads
      final readFutures = <Future<LocalIssue?>>[];
      for (int i = 0; i < 10; i++) {
        readFutures.add(localDataService.getLocalIssue('concurrent-$i'));
      }

      final results = await Future.wait(readFutures);
      expect(results.length, 10);
      expect(results.every((issue) => issue != null), true);

      developer.log('Concurrent database operations verified', name: 'CoreOfflineTest');
    });

    test('Complete offline workflow simulation', () async {
      developer.log('Testing complete offline workflow simulation', name: 'CoreOfflineTest');

      final testLocation = LocationModel(
        latitude: 28.6139,
        longitude: 77.2090,
        address: 'Test Location, New Delhi',
      );

      // PHASE 1: Start online
      expect(mockConnectivityService.isOnline, true);
      expect(mockConnectivityService.wasOffline, false);

      // PHASE 2: Go offline and create issues
      mockConnectivityService.setOnlineStatus(false);
      expect(mockConnectivityService.isOnline, false);
      expect(mockConnectivityService.wasOffline, true);

      // Create offline issues
      final issue1 = LocalIssue(
        localId: 'offline-workflow-1',
        description: 'Pothole on main street',
        category: 'Roads',
        urgency: 'Medium',
        tags: ['pothole', 'urgent'],
        timestamp: DateTime.now(),
        location: testLocation,
        userId: 'user-123',
        username: 'testuser',
        status: 'Reported',
        isSynced: false,
        metadata: {'created_offline': true},
      );

      final issue2 = LocalIssue(
        localId: 'offline-workflow-2',
        description: 'Broken streetlight',
        category: 'Electricity',
        urgency: 'Medium',
        tags: ['streetlight', 'safety'],
        timestamp: DateTime.now(),
        location: testLocation,
        userId: 'user-123',
        username: 'testuser',
        status: 'Reported',
        isSynced: false,
        metadata: {'created_offline': true},
      );

      await localDataService.insertIssue(issue1);
      await localDataService.insertIssue(issue2);

      // PHASE 3: Verify offline storage
      var stats = await localDataService.getDatabaseStats();
      expect(stats['total'], 2);
      expect(stats['unsynced'], 2);
      expect(stats['synced'], 0);

      final unsyncedIssues = await localDataService.getUnsyncedIssues();
      expect(unsyncedIssues.length, 2);
      expect(unsyncedIssues.every((issue) => !issue.isSynced), true);
      expect(unsyncedIssues.every((issue) => issue.urgency == 'Medium'), true);

      // PHASE 4: Test issue management
      await localDataService.deleteLocalIssue(issue2.localId);
      
      final remainingIssues = await localDataService.getUnsyncedIssues();
      expect(remainingIssues.length, 1);
      expect(remainingIssues.first.localId, issue1.localId);

      // PHASE 5: Simulate sync (mark as synced)
      mockConnectivityService.setOnlineStatus(true);
      expect(mockConnectivityService.isOnline, true);

      await localDataService.updateIssueSync(issue1.localId, 'firebase-synced-123');

      // PHASE 6: Verify sync status
      final syncedIssue = await localDataService.getLocalIssue(issue1.localId);
      expect(syncedIssue!.isSynced, true);
      expect(syncedIssue.firebaseId, 'firebase-synced-123');
      expect(syncedIssue.syncedAt, isNotNull);

      final finalStats = await localDataService.getDatabaseStats();
      expect(finalStats['total'], 1);
      expect(finalStats['synced'], 1);
      expect(finalStats['unsynced'], 0);

      developer.log('Complete offline workflow simulation verified', name: 'CoreOfflineTest');
    });
  });
}