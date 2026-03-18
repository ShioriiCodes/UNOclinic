import 'package:flutter/material.dart';

/// Section card with optional title and actions for main content areas.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    this.title,
    this.actions,
    required this.child,
    this.padding,
    this.expandChild = false,
  });

  final String? title;
  final List<Widget>? actions;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool expandChild;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = padding ?? const EdgeInsets.all(24);

    return Card(
      child: Padding(
        padding: p,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null || (actions != null && actions!.isNotEmpty)) ...[
              Row(
                children: [
                  if (title != null)
                    Expanded(
                      child: Text(
                        title!,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (actions != null) ...actions!,
                ],
              ),
              const SizedBox(height: 16),
            ],
            if (expandChild) Expanded(child: child) else child,
          ],
        ),
      ),
    );
  }
}
