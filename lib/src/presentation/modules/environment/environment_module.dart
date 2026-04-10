import 'package:flutter/material.dart';
import '../../../core/theme/debug_colors.dart';
import '../../../core/theme/debug_text_styles.dart';
import '../../../core/widgets/debug_bottom_sheet_scaffold.dart';
import '../../../core/widgets/debug_info_row.dart';
import '../../../core/widgets/debug_section.dart';
import '../../../domain/entities/debug_environment.dart';
import '../../../domain/module/debug_module.dart';

/// Displays current environment and allows switching between environments.
class EnvironmentModule extends DebugModule with DebugEnvironmentProvider {
  final List<DebugEnvironment> environments;
  @override
  final DebugEnvironment currentEnvironment;
  final Future<void> Function(DebugEnvironment env) onSwitch;
  final bool showConfirmDialog;

  const EnvironmentModule({
    required this.environments,
    required this.currentEnvironment,
    required this.onSwitch,
    this.showConfirmDialog = true,
  });

  @override
  String get title => 'Environment';

  @override
  IconData get icon => Icons.cloud_outlined;

  @override
  Widget? buildPreview(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: currentEnvironment.color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: currentEnvironment.color, width: 0.5),
          ),
          child: Text(
            currentEnvironment.tag,
            style: DebugTextStyles.caption.copyWith(
              color: currentEnvironment.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(currentEnvironment.name, style: DebugTextStyles.value),
      ],
    );
  }

  @override
  Widget buildPage(BuildContext context) => _EnvironmentPage(module: this);
}

class _EnvironmentPage extends StatefulWidget {
  final EnvironmentModule module;

  const _EnvironmentPage({required this.module});

  @override
  State<_EnvironmentPage> createState() => _EnvironmentPageState();
}

class _EnvironmentPageState extends State<_EnvironmentPage> {
  bool _isSwitching = false;
  late DebugEnvironment _currentEnv;

  @override
  void initState() {
    super.initState();
    _currentEnv = widget.module.currentEnvironment;
  }

  Future<void> _onSwitch(DebugEnvironment env) async {
    if (env.name == _currentEnv.name) return;

    if (widget.module.showConfirmDialog) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => _ConfirmSwitchDialog(environment: env),
      );
      if (confirmed != true) return;
    }

    setState(() => _isSwitching = true);
    try {
      await widget.module.onSwitch(env);
      if (mounted) setState(() => _currentEnv = env);
    } finally {
      if (mounted) setState(() => _isSwitching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DebugBottomSheetScaffold(
      title: 'Environment',
      children: [
        DebugSection(
          title: 'Current',
          children: [
            DebugInfoRow(
              label: 'Active',
              value: _currentEnv.name,
            ),
            ..._currentEnv.values.entries.map(
              (e) => DebugInfoRow(label: e.key, value: e.value),
            ),
          ],
        ),
        DebugSection(
          title: 'Switch Environment',
          children: widget.module.environments.map((env) {
            final isActive = env.name == _currentEnv.name;
            return _EnvironmentTile(
              environment: env,
              isActive: isActive,
              isLoading: _isSwitching,
              onTap: () => _onSwitch(env),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _EnvironmentTile extends StatelessWidget {
  final DebugEnvironment environment;
  final bool isActive;
  final bool isLoading;
  final VoidCallback onTap;

  const _EnvironmentTile({
    required this.environment,
    required this.isActive,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? environment.color : DebugColors.textTertiary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                environment.name,
                style: DebugTextStyles.label.copyWith(
                  color: isActive
                      ? DebugColors.textPrimary
                      : DebugColors.textSecondary,
                ),
              ),
            ),
            if (isActive)
              const Icon(Icons.check, size: 16, color: DebugColors.success),
          ],
        ),
      ),
    );
  }
}

class _ConfirmSwitchDialog extends StatelessWidget {
  final DebugEnvironment environment;

  const _ConfirmSwitchDialog({required this.environment});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: DebugColors.surface,
      title: const Text('Switch environment?', style: DebugTextStyles.title),
      content: Text(
        'Switching to ${environment.name} may clear your session and restart the app.',
        style: DebugTextStyles.value,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            'Switch to ${environment.tag}',
            style: TextStyle(color: environment.color),
          ),
        ),
      ],
    );
  }
}
