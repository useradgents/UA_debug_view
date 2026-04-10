import 'dart:async';
import '../../domain/entities/debug_log.dart';

/// Singleton logger used by [LogsModule].
///
/// Use [DebugLogger.log] anywhere in your app to emit logs visible
/// in the debug panel. Alternatively, pipe your own log stream
/// via [LogsModule.logStream].
class DebugLogger {
  DebugLogger._();

  static final _controller = StreamController<DebugLog>.broadcast();
  static final List<DebugLog> _buffer = [];
  static int _maxLogs = 500;

  /// Stream of all logs emitted via [log].
  static Stream<DebugLog> get stream => _controller.stream;

  /// All logs currently stored in the buffer, most recent first.
  static List<DebugLog> get logs => List.unmodifiable(_buffer);

  /// Clears the in-memory log buffer.
  static void clear() => _buffer.clear();

  /// Emit a log entry into the debug panel.
  static void log(
    String message, {
    LogLevel level = LogLevel.debug,
    String? tag,
  }) {
    if (_controller.isClosed) return;
    final entry = DebugLog(
      timestamp: DateTime.now(),
      level: level,
      message: message,
      tag: tag,
    );
    _buffer.insert(0, entry);
    if (_buffer.length > _maxLogs) _buffer.removeLast();
    _controller.add(entry);
  }

  /// Convenience shortcuts.
  static void v(String message, {String? tag}) =>
      log(message, level: LogLevel.verbose, tag: tag);
  static void d(String message, {String? tag}) =>
      log(message, level: LogLevel.debug, tag: tag);
  static void i(String message, {String? tag}) =>
      log(message, level: LogLevel.info, tag: tag);
  static void w(String message, {String? tag}) =>
      log(message, level: LogLevel.warning, tag: tag);
  static void e(String message, {String? tag}) =>
      log(message, level: LogLevel.error, tag: tag);
}
