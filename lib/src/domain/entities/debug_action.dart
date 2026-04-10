import 'package:flutter/widgets.dart';

/// A single action button shown in [ActionsModule].
class DebugAction {
  final String label;
  final IconData icon;

  /// Called when the user taps the action button.
  final Future<void> Function() onTap;

  /// If true, a confirmation dialog is shown before calling [onTap].
  final bool requiresConfirmation;

  const DebugAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.requiresConfirmation = false,
  });
}
