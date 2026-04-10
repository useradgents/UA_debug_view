/// Severity level of a [DebugLog].
enum LogLevel { verbose, debug, info, warning, error }

/// A single log entry captured by [DebugLogger].
class DebugLog {
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final String? tag;

  const DebugLog({
    required this.timestamp,
    required this.level,
    required this.message,
    this.tag,
  });
}
