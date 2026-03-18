import 'package:flutter/material.dart';

import '../utils/breakpoints.dart';

/// Top app bar: app title, global search (UI only), sync status chip, user menu chip.
/// Responsive: search width and padding by breakpoint.
class Topbar extends StatelessWidget {
  const Topbar({
    super.key,
    this.syncStatus = SyncStatus.online,
    this.onSyncStatusTap,
    this.userLabel = 'Admin',
  });

  final SyncStatus syncStatus;
  final VoidCallback? onSyncStatusTap;
  final String userLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final horizontalPadding = Breakpoints.isSmall(context) ? 16.0 : 24.0;
    final searchMax = Breakpoints.searchMaxWidth(context);

    return Container(
      height: 56,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 900;

          return Row(
            children: [
              Text(
                'UNOclinic',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
              SizedBox(width: Breakpoints.isSmall(context) ? 12 : 24),
              if (!compact)
                Expanded(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: searchMax),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search patients, visits…',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onChanged: (_) {}, // UI only
                    ),
                  ),
                )
              else
                const Spacer(),
              SizedBox(width: compact ? 8 : 16),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onSyncStatusTap,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _syncIcon(syncStatus),
                          size: 18,
                          color: _syncColor(context, syncStatus),
                        ),
                        if (!compact) ...[
                          const SizedBox(width: 8),
                          Text(
                            _syncLabel(syncStatus),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: _syncColor(context, syncStatus),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: compact ? 8 : 12),
              if (compact)
                Tooltip(
                  message: userLabel,
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      userLabel.isNotEmpty ? userLabel[0].toUpperCase() : '?',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: Chip(
                    avatar: CircleAvatar(
                      radius: 14,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        userLabel.isNotEmpty ? userLabel[0].toUpperCase() : '?',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    label: Text(
                      userLabel,
                      overflow: TextOverflow.ellipsis,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  static IconData _syncIcon(SyncStatus s) {
    switch (s) {
      case SyncStatus.offline:
        return Icons.cloud_off_rounded;
      case SyncStatus.syncing:
        return Icons.sync_rounded;
      case SyncStatus.online:
        return Icons.cloud_done_rounded;
    }
  }

  static Color _syncColor(BuildContext context, SyncStatus s) {
    switch (s) {
      case SyncStatus.offline:
        return Colors.orange;
      case SyncStatus.syncing:
        return Theme.of(context).colorScheme.primary;
      case SyncStatus.online:
        return Colors.green;
    }
  }

  static String _syncLabel(SyncStatus s) {
    switch (s) {
      case SyncStatus.offline:
        return 'Offline';
      case SyncStatus.syncing:
        return 'Syncing…';
      case SyncStatus.online:
        return 'Online';
    }
  }
}

enum SyncStatus { offline, online, syncing }
