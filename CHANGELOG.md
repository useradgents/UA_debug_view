# Changelog

## 1.0.0

Initial release.

### Features

- **`DebugPanel`** — wrap your app to get a draggable debug FAB and a modular debug bottom sheet. Visibility per build mode via `DebugVisibility` (`debugOnly`, `debugAndProfile`, `always`, `never`).
- **Triggers** — open the panel via the FAB, N taps on any widget (`DebugTrigger`), long press (`DebugTrigger.longPress`), or device shake (`DebugShakeTrigger`).
- **9 built-in modules**:
  - `AppInfoModule` — app version, build number, bundle ID, custom extras.
  - `EnvironmentModule` — environment switcher with confirmation dialog and FAB badge.
  - `AuthModule` — access/refresh tokens, expiry, user info, one-tap copy, optional logout.
  - `NetworkModule` — HTTP request/response inspector, powered by `DebugHttpOverrides` / `DebugView.enableNetworkCapture()`, with manual capture support via `DebugNetworkStore`.
  - `LogsModule` — filterable log console (levels + tags), pipe an existing log stream or use the built-in `DebugLogger`.
  - `StorageModule` — SharedPreferences browser with sensitive-key masking and custom storage providers.
  - `ActionsModule` — one-tap debug actions and toggle switches, with optional confirmation.
  - `DesignSystemModule` — preview pages for design tokens (colors, typography, components).
  - `CustomModule` — bring your own widget; or implement `DebugModule` for a reusable module.
- **`DebugAccountPicker`** — drop-in login-form widget to pre-fill test credentials; works standalone (no `DebugPanel` required), inline or as a bottom sheet (`DebugAccountPickerButton`, `DebugAccountPicker.showAsSheet`), with optional per-environment filtering.
- **Customization** — `accentColor` override for the FAB and panel.
