import 'package:flutter/material.dart';

/// Right-side details drawer panel (~380–420px). Optional tabs, close button.
class DetailsDrawer extends StatelessWidget {
  const DetailsDrawer({
    super.key,
    this.title = 'Details',
    this.tabs,
    this.tabViews,
    this.child,
    this.actions,
    this.onClose,
  }) : assert(
         (tabs == null && tabViews == null) || (tabs != null && tabViews != null && tabs.length == tabViews.length),
         'tabs and tabViews must both be null or have same length',
       );

  final String title;
  final List<String>? tabs;
  final List<Widget>? tabViews;
  final Widget? child;
  final List<Widget>? actions;
  final VoidCallback? onClose;

  static const double width = 400;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(-2, 0),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onClose,
                    tooltip: 'Close',
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Tabs or single child
          if (tabs != null && tabViews != null)
            Expanded(
              child: _DrawerWithTabs(
                tabs: tabs!,
                tabViews: tabViews!,
                actions: actions,
              ),
            )
          else if (child != null)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (actions != null && actions!.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: actions!,
                      ),
                    ),
                    const Divider(height: 1),
                  ],
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: child,
                    ),
                  ),
                ],
              ),
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }
}

class _DrawerWithTabs extends StatefulWidget {
  const _DrawerWithTabs({
    required this.tabs,
    required this.tabViews,
    this.actions,
  });

  final List<String> tabs;
  final List<Widget> tabViews;
  final List<Widget>? actions;

  @override
  State<_DrawerWithTabs> createState() => _DrawerWithTabsState();
}

class _DrawerWithTabsState extends State<_DrawerWithTabs> with SingleTickerProviderStateMixin {
  late TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: widget.tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.actions != null && widget.actions!.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.actions!,
            ),
          ),
          const Divider(height: 1),
        ],
        Material(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          child: TabBar(
            controller: _controller,
            tabs: widget.tabs.map((t) => Tab(text: t)).toList(),
            isScrollable: true,
            tabAlignment: TabAlignment.start,
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _controller,
            children: widget.tabViews,
          ),
        ),
      ],
    );
  }
}
