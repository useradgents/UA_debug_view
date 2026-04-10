import 'package:flutter/material.dart';
import '../theme/debug_colors.dart';
import '../theme/debug_text_styles.dart';

/// Consistent scaffold used by every module page inside the bottom sheet.
///
/// Provide either [children] (wrapped in a scrollable ListView) or [body]
/// (rendered as-is, useful for custom layouts that manage their own scrolling).
class DebugBottomSheetScaffold extends StatelessWidget {
  final String title;
  final List<Widget>? children;
  final Widget? body;
  final List<Widget>? actions;
  final bool showBackButton;

  const DebugBottomSheetScaffold({
    required this.title,
    super.key,
    this.children,
    this.body,
    this.showBackButton = true,
    this.actions,
  }) : assert(children != null || body != null, 'Provide children or body');

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DebugColors.background,
      child: Column(
        children: [
          _DebugNavBar(
            title: title,
            actions: actions,
            showBackButton: showBackButton,
          ),
          Expanded(
            child: body ??
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: children!,
                ),
          ),
        ],
      ),
    );
  }
}

class _DebugNavBar extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;

  const _DebugNavBar({
    required this.title,
    required this.showBackButton,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: const BoxDecoration(
        color: DebugColors.surface,
        border: Border(
          bottom: BorderSide(color: DebugColors.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          if (showBackButton)
            IconButton(
              icon: const Icon(
                Icons.chevron_left,
                color: DebugColors.textPrimary,
              ),
              onPressed: () => Navigator.of(context).pop(),
            )
          else
            const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: DebugTextStyles.title,
              textAlign: TextAlign.center,
            ),
          ),
          if (actions != null) ...actions! else const SizedBox(width: 48),
        ],
      ),
    );
  }
}
