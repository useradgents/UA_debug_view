# ua_debug_view

A fully modular, customizable Flutter debug panel by [UserAdgents](https://github.com/useradgents).

Plug in only the modules you need — environment switcher, network inspector, logs console, auth tokens, storage browser, and more. Drop in `DebugAccountPicker` straight into your login form to pre-fill credentials. Zero configuration required to get started.

---

## Features

- **Draggable FAB** — floating bug button, visible in debug builds only by default
- **Multiple triggers** — FAB, N-taps on any widget, long press, or shake
- **10 built-in modules** — cover the most common debug needs out of the box
- **Fully modular** — register only what you need, build your own with `CustomModule`
- **Self-contained** — fixed dark theme, no state management dependency, no generated code

---

## Getting started

Add the dependency:

```yaml
dependencies:
  ua_debug_view: ^0.0.1
```

Wrap your `MaterialApp`:

```dart
void main() {
  runApp(
    DebugPanel(
      modules: [
        AppInfoModule(),
        EnvironmentModule(...),
      ],
      child: MaterialApp(...),
    ),
  );
}
```

---

## Triggers

Three ways to open the panel — combine them freely:

```dart
// 1. Automatic draggable FAB (default)
DebugPanel(modules: [...], child: MaterialApp(...))

// 2. Tap N times on any widget (e.g. your logo)
DebugTrigger(
  tapCount: 5,
  modules: [...],
  child: MyLogoWidget(),
)

// 3. Long press
DebugTrigger.longPress(modules: [...], child: MyWidget())

// 4. Shake the device
DebugShakeTrigger(modules: [...], child: MyApp())
```

Control visibility per build mode:

```dart
DebugPanel(
  visibility: DebugVisibility.debugOnly,    // default
  // DebugVisibility.debugAndProfile
  // DebugVisibility.always
  // DebugVisibility.never
  modules: [...],
  child: MaterialApp(...),
)
```

---

## Modules

### AppInfoModule

Displays version, build number, bundle ID, and any extra key/value pairs.

```dart
AppInfoModule()
// Auto-reads version & bundle ID from package_info_plus.
// Pass extras for additional build metadata:
AppInfoModule(extras: {'Git SHA': 'a3f5c2', 'Built at': '2026-04-03'})
```

---

### EnvironmentModule

Switch between environments with a confirmation dialog. The active environment badge appears on the FAB automatically.

```dart
EnvironmentModule(
  environments: [
    DebugEnvironment(
      name: 'Development',
      tag: 'DEV',
      color: Colors.green,
      values: {'Base URL': 'https://dev.api.example.com'},
    ),
    DebugEnvironment(name: 'Staging',    tag: 'STG', color: Colors.orange),
    DebugEnvironment(name: 'Production', tag: 'PROD', color: Colors.red),
  ],
  currentEnvironment: myEnvService.current,
  onSwitch: (env) async => await myEnvService.switchTo(env),
  showConfirmDialog: true, // default
)
```

---

### AuthModule

Displays access token, refresh token, expiry, and user info. One-tap copy on any token. Optional logout button.

```dart
AuthModule(
  accessToken:  () => myAuth.accessToken,
  refreshToken: () => myAuth.refreshToken,   // optional
  tokenExpiry:  () => myAuth.expiry,         // optional, DateTime
  additionalInfo: {
    'Email': () => myAuth.userEmail,
    'Role':  () => myAuth.role,
  },
  onLogout: () async => await myAuth.logout(), // optional
)
```

---

### DebugAccountPicker

A drop-in widget you place **inside your login form**. Tapping a test account calls `onSelected` so you can fill your form fields — the user then submits using your normal "Sign in" button. Auto-hides outside debug builds.

`onSelected` is **form-library agnostic** — it just hands you the `TestAccount`, you fill the fields however you like (see [Filling the fields](#filling-the-fields) below). Need a bottom sheet instead of an inline widget? See [As a bottom sheet](#as-a-bottom-sheet).

**Works standalone — no `DebugPanel` required.** Just drop it into the form and you're done.

```dart
// Anywhere convenient — alongside the screen, in a const file, etc.
const _testAccounts = [
  TestAccount(
    id: 'user@dev.com',
    password: '1234',
    label: 'Standard user',
    info: 'bronze loyalty',
  ),
  TestAccount(
    id: 'admin@dev.com',
    password: 'admin',
    label: 'Dev-only admin',
    info: 'full access',
  ),
  TestAccount(
    id: '+33612345678',
    password: '1234',
    label: 'Phone login',
  ),
];

// Inside your login screen's build():
Column(
  children: [
    DebugAccountPicker(
      accounts: _testAccounts,
      onSelected: (acc) {
        _idController.text = acc.id;
        _passwordController.text = acc.password;
      },
      // accentColor: Colors.purple, // optional override
    ),
    TextField(controller: _idController),
    TextField(controller: _passwordController, obscureText: true),
    ElevatedButton(onPressed: _login, child: const Text('Sign in')),
  ],
)
```

#### Filling the fields

`onSelected` doesn't assume any form library. Two common ways:

```dart
// 1. Raw TextEditingControllers
onSelected: (acc) {
  _idController.text = acc.id;
  _passwordController.text = acc.password;
},

// 2. flutter_form_builder — no controller needed, drive the fields
//    straight from the form key:
onSelected: (acc) {
  final fields = _formKey.currentState?.fields;
  fields?['email']?.didChange(acc.id);
  fields?['password']?.didChange(acc.password);
},
```

#### As a bottom sheet

When the inline widget doesn't fit your layout — it lives inside a `Row`, a horizontally-scrolling list, an `IntrinsicHeight`, or any context that doesn't give it a bounded height — rendering inline can break layout. Open the picker in a modal bottom sheet instead: the list lives in its own route with its own constraints, so it never touches your form's layout.

Use the ready-made button (self-hides with the same rules as the inline picker):

```dart
DebugAccountPickerButton(
  accounts: _testAccounts,
  onSelected: (acc) {
    _idController.text = acc.id;
    _passwordController.text = acc.password;
  },
  // label: 'Pick a test account', // optional
)
```

…or trigger the sheet yourself from any callback:

```dart
final picked = await DebugAccountPicker.showAsSheet(
  context,
  accounts: _testAccounts,
  onSelected: (acc) { /* fill your fields */ },
);
// `picked` is the selected TestAccount, or null if dismissed.
```

`TestAccount` fields:

| Field | Required | Purpose |
|---|---|---|
| `id` | yes | Identifier passed to your form (email, phone, username — whatever) |
| `password` | yes | Password matching `id` |
| `label` | no | Human-readable name (e.g. `"Alice — admin"`). Falls back to `id`. |
| `info` | no | Free-form info shown below the label (e.g. `"Hybris ✓ · Comarch ✗"`) |
| `environments` | no | Per-environment filter — see below. Only effective when wrapped by `DebugPanel`. |

**Optional integration with `DebugPanel`** — if a `DebugPanel` happens to wrap your app, the picker automatically:

- inherits its `accentColor` (override with the `accentColor` prop on the picker if needed);
- respects its `DebugVisibility` setting (e.g. `never` hides the picker too);
- filters accounts by the active `DebugEnvironment` — accounts whose `environments` list is non-empty only show when one of those envs is active. Useful for `dev`-only or `staging`-only credentials.

Without `DebugPanel`, all accounts are shown in debug builds (`environments` is ignored), and the default blue accent is used unless overridden.

---

### NetworkModule

Captures all HTTP requests and responses in a Charles Proxy-style list. Tap any request to see full details.

```dart
// Enable interception in main():
void main() {
  HttpOverrides.global = DebugHttpOverrides();
  runApp(...);
}

// Register the module:
NetworkModule(
  maxRequests: 100,
  ignoredPaths: ['/healthcheck'],
)
```

You can also add requests manually (useful with Dio or other clients):

```dart
DebugNetworkStore.instance.add(
  DebugNetworkRequest(
    timestamp: DateTime.now(),
    method: 'POST',
    url: 'https://api.example.com/login',
    statusCode: 200,
    duration: Duration(milliseconds: 312),
    responseBody: '{"token": "..."}',
  ),
);
```

---

### LogsModule

Filterable log console with levels (verbose, debug, info, warning, error) and tags.

The recommended approach is to pipe your existing logger's stream — the panel stays a passive observer, with no coupling to your app code:

```dart
LogsModule(logStream: myLogger.stream)
```

If you don't have a logging infrastructure yet, `DebugLogger` is a built-in lightweight option:

```dart
LogsModule(maxLogs: 500)

// Emit logs from anywhere in your app:
DebugLogger.v('Verbose message');
DebugLogger.d('Debug message', tag: 'AUTH');
DebugLogger.i('Info message',  tag: 'NETWORK');
DebugLogger.w('Warning');
DebugLogger.e('Error occurred');
```

> **Note:** Avoid calling `DebugLogger` directly in production app code — it couples your business logic to the debug panel. Prefer piping an existing stream.

---

### StorageModule

Browse all SharedPreferences keys. Sensitive keys are masked automatically. Supports additional custom storage providers.

```dart
StorageModule(
  sensitiveKeys: ['token', 'password', 'secret'],
  additionalStorages: [
    DebugStorageProvider(
      name: 'Secure Storage',
      read: () async => await mySecureStorage.readAll(),
    ),
  ],
)
```

---

### ActionsModule

One-tap debug actions: clear cache, reset onboarding, trigger a crash, etc. Optional confirmation dialog per action. Toggle switches for boolean flags.

```dart
ActionsModule(
  // Toggle switches — shown in a dedicated "Toggles" section
  toggles: [
    DebugToggleAction(
      label: 'Dark mode',
      icon: Icons.dark_mode_outlined,
      initialValue: isDarkMode,
      onToggle: (value) async => setDarkMode(value),
    ),
    DebugToggleAction(
      label: 'Show grid overlay',
      icon: Icons.grid_on_outlined,
      initialValue: false,
      onToggle: (value) async => setGridOverlay(value),
    ),
  ],
  // Buttons — shown in an "Available Actions" section
  actions: [
    DebugAction(
      label: 'Clear cache',
      icon: Icons.delete_outline,
      onTap: () async => await CacheService.clear(),
    ),
    DebugAction(
      label: 'Reset onboarding',
      icon: Icons.replay,
      requiresConfirmation: true,
      onTap: () async => await OnboardingService.reset(),
    ),
  ],
)
```

Both `actions` and `toggles` are optional — pass only what you need.

---

### DesignSystemModule

Preview pages for your app's design tokens — colors, typography, components.

```dart
DesignSystemModule(
  sections: [
    DesignSystemSection(
      title: 'Colors',
      builder: (context) => MyColorPaletteWidget(),
    ),
    DesignSystemSection(
      title: 'Typography',
      builder: (context) => MyTypographyWidget(),
    ),
  ],
)
```

---

### CustomModule

Fully custom module — supply your own title, icon, and widget. No contract to implement beyond that.

```dart
CustomModule(
  title: 'Feature Flags',
  icon: Icons.flag_outlined,
  builder: (context) => MyFeatureFlagsWidget(),
)
```

---

### Build your own module

Implement `DebugModule` to create a reusable module:

```dart
class MyModule extends DebugModule {
  const MyModule();

  @override
  String get title => 'My Module';

  @override
  IconData get icon => Icons.star_outline;

  @override
  Widget buildPage(BuildContext context) => const MyModulePage();

  // Optional: inline preview shown in the menu
  @override
  Widget? buildPreview(BuildContext context) => const Text('Quick info here');
}
```

---

## Accent color

Override the default blue accent for the FAB and the panel:

```dart
DebugPanel(
  accentColor: const Color(0xFF9B59B6),
  modules: [...],
  child: MaterialApp(...),
)
```

---

## Dependencies

| Package | Usage |
|---|---|
| `package_info_plus` | App version & bundle ID in `AppInfoModule` |
| `shared_preferences` | Storage browsing in `StorageModule` |
| `sensors_plus` | Shake detection in `DebugShakeTrigger` |

---

## License

MIT — see [LICENSE](LICENSE).
