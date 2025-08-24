// test/simple_toissue_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_auth_app/models/local_issue_model.dart';
import 'package:modern_auth_app/models/issue_model.dart';

void main() {
  test('LocalIssue toIssue conversion works', () {
    final testLocation = LocationModel(
      latitude: 28.6139,
      longitude: 77.2090,
      address: 'Test Address, New Delhi',
    );

    final localIssue = LocalIssue(
      localId: 'test-local-123',
      firebaseId: 'firebase-456',
      description: 'Test issue',
      category: 'Infrastructure',
      urgency: 'High',
      tags: ['test'],
      timestamp: DateTime.now(),
      location: testLocation,
      userId: 'user-123',
      username: 'testuser',
      status: 'Reported',
      isSynced: true,
    );

    print('LocalIssue firebaseId: ${localIssue.firebaseId}');
    print('LocalIssue localId: ${localIssue.localId}');

    final issue = localIssue.toIssue();
    
    print('Issue id: ${issue.id}');
    print('Issue description: ${issue.description}');

    expect(issue.id, isNotNull);
    expect(issue.id, 'firebase-456');
    expect(issue.description, 'Test issue');
  });
}