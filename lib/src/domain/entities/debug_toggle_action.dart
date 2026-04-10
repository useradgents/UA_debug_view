import 'package:flutter/widgets.dart';

/// A toggle action shown as a Switch row in [ActionsModule].
class DebugToggleAction {
  final String label;
  final IconData icon;

  /// The initial value of the switch.
  final bool initialValue;

  /// Called when the user toggles the switch.
  final Future<void> Function(bool value) onToggle;

  const DebugToggleAction({
    required this.label,
    required this.icon,
    required this.initialValue,
    required this.onToggle,
  });
}
