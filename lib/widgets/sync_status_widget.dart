// lib/widgets/sync_status_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/offline_sync_service.dart';


class SyncStatusWidget extends StatelessWidget {
  final bool showOnlyWhenSyncing;
  final EdgeInsetsGeometry? padding;

  const SyncStatusWidget({
    super.key,
    this.showOnlyWhenSyncing = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<OfflineSyncService>(
      builder: (context, syncService, child) {
        
        // Don't show anything if not syncing and showOnlyWhenSyncing is true
        if (showOnlyWhenSyncing && !syncService.isSyncing) {
          return const SizedBox.shrink();
        }

        // Don't show if there's no status message
        if (syncService.syncStatus.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  // Show loading indicator when syncing
                  if (syncService.isSyncing) ...[
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ] else ...[
                    // Show success/error icon when not syncing
                    Icon(
                      syncService.syncStatus.contains('complete') || 
                      syncService.syncStatus.contains('successfully')
                          ? Icons.check_circle
                          : syncService.syncStatus.contains('failed') || 
                            syncService.syncStatus.contains('error')
                              ? Icons.error
                              : Icons.info,
                      color: syncService.syncStatus.contains('complete') || 
                             syncService.syncStatus.contains('successfully')
                          ? Colors.green
                          : syncService.syncStatus.contains('failed') || 
                            syncService.syncStatus.contains('error')
                              ? Colors.red
                              : Colors.blue,
                      size: 16,
                    ),
                    const SizedBox(width: 12),
                  ],
                  
                  // Status text
                  Expanded(
                    child: Text(
                      syncService.syncStatus,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: syncService.isSyncing 
                            ? Colors.blue[700]
                            : syncService.syncStatus.contains('complete') || 
                              syncService.syncStatus.contains('successfully')
                                ? Colors.green[700]
                                : syncService.syncStatus.contains('failed') || 
                                  syncService.syncStatus.contains('error')
                                    ? Colors.red[700]
                                    : Colors.grey[700],
                      ),
                    ),
                  ),
                  
                  // Progress indicator when syncing
                  if (syncService.isSyncing && syncService.totalToSync > 0) ...[
                    const SizedBox(width: 8),
                    Text(
                      '${syncService.syncedCount}/${syncService.totalToSync}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class SyncStatusSnackBar {
  static void show(BuildContext context, OfflineSyncService syncService) {
    if (syncService.syncStatus.isEmpty) return;

    final messenger = ScaffoldMessenger.of(context);
    
    // Clear any existing snackbars
    messenger.clearSnackBars();
    
    final snackBar = SnackBar(
      content: Row(
        children: [
          if (syncService.isSyncing) ...[
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
          ] else ...[
            Icon(
              syncService.syncStatus.contains('complete') || 
              syncService.syncStatus.contains('successfully')
                  ? Icons.check_circle
                  : syncService.syncStatus.contains('failed') || 
                    syncService.syncStatus.contains('error')
                      ? Icons.error
                      : Icons.info,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(syncService.syncStatus),
          ),
        ],
      ),
      backgroundColor: syncService.isSyncing 
          ? Colors.blue[600]
          : syncService.syncStatus.contains('complete') || 
            syncService.syncStatus.contains('successfully')
              ? Colors.green[600]
              : syncService.syncStatus.contains('failed') || 
                syncService.syncStatus.contains('error')
                  ? Colors.red[600]
                  : Colors.grey[600],
      duration: syncService.isSyncing 
          ? const Duration(seconds: 30) // Longer duration for syncing
          : const Duration(seconds: 4),
      behavior: SnackBarBehavior.floating,
    );
    
    messenger.showSnackBar(snackBar);
  }
}