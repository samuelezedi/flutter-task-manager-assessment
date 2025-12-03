import 'package:flutter/material.dart';

/// Widget for displaying sync status and manual sync button
class SyncIndicator extends StatelessWidget {
  final bool isOnline;
  final bool isSyncing;
  final int pendingSyncCount;
  final VoidCallback onSyncTap;

  const SyncIndicator({
    super.key,
    required this.isOnline,
    required this.isSyncing,
    required this.pendingSyncCount,
    required this.onSyncTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Online/Offline indicator
        Icon(
          isOnline ? Icons.cloud_done : Icons.cloud_off,
          size: 20,
          color: isOnline ? Colors.green : Colors.grey,
        ),
        const SizedBox(width: 8),
        // Pending sync count badge
        if (pendingSyncCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$pendingSyncCount',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        const SizedBox(width: 8),
        // Sync button
        IconButton(
          icon: isSyncing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.sync),
          onPressed: isOnline && !isSyncing ? onSyncTap : null,
          tooltip: isOnline
              ? (isSyncing ? 'Syncing...' : 'Sync now')
              : 'Offline: cannot sync',
        ),
      ],
    );
  }
}

