// lib/models/local_issue_model.dart
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:modern_auth_app/models/issue_model.dart';

class LocalIssue {
  final String localId;           // UUID for local identification
  final String? firebaseId;       // Firebase document ID (null if unsynced)
  final String description;
  final String category;
  final String urgency;           // Always "Medium" for offline issues
  final List<String> tags;
  final String? localImagePath;   // Local file path
  final String? imageUrl;         // Cloudinary URL (null if unsynced)
  final DateTime timestamp;
  final LocationModel location;
  final String userId;
  final String username;
  final String status;            // Always "Reported" for offline issues
  final bool isSynced;           // Sync status
  final DateTime? syncedAt;      // When it was synced
  final String? syncError;       // Error message if sync failed
  final Map<String, dynamic> metadata; // Additional offline-specific data

  LocalIssue({
    required this.localId,
    this.firebaseId,
    required this.description,
    required this.category,
    this.urgency = 'Medium',
    List<String>? tags,
    this.localImagePath,
    this.imageUrl,
    required this.timestamp,
    required this.location,
    required this.userId,
    required this.username,
    this.status = 'Reported',
    this.isSynced = false,
    this.syncedAt,
    this.syncError,
    Map<String, dynamic>? metadata,
  }) : tags = tags ?? [],
       metadata = metadata ?? {};

  // Convert LocalIssue to Map for SQLite storage
  Map<String, dynamic> toMap() {
    return {
      'local_id': localId,
      'firebase_id': firebaseId,
      'description': description,
      'category': category,
      'urgency': urgency,
      'tags': jsonEncode(tags),
      'local_image_path': localImagePath,
      'image_url': imageUrl,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'location_data': jsonEncode(location.toMap()),
      'user_id': userId,
      'username': username,
      'status': status,
      'is_synced': isSynced ? 1 : 0,
      'synced_at': syncedAt?.millisecondsSinceEpoch,
      'sync_error': syncError,
      'metadata': jsonEncode(metadata),
    };
  }

  // Create LocalIssue from SQLite Map
  factory LocalIssue.fromMap(Map<String, dynamic> map) {
    return LocalIssue(
      localId: map['local_id'] as String,
      firebaseId: map['firebase_id'] as String?,
      description: map['description'] as String,
      category: map['category'] as String,
      urgency: map['urgency'] as String? ?? 'Medium',
      tags: List<String>.from(jsonDecode(map['tags'] as String? ?? '[]')),
      localImagePath: map['local_image_path'] as String?,
      imageUrl: map['image_url'] as String?,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      location: LocationModel.fromMap(jsonDecode(map['location_data'] as String)),
      userId: map['user_id'] as String,
      username: map['username'] as String,
      status: map['status'] as String? ?? 'Reported',
      isSynced: (map['is_synced'] as int) == 1,
      syncedAt: map['synced_at'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['synced_at'] as int)
          : null,
      syncError: map['sync_error'] as String?,
      metadata: Map<String, dynamic>.from(jsonDecode(map['metadata'] as String? ?? '{}')),
    );
  }

  // Create LocalIssue from regular Issue (for caching)
  factory LocalIssue.fromIssue(Issue issue, {String? localImagePath}) {
    return LocalIssue(
      localId: issue.id, // Use Firebase ID as local ID for cached issues
      firebaseId: issue.id,
      description: issue.description,
      category: issue.category,
      urgency: issue.urgency ?? 'Medium',
      tags: issue.tags ?? [],
      localImagePath: localImagePath,
      imageUrl: issue.imageUrl,
      timestamp: issue.timestamp.toDate(),
      location: issue.location,
      userId: issue.userId,
      username: issue.username,
      status: issue.status,
      isSynced: true, // Already synced since it came from Firebase
      syncedAt: DateTime.now(),
    );
  }

  // Convert LocalIssue to regular Issue (for display)
  Issue toIssue() {
    return Issue(
      id: firebaseId ?? localId,
      description: description,
      category: category,
      urgency: urgency,
      tags: tags,
      imageUrl: imageUrl ?? '',
      timestamp: Timestamp.fromDate(timestamp),
      location: location,
      userId: userId,
      username: username,
      status: status,
      upvotes: 0,
      downvotes: 0,
      voters: {},
      commentsCount: 0,
      affectedUsersCount: 1,
      affectedUserIds: [userId],
    );
  }

  // Create a copy with updated fields
  LocalIssue copyWith({
    String? localId,
    String? firebaseId,
    String? description,
    String? category,
    String? urgency,
    List<String>? tags,
    String? localImagePath,
    String? imageUrl,
    DateTime? timestamp,
    LocationModel? location,
    String? userId,
    String? username,
    String? status,
    bool? isSynced,
    DateTime? syncedAt,
    String? syncError,
    Map<String, dynamic>? metadata,
  }) {
    return LocalIssue(
      localId: localId ?? this.localId,
      firebaseId: firebaseId ?? this.firebaseId,
      description: description ?? this.description,
      category: category ?? this.category,
      urgency: urgency ?? this.urgency,
      tags: tags ?? this.tags,
      localImagePath: localImagePath ?? this.localImagePath,
      imageUrl: imageUrl ?? this.imageUrl,
      timestamp: timestamp ?? this.timestamp,
      location: location ?? this.location,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      status: status ?? this.status,
      isSynced: isSynced ?? this.isSynced,
      syncedAt: syncedAt ?? this.syncedAt,
      syncError: syncError ?? this.syncError,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'LocalIssue(localId: $localId, firebaseId: $firebaseId, description: $description, isSynced: $isSynced)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocalIssue && other.localId == localId;
  }

  @override
  int get hashCode => localId.hashCode;
}