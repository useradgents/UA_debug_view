import 'dart:io';

import 'data/network/debug_http_client.dart';

/// Top-level entry point for wiring `ua_debug_view` into an app.
///
/// Groups the package's one-line activation helpers so the wiring reads as
/// belonging to ua_debug_view rather than poking at SDK globals directly.
class DebugView {
  DebugView._();

  /// Routes all `dart:io` HTTP traffic through [DebugHttpOverrides] so the
  /// `NetworkModule` can display it. Call once, before `runApp`:
  ///
  /// ```dart
  /// void main() {
  ///   DebugView.enableNetworkCapture();
  ///   runApp(const MyApp());
  /// }
  /// ```
  ///
  /// Captures Dio (default adapter) and the `http` package on native
  /// platforms. Any [HttpOverrides] the app already installed is preserved and
  /// chained, so proxy / certificate-pinning overrides keep working. Calling it
  /// more than once is a no-op. Not supported on Flutter Web (no `dart:io`).
  static void enableNetworkCapture() {
    final existing = HttpOverrides.current;
    if (existing is DebugHttpOverrides) return; // already enabled
    HttpOverrides.global = DebugHttpOverrides(existing);
  }
}
