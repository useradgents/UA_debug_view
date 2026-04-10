import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/debug_panel_scope.dart';
import '../domain/entities/debug_environment.dart';
import '../domain/module/debug_module.dart';
import 'bottom_sheet/debug_bottom_sheet.dart';
import 'fab/debug_fab.dart';

/// Which build modes should show the debug FAB.
enum DebugVisibility {
  /// Only shown in debug builds (`kDebugMode`).
  debugOnly,

  /// Shown in debug and profile builds.
  debugAndProfile,

  /// Always shown (use with caution in production).
  always,

  /// Never shown — useful for disabling without removing the widget.
  never,
}

/// The main entry point of `ua_debug_view`.
///
/// Wrap [MaterialApp] (or any root widget) with [DebugPanel]:
///
/// ```dart
/// DebugPanel(
///   modules: [
///     AppInfoModule(),
///     EnvironmentModule(...),
///   ],
///   child: MaterialApp(...),
/// )
/// ```
///
/// [DebugPanel] manages its own internal [Navigator] and [Localizations] for
/// the debug overlay, so it works regardless of its position in the tree.
class DebugPanel extends StatefulWidget {
  final Widget child;
  final List<DebugModule> modules;
  final DebugVisibility visibility;
  final Color accentColor;

  const DebugPanel({
    required this.child,
    required this.modules,
    super.key,
    this.visibility = DebugVisibility.debugOnly,
    this.accentColor = const Color(0xFF0A84FF),
  });

  @override
  State<DebugPanel> createState() => _DebugPanelState();
}

typedef _EnvInfo = ({String? tag, Color? color});

class _DebugPanelState extends State<DebugPanel> {
  late final ValueNotifier<List<DebugModule>> _modulesNotifier;
  late final ValueNotifier<_EnvInfo> _envNotifier;

  bool get _shouldShow {
    return switch (widget.visibility) {
      DebugVisibility.debugOnly => kDebugMode,
      DebugVisibility.debugAndProfile => kDebugMode || kProfileMode,
      DebugVisibility.always => true,
      DebugVisibility.never => false,
    };
  }

  DebugEnvironment? _activeEnvironment([List<DebugModule>? modules]) {
    for (final module in modules ?? widget.modules) {
      if (module is DebugEnvironmentProvider) return module.currentEnvironment;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    final env = _activeEnvironment();
    _modulesNotifier = ValueNotifier(widget.modules);
    _envNotifier = ValueNotifier((tag: env?.tag, color: env?.color));
  }

  @override
  void didUpdateWidget(DebugPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _modulesNotifier.value = widget.modules;
    final env = _activeEnvironment();
    _envNotifier.value = (tag: env?.tag, color: env?.color);
  }

  @override
  void dispose() {
    _modulesNotifier.dispose();
    _envNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldShow) return widget.child;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          widget.child,
          // Isolated overlay: own Navigator + Localizations so the FAB and
          // bottom sheet work regardless of where DebugPanel sits in the tree.
          Localizations(
            locale: const Locale('en'),
            delegates: const [
              DefaultMaterialLocalizations.delegate,
              DefaultWidgetsLocalizations.delegate,
            ],
            child: _DebugFabOverlay(
              modulesNotifier: _modulesNotifier,
              envNotifier: _envNotifier,
              accentColor: widget.accentColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Transparent overlay that hosts the FAB inside its own [Navigator].
///
/// Uses [ValueNotifier]s so environment badge and modules stay in sync
/// with the host app even though the Navigator caches its route.
class _DebugFabOverlay extends StatefulWidget {
  const _DebugFabOverlay({
    required this.modulesNotifier,
    required this.envNotifier,
    required this.accentColor,
  });

  final ValueNotifier<List<DebugModule>> modulesNotifier;
  final ValueNotifier<_EnvInfo> envNotifier;
  final Color accentColor;

  @override
  State<_DebugFabOverlay> createState() => _DebugFabOverlayState();
}

class _DebugFabOverlayState extends State<_DebugFabOverlay> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  void _closePanel() => _navigatorKey.currentState?.pop();

  @override
  Widget build(BuildContext context) {
    return DebugPanelScope(
      closePanel: _closePanel,
      child: Navigator(
        key: _navigatorKey,
        onGenerateRoute: (_) => _FabRoute(
          child: Builder(
            builder: (navContext) => Stack(
              children: [
                ValueListenableBuilder<_EnvInfo>(
                  valueListenable: widget.envNotifier,
                  builder: (_, env, __) => DebugFab(
                    accentColor: widget.accentColor,
                    environmentTag: env.tag,
                    environmentColor: env.color,
                    onTap: () => DebugBottomSheet.show(
                      navContext,
                      modulesNotifier: widget.modulesNotifier,
                      accentColor: widget.accentColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Un [OverlayRoute] sans ModalBarrier — ne consomme aucun événement pointer
/// en dehors des widgets qu'il contient.
class _FabRoute extends OverlayRoute<void> {
  _FabRoute({required this.child});

  final Widget child;

  @override
  Iterable<OverlayEntry> createOverlayEntries() sync* {
    yield OverlayEntry(
      opaque: false,
      builder: (_) => child,
    );
  }
}
