import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:math';
import 'dart:developer' as developer;

import '../models/issue_model.dart';
import '../utils/location_utils.dart';
import './image_comparison_service.dart';

class DuplicateDetectionService {
  final FirebaseFirestore _firestore;
  static const double _duplicateRadiusMeters = 200.0; // 200 meters radius for duplicate detection
  
  DuplicateDetectionService({FirebaseFirestore? firestore}) 
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Checks if a new issue might be a duplicate of existing issues within 200 meters
  /// Returns a list of potential duplicate issues
  Future<List<Issue>> findPotentialDuplicates(Issue newIssue) async {
    try {
      // Get all issues from Firestore
      final QuerySnapshot issuesSnapshot = await _firestore
          .collection('issues')
          .get();
      
      // Convert to Issue objects
      final List<Issue> allIssues = issuesSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Issue.fromFirestore(data, doc.id);
      }).toList();
      
      // Filter issues within 200 meters of the new issue
      final List<Issue> nearbyIssues = allIssues.where((existingIssue) {
        // Skip comparing with itself if it's an existing issue being updated
        if (existingIssue.id == newIssue.id) return false;
        
        // Check if within 200 meters using the Haversine formula
        return LocationUtils.isLocationWithinRadius(
          newIssue.location.latitude,
          newIssue.location.longitude,
          existingIssue.location.latitude,
          existingIssue.location.longitude,
          _duplicateRadiusMeters / 1000 // Convert meters to kilometers
        );
      }).toList();
      
      return nearbyIssues;
    } catch (e) {
      developer.log('Error finding potential duplicates: ${e.toString()}', name: 'DuplicateDetectionService');
      return [];
    }
  }
  
  /// Determines if a new issue is likely a duplicate based on location proximity
  /// and image similarity.
  /// Returns the ID of the duplicate issue if found, otherwise null
  Future<String?> checkForDuplicate(Issue newIssue, List<File> newIssueImages) async {
    try {
      final List<Issue> potentialDuplicates = await findPotentialDuplicates(newIssue);
      
      if (potentialDuplicates.isEmpty) {
        return null; // No potential duplicates found
      }
      
      // First filter by location proximity
      List<Issue> proximityFilteredIssues = [];
      Map<String, double> issueDistances = {};
      
      for (final issue in potentialDuplicates) {
        final distance = LocationUtils.calculateDistance(
          newIssue.location.latitude,
          newIssue.location.longitude,
          issue.location.latitude,
          issue.location.longitude
        );
        
        // Store the distance for later use
        issueDistances[issue.id] = distance;
        
        // Only consider issues within the duplicate radius
        if (distance <= (_duplicateRadiusMeters / 1000)) {
          proximityFilteredIssues.add(issue);
        }
      }
      
      if (proximityFilteredIssues.isEmpty) {
        return null; // No issues within the duplicate radius
      }
      
      // If we have images to compare, use image comparison
      if (newIssueImages.isNotEmpty) {
        // Sort issues by proximity for more efficient processing
        proximityFilteredIssues.sort((a, b) => 
          (issueDistances[a.id] ?? double.infinity)
            .compareTo(issueDistances[b.id] ?? double.infinity));
        
        // Check each potential duplicate with image comparison
        for (final issue in proximityFilteredIssues) {
          // Skip if the potential duplicate has no images
          if (issue.evidenceImages.isEmpty) continue;
          
          // Convert image URLs to File objects
          // Note: In a real implementation, you would need to download these images first
          // This is a simplified version that assumes the images are already available locally
          List<File> existingIssueImages = [];
          for (final imageUrl in issue.evidenceImages) {
            // This is a placeholder - in a real app, you would download the image
            // or access it from a local cache
            final localPath = await _getLocalPathForImage(imageUrl);
            if (localPath != null) {
              existingIssueImages.add(File(localPath));
            }
          }
          
          if (existingIssueImages.isEmpty) continue;
          
          // Compare the image sets
          final bool areImagesSimilar = await ImageComparisonService.areImageSetsDuplicates(
            newIssueImages, 
            existingIssueImages
          );
          
          // If images are similar, this is likely a duplicate
          if (areImagesSimilar) {
            return issue.id;
          }
        }
      } else {
        // If no images to compare, fall back to closest issue by distance
        Issue closestIssue = proximityFilteredIssues.reduce((a, b) => 
          (issueDistances[a.id] ?? double.infinity) < (issueDistances[b.id] ?? double.infinity) ? a : b);
        return closestIssue.id;
      }
      
      return null;
    } catch (e) {
      developer.log('Error checking for duplicates: ${e.toString()}', name: 'DuplicateDetectionService');
      return null;
    }
  }
  
  /// Helper method to get local path for an image URL
  /// In a real implementation, this would download the image or check a local cache
  Future<String?> _getLocalPathForImage(String imageUrl) async {
    // This is a placeholder implementation
    // In a real app, you would download the image or check a local cache
    try {
      // For demonstration purposes only - this would be replaced with actual logic
      // to download or retrieve the image from cache
      return null;
    } catch (e) {
      developer.log('Error getting local path for image: ${e.toString()}', name: 'DuplicateDetectionService');
      return null;
    }
  }
  
  /// Marks an issue as a duplicate of another issue
  Future<bool> markAsDuplicate(String issueId, String duplicateOfIssueId) async {
    try {
      await _firestore.collection('issues').doc(issueId).update({
        'duplicateOfIssueId': duplicateOfIssueId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      developer.log('Error marking issue as duplicate: ${e.toString()}', name: 'DuplicateDetectionService');
      return false;
    }
  }
}