import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ua_debug_view/ua_debug_view.dart';

void main() {
  HttpOverrides.global = DebugHttpOverrides();
  runApp(const ExampleApp());
}

// ---------------------------------------------------------------------------
// Environments
// ---------------------------------------------------------------------------

final _environments = [
  const DebugEnvironment(
    name: 'Development',
    tag: 'DEV',
    color: Color(0xFF34C759),
    values: {'Base URL': 'https://dev.api.example.com'},
  ),
  const DebugEnvironment(
    name: 'Staging',
    tag: 'STG',
    color: Color(0xFFFF9F0A),
    values: {'Base URL': 'https://staging.api.example.com'},
  ),
  const DebugEnvironment(
    name: 'Production',
    tag: 'PROD',
    color: Color(0xFFFF3B30),
    values: {'Base URL': 'https://api.example.com'},
  ),
];

// ---------------------------------------------------------------------------
// App
// ---------------------------------------------------------------------------

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  DebugEnvironment _currentEnv = _environments.first;

  List<DebugModule> get _modules => [
        TestAccountsModule(
          currentEnvironment: _currentEnv,
          accounts: [
            TestAccount(
              label: 'Alice (admin)',
              credentials: {'email': 'alice@example.com', 'password': 'admin123'},
              tags: ['admin'],
            ),
            TestAccount(
              label: 'Bob (user)',
              credentials: {'email': 'bob@example.com', 'password': 'user456'},
              tags: ['user'],
            ),
            TestAccount(
              label: 'Dev only account',
              credentials: {'email': 'dev@example.com', 'password': 'dev789'},
              environments: [_environments[0]], // DEV uniquement
              tags: ['dev'],
            ),
          ],
          onLogin: (account) async {
            await Future<void>.delayed(const Duration(milliseconds: 800));
            DebugLogger.i(
              'Logged in as ${account.label}',
              tag: 'Auth',
            );
          },
        ),
        AppInfoModule(),
        EnvironmentModule(
          environments: _environments,
          currentEnvironment: _currentEnv,
          onSwitch: (env) async {
            await Future<void>.delayed(const Duration(milliseconds: 500));
            if (mounted) setState(() => _currentEnv = env);
          },
        ),
        AuthModule(
          accessToken: () => 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.example',
          refreshToken: () => 'refresh_token_example_xyz',
          tokenExpiry: () => DateTime.now().add(const Duration(minutes: 42)),
          additionalInfo: {
            'User ID': () => '42',
            'Email': () => 'alice@example.com',
            'Role': () => 'admin',
          },
          onLogout: () async {
            await Future<void>.delayed(const Duration(milliseconds: 500));
            DebugLogger.w('User logged out', tag: 'Auth');
          },
        ),
        NetworkModule(ignoredPaths: const ['/health']),
        LogsModule(),
        StorageModule(sensitiveKeys: const ['token', 'password']),
        ActionsModule(
          actions: [
            DebugAction(
              label: 'Emit info log',
              icon: Icons.info_outline,
              onTap: () async => DebugLogger.i('Hello from action!', tag: 'Example'),
            ),
            DebugAction(
              label: 'Emit error log',
              icon: Icons.error_outline,
              onTap: () async => DebugLogger.e('Something went wrong', tag: 'Example'),
            ),
          ],
        ),
        DesignSystemModule(
          sections: [
            DesignSystemSection(
              title: 'Colors',
              builder: (_) => const _ColorsPreview(),
            ),
            DesignSystemSection(
              title: 'Typography',
              builder: (_) => const _TypographyPreview(),
            ),
          ],
        ),
        CustomModule(
          title: 'Feature Flags',
          icon: Icons.flag_outlined,
          builder: (_) => const _FeatureFlagsPage(),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return DebugPanel(
      modules: _modules,
      child: MaterialApp(
        title: 'ua_debug_view Example',
        theme: ThemeData.dark(useMaterial3: true),
        home: const _HomePage(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Home page
// ---------------------------------------------------------------------------

class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ua_debug_view example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Tap the bug FAB to open the debug panel.\n'
              'Or use the trigger below.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            DebugTrigger(
              tapCount: 5,
              modules: const [],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white24),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Tap 5× to open panel'),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.send),
              label: const Text('Fake network request'),
              onPressed: _fakeRequest,
            ),
          ],
        ),
      ),
    );
  }

  void _fakeRequest() {
    DebugLogger.d('Sending fake request…', tag: 'Network');
    DebugNetworkStore.instance.add(
      DebugNetworkRequest(
        timestamp: DateTime.now(),
        method: 'GET',
        url: 'https://api.example.com/users/me',
        statusCode: 200,
        duration: const Duration(milliseconds: 142),
        responseBody: '{"id": 1, "name": "John Doe"}',
      ),
    );
    DebugLogger.i('Request complete — 200 OK', tag: 'Network');
  }
}

// ---------------------------------------------------------------------------
// DesignSystem previews
// ---------------------------------------------------------------------------

class _ColorsPreview extends StatelessWidget {
  const _ColorsPreview();

  @override
  Widget build(BuildContext context) {
    final colors = {
      'Primary': const Color(0xFF0A84FF),
      'Success': const Color(0xFF34C759),
      'Warning': const Color(0xFFFF9F0A),
      'Error': const Color(0xFFFF3B30),
      'Surface': const Color(0xFF1C1C1E),
      'Background': const Color(0xFF000000),
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: colors.entries.map((e) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: e.value,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            e.key,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        );
      }).toList(),
    );
  }
}

class _TypographyPreview extends StatelessWidget {
  const _TypographyPreview();

  @override
  Widget build(BuildContext context) {
    final styles = {
      'Title — 17 / semibold': const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      'Label — 15 / medium': const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      'Value — 14 / regular': const TextStyle(fontSize: 14),
      'Caption — 12 / regular': const TextStyle(fontSize: 12),
      'Code — 12 / mono': const TextStyle(fontSize: 12, fontFamily: 'monospace'),
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: styles.entries.map((e) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(e.key, style: e.value.copyWith(color: Colors.white)),
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// CustomModule example: Feature Flags
// ---------------------------------------------------------------------------

class _FeatureFlagsPage extends StatefulWidget {
  const _FeatureFlagsPage();

  @override
  State<_FeatureFlagsPage> createState() => _FeatureFlagsPageState();
}

class _FeatureFlagsPageState extends State<_FeatureFlagsPage> {
  final Map<String, bool> _flags = {
    'New onboarding flow': false,
    'Dark mode v2': true,
    'Beta checkout': false,
    'Push notifications': true,
  };

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: _flags.entries.map((e) {
        return SwitchListTile(
          title: Text(e.key),
          value: e.value,
          onChanged: (v) => setState(() => _flags[e.key] = v),
        );
      }).toList(),
    );
  }
}
