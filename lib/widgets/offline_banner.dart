import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:modern_auth_app/l10n/app_localizations.dart';
import '../services/connectivity_service.dart';
import '../services/offline_sync_service.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final connectivityService = Provider.of<ConnectivityService>(context);
    final l10n = AppLocalizations.of(context);

    return StreamBuilder<ConnectivityResult>(
      stream: connectivityService.connectivityStream,
      builder: (context, snapshot) {
        final isOffline = snapshot.data == ConnectivityResult.none;
        if (!isOffline) {
          // If online, check if we are syncing
          return Consumer<OfflineSyncService>(
            builder: (context, offlineService, child) {
              if (offlineService.isSyncing) {
                return Material(
                  color: Colors.orange.shade700,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                        ),
                        const SizedBox(width: 12),
                        Text(l10n?.syncingIssues ?? 'Syncing issues...', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox.shrink(); // Not syncing, show nothing
            },
          );
        }

        // If offline, show the offline banner
        return Material(
          color: Colors.red.shade700,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wifi_off, color: Colors.white, size: 18),
                const SizedBox(width: 12),
                Text(l10n?.offlineMode ?? 'Offline Mode', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      },
    );
  }
}
