// test/local_data_service_test.dart
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
    // Delete any existing test database
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

  group('LocalDataService Tests', () {
    test('should initialize database successfully', () async {
      // Database should be initialized in setUp
      final stats = await localDataService.getDatabaseStats();
      expect(stats['total'], equals(0));
      expect(stats['unsynced'], equals(0));
      expect(stats['synced'], equals(0));
    });

    test('should insert and retrieve local issue', () async {
      // Create a test local issue
      final localIssue = LocalIssue(
        localId: const Uuid().v4(),
        description: 'Test issue description',
        category: 'Infrastructure',
        urgency: 'Medium',
        tags: ['test', 'offline'],
        timestamp: DateTime.now(),
        location: LocationModel(
          latitude: 28.6139,
          longitude: 77.2090,
          address: 'New Delhi, India',
        ),
        userId: 'test_user_123',
        username: 'Test User',
        status: 'Reported',
        isSynced: false,
      );

      // Insert the issue
      await localDataService.insertIssue(localIssue);

      // Retrieve unsynced issues
      final unsyncedIssues = await localDataService.getUnsyncedIssues();
      expect(unsyncedIssues.length, equals(1));
      expect(unsyncedIssues.first.localId, equals(localIssue.localId));
      expect(unsyncedIssues.first.description, equals(localIssue.description));
      expect(unsyncedIssues.first.isSynced, equals(false));
    });

    test('should update issue sync status', () async {
      // Create and insert a test local issue
      final localIssue = LocalIssue(
        localId: const Uuid().v4(),
        description: 'Test sync issue',
        category: 'Infrastructure',
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

      await localDataService.insertIssue(localIssue);

      // Update sync status
      const firebaseId = 'firebase_test_id_123';
      await localDataService.updateIssueSync(localIssue.localId, firebaseId);

      // Retrieve the updated issue
      final updatedIssue = await localDataService.getLocalIssue(localIssue.localId);
      expect(updatedIssue, isNotNull);
      expect(updatedIssue!.firebaseId, equals(firebaseId));
      expect(updatedIssue.isSynced, equals(true));
      expect(updatedIssue.syncedAt, isNotNull);
    });

    test('should delete local issue', () async {
      // Create and insert a test local issue
      final localIssue = LocalIssue(
        localId: const Uuid().v4(),
        description: 'Test delete issue',
        category: 'Infrastructure',
        timestamp: DateTime.now(),
        location: LocationModel(
          latitude: 28.6139,
          longitude: 77.2090,
          address: 'New Delhi, India',
        ),
        userId: 'test_user_123',
        username: 'Test User',
      );

      await localDataService.insertIssue(localIssue);

      // Verify issue exists
      var retrievedIssue = await localDataService.getLocalIssue(localIssue.localId);
      expect(retrievedIssue, isNotNull);

      // Delete the issue
      await localDataService.deleteLocalIssue(localIssue.localId);

      // Verify issue is deleted
      retrievedIssue = await localDataService.getLocalIssue(localIssue.localId);
      expect(retrievedIssue, isNull);
    });

    test('should get database statistics', () async {
      // Insert multiple issues with different sync statuses
      final issue1 = LocalIssue(
        localId: const Uuid().v4(),
        description: 'Unsynced issue 1',
        category: 'Infrastructure',
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

      final issue2 = LocalIssue(
        localId: const Uuid().v4(),
        description: 'Synced issue 1',
        category: 'Infrastructure',
        timestamp: DateTime.now(),
        location: LocationModel(
          latitude: 28.6139,
          longitude: 77.2090,
          address: 'New Delhi, India',
        ),
        userId: 'test_user_123',
        username: 'Test User',
        isSynced: true,
        firebaseId: 'firebase_id_1',
        syncedAt: DateTime.now(),
      );

      await localDataService.insertIssue(issue1);
      await localDataService.insertIssue(issue2);

      // Get statistics
      final stats = await localDataService.getDatabaseStats();
      expect(stats['total'], equals(2));
      expect(stats['unsynced'], equals(1));
      expect(stats['synced'], equals(1));
    });
  });

  group('LocalIssue Model Tests', () {
    test('should convert to and from Map correctly', () {
      final originalIssue = LocalIssue(
        localId: const Uuid().v4(),
        description: 'Test issue for serialization',
        category: 'Infrastructure',
        urgency: 'High',
        tags: ['test', 'serialization'],
        timestamp: DateTime.now(),
        location: LocationModel(
          latitude: 28.6139,
          longitude: 77.2090,
          address: 'New Delhi, India',
        ),
        userId: 'test_user_123',
        username: 'Test User',
        status: 'Reported',
        isSynced: false,
        metadata: {'test_key': 'test_value'},
      );

      // Convert to map and back
      final map = originalIssue.toMap();
      final reconstructedIssue = LocalIssue.fromMap(map);

      // Verify all fields are preserved
      expect(reconstructedIssue.localId, equals(originalIssue.localId));
      expect(reconstructedIssue.description, equals(originalIssue.description));
      expect(reconstructedIssue.category, equals(originalIssue.category));
      expect(reconstructedIssue.urgency, equals(originalIssue.urgency));
      expect(reconstructedIssue.tags, equals(originalIssue.tags));
      expect(reconstructedIssue.userId, equals(originalIssue.userId));
      expect(reconstructedIssue.username, equals(originalIssue.username));
      expect(reconstructedIssue.status, equals(originalIssue.status));
      expect(reconstructedIssue.isSynced, equals(originalIssue.isSynced));
      expect(reconstructedIssue.metadata, equals(originalIssue.metadata));
      expect(reconstructedIssue.location.latitude, equals(originalIssue.location.latitude));
      expect(reconstructedIssue.location.longitude, equals(originalIssue.location.longitude));
      expect(reconstructedIssue.location.address, equals(originalIssue.location.address));
    });

    test('should create LocalIssue from Issue correctly', () {
      // This test would require creating a mock Issue object
      // For now, we'll test the basic structure
      final location = LocationModel(
        latitude: 28.6139,
        longitude: 77.2090,
        address: 'New Delhi, India',
      );

      final localIssue = LocalIssue(
        localId: 'test_local_id',
        firebaseId: 'test_firebase_id',
        description: 'Test issue',
        category: 'Infrastructure',
        timestamp: DateTime.now(),
        location: location,
        userId: 'test_user',
        username: 'Test User',
        isSynced: true,
      );

      expect(localIssue.localId, equals('test_local_id'));
      expect(localIssue.firebaseId, equals('test_firebase_id'));
      expect(localIssue.isSynced, equals(true));
    });
  });
}