// lib/services/local_data_service.dart
import 'dart:developer' as developer;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:modern_auth_app/models/local_issue_model.dart';
import 'package:modern_auth_app/models/issue_model.dart';

class LocalDataService {
  static const String _databaseName = 'nivaran_offline.db';
  static const int _databaseVersion = 1;
  
  // Table names
  static const String _localIssuesTable = 'local_issues';
  static const String _cachedIssuesTable = 'cached_issues';
  
  Database? _database;
  
  // Singleton pattern
  static final LocalDataService _instance = LocalDataService._internal();
  factory LocalDataService() => _instance;
  LocalDataService._internal();

  // Initialize database
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      String path = join(await getDatabasesPath(), _databaseName);
      developer.log('Initializing database at: $path', name: 'LocalDataService');
      
      return await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      developer.log('Error initializing database: $e', name: 'LocalDataService');
      rethrow;
    }
  }

  // Create database tables
  Future<void> _onCreate(Database db, int version) async {
    try {
      developer.log('Creating database tables', name: 'LocalDataService');
      
      // Create local_issues table
      await db.execute('''
        CREATE TABLE $_localIssuesTable (
          local_id TEXT PRIMARY KEY,
          firebase_id TEXT,
          description TEXT NOT NULL,
          category TEXT NOT NULL,
          urgency TEXT DEFAULT 'Medium',
          tags TEXT,
          local_image_path TEXT,
          image_url TEXT,
          timestamp INTEGER NOT NULL,
          location_data TEXT NOT NULL,
          user_id TEXT NOT NULL,
          username TEXT NOT NULL,
          status TEXT DEFAULT 'Reported',
          is_synced INTEGER DEFAULT 0,
          synced_at INTEGER,
          sync_error TEXT,
          metadata TEXT
        )
      ''');

      // Create cached_issues table for offline viewing
      await db.execute('''
        CREATE TABLE $_cachedIssuesTable (
          firebase_id TEXT PRIMARY KEY,
          issue_data TEXT NOT NULL,
          cached_at INTEGER NOT NULL,
          expires_at INTEGER NOT NULL
        )
      ''');

      // Create indexes for better performance
      await db.execute('CREATE INDEX idx_local_issues_synced ON $_localIssuesTable(is_synced)');
      await db.execute('CREATE INDEX idx_local_issues_user ON $_localIssuesTable(user_id)');
      await db.execute('CREATE INDEX idx_cached_issues_expires ON $_cachedIssuesTable(expires_at)');
      
      developer.log('Database tables created successfully', name: 'LocalDataService');
    } catch (e) {
      developer.log('Error creating database tables: $e', name: 'LocalDataService');
      rethrow;
    }
  }

  // Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    developer.log('Upgrading database from version $oldVersion to $newVersion', name: 'LocalDataService');
    // Handle future database schema changes here
  }

  // Initialize database (called during app startup)
  Future<void> initializeDatabase() async {
    try {
      await database;
      developer.log('Database initialized successfully', name: 'LocalDataService');
    } catch (e) {
      developer.log('Failed to initialize database: $e', name: 'LocalDataService');
      rethrow;
    }
  }

  // Insert a new local issue
  Future<void> insertIssue(LocalIssue issue) async {
    try {
      final db = await database;
      await db.insert(
        _localIssuesTable,
        issue.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      developer.log('Inserted local issue: ${issue.localId}', name: 'LocalDataService');
    } catch (e) {
      developer.log('Error inserting local issue: $e', name: 'LocalDataService');
      rethrow;
    }
  }

  // Get all unsynced issues
  Future<List<LocalIssue>> getUnsyncedIssues() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _localIssuesTable,
        where: 'is_synced = ?',
        whereArgs: [0],
        orderBy: 'timestamp DESC',
      );
      
      List<LocalIssue> issues = maps.map((map) => LocalIssue.fromMap(map)).toList();
      developer.log('Retrieved ${issues.length} unsynced issues', name: 'LocalDataService');
      return issues;
    } catch (e) {
      developer.log('Error getting unsynced issues: $e', name: 'LocalDataService');
      return [];
    }
  }

  // Get all cached issues for offline viewing
  Future<List<LocalIssue>> getCachedIssues() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _localIssuesTable,
        orderBy: 'timestamp DESC',
      );
      
      List<LocalIssue> issues = maps.map((map) => LocalIssue.fromMap(map)).toList();
      developer.log('Retrieved ${issues.length} cached issues', name: 'LocalDataService');
      return issues;
    } catch (e) {
      developer.log('Error getting cached issues: $e', name: 'LocalDataService');
      return [];
    }
  }

  // Update issue sync status
  Future<void> updateIssueSync(String localId, String firebaseId) async {
    try {
      final db = await database;
      await db.update(
        _localIssuesTable,
        {
          'firebase_id': firebaseId,
          'is_synced': 1,
          'synced_at': DateTime.now().millisecondsSinceEpoch,
          'sync_error': null,
        },
        where: 'local_id = ?',
        whereArgs: [localId],
      );
      developer.log('Updated sync status for issue: $localId -> $firebaseId', name: 'LocalDataService');
    } catch (e) {
      developer.log('Error updating issue sync status: $e', name: 'LocalDataService');
      rethrow;
    }
  }

  // Update issue sync error
  Future<void> updateIssueSyncError(String localId, String error) async {
    try {
      final db = await database;
      await db.update(
        _localIssuesTable,
        {
          'sync_error': error,
        },
        where: 'local_id = ?',
        whereArgs: [localId],
      );
      developer.log('Updated sync error for issue: $localId', name: 'LocalDataService');
    } catch (e) {
      developer.log('Error updating issue sync error: $e', name: 'LocalDataService');
      rethrow;
    }
  }

  // Delete a local issue
  Future<void> deleteLocalIssue(String localId) async {
    try {
      final db = await database;
      await db.delete(
        _localIssuesTable,
        where: 'local_id = ?',
        whereArgs: [localId],
      );
      developer.log('Deleted local issue: $localId', name: 'LocalDataService');
    } catch (e) {
      developer.log('Error deleting local issue: $e', name: 'LocalDataService');
      rethrow;
    }
  }

  // Get a specific local issue by ID
  Future<LocalIssue?> getLocalIssue(String localId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _localIssuesTable,
        where: 'local_id = ?',
        whereArgs: [localId],
        limit: 1,
      );
      
      if (maps.isNotEmpty) {
        return LocalIssue.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      developer.log('Error getting local issue: $e', name: 'LocalDataService');
      return null;
    }
  }

  // Get issues by user ID
  Future<List<LocalIssue>> getIssuesByUser(String userId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _localIssuesTable,
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'timestamp DESC',
      );
      
      List<LocalIssue> issues = maps.map((map) => LocalIssue.fromMap(map)).toList();
      developer.log('Retrieved ${issues.length} issues for user: $userId', name: 'LocalDataService');
      return issues;
    } catch (e) {
      developer.log('Error getting issues by user: $e', name: 'LocalDataService');
      return [];
    }
  }

  // Cache online issues for offline viewing
  Future<void> cacheOnlineIssues(List<Issue> issues) async {
    try {
      final db = await database;
      final batch = db.batch();
      
      for (Issue issue in issues) {
        LocalIssue localIssue = LocalIssue.fromIssue(issue);
        batch.insert(
          _localIssuesTable,
          localIssue.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      
      await batch.commit();
      developer.log('Cached ${issues.length} online issues', name: 'LocalDataService');
    } catch (e) {
      developer.log('Error caching online issues: $e', name: 'LocalDataService');
      rethrow;
    }
  }

  // Clear old cached data (keep only recent data)
  Future<void> clearOldCache({int daysToKeep = 7}) async {
    try {
      final db = await database;
      final cutoffTime = DateTime.now().subtract(Duration(days: daysToKeep)).millisecondsSinceEpoch;
      
      // Only delete synced issues that are older than cutoff
      int deletedCount = await db.delete(
        _localIssuesTable,
        where: 'is_synced = 1 AND timestamp < ?',
        whereArgs: [cutoffTime],
      );
      
      developer.log('Cleared $deletedCount old cached issues', name: 'LocalDataService');
    } catch (e) {
      developer.log('Error clearing old cache: $e', name: 'LocalDataService');
      rethrow;
    }
  }

  // Get database statistics
  Future<Map<String, int>> getDatabaseStats() async {
    try {
      final db = await database;
      
      final totalIssues = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $_localIssuesTable')
      ) ?? 0;
      
      final unsyncedIssues = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $_localIssuesTable WHERE is_synced = 0')
      ) ?? 0;
      
      final syncedIssues = totalIssues - unsyncedIssues;
      
      return {
        'total': totalIssues,
        'unsynced': unsyncedIssues,
        'synced': syncedIssues,
      };
    } catch (e) {
      developer.log('Error getting database stats: $e', name: 'LocalDataService');
      return {'total': 0, 'unsynced': 0, 'synced': 0};
    }
  }

  // Close database connection
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      developer.log('Database connection closed', name: 'LocalDataService');
    }
  }

  // Delete database (for testing or reset purposes)
  Future<void> deleteDatabase() async {
    try {
      String path = join(await getDatabasesPath(), _databaseName);
      await databaseFactory.deleteDatabase(path);
      _database = null;
      developer.log('Database deleted', name: 'LocalDataService');
    } catch (e) {
      developer.log('Error deleting database: $e', name: 'LocalDataService');
      rethrow;
    }
  }
}