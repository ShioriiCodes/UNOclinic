import 'package:flutter/material.dart';

/// Left sidebar — collapsible (icon-only mode). Highlights active index.
class Sidebar extends StatelessWidget {
  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    required this.collapsed,
    required this.onToggleCollapse,
    this.versionLabel,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final bool collapsed;
  final VoidCallback onToggleCollapse;
  final String? versionLabel;

  static const List<_NavItem> _items = [
    _NavItem(Icons.dashboard_rounded, 'Dashboard'),
    _NavItem(Icons.person_rounded, 'Patients'),
    _NavItem(Icons.medical_services_rounded, 'Visits'),
    _NavItem(Icons.badge_rounded, 'Health Certificates'),
    _NavItem(Icons.forward_rounded, 'Referrals'),
    _NavItem(Icons.inventory_2_rounded, 'Inventory'),
    _NavItem(Icons.assessment_rounded, 'Reports'),
    _NavItem(Icons.settings_rounded, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = collapsed ? 72.0 : 240.0;
    final items = _items;

    return Material(
      color: theme.colorScheme.surface,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(right: BorderSide(color: theme.dividerColor)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            IconButton(
              icon: Icon(collapsed ? Icons.menu_open_rounded : Icons.menu_rounded),
              onPressed: onToggleCollapse,
              tooltip: collapsed ? 'Expand sidebar' : 'Collapse sidebar',
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final item = items[i];
                  final selected = selectedIndex == i;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Tooltip(
                      message: item.label,
                      preferBelow: false,
                      child: Material(
                        color: selected
                            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          onTap: () => onSelect(i),
                          borderRadius: BorderRadius.circular(8),
                          mouseCursor: SystemMouseCursors.click,
                          child: SizedBox(
                            width: double.infinity,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: collapsed ? 12 : 16,
                                vertical: 12,
                              ),
                              child: collapsed
                                  ? Center(
                                      child: Icon(
                                        item.icon,
                                        size: 22,
                                        color: selected
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.onSurfaceVariant,
                                      ),
                                    )
                                  : Row(
                                      children: [
                                        Icon(
                                          item.icon,
                                          size: 22,
                                          color: selected
                                              ? theme.colorScheme.primary
                                              : theme.colorScheme.onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Text(
                                            item.label,
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              fontWeight: selected ? FontWeight.w600 : null,
                                              color: selected
                                                  ? theme.colorScheme.primary
                                                  : theme.colorScheme.onSurface,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if ((versionLabel ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: collapsed ? 8 : 16,
                  vertical: 8,
                ),
                child: collapsed
                    ? Tooltip(
                        message: versionLabel!,
                        preferBelow: false,
                        child: Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      )
                    : Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          versionLabel!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.icon, this.label);
  final IconData icon;
  final String label;
}
