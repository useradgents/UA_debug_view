import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/debug_panel_scope.dart';
import '../../domain/entities/test_account.dart';

/// A drop-in widget that surfaces a list of [TestAccount]s right inside your
/// login form (or any form really). Tapping an entry calls [onSelected] so you
/// can fill your form fields — the user then submits the form using your normal
/// "Sign in" button.
///
/// `onSelected` is form-library agnostic. Two common ways to fill the fields:
///
/// ```dart
/// // 1. Raw TextEditingControllers
/// onSelected: (acc) {
///   _emailController.text = acc.id;
///   _passwordController.text = acc.password;
/// },
///
/// // 2. flutter_form_builder — no controller needed, drive the fields via the
/// //    form key directly:
/// onSelected: (acc) {
///   final fields = _formKey.currentState?.fields;
///   fields?['email']?.didChange(acc.id);
///   fields?['password']?.didChange(acc.password);
/// },
/// ```
///
/// **Standalone usage** — no `DebugPanel` required. Works on its own and only
/// shows in debug builds (`kDebugMode`):
/// ```dart
/// DebugAccountPicker(
///   accounts: const [
///     TestAccount(id: 'alice@x.com', password: 'admin123', label: 'Alice', info: 'admin'),
///   ],
///   onSelected: (acc) { /* fill your fields */ },
/// )
/// ```
///
/// **As a modal bottom sheet** — when your layout doesn't give the picker a
/// bounded height (it lives in a `Row`, a horizontally-scrolling list, etc.),
/// rendering inline can break layout. Use [showAsSheet] (or the ready-made
/// [DebugAccountPickerButton]) instead: the list opens in its own route with
/// its own constraints, so it never affects your form's layout.
///
/// **With a surrounding `DebugPanel`** — the picker automatically:
///   - respects the panel's `DebugVisibility` (debug-only / always / never…);
///   - filters accounts by the active `DebugEnvironment`
///     (see [TestAccount.environments]);
///   - inherits the panel's accent color.
///
/// Pass [accentColor] to override the color regardless of context.
///
/// The widget auto-hides when [accounts] is empty after environment filtering,
/// or when the surrounding panel reports it should not render.
class DebugAccountPicker extends StatefulWidget {
  const DebugAccountPicker({
    required this.accounts,
    required this.onSelected,
    this.accentColor,
    super.key,
  });

  /// The accounts to show. Filtered by the active environment when their
  /// [TestAccount.environments] list is non-empty.
  final List<TestAccount> accounts;

  /// Called when the user taps an account. Use it to fill your form fields.
  final void Function(TestAccount account) onSelected;

  /// Overrides the accent color. When null, the color is inherited from the
  /// surrounding `DebugPanel`, or falls back to a sensible default.
  final Color? accentColor;

  @override
  State<DebugAccountPicker> createState() => _DebugAccountPickerState();

  /// Opens the account picker in a modal bottom sheet instead of rendering
  /// inline. Prefer this when your form layout doesn't give the picker a
  /// bounded height (placing it inside a `Row`, a horizontally-scrolling list,
  /// an `IntrinsicHeight`, …) — the sheet lives in its own route with its own
  /// constraints, so it never affects your form's layout.
  ///
  /// Honours the same visibility + environment-filtering rules as the inline
  /// widget. Returns the selected account (which is also passed to
  /// [onSelected]), or `null` if the sheet was dismissed. When the picker
  /// shouldn't show (wrong build mode, no matching accounts) this is a no-op
  /// that completes with `null`.
  static Future<TestAccount?> showAsSheet(
    BuildContext context, {
    required List<TestAccount> accounts,
    required void Function(TestAccount account) onSelected,
    Color? accentColor,
  }) {
    final resolved = _PickerResolution.of(context, accounts, accentColor);
    if (!resolved.shouldShow) return Future<TestAccount?>.value();

    return showModalBottomSheet<TestAccount>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _DebugBadge(color: resolved.accent),
                    const SizedBox(width: 8),
                    const Text(
                      'Test accounts — tap to fill',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: resolved.accounts
                          .map((a) => _AccountTile(
                                account: a,
                                accentColor: resolved.accent,
                                isSelected: false,
                                onTap: () {
                                  onSelected(a);
                                  Navigator.of(sheetContext).pop(a);
                                },
                              ))
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Result of resolving a picker's visibility, environment filtering and accent
/// color against the surrounding [DebugPanelScope] (if any). Shared by the
/// inline [DebugAccountPicker], [DebugAccountPicker.showAsSheet] and
/// [DebugAccountPickerButton] so they all behave identically.
class _PickerResolution {
  const _PickerResolution({
    required this.shouldShow,
    required this.accounts,
    required this.accent,
  });

  /// Whether the picker should render at all (correct build mode AND at least
  /// one account survives environment filtering).
  final bool shouldShow;

  /// Accounts left after environment filtering.
  final List<TestAccount> accounts;

  /// Resolved accent color.
  final Color accent;

  static _PickerResolution of(
    BuildContext context,
    List<TestAccount> accounts,
    Color? accentOverride,
  ) {
    final scope = DebugPanelScope.maybeOf(context);

    // Visibility: if a DebugPanel is around, follow its setting. Otherwise
    // default to debug-only.
    final enabled = scope?.isEnabled ?? kDebugMode;

    // Env filtering only applies when a DebugPanel exposes a current env.
    final currentEnv = scope?.currentEnvironment;
    final visible = accounts.where((a) {
      if (a.environments.isEmpty) return true;
      if (currentEnv == null) return true;
      return a.environments.any((e) => e.name == currentEnv.name);
    }).toList();

    const defaultAccent = Color(0xFF0A84FF);
    final accent = accentOverride ?? scope?.accentColor ?? defaultAccent;

    return _PickerResolution(
      shouldShow: enabled && visible.isNotEmpty,
      accounts: visible,
      accent: accent,
    );
  }
}

/// A compact button that opens the [DebugAccountPicker] in a modal bottom sheet
/// (via [DebugAccountPicker.showAsSheet]). Drop it anywhere — it self-hides
/// using the exact same rules as the inline picker, and keeps your form layout
/// untouched since the account list lives in its own route.
///
/// ```dart
/// DebugAccountPickerButton(
///   accounts: _testAccounts,
///   onSelected: (acc) {
///     final fields = _formKey.currentState?.fields;
///     fields?['email']?.didChange(acc.id);
///     fields?['password']?.didChange(acc.password);
///   },
/// )
/// ```
class DebugAccountPickerButton extends StatelessWidget {
  const DebugAccountPickerButton({
    required this.accounts,
    required this.onSelected,
    this.accentColor,
    this.label,
    super.key,
  });

  /// The accounts to show. Filtered by the active environment when their
  /// [TestAccount.environments] list is non-empty.
  final List<TestAccount> accounts;

  /// Called when the user taps an account in the sheet.
  final void Function(TestAccount account) onSelected;

  /// Overrides the accent color. When null, inherited from the surrounding
  /// `DebugPanel`, or a sensible default.
  final Color? accentColor;

  /// Overrides the button label. Defaults to `Test accounts (N)`.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final resolved = _PickerResolution.of(context, accounts, accentColor);
    if (!resolved.shouldShow) return const SizedBox.shrink();

    return OutlinedButton.icon(
      onPressed: () => DebugAccountPicker.showAsSheet(
        context,
        accounts: accounts,
        onSelected: onSelected,
        accentColor: accentColor,
      ),
      icon: _DebugBadge(color: resolved.accent),
      label: Text(label ?? 'Test accounts (${resolved.accounts.length})'),
      style: OutlinedButton.styleFrom(
        foregroundColor: resolved.accent,
        side: BorderSide(color: resolved.accent.withValues(alpha: 0.4)),
      ),
    );
  }
}

class _DebugAccountPickerState extends State<DebugAccountPicker> {
  bool _expanded = false;
  TestAccount? _lastSelected;

  @override
  Widget build(BuildContext context) {
    final resolved =
        _PickerResolution.of(context, widget.accounts, widget.accentColor);
    if (!resolved.shouldShow) return const SizedBox.shrink();

    final visible = resolved.accounts;
    final accent = resolved.accent;
    final headerLabel = _expanded
        ? 'Test accounts — tap to fill'
        : _lastSelected != null
            ? '${_lastSelected!.label ?? _lastSelected!.id} — tap to change'
            : 'Test accounts (${visible.length}) — tap to expand';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _DebugBadge(color: accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      headerLabel,
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down, size: 18),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            Divider(height: 1, color: accent.withValues(alpha: 0.3)),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: visible
                    .map((a) => _AccountTile(
                          account: a,
                          accentColor: accent,
                          isSelected: _lastSelected == a,
                          onTap: () {
                            widget.onSelected(a);
                            setState(() {
                              _lastSelected = a;
                              _expanded = false;
                            });
                          },
                        ))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DebugBadge extends StatelessWidget {
  const _DebugBadge({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'DEBUG',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.account,
    required this.accentColor,
    required this.isSelected,
    required this.onTap,
  });

  final TestAccount account;
  final Color accentColor;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isSelected
                ? accentColor.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected
                  ? accentColor
                  : accentColor.withValues(alpha: 0.25),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.label ?? account.id,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (account.label != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        account.id,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                    if (account.info != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        account.info!,
                        style: TextStyle(
                          fontSize: 10,
                          color: accentColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.touch_app_outlined,
                size: 18,
                color: accentColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
