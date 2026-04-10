import 'package:flutter/material.dart';

/// Represents a configurable app environment (dev, staging, prod, etc.).
class DebugEnvironment {
  /// Display name (e.g. "Development").
  final String name;

  /// Short tag displayed on the FAB badge (e.g. "DEV", "STG").
  final String tag;

  /// Badge color for this environment.
  final Color color;

  /// Arbitrary key/value pairs describing this environment (URLs, flags, etc.).
  final Map<String, String> values;

  const DebugEnvironment({
    required this.name,
    required this.tag,
    required this.color,
    this.values = const {},
  });
}
