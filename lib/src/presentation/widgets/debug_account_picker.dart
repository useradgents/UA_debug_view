import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/debug_panel_scope.dart';
import '../../domain/entities/test_account.dart';

/// A drop-in widget that surfaces a list of [TestAccount]s right inside your
/// login form (or any form really). Tapping an entry calls [onSelected] so you
/// can fill your `TextEditingController`s — the user then submits the form
/// using your normal "Sign in" button.
///
/// **Standalone usage** — no `DebugPanel` required. Works on its own and only
/// shows in debug builds (`kDebugMode`):
/// ```dart
/// DebugAccountPicker(
///   accounts: const [
///     TestAccount(id: 'alice@x.com', password: 'admin123', label: 'Alice', info: 'admin'),
///   ],
///   onSelected: (acc) {
///     _emailController.text = acc.id;
///     _passwordController.text = acc.password;
///   },
/// )
/// ```
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
}

class _DebugAccountPickerState extends State<DebugAccountPicker> {
  bool _expanded = false;
  TestAccount? _lastSelected;

  @override
  Widget build(BuildContext context) {
    final scope = DebugPanelScope.maybeOf(context);

    // Visibility: if a DebugPanel is around, follow its setting. Otherwise
    // default to debug-only.
    final shouldShow = scope?.isEnabled ?? kDebugMode;
    if (!shouldShow) return const SizedBox.shrink();

    // Env filtering only applies when a DebugPanel exposes a current env.
    final currentEnv = scope?.currentEnvironment;
    final visible = widget.accounts.where((a) {
      if (a.environments.isEmpty) return true;
      if (currentEnv == null) return true;
      return a.environments.any((e) => e.name == currentEnv.name);
    }).toList();

    if (visible.isEmpty) return const SizedBox.shrink();

    const defaultAccent = Color(0xFF0A84FF);
    final accent =
        widget.accentColor ?? scope?.accentColor ?? defaultAccent;
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
