import 'package:flutter/material.dart';

/// Color palette for the debug panel dark theme.
abstract class DebugColors {
  static const Color background = Color(0xFF0F0F0F);
  static const Color surface = Color(0xFF1C1C1E);
  static const Color surfaceElevated = Color(0xFF2C2C2E);
  static const Color border = Color(0xFF3A3A3C);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color textTertiary = Color(0xFF48484A);

  static const Color accentDefault = Color(0xFF0A84FF);

  static const Color success = Color(0xFF30D158);
  static const Color warning = Color(0xFFFF9F0A);
  static const Color error = Color(0xFFFF453A);
  static const Color info = Color(0xFF0A84FF);

  // Log level colors
  static const Color logVerbose = Color(0xFF8E8E93);
  static const Color logDebug = Color(0xFFFFFFFF);
  static const Color logInfo = Color(0xFF0A84FF);
  static const Color logWarning = Color(0xFFFF9F0A);
  static const Color logError = Color(0xFFFF453A);
}
