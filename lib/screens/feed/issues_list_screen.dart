// lib/screens/feed/issues_list_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:developer' as developer;
import 'package:modern_auth_app/l10n/app_localizations.dart';
import 'package:provider/provider.dart'; // Add provider import
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../widgets/issue_card.dart'; // Uses IssueCard
import '../../models/issue_model.dart';
import '../../models/local_issue_model.dart'; // Import LocalIssue
import '../../services/location_service.dart';
import '../../services/offline_sync_service.dart'; // Import OfflineSyncService
import '../../services/connectivity_service.dart'; // Import ConnectivityService
import '../../utils/location_utils.dart';

class IssuesListScreen extends StatefulWidget {
  const IssuesListScreen({super.key});

  @override
  State<IssuesListScreen> createState() => _IssuesListScreenState();
}

class _IssuesListScreenState extends State<IssuesListScreen> {
  String _currentLocationDisplay = "Nearby";
  bool _isFetchingLocation = false;
  bool _isProximityFilterEnabled = true; // Default to enabled
  final LocationService _locationService = LocationService();
  Position? _currentPosition; // Store current position for filtering
  static const double _proximityRadiusKm = 10.0; // 10km radius for proximity filtering

  late OfflineSyncService _offlineSyncService;
  late ConnectivityService _connectivityService;
  bool _isOffline = false;
  List<LocalIssue> _localIssues = [];

  @override
  void initState() {
    super.initState();
    _offlineSyncService = Provider.of<OfflineSyncService>(context, listen: false);
    _connectivityService = Provider.of<ConnectivityService>(context, listen: false);
    _checkConnectivityAndLoadIssues();
    _connectivityService.connectivityStream.listen((result) {
      final isOffline = result == ConnectivityResult.none;
      if (_isOffline != isOffline) {
        setState(() {
          _isOffline = isOffline;
        });
        _checkConnectivityAndLoadIssues(); // Re-check and load when connectivity changes
      }
    });
    _fetchCurrentLocationAndUpdateDisplay();
  }

  Future<void> _checkConnectivityAndLoadIssues() async {
    final connectivityResult = await _connectivityService.checkConnectivity();
    setState(() {
      _isOffline = connectivityResult == ConnectivityResult.none;
    });

    if (_isOffline) {
      final localIssues = await _offlineSyncService.getUnsyncedIssues();
      setState(() {
        _localIssues = localIssues;
      });
    } else {
      // When online, the StreamBuilder will handle loading from Firestore.
      // We might want to clear local issues if they are now synced.
      setState(() {
        _localIssues = [];
      });
    }
  }


  Future<void> _requestLocationPermission() async {
    var status = await Permission.locationWhenInUse.status;
    if (status.isDenied) {
      status = await Permission.locationWhenInUse.request();
    }
    if (status.isPermanentlyDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission is permanently denied. Please enable it in settings.'),
            action: SnackBarAction(label: 'Open Settings', onPressed: openAppSettings),
          ),
        );
      }
    }
  }

  Future<void> _fetchCurrentLocationAndUpdateDisplay() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _isFetchingLocation = true;
      _currentLocationDisplay = "Fetching location...";
    });

    await _requestLocationPermission();

    var status = await Permission.locationWhenInUse.status;
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied. Showing general feed.')),
        );
        setState(() {
          _currentLocationDisplay = "All Issues";
          _isProximityFilterEnabled = false; // Disable proximity filter if no permission
          _isFetchingLocation = false;
        });
      }
      return;
    }

    try {
      final Position? position = await _locationService.getCurrentPosition();

      if (position != null) {
        // Store position for filtering
        _currentPosition = position;

        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (mounted && placemarks.isNotEmpty) {
          final Placemark place = placemarks.first;
          String displayAddress = "";

          if (place.street != null && place.street!.isNotEmpty) {
            displayAddress += place.street!;
          } else if (place.thoroughfare != null && place.thoroughfare!.isNotEmpty) {
            displayAddress += place.thoroughfare!;
          }

          if (place.subLocality != null && place.subLocality!.isNotEmpty) {
            if (displayAddress.isNotEmpty) displayAddress += ", ";
            displayAddress += place.subLocality!;
          } else if (place.locality != null && place.locality!.isNotEmpty) {
            if (displayAddress.isNotEmpty) displayAddress += ", ";
            displayAddress += place.locality!;
          }

          if (displayAddress.isEmpty) {
            displayAddress = place.locality ?? place.administrativeArea ?? l10n!.location;
          }

          if (displayAddress.length > 30) {
            displayAddress = '${displayAddress.substring(0, 27)}...';
          }

          if (mounted) {
            setState(() {
              _currentLocationDisplay = _isProximityFilterEnabled
                  ? "${displayAddress.isNotEmpty ? displayAddress : "Unnamed Area"} (10km radius)"
                  : displayAddress.isNotEmpty ? displayAddress : "Unnamed Area";
            });
          }
        } else if (mounted) {
          setState(() {
            _currentLocationDisplay = _isProximityFilterEnabled
                ? "Current Location (10km radius)"
                : l10n!.location;
          });
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not fetch location data.')),
        );
        setState(() {
          _currentLocationDisplay = "Location Unavailable";
          _isProximityFilterEnabled = false; // Disable proximity filter if location unavailable
        });
      }
    } catch (e) {
      developer.log('Error fetching location in IssuesListScreen: ${e.toString()}', name: 'IssuesListScreen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error determining location: Check permissions and services.')),
        );
        setState(() {
          _currentLocationDisplay = "Location Error";
          _isProximityFilterEnabled = false; // Disable proximity filter on error
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingLocation = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.location_on_outlined, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _isFetchingLocation ? l10n!.location : _currentLocationDisplay,
                style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          // Toggle for proximity filter
          Tooltip(
            message: _isProximityFilterEnabled ? "Showing issues within 10km" : "Showing all issues",
            child: Switch(
              value: _isProximityFilterEnabled,
              onChanged: (value) {
                setState(() {
                  _isProximityFilterEnabled = value;
                  if (value && _currentPosition == null) {
                    // If enabling proximity filter but no position, fetch it
                    _fetchCurrentLocationAndUpdateDisplay();
                  }
                });
              },
            ),
          ),
        ],
      ),
      body: _isOffline ? _buildOfflineBody(l10n) : _buildOnlineBody(l10n),
    );
  }

  Widget _buildOfflineBody(AppLocalizations? l10n) {
    if (_localIssues.isEmpty) {
      return const Center(child: Text("No locally saved issues."));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _localIssues.length,
      itemBuilder: (context, index) {
        final localIssue = _localIssues[index];
        final issue = Issue.fromLocalIssue(localIssue);
        return IssueCard(issue: issue);
      },
    );
  }

  Widget _buildOnlineBody(AppLocalizations? l10n) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('issues')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !_isFetchingLocation) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          developer.log('Firestore Error: ${snapshot.error}', name: 'IssuesListScreen');
          return Center(child: Text(l10n!.issueDetails));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No issues reported yet. Be the first!'));
        }

        final issuesDocs = snapshot.data!.docs;
        final List<Issue> allIssues = issuesDocs.map((doc) {
          final issueData = doc.data() as Map<String, dynamic>;
          return Issue.fromFirestore(issueData, doc.id);
        }).toList();

        // Apply proximity filter if enabled and location is available
        List<Issue> displayedIssues = allIssues;
        if (_isProximityFilterEnabled && _currentPosition != null) {
          displayedIssues = allIssues.where((issue) {
            return LocationUtils.isLocationWithinRadius(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
              issue.location.latitude,
              issue.location.longitude,
              _proximityRadiusKm
            );
          }).toList();
        }

        if (displayedIssues.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('No issues found in your area.'),
                if (_isProximityFilterEnabled)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isProximityFilterEnabled = false;
                      });
                    },
                    child: Text(l10n!.issuesFeed),
                  ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: displayedIssues.length,
          itemBuilder: (context, index) {
            final issue = displayedIssues[index];
            // Each issue is rendered using IssueCard, which handles image display
            return IssueCard(issue: issue);
          },
        );
      },
    );
  }
}
