import 'package:flutter/material.dart';
import '../../../core/debug_panel_scope.dart';
import '../../../core/theme/debug_colors.dart';
import '../../../core/theme/debug_text_styles.dart';
import '../../../core/widgets/debug_bottom_sheet_scaffold.dart';
import '../../../core/widgets/debug_section.dart';
import '../../../domain/entities/debug_environment.dart';
import '../../../domain/entities/test_account.dart';
import '../../../domain/module/debug_module.dart';

/// Lists test accounts per environment with a one-tap login button.
class TestAccountsModule extends DebugModule {
  final List<TestAccount> accounts;
  final Future<void> Function(TestAccount account) onLogin;
  final DebugEnvironment? currentEnvironment;

  const TestAccountsModule({
    required this.accounts,
    required this.onLogin,
    this.currentEnvironment,
  });

  @override
  String get title => 'Test Accounts';

  @override
  IconData get icon => Icons.people_outline;

  @override
  Widget buildPage(BuildContext context) => _TestAccountsPage(module: this);
}

class _TestAccountsPage extends StatefulWidget {
  final TestAccountsModule module;

  const _TestAccountsPage({required this.module});

  @override
  State<_TestAccountsPage> createState() => _TestAccountsPageState();
}

class _TestAccountsPageState extends State<_TestAccountsPage> {
  String? _loadingAccount;

  List<TestAccount> get _visibleAccounts {
    if (widget.module.currentEnvironment == null) return widget.module.accounts;
    return widget.module.accounts.where((a) {
      if (a.environments.isEmpty) return true;
      return a.environments.any((e) => e.name == widget.module.currentEnvironment!.name);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final accounts = _visibleAccounts;

    return DebugBottomSheetScaffold(
      title: 'Test Accounts',
      children: [
        DebugSection(
          title: 'Accounts',
          children: accounts.isEmpty
              ? [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        'No accounts for current environment',
                        style: DebugTextStyles.value,
                      ),
                    ),
                  ),
                ]
              : accounts.map((account) {
                  final isLoading = _loadingAccount == account.label;
                  return _AccountTile(
                    account: account,
                    isLoading: isLoading,
                    onTap: () async {
                      final closePanel = DebugPanelScope.maybeOf(context)?.closePanel;
                      setState(() => _loadingAccount = account.label);
                      await widget.module.onLogin(account);
                      if (mounted) {
                        setState(() => _loadingAccount = null);
                        closePanel?.call();
                      }
                    },
                  );
                }).toList(),
        ),
      ],
    );
  }
}

class _AccountTile extends StatelessWidget {
  final TestAccount account;
  final bool isLoading;
  final VoidCallback onTap;

  const _AccountTile({
    required this.account,
    required this.isLoading,
    required this.onTap,
  });

  static const TextStyle _defaultDescriptionStyle = TextStyle(
    color: Colors.white,
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle _tagStyle = TextStyle(
    color: DebugColors.textSecondary,
    fontSize: 11,
    fontWeight: FontWeight.w400,
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(account.label, style: DebugTextStyles.label),
                if (account.description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    account.description!,
                    style: account.descriptionStyle ?? _defaultDescriptionStyle,
                  ),
                ],
                if (account.tags.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: account.tags
                        .map(
                          (tag) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: DebugColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(tag, style: _tagStyle),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 64,
            height: 32,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: DebugColors.accentDefault,
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
                textStyle: DebugTextStyles.caption,
              ),
              onPressed: isLoading ? null : onTap,
              child: isLoading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Login'),
            ),
          ),
        ],
      ),
    );
  }
}
