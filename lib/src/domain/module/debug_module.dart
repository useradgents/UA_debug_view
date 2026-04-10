import 'package:flutter/widgets.dart';
import '../entities/debug_environment.dart';

/// Abstract contract that every debug module must implement.
///
/// A [DebugModule] represents a self-contained section inside the debug panel.
/// Register only the modules your app needs via [DebugPanel.modules].
abstract class DebugModule {
  const DebugModule();

  /// Title shown in the debug panel menu.
  String get title;

  /// Icon shown next to the title in the menu.
  IconData get icon;

  /// Builds the full-page content shown when the user taps this module.
  Widget buildPage(BuildContext context);

  /// Optional preview widget shown inline in the main menu.
  /// Return null to show only a navigation tile.
  Widget? buildPreview(BuildContext context) => null;
}

/// Mixin that exposes the current environment to [DebugPanel].
///
/// Implement this on any module that manages environments so the FAB badge
/// can display the active environment tag without string-based type checks.
mixin DebugEnvironmentProvider on DebugModule {
  DebugEnvironment get currentEnvironment;
}
