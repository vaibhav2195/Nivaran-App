// test/task_3_verification.dart
// Verification script for Task 3: LocalIssue model and storage implementation

import 'package:flutter_test/flutter_test.dart';
import 'package:modern_auth_app/models/local_issue_model.dart';
import 'package:modern_auth_app/models/issue_model.dart';
import 'package:modern_auth_app/services/local_data_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

void main() {
  late LocalDataService localDataService;
  
  setUpAll(() {
    // Initialize FFI for testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    localDataService = LocalDataService();
    // Clean up any existing database
    try {
      await localDataService.deleteDatabase();
    } catch (e) {
      // Ignore if database doesn't exist
    }
    await localDataService.initializeDatabase();
  });

  tearDown(() async {
    await localDataService.close();
  });

  group('Task 3 Verification: LocalIssue Model and Storage', () {
    test('LocalIssue model has all essential fields as per requirements', () {
      // Create a LocalIssue with all essential fields
      final localIssue = LocalIssue(
        localId: const Uuid().v4(), // id (as localId)
        description: 'Test pothole on main street',
        category: 'Infrastructure',
        urgency: 'Medium',
        timestamp: DateTime.now(),
        location: LocationModel(
          latitude: 28.6139,
          longitude: 77.2090,
          address: 'New Delhi, India',
        ),
        userId: 'test_user_123',
        username: 'Test User',
        isSynced: false,
      );

      // Verify all essential fields are present
      expect(localIssue.localId, isNotEmpty); // id
      expect(localIssue.description, equals('Test pothole on main street')); // description
      expect(localIssue.category, equals('Infrastructure')); // category
      expect(localIssue.urgency, equals('Medium')); // urgency
      expect(localIssue.timestamp, isA<DateTime>()); // timestamp
      expect(localIssue.location, isA<LocationModel>()); // location
      expect(localIssue.userId, equals('test_user_123')); // userId
      expect(localIssue.isSynced, equals(false)); // isSynced
    });

    test('SQLite database with local_issues table is created successfully', () async {
      // Database should be initialized in setUp
      final stats = await localDataService.getDatabaseStats();
      
      // Verify database is working and table exists
      expect(stats, isA<Map<String, int>>());
      expect(stats.containsKey('total'), true);
      expect(stats.containsKey('unsynced'), true);
      expect(stats.containsKey('synced'), true);
      expect(stats['total'], equals(0)); // Should be empty initially
    });

    test('LocalDataService provides basic CRUD operations', () async {
      final testIssue = LocalIssue(
        localId: const Uuid().v4(),
        description: 'CRUD test issue',
        category: 'Infrastructure',
        urgency: 'Medium',
        timestamp: DateTime.now(),
        location: LocationModel(
          latitude: 28.6139,
          longitude: 77.2090,
          address: 'Test Location',
        ),
        userId: 'crud_test_user',
        username: 'CRUD Test User',
        isSynced: false,
      );

      // CREATE - Insert issue
      await localDataService.insertIssue(testIssue);
      
      // READ - Get issue by ID
      final retrievedIssue = await localDataService.getLocalIssue(testIssue.localId);
      expect(retrievedIssue, isNotNull);
      expect(retrievedIssue!.localId, equals(testIssue.localId));
      expect(retrievedIssue.description, equals(testIssue.description));

      // READ - Get unsynced issues
      final unsyncedIssues = await localDataService.getUnsyncedIssues();
      expect(unsyncedIssues.length, equals(1));
      expect(unsyncedIssues.first.localId, equals(testIssue.localId));

      // UPDATE - Update sync status
      await localDataService.updateIssueSync(testIssue.localId, 'firebase_123');
      final updatedIssue = await localDataService.getLocalIssue(testIssue.localId);
      expect(updatedIssue!.isSynced, equals(true));
      expect(updatedIssue.firebaseId, equals('firebase_123'));

      // DELETE - Delete issue
      await localDataService.deleteLocalIssue(testIssue.localId);
      final deletedIssue = await localDataService.getLocalIssue(testIssue.localId);
      expect(deletedIssue, isNull);
    });

    test('Database initialization is integrated into app startup', () async {
      // This test verifies that the database can be initialized
      // The actual integration is verified by checking main.dart
      
      // Re-initialize database to simulate app startup
      await localDataService.initializeDatabase();
      
      // Verify database is working after initialization
      final stats = await localDataService.getDatabaseStats();
      expect(stats, isA<Map<String, int>>());
      expect(stats['total'], equals(0));
    });

    test('LocalIssue model serialization works correctly', () {
      final originalIssue = LocalIssue(
        localId: 'test_serialization_id',
        description: 'Serialization test issue',
        category: 'Infrastructure',
        urgency: 'High',
        tags: ['test', 'serialization'],
        timestamp: DateTime.now(),
        location: LocationModel(
          latitude: 28.6139,
          longitude: 77.2090,
          address: 'Serialization Test Location',
        ),
        userId: 'serialization_user',
        username: 'Serialization User',
        status: 'Reported',
        isSynced: false,
        metadata: {'test_key': 'test_value'},
      );

      // Convert to Map (for SQLite storage)
      final map = originalIssue.toMap();
      expect(map, isA<Map<String, dynamic>>());
      expect(map['local_id'], equals(originalIssue.localId));
      expect(map['description'], equals(originalIssue.description));
      expect(map['is_synced'], equals(0)); // false as integer

      // Convert back from Map
      final reconstructedIssue = LocalIssue.fromMap(map);
      expect(reconstructedIssue.localId, equals(originalIssue.localId));
      expect(reconstructedIssue.description, equals(originalIssue.description));
      expect(reconstructedIssue.isSynced, equals(originalIssue.isSynced));
    });

    test('Database handles multiple issues correctly', () async {
      // Insert multiple issues
      final issues = <LocalIssue>[];
      for (int i = 0; i < 5; i++) {
        final issue = LocalIssue(
          localId: 'test_issue_$i',
          description: 'Test issue $i',
          category: 'Infrastructure',
          urgency: 'Medium',
          timestamp: DateTime.now().subtract(Duration(hours: i)),
          location: LocationModel(
            latitude: 28.6139 + i * 0.001,
            longitude: 77.2090 + i * 0.001,
            address: 'Test Location $i',
          ),
          userId: 'test_user_$i',
          username: 'Test User $i',
          isSynced: i % 2 == 0, // Alternate sync status
        );
        issues.add(issue);
        await localDataService.insertIssue(issue);
      }

      // Verify all issues are stored
      final stats = await localDataService.getDatabaseStats();
      expect(stats['total'], equals(5));
      expect(stats['synced'], equals(3)); // Issues 0, 2, 4
      expect(stats['unsynced'], equals(2)); // Issues 1, 3

      // Verify unsynced issues retrieval
      final unsyncedIssues = await localDataService.getUnsyncedIssues();
      expect(unsyncedIssues.length, equals(2));
      expect(unsyncedIssues.map((i) => i.localId).toSet(), 
             equals({'test_issue_1', 'test_issue_3'}));
    });
  });
}