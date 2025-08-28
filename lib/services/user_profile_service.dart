// lib/services/user_profile_service.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // For token type
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_user_model.dart';
import '../utils/offline_first_data_loader.dart';
import 'fcm_token_service.dart';
import 'dart:developer' as developer;

class UserProfileService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AppUser? _currentUserProfile;
  AppUser? get currentUserProfile => _currentUserProfile;

  bool _isLoadingProfile = true;
  bool get isLoadingProfile => _isLoadingProfile;

  UserProfileService() {
    developer.log(
      "UserProfileService: Initializing and listening to authStateChanges.",
      name: "UserProfileService",
    );
    _auth.authStateChanges().listen(_onAuthStateChanged);
    if (_auth.currentUser != null) {
      _fetchUserProfile(_auth.currentUser!);
    } else {
      _isLoadingProfile = false;
    }
  }

  Future<void> _onAuthStateChanged(User? authUser) async {
    developer.log(
      "UserProfileService: Auth state changed. User: ${authUser?.uid}",
      name: "UserProfileService",
    );
    if (authUser == null) {
      _currentUserProfile = null;
      _isLoadingProfile = false;
      notifyListeners();
      return;
    }
    await _fetchUserProfile(authUser);
    await FCMTokenService.registerToken(); // Register FCM token on auth change
  }

  Future<void> fetchAndSetCurrentUserProfile() async {
    User? authUser = _auth.currentUser;
    if (authUser != null) {
      await _fetchUserProfile(authUser);
      await FCMTokenService.registerToken(); // Also register token on explicit fetch
    } else {
      _currentUserProfile = null;
      _isLoadingProfile = false;
      notifyListeners();
    }
  }

  Future<AppUser?> _fetchUserProfile(User authUser) async {
    if (_isLoadingProfile && _currentUserProfile?.uid == authUser.uid) {
      // Already loading or loaded for this user
      // return _currentUserProfile; // Can cause issues if called rapidly
    }

    _isLoadingProfile = true;
    if (hasListeners) {
      notifyListeners();
    }

    try {
      // Use OfflineFirstDataLoader to prevent Firebase hangs
      _currentUserProfile =
          await OfflineFirstDataLoader.loadUserProfileWithFallback(authUser);

      if (_currentUserProfile != null) {
        // Persist the user's UID locally to indicate a cached profile
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_user_uid', authUser.uid);
        developer.log(
          "UserProfileService: Profile loaded for ${authUser.uid}. Role: ${_currentUserProfile?.role}, Dept: ${_currentUserProfile?.department}",
          name: "UserProfileService",
        );

        // Subscribe to notification topics based on user role
        await _subscribeToNotificationTopics();
      } else {
        developer.log(
          "UserProfileService: Failed to load profile for ${authUser.uid}",
          name: "UserProfileService",
        );
      }
    } catch (e, s) {
      developer.log(
        "UserProfileService: Error fetching user profile for ${authUser.uid}: $e",
        name: "UserProfileService",
        error: e,
        stackTrace: s,
      );
      _currentUserProfile = null;
    } finally {
      _isLoadingProfile = false;
      notifyListeners();
    }
    return _currentUserProfile;
  }

  // Subscribe to notification topics based on user profile
  Future<void> _subscribeToNotificationTopics() async {
    if (_currentUserProfile != null) {
      await FCMTokenService.subscribeToTopics(
        _currentUserProfile!.role,
        department: _currentUserProfile!.department,
      );
    }
  }

  void clearUserProfile() {
    _currentUserProfile = null;
    _isLoadingProfile = false;

    notifyListeners();
    developer.log(
      "UserProfileService: Profile cleared.",
      name: "UserProfileService",
    );
  }

  Future<bool> hasCachedUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedUid = prefs.getString('cached_user_uid');
    developer.log(
      "Checking for cached user profile. Found UID: $cachedUid",
      name: "UserProfileService",
    );
    return cachedUid != null && cachedUid.isNotEmpty;
  }
}
