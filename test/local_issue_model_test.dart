// test/local_issue_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_auth_app/models/local_issue_model.dart';
import 'package:modern_auth_app/models/issue_model.dart';

void main() {
  group('LocalIssue Model Tests', () {
    test('should create LocalIssue from map', () {
      final testMap = {
        'local_id': 'test-local-123',
        'firebase_id': null,
        'description': 'Test pothole on main road',
        'category': 'Roads',
        'urgency': 'Medium',
        'tags': '["pothole", "urgent"]',
        'local_image_path': '/test/path/image.jpg',
        'image_url': null,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'location_data': '{"latitude": 12.9716, "longitude": 77.5946, "address": "Test Address"}',
        'user_id': 'user-123',
        'username': 'testuser',
        'status': 'Reported',
        'is_synced': 0,
        'synced_at': null,
        'sync_error': null,
        'metadata': '{"created_offline": true}',
      };

      final localIssue = LocalIssue.fromMap(testMap);

      expect(localIssue.localId, 'test-local-123');
      expect(localIssue.firebaseId, null);
      expect(localIssue.description, 'Test pothole on main road');
      expect(localIssue.category, 'Roads');
      expect(localIssue.urgency, 'Medium');
      expect(localIssue.tags, ['pothole', 'urgent']);
      expect(localIssue.localImagePath, '/test/path/image.jpg');
      expect(localIssue.userId, 'user-123');
      expect(localIssue.username, 'testuser');
      expect(localIssue.isSynced, false);
      expect(localIssue.metadata['created_offline'], true);
    });

    test('should convert LocalIssue to map', () {
      final testLocation = LocationModel(
        latitude: 12.9716,
        longitude: 77.5946,
        address: 'Test Address, Bangalore',
      );

      final localIssue = LocalIssue(
        localId: 'test-local-456',
        description: 'Test water leak',
        category: 'Water',
        urgency: 'Medium',
        tags: ['leak', 'urgent'],
        localImagePath: '/test/path/water.jpg',
        timestamp: DateTime.now(),
        location: testLocation,
        userId: 'user-456',
        username: 'testuser2',
        metadata: {'created_offline': true},
      );

      final map = localIssue.toMap();

      expect(map['local_id'], 'test-local-456');
      expect(map['description'], 'Test water leak');
      expect(map['category'], 'Water');
      expect(map['urgency'], 'Medium');
      expect(map['tags'], '["leak","urgent"]');
      expect(map['local_image_path'], '/test/path/water.jpg');
      expect(map['user_id'], 'user-456');
      expect(map['username'], 'testuser2');
      expect(map['is_synced'], 0);
      expect(map['metadata'], '{"created_offline":true}');
    });

    test('should convert LocalIssue to Issue', () {
      final testLocation = LocationModel(
        latitude: 12.9716,
        longitude: 77.5946,
        address: 'Test Address, Bangalore',
      );

      final localIssue = LocalIssue(
        localId: 'test-local-789',
        firebaseId: 'firebase-789',
        description: 'Test garbage issue',
        category: 'Waste',
        urgency: 'Medium',
        tags: ['garbage', 'smell'],
        imageUrl: 'https://example.com/image.jpg',
        timestamp: DateTime.now(),
        location: testLocation,
        userId: 'user-789',
        username: 'testuser3',
        isSynced: true,
      );

      final issue = localIssue.toIssue();

      expect(issue.id, 'firebase-789');
      expect(issue.description, 'Test garbage issue');
      expect(issue.category, 'Waste');
      expect(issue.urgency, 'Medium');
      expect(issue.tags, ['garbage', 'smell']);
      expect(issue.imageUrl, 'https://example.com/image.jpg');
      expect(issue.userId, 'user-789');
      expect(issue.username, 'testuser3');
      expect(issue.upvotes, 0);
      expect(issue.downvotes, 0);
      expect(issue.commentsCount, 0);
    });

    test('should create copy with updated fields', () {
      final testLocation = LocationModel(
        latitude: 12.9716,
        longitude: 77.5946,
        address: 'Test Address, Bangalore',
      );

      final originalIssue = LocalIssue(
        localId: 'test-local-copy',
        description: 'Original description',
        category: 'Roads',
        urgency: 'Medium',
        tags: ['original'],
        timestamp: DateTime.now(),
        location: testLocation,
        userId: 'user-copy',
        username: 'originaluser',
        isSynced: false,
      );

      final updatedIssue = originalIssue.copyWith(
        firebaseId: 'firebase-copy',
        description: 'Updated description',
        isSynced: true,
        syncedAt: DateTime.now(),
      );

      expect(updatedIssue.localId, 'test-local-copy'); // unchanged
      expect(updatedIssue.firebaseId, 'firebase-copy'); // updated
      expect(updatedIssue.description, 'Updated description'); // updated
      expect(updatedIssue.category, 'Roads'); // unchanged
      expect(updatedIssue.isSynced, true); // updated
      expect(updatedIssue.syncedAt, isNotNull); // updated
      expect(updatedIssue.userId, 'user-copy'); // unchanged
      expect(updatedIssue.username, 'originaluser'); // unchanged
    });

    test('should handle empty tags correctly', () {
      final testLocation = LocationModel(
        latitude: 12.9716,
        longitude: 77.5946,
        address: 'Test Address, Bangalore',
      );

      final localIssue = LocalIssue(
        localId: 'test-no-tags',
        description: 'Issue without tags',
        category: 'General',
        timestamp: DateTime.now(),
        location: testLocation,
        userId: 'user-no-tags',
        username: 'testuser',
      );

      expect(localIssue.tags, isEmpty);
      
      final map = localIssue.toMap();
      expect(map['tags'], '[]');
      
      final recreatedIssue = LocalIssue.fromMap(map);
      expect(recreatedIssue.tags, isEmpty);
    });
  });
}