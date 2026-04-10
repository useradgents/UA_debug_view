import 'package:flutter/material.dart';
import '../../../core/theme/debug_colors.dart';
import '../../../core/theme/debug_text_styles.dart';
import '../../../core/widgets/debug_bottom_sheet_scaffold.dart';
import '../../../core/widgets/debug_section.dart';
import '../../../domain/entities/debug_action.dart';
import '../../../domain/entities/debug_toggle_action.dart';
import '../../../domain/module/debug_module.dart';

/// A list of custom action buttons and toggles (clear cache, reset onboarding, etc.).
class ActionsModule extends DebugModule {
  final List<DebugAction> actions;
  final List<DebugToggleAction> toggles;

  const ActionsModule({
    this.actions = const [],
    this.toggles = const [],
  });

  @override
  String get title => 'Actions';

  @override
  IconData get icon => Icons.bolt_outlined;

  @override
  Widget buildPage(BuildContext context) => _ActionsPage(module: this);
}

class _ActionsPage extends StatefulWidget {
  final ActionsModule module;

  const _ActionsPage({required this.module});

  @override
  State<_ActionsPage> createState() => _ActionsPageState();
}

class _ActionsPageState extends State<_ActionsPage> {
  String? _loadingAction;
  late final Map<String, bool> _toggleValues;

  @override
  void initState() {
    super.initState();
    _toggleValues = {
      for (final t in widget.module.toggles) t.label: t.initialValue,
    };
  }

  Future<void> _onTap(DebugAction action) async {
    if (action.requiresConfirmation) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: DebugColors.surface,
          title: Text(action.label, style: DebugTextStyles.title),
          content: const Text('Are you sure?', style: DebugTextStyles.value),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Confirm',
                style: TextStyle(color: DebugColors.error),
              ),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    setState(() => _loadingAction = action.label);
    await Future.wait([
      action.onTap(),
      Future<void>.delayed(const Duration(milliseconds: 300)),
    ]);
    if (mounted) setState(() => _loadingAction = null);
  }

  Future<void> _onToggle(DebugToggleAction toggle, bool value) async {
    setState(() => _toggleValues[toggle.label] = value);
    await toggle.onToggle(value);
  }

  @override
  Widget build(BuildContext context) {
    final hasActions = widget.module.actions.isNotEmpty;
    final hasToggles = widget.module.toggles.isNotEmpty;

    return DebugBottomSheetScaffold(
      title: 'Actions',
      children: [
        if (hasToggles)
          DebugSection(
            title: 'Toggles',
            children: widget.module.toggles.map((toggle) {
              return SwitchListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                secondary: Icon(toggle.icon, size: 18, color: DebugColors.textPrimary),
                title: Text(toggle.label, style: DebugTextStyles.label),
                value: _toggleValues[toggle.label] ?? toggle.initialValue,
                activeColor: DebugColors.accentDefault,
                onChanged: (value) => _onToggle(toggle, value),
              );
            }).toList(),
          ),
        if (hasActions)
          DebugSection(
            title: 'Available Actions',
            children: widget.module.actions.map((action) {
              final isLoading = _loadingAction == action.label;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DebugColors.textPrimary,
                      side: const BorderSide(color: DebugColors.border),
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    icon: isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(action.icon, size: 18),
                    label: Text(action.label, style: DebugTextStyles.label),
                    onPressed: isLoading ? null : () => _onTap(action),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}
