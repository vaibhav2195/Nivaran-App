import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:modern_auth_app/l10n/app_localizations.dart';
import '../services/connectivity_service.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityService>(
      builder: (context, connectivityService, child) {
        final l10n = AppLocalizations.of(context);

        if (connectivityService.isOnline) {
          return const SizedBox.shrink(); // Online, show nothing
        } else {
          // If offline, show the offline banner
          return Container(
            width: double.infinity,
            color: Colors.red.shade700,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off, color: Colors.white, size: 18),
                    const SizedBox(width: 12),
                    Text(
                      l10n?.offlineMode ?? 'Offline Mode',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      },
    );
  }
}
