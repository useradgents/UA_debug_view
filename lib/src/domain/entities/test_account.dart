import 'debug_environment.dart';

/// A test account usable in [DebugAccountPicker].
///
/// Drop a list of these into a `DebugAccountPicker` placed inside your
/// login form — tapping an entry calls `onSelected` so you can fill your
/// `TextEditingController`s, then the user submits the form themselves.
class TestAccount {
  /// Identifier used to log in (email, phone, username — whatever your form expects).
  final String id;

  /// Password matching [id].
  final String password;

  /// Optional human-readable name shown as the main line (e.g. "Alice — admin").
  /// Falls back to [id] when null.
  final String? label;

  /// Optional free-form info displayed below the label (e.g. "bronze loyalty",
  /// "Hybris ✓ Comarch ✗"). Purely informational — not used by the picker logic.
  final String? info;

  /// If non-empty, restricts the account to specific environments. Only
  /// effective when a surrounding `DebugPanel` exposes a current
  /// [DebugEnvironment] — the picker will then hide accounts whose
  /// [environments] list does not include the active env.
  ///
  /// Without a `DebugPanel`, this field is ignored (account always visible).
  final List<DebugEnvironment> environments;

  const TestAccount({
    required this.id,
    required this.password,
    this.label,
    this.info,
    this.environments = const [],
  });
}
