import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../bottom_sheet/debug_bottom_sheet.dart';
import '../../domain/module/debug_module.dart';

/// Wraps any widget and opens the debug panel after [tapCount] taps.
///
/// ```dart
/// DebugTrigger(
///   tapCount: 5,
///   modules: myModules,
///   child: MyLogoWidget(),
/// )
/// ```
class DebugTrigger extends StatefulWidget {
  final Widget child;
  final int tapCount;
  final List<DebugModule> modules;
  final Color accentColor;

  const DebugTrigger({
    required this.child,
    required this.modules,
    super.key,
    this.tapCount = 5,
    this.accentColor = const Color(0xFF0A84FF),
  });

  /// Wraps [child] to open the debug panel on long press.
  factory DebugTrigger.longPress({
    required Widget child,
    required List<DebugModule> modules,
    Key? key,
    Color accentColor = const Color(0xFF0A84FF),
  }) {
    return _LongPressDebugTrigger(
      key: key,
      modules: modules,
      accentColor: accentColor,
      child: child,
    );
  }

  @override
  State<DebugTrigger> createState() => _DebugTriggerState();
}

class _DebugTriggerState extends State<DebugTrigger> {
  int _tapCount = 0;
  Timer? _resetTimer;

  void _onTap() {
    _resetTimer?.cancel();
    _tapCount++;
    if (_tapCount >= widget.tapCount) {
      _tapCount = 0;
      _openPanel();
    } else {
      _resetTimer = Timer(const Duration(seconds: 2), () {
        _tapCount = 0;
      });
    }
  }

  void _openPanel() {
    DebugBottomSheet.show(
      context,
      modulesNotifier: ValueNotifier(widget.modules),
      accentColor: widget.accentColor,
    );
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: _onTap, child: widget.child);
  }
}

class _LongPressDebugTrigger extends DebugTrigger {
  const _LongPressDebugTrigger({
    required super.child,
    required super.modules,
    super.key,
    super.accentColor,
  });

  @override
  State<DebugTrigger> createState() => _LongPressDebugTriggerState();
}

class _LongPressDebugTriggerState extends State<_LongPressDebugTrigger> {
  void _openPanel() {
    DebugBottomSheet.show(
      context,
      modulesNotifier: ValueNotifier(widget.modules),
      accentColor: widget.accentColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onLongPress: _openPanel, child: widget.child);
  }
}

/// A widget that listens for device shake events and opens the debug panel.
///
/// Place it once near the root of your widget tree:
/// ```dart
/// DebugShakeTrigger(modules: myModules, child: MyApp())
/// ```
class DebugShakeTrigger extends StatefulWidget {
  final Widget child;
  final List<DebugModule> modules;
  final Color accentColor;

  /// Minimum acceleration magnitude to consider a shake (m/s²).
  final double shakeThreshold;

  const DebugShakeTrigger({
    required this.child,
    required this.modules,
    super.key,
    this.accentColor = const Color(0xFF0A84FF),
    this.shakeThreshold = 25.0,
  });

  @override
  State<DebugShakeTrigger> createState() => _DebugShakeTriggerState();
}

class _DebugShakeTriggerState extends State<DebugShakeTrigger> {
  StreamSubscription<AccelerometerEvent>? _subscription;
  DateTime? _lastShake;

  @override
  void initState() {
    super.initState();
    _subscription = accelerometerEventStream().listen(_onAccelerometer);
  }

  void _onAccelerometer(AccelerometerEvent event) {
    final magnitude = (event.x * event.x + event.y * event.y + event.z * event.z);
    final now = DateTime.now();

    if (magnitude > widget.shakeThreshold * widget.shakeThreshold) {
      if (_lastShake == null ||
          now.difference(_lastShake!) > const Duration(seconds: 2)) {
        _lastShake = now;
        _openPanel();
      }
    }
  }

  void _openPanel() {
    DebugBottomSheet.show(
      context,
      modulesNotifier: ValueNotifier(widget.modules),
      accentColor: widget.accentColor,
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
