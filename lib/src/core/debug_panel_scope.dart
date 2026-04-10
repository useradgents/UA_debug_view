import 'package:flutter/widgets.dart';

/// Provides panel-level actions to module pages deep in the widget tree.
///
/// Placed by [DebugPanel] above its internal [Navigator] so any module page
/// can call [closePanel] to dismiss the entire debug bottom sheet.
class DebugPanelScope extends InheritedWidget {
  const DebugPanelScope({
    required this.closePanel,
    required super.child,
    super.key,
  });

  /// Closes the debug panel entirely (dismisses the modal bottom sheet).
  final VoidCallback closePanel;

  static DebugPanelScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DebugPanelScope>();

  @override
  bool updateShouldNotify(DebugPanelScope oldWidget) => false;
}
