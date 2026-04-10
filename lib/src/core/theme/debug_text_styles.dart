import 'package:flutter/material.dart';
import 'debug_colors.dart';

/// Text styles for the debug panel.
abstract class DebugTextStyles {
  static const TextStyle title = TextStyle(
    color: DebugColors.textPrimary,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.4,
  );

  static const TextStyle sectionTitle = TextStyle(
    color: DebugColors.textSecondary,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  static const TextStyle label = TextStyle(
    color: DebugColors.textPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle value = TextStyle(
    color: DebugColors.textSecondary,
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle code = TextStyle(
    color: DebugColors.textSecondary,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    fontFamily: 'monospace',
  );

  static const TextStyle caption = TextStyle(
    color: DebugColors.textTertiary,
    fontSize: 11,
    fontWeight: FontWeight.w400,
  );
}
