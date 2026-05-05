import 'package:flutter/widgets.dart';
import '../domain/entities/debug_environment.dart';

/// Inherited data exposed by [DebugPanel] to its descendants.
///
/// Two purposes:
///   1. Internal — module pages call [closePanel] to dismiss the bottom sheet.
///   2. External — widgets like `DebugAccountPicker` read [currentEnvironment]
///      and [accentColor] without needing them passed as props.
///
/// The scope is placed above the user's app subtree, so any widget anywhere
/// in the tree can find it via [maybeOf].
class DebugPanelScope extends InheritedWidget {
  const DebugPanelScope({
    required this.isEnabled,
    required this.accentColor,
    required this.currentEnvironment,
    required super.child,
    this.closePanel,
    super.key,
  });

  /// Whether the debug panel is currently rendered (respects [DebugVisibility]).
  /// External widgets should hide themselves when this is false.
  final bool isEnabled;

  /// Accent color applied by the surrounding [DebugPanel].
  final Color accentColor;

  /// Active environment from the surrounding [DebugPanel], if any.
  final DebugEnvironment? currentEnvironment;

  /// Closes the debug panel entirely. Only set inside the panel's own subtree.
  final VoidCallback? closePanel;

  static DebugPanelScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DebugPanelScope>();

  @override
  bool updateShouldNotify(DebugPanelScope oldWidget) =>
      isEnabled != oldWidget.isEnabled ||
      accentColor != oldWidget.accentColor ||
      currentEnvironment != oldWidget.currentEnvironment;
}
