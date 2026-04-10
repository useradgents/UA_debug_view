import 'package:flutter/material.dart';
import '../../../core/widgets/debug_bottom_sheet_scaffold.dart';
import '../../../core/widgets/debug_copy_tile.dart';
import '../../../core/widgets/debug_section.dart';
import '../../../core/widgets/debug_info_row.dart';
import '../../../core/theme/debug_colors.dart';
import '../../../domain/module/debug_module.dart';

/// Displays authentication tokens, expiry, and optional user info.
class AuthModule extends DebugModule {
  final String? Function() accessToken;
  final String? Function()? refreshToken;
  final DateTime? Function()? tokenExpiry;
  final Map<String, String? Function()> additionalInfo;
  final Future<void> Function()? onLogout;

  const AuthModule({
    required this.accessToken,
    this.refreshToken,
    this.tokenExpiry,
    this.additionalInfo = const {},
    this.onLogout,
  });

  @override
  String get title => 'Auth';

  @override
  IconData get icon => Icons.lock_outline;

  @override
  Widget buildPage(BuildContext context) => _AuthPage(module: this);
}

class _AuthPage extends StatefulWidget {
  final AuthModule module;

  const _AuthPage({required this.module});

  @override
  State<_AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<_AuthPage> {
  bool _isLoggingOut = false;

  String _formatExpiry(DateTime? expiry) {
    if (expiry == null) return '—';
    final diff = expiry.difference(DateTime.now());
    if (diff.isNegative) {
      return 'Expired ${diff.abs().inMinutes}m ago';
    }
    return 'Expires in ${diff.inMinutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final accessToken = widget.module.accessToken();
    final refreshToken = widget.module.refreshToken?.call();
    final expiry = widget.module.tokenExpiry?.call();

    return DebugBottomSheetScaffold(
      title: 'Auth',
      children: [
        DebugSection(
          title: 'Tokens',
          children: [
            if (accessToken != null)
              DebugCopyTile(label: 'Access Token', value: accessToken)
            else
              const DebugInfoRow(label: 'Access Token', value: '—', copyable: false),
            if (refreshToken != null)
              DebugCopyTile(label: 'Refresh Token', value: refreshToken),
            if (expiry != null)
              DebugInfoRow(label: 'Expiry', value: _formatExpiry(expiry), copyable: false),
          ],
        ),
        if (widget.module.additionalInfo.isNotEmpty)
          DebugSection(
            title: 'User Info',
            children: widget.module.additionalInfo.entries.map((e) {
              final value = e.value();
              return DebugInfoRow(
                label: e.key,
                value: value ?? '—',
              );
            }).toList(),
          ),
        if (widget.module.onLogout != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: DebugColors.error,
                  side: const BorderSide(color: DebugColors.error),
                ),
                onPressed: _isLoggingOut
                    ? null
                    : () async {
                        setState(() => _isLoggingOut = true);
                        await widget.module.onLogout!();
                        if (mounted) setState(() => _isLoggingOut = false);
                      },
                child: _isLoggingOut
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Logout'),
              ),
            ),
          ),
      ],
    );
  }
}
