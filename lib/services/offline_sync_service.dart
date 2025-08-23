import 'dart:developer' as developer;
import 'dart:io'; // For File
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart'; // For Uuid
import 'package:cloud_firestore/cloud_firestore.dart'; // For Timestamp
import '../models/issue_model.dart';
import '../models/local_issue_model.dart';
import 'auth_service.dart';
import 'connectivity_service.dart';
import 'firestore_service.dart';
import 'image_upload_service.dart';

class OfflineSyncService extends ChangeNotifier {
  final Isar _isar;
  final ConnectivityService _connectivityService;
  final AuthService _authService;
  final FirestoreService _firestoreService;
  final ImageUploadService _imageUploadService;

  bool _isOffline = false;
  bool get isOffline => _isOffline;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  OfflineSyncService(
    this._isar,
    this._connectivityService,
    this._authService,
    this._firestoreService,
    this._imageUploadService,
  );

  Future<void> initialize() async {
    _connectivityService.connectivityStream.listen((connectivityResult) {
      if (connectivityResult == ConnectivityResult.none) {
        _isOffline = true;
        notifyListeners();
      } else {
        _isOffline = false;
        _syncUnsyncedIssues();
        notifyListeners();
      }
    });
  }

  Future<void> saveIssueLocally(Issue issue, String localImagePath) async {
    final localIssue = LocalIssue()
      ..description = issue.description
      ..category = issue.category
      ..urgency = issue.urgency ?? 'Low' // Default urgency if not provided
      ..tags = issue.tags ?? []
      ..imageUrl = issue.imageUrl
      ..timestamp = issue.timestamp.toDate() // Convert Timestamp to DateTime
      ..isSynced = false
      ..isAiAnalysisDone = false
      ..localImagePath = localImagePath;
    await _isar.writeTxn(() async {
      await _isar.localIssues.put(localIssue);
    });
    notifyListeners();
  }

  Future<void> _syncUnsyncedIssues() async {
    if (_isSyncing) return;

    _isSyncing = true;
    notifyListeners();

    final unsyncedIssues = await _isar.localIssues.filter().isSyncedEqualTo(false).findAll();

    for (var localIssue in unsyncedIssues) {
      try {
        String? uploadedImageUrl = localIssue.imageUrl;
        if (localIssue.localImagePath != null && localIssue.localImagePath!.isNotEmpty) {
          uploadedImageUrl = await _imageUploadService.uploadImage(File(localIssue.localImagePath!));
          // Delete local image after upload
          // final file = File(localIssue.localImagePath!);
          // if (await file.exists()) {
          //   await file.delete();
          // }
        }

        // Convert LocalIssue to Issue for Firestore upload
        // Generate a new ID for the issue as it's being synced for the first time
        final String newIssueId = const Uuid().v4();
        final issueToUpload = Issue(
          id: newIssueId,
          description: localIssue.description,
          category: localIssue.category,
          urgency: localIssue.urgency,
          tags: localIssue.tags,
          imageUrl: uploadedImageUrl ?? '', // Ensure imageUrl is not null
          timestamp: Timestamp.fromDate(localIssue.timestamp), // Convert DateTime to Timestamp
          location: LocationModel(latitude: 0.0, longitude: 0.0, address: 'Offline Report'), // Placeholder
          userId: _authService.getCurrentUser()?.uid ?? 'anonymous', // Use current user ID
          username: _authService.getCurrentUser()?.displayName ?? 'Anonymous', // Use current username
          status: 'Reported', // Default status for new issues
          upvotes: 0,
          downvotes: 0,
          voters: {},
          commentsCount: 0,
        );

        await _firestoreService.addIssue(issueToUpload.toMap()); // Pass as map

        // Mock AI analysis for urgency
        if (!localIssue.isAiAnalysisDone) {
          // Placeholder for AI analysis
          // For now, just mark as done
          localIssue.urgency = 'Low'; // Default or mock value
          localIssue.isAiAnalysisDone = true;
        }

        localIssue.isSynced = true;
        localIssue.localImagePath = null; // Clear local path after sync
        await _isar.writeTxn(() async {
          await _isar.localIssues.put(localIssue);
        });
      } catch (e) {
        developer.log('Error syncing issue ${localIssue.issueId}: $e', name: 'OfflineSyncService');
        // Log error and potentially implement retry logic
      }
    }
    _isSyncing = false;
    notifyListeners();
  }

  Future<void> refreshCachedIssues() async {
    if (!_isOffline) {
      final fetchedIssues = await _firestoreService.getIssues(); // This method needs to be added to FirestoreService
      await _isar.writeTxn(() async {
        await _isar.localIssues.filter().isSyncedEqualTo(true).deleteAll(); // Clear only synced issues
        for (var issue in fetchedIssues) {
          final localIssue = LocalIssue()
            ..issueId = issue.id
            ..description = issue.description
            ..category = issue.category
            ..urgency = issue.urgency ?? 'Low'
            ..tags = issue.tags ?? []
            ..imageUrl = issue.imageUrl
            ..timestamp = issue.timestamp.toDate()
            ..isSynced = true
            ..isAiAnalysisDone = true
            ..localImagePath = null;
          await _isar.localIssues.put(localIssue);
        }
      });
      notifyListeners();
    }
  }

  Future<List<LocalIssue>> getUnsyncedIssues() async {
    return await _isar.localIssues.filter().isSyncedEqualTo(false).findAll();
  }

  Future<void> deleteLocalIssue(int id) async {
    await _isar.writeTxn(() async {
      await _isar.localIssues.delete(id);
    });
    notifyListeners();
  }
  Future<bool> hasCachedIssues() async {
    final count = await _isar.localIssues.count();
    return count > 0;
  }
}
