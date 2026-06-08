import 'dart:async';
import 'package:flutter/cupertino.dart' show DefaultCupertinoLocalizations;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/debug_panel_scope.dart';
import '../data/network/debug_network_store.dart';
import '../domain/entities/debug_action.dart';
import '../domain/entities/debug_environment.dart';
import '../domain/entities/debug_log.dart';
import '../domain/entities/debug_storage_provider.dart';
import '../domain/entities/debug_toggle_action.dart';
import '../domain/module/debug_module.dart';
import '../presentation/modules/actions/actions_module.dart';
import '../presentation/modules/app_info/app_info_module.dart';
import '../presentation/modules/auth/auth_module.dart';
import '../presentation/modules/design_system/design_system_module.dart';
import '../presentation/modules/environment/environment_module.dart';
import '../presentation/modules/logs/logs_module.dart';
import '../presentation/modules/network/network_module.dart';
import '../presentation/modules/storage/storage_module.dart';
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
/// Wrap [MaterialApp] (or any root widget) with [DebugPanel]. All modules are
/// pre-configured and activated automatically based on the parameters you pass.
/// Only provide the parameters relevant to your app — everything else is
/// either handled automatically or left out.
///
/// **Minimal setup** — AppInfo, Network, Logs and Storage are always active:
/// ```dart
/// DebugPanel(
///   child: MaterialApp(...),
/// )
/// ```
///
/// **With environments and auth:**
/// ```dart
/// DebugPanel(
///   child: MaterialApp(...),
///   environments: [devEnv, stagingEnv, prodEnv],
///   currentEnvironment: _currentEnv,
///   onEnvironmentSwitch: (env) => setState(() => _currentEnv = env),
///   accessToken: () => myAuth.token,
///   onLogout: () async => myAuth.logout(),
/// )
/// ```
class DebugPanel extends StatefulWidget {
  final Widget child;

  // ── Global ────────────────────────────────────────────────────────────────

  /// Controls in which build modes the FAB is shown. Defaults to [DebugVisibility.debugOnly].
  final DebugVisibility visibility;

  /// Accent color for the FAB and the panel. Defaults to blue.
  final Color accentColor;

  // ── AppInfoModule (always active) ────────────────────────────────────────

  /// Extra key/value pairs to display in App Info (e.g. git SHA, build date).
  final Map<String, String> appInfoExtras;

  // ── NetworkModule (always active) ────────────────────────────────────────

  /// URL path fragments to exclude from the network inspector.
  final List<String> networkIgnoredPaths;

  /// Maximum number of requests kept in memory. Defaults to 100.
  final int networkMaxRequests;

  // ── LogsModule (always active) ───────────────────────────────────────────

  /// Optional external log stream. Falls back to the built-in [DebugLogger].
  final Stream<DebugLog>? logStream;

  /// Maximum number of log entries kept in memory. Defaults to 500.
  final int logsMaxEntries;

  // ── StorageModule (always active) ────────────────────────────────────────

  /// Keys whose values are masked in the storage browser (e.g. 'token', 'password').
  final List<String> storageSensitiveKeys;

  /// Additional custom storage providers shown alongside SharedPreferences.
  final List<DebugStorageProvider> storageAdditional;

  // ── EnvironmentModule (active when [environments] is provided) ────────────

  /// List of environments to display. Activates the Environment module.
  final List<DebugEnvironment>? environments;

  /// The currently active environment.
  final DebugEnvironment? currentEnvironment;

  /// Called when the user selects a different environment.
  final Future<void> Function(DebugEnvironment env)? onEnvironmentSwitch;

  /// Whether to show a confirmation dialog before switching. Defaults to true.
  final bool environmentShowConfirmDialog;

  // ── AuthModule (active when [accessToken] is provided) ───────────────────

  /// Returns the current access token. Activates the Auth module.
  final String? Function()? accessToken;

  /// Returns the current refresh token.
  final String? Function()? refreshToken;

  /// Returns the token expiry date.
  final DateTime? Function()? tokenExpiry;

  /// Additional user info to display (e.g. email, role).
  final Map<String, String? Function()> authAdditionalInfo;

  /// Called when the user taps the Logout button.
  final Future<void> Function()? onLogout;

  // ── ActionsModule (active when [debugActions] or [debugToggles] is provided)

  /// Debug action buttons (clear cache, reset onboarding, etc.).
  final List<DebugAction>? debugActions;

  /// Debug toggle switches (feature flags, overlays, etc.).
  final List<DebugToggleAction>? debugToggles;

  // ── DesignSystemModule (active when [designSystemSections] is provided) ───

  /// Design system preview sections (colors, typography, components).
  final List<DesignSystemSection>? designSystemSections;

  // ── Extra modules ─────────────────────────────────────────────────────────

  /// Additional custom modules appended at the end of the panel.
  final List<DebugModule> extraModules;

  const DebugPanel({
    required this.child,
    super.key,
    // Global
    this.visibility = DebugVisibility.debugOnly,
    this.accentColor = const Color(0xFF0A84FF),
    // AppInfo
    this.appInfoExtras = const {},
    // Network
    this.networkIgnoredPaths = const [],
    this.networkMaxRequests = 100,
    // Logs
    this.logStream,
    this.logsMaxEntries = 500,
    // Storage
    this.storageSensitiveKeys = const [],
    this.storageAdditional = const [],
    // Environment
    this.environments,
    this.currentEnvironment,
    this.onEnvironmentSwitch,
    this.environmentShowConfirmDialog = true,
    // Auth
    this.accessToken,
    this.refreshToken,
    this.tokenExpiry,
    this.authAdditionalInfo = const {},
    this.onLogout,
    // Actions
    this.debugActions,
    this.debugToggles,
    // Design system
    this.designSystemSections,
    // Extra
    this.extraModules = const [],
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

  List<DebugModule> _buildModules() {
    return [
      // ── Always active ────────────────────────────────────────────────────
      AppInfoModule(extras: widget.appInfoExtras),
      NetworkModule(
        maxRequests: widget.networkMaxRequests,
        ignoredPaths: widget.networkIgnoredPaths,
      ),
      LogsModule(
        logStream: widget.logStream,
        maxLogs: widget.logsMaxEntries,
      ),
      StorageModule(
        sensitiveKeys: widget.storageSensitiveKeys,
        additionalStorages: widget.storageAdditional,
      ),

      // ── Conditional ──────────────────────────────────────────────────────
      if (widget.environments != null &&
          widget.currentEnvironment != null &&
          widget.onEnvironmentSwitch != null)
        EnvironmentModule(
          environments: widget.environments!,
          currentEnvironment: widget.currentEnvironment!,
          onSwitch: widget.onEnvironmentSwitch!,
          showConfirmDialog: widget.environmentShowConfirmDialog,
        ),

      if (widget.accessToken != null)
        AuthModule(
          accessToken: widget.accessToken!,
          refreshToken: widget.refreshToken,
          tokenExpiry: widget.tokenExpiry,
          additionalInfo: widget.authAdditionalInfo,
          onLogout: widget.onLogout,
        ),

      if ((widget.debugActions?.isNotEmpty ?? false) ||
          (widget.debugToggles?.isNotEmpty ?? false))
        ActionsModule(
          actions: widget.debugActions ?? [],
          toggles: widget.debugToggles ?? [],
        ),

      if (widget.designSystemSections != null &&
          widget.designSystemSections!.isNotEmpty)
        DesignSystemModule(sections: widget.designSystemSections!),

      // ── Custom extras ────────────────────────────────────────────────────
      ...widget.extraModules,
    ];
  }

  DebugEnvironment? get _activeEnvironment {
    for (final module in _modulesNotifier.value) {
      if (module is DebugEnvironmentProvider) return module.currentEnvironment;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    // Configure the network store up-front so ignored paths are dropped from
    // the moment the app starts — before the page is ever opened — otherwise
    // background traffic (e.g. connectivity checks) fills the buffer and evicts
    // real requests.
    DebugNetworkStore.instance
      ..maxRequests = widget.networkMaxRequests
      ..ignoredPaths = widget.networkIgnoredPaths;
    final modules = _buildModules();
    _modulesNotifier = ValueNotifier(modules);
    final env = _activeEnvironment;
    _envNotifier = ValueNotifier((tag: env?.tag, color: env?.color));
  }

  @override
  void didUpdateWidget(DebugPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _modulesNotifier.value = _buildModules();
    final env = _activeEnvironment;
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
    final scopedChild = DebugPanelScope(
      isEnabled: _shouldShow,
      accentColor: widget.accentColor,
      currentEnvironment: _activeEnvironment,
      child: widget.child,
    );

    if (!_shouldShow) return scopedChild;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          scopedChild,
          Localizations(
            locale: const Locale('en'),
            delegates: const [
              DefaultMaterialLocalizations.delegate,
              DefaultWidgetsLocalizations.delegate,
              // Required so the iOS text-selection toolbar (Copy/Paste) on
              // SelectableText can resolve its labels inside this overlay.
              DefaultCupertinoLocalizations.delegate,
            ],
            child: _DebugFabOverlay(
              modulesNotifier: _modulesNotifier,
              envNotifier: _envNotifier,
              accentColor: widget.accentColor,
              currentEnvironment: _activeEnvironment,
            ),
          ),
        ],
      ),
    );
  }
}

/// Transparent overlay that hosts the FAB inside its own [Navigator].
class _DebugFabOverlay extends StatefulWidget {
  const _DebugFabOverlay({
    required this.modulesNotifier,
    required this.envNotifier,
    required this.accentColor,
    required this.currentEnvironment,
  });

  final ValueNotifier<List<DebugModule>> modulesNotifier;
  final ValueNotifier<_EnvInfo> envNotifier;
  final Color accentColor;
  final DebugEnvironment? currentEnvironment;

  @override
  State<_DebugFabOverlay> createState() => _DebugFabOverlayState();
}

class _DebugFabOverlayState extends State<_DebugFabOverlay> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  void _closePanel() => _navigatorKey.currentState?.pop();

  @override
  Widget build(BuildContext context) {
    return DebugPanelScope(
      isEnabled: true,
      accentColor: widget.accentColor,
      currentEnvironment: widget.currentEnvironment,
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
