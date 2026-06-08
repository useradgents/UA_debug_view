import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ua_debug_view/ua_debug_view.dart';

void main() {
  DebugView.enableNetworkCapture();
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

  @override
  Widget build(BuildContext context) {
    return DebugPanel(
      // ── Global ───────────────────────────────────────────────────────────
      accentColor: const Color(0xFF0A84FF),

      // ── Environments ─────────────────────────────────────────────────────
      environments: _environments,
      currentEnvironment: _currentEnv,
      onEnvironmentSwitch: (env) async {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        if (mounted) setState(() => _currentEnv = env);
      },

      // ── Auth ─────────────────────────────────────────────────────────────
      accessToken: () => 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.example',
      refreshToken: () => 'refresh_token_example_xyz',
      tokenExpiry: () => DateTime.now().add(const Duration(minutes: 42)),
      authAdditionalInfo: {
        'User ID': () => '42',
        'Email': () => 'alice@example.com',
        'Role': () => 'admin',
      },
      onLogout: () async {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        DebugLogger.w('User logged out', tag: 'Auth');
      },

      // ── Network ──────────────────────────────────────────────────────────
      networkIgnoredPaths: const ['/health'],

      // ── Storage ──────────────────────────────────────────────────────────
      storageSensitiveKeys: const ['token', 'password'],

      // ── Actions ──────────────────────────────────────────────────────────
      debugActions: [
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

      // ── Design System ────────────────────────────────────────────────────
      designSystemSections: [
        DesignSystemSection(
          title: 'Colors',
          builder: (_) => const _ColorsPreview(),
        ),
        DesignSystemSection(
          title: 'Typography',
          builder: (_) => const _TypographyPreview(),
        ),
      ],

      // ── Extra custom modules ─────────────────────────────────────────────
      extraModules: [
        CustomModule(
          title: 'Feature Flags',
          icon: Icons.flag_outlined,
          builder: (_) => const _FeatureFlagsPage(),
        ),
      ],

      child: MaterialApp(
        title: 'ua_debug_view Example',
        theme: ThemeData.dark(useMaterial3: true),
        home: const _LoginScreen(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Login screen — shows how to use DebugAccountPicker inside a real form
// ---------------------------------------------------------------------------

// Test accounts can live wherever you want — here, alongside the screen that
// uses them. You can also `const`-extract them into their own file, or build
// the list dynamically. The package doesn't care.
final _testAccounts = <TestAccount>[
  const TestAccount(
    id: 'alice@example.com',
    password: 'admin123',
    label: 'Alice',
    info: 'admin · bronze loyalty',
  ),
  const TestAccount(
    id: 'bob@example.com',
    password: 'user456',
    label: 'Bob',
    info: 'standard user',
  ),
  TestAccount(
    id: 'dev@example.com',
    password: 'dev789',
    label: 'Dev only',
    info: 'shows in DEV environment only',
    environments: [_environments[0]],
  ),
];

class _LoginScreen extends StatefulWidget {
  const _LoginScreen();

  @override
  State<_LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<_LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    DebugLogger.i('Login submitted: ${_emailController.text}', tag: 'Auth');
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => const _HomePage(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // ── The picker — drop-in, reads accounts from props ──────────
            // Auto-hides outside debug builds and respects current env.
            //
            // `onSelected` is form-library agnostic. Here we use raw
            // TextEditingControllers:
            DebugAccountPicker(
              accounts: _testAccounts,
              onSelected: (account) {
                _emailController.text = account.id;
                _passwordController.text = account.password;
              },
            ),
            // If you use flutter_form_builder instead, you don't need any
            // controller — drive the fields straight from the form key:
            //
            //   onSelected: (account) {
            //     final fields = _formKey.currentState?.fields;
            //     fields?['email']?.didChange(account.id);
            //     fields?['password']?.didChange(account.password);
            //   },
            //
            // ── Prefer a bottom sheet? ───────────────────────────────────
            // When the inline picker doesn't fit your layout (it lives in a
            // Row, an unbounded-height context, …) use the button variant —
            // the account list opens in its own route and never touches your
            // form's layout:
            //
            //   DebugAccountPickerButton(
            //     accounts: _testAccounts,
            //     onSelected: (account) {
            //       _emailController.text = account.id;
            //       _passwordController.text = account.password;
            //     },
            //   ),

            // ── Regular form ─────────────────────────────────────────────
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _login,
                child: const Text('Se connecter'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Home page (post-login)
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
              label: const Text('GET + POST request'),
              onPressed: _realRequests,
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.error_outline),
              label: const Text('Failing request'),
              onPressed: _failingRequest,
            ),
          ],
        ),
      ),
    );
  }

  // Real traffic through dart:io — captured automatically by DebugHttpOverrides.
  Future<void> _realRequests() async {
    DebugLogger.d('Sending requests…', tag: 'Network');
    final client = HttpClient();
    try {
      // GET with a JSON response body.
      final getReq = await client
          .getUrl(Uri.parse('https://jsonplaceholder.typicode.com/users/1'));
      final getResp = await getReq.close();
      await getResp.transform(utf8.decoder).join();

      // POST with a JSON request body.
      final postReq = await client
          .postUrl(Uri.parse('https://jsonplaceholder.typicode.com/posts'));
      postReq.headers.contentType = ContentType.json;
      postReq.write(jsonEncode({'title': 'foo', 'body': 'bar', 'userId': 1}));
      final postResp = await postReq.close();
      await postResp.transform(utf8.decoder).join();

      DebugLogger.i('Requests complete', tag: 'Network');
    } catch (e) {
      DebugLogger.e('Request failed: $e', tag: 'Network');
    } finally {
      client.close();
    }
  }

  // Hits an unresolvable host so the error path is captured.
  Future<void> _failingRequest() async {
    DebugLogger.d('Sending failing request…', tag: 'Network');
    final client = HttpClient();
    try {
      final req = await client
          .getUrl(Uri.parse('https://this-host-does-not-exist.invalid/data'));
      await req.close();
    } catch (e) {
      DebugLogger.e('Expected failure: $e', tag: 'Network');
    } finally {
      client.close();
    }
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
