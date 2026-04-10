import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/widgets/debug_bottom_sheet_scaffold.dart';
import '../../../core/widgets/debug_info_row.dart';
import '../../../core/widgets/debug_section.dart';
import '../../../domain/module/debug_module.dart';

/// Shows app version, build number, bundle ID, and optional extra fields.
class AppInfoModule extends DebugModule {
  /// Override the app version (auto-detected via package_info_plus if null).
  final String? version;

  /// Override the build number (auto-detected if null).
  final String? buildNumber;

  /// Override the bundle ID / package name (auto-detected if null).
  final String? bundleId;

  /// Extra key/value pairs to display (e.g. git SHA, build date).
  final Map<String, String> extras;

  const AppInfoModule({
    this.version,
    this.buildNumber,
    this.bundleId,
    this.extras = const {},
  });

  @override
  String get title => 'App Info';

  @override
  IconData get icon => Icons.info_outline;

  @override
  Widget buildPage(BuildContext context) => _AppInfoPage(module: this);
}

class _AppInfoPage extends StatefulWidget {
  final AppInfoModule module;

  const _AppInfoPage({required this.module});

  @override
  State<_AppInfoPage> createState() => _AppInfoPageState();
}

class _AppInfoPageState extends State<_AppInfoPage> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _packageInfo = info);
  }

  @override
  Widget build(BuildContext context) {
    final version = widget.module.version ?? _packageInfo?.version ?? '—';
    final buildNumber = widget.module.buildNumber ?? _packageInfo?.buildNumber ?? '—';
    final bundleId = widget.module.bundleId ?? _packageInfo?.packageName ?? '—';
    final appName = _packageInfo?.appName ?? '—';

    return DebugBottomSheetScaffold(
      title: 'App Info',
      children: [
        DebugSection(
          title: 'Application',
          children: [
            DebugInfoRow(label: 'Name', value: appName),
            DebugInfoRow(label: 'Version', value: version),
            DebugInfoRow(label: 'Build', value: buildNumber),
            DebugInfoRow(label: 'Bundle ID', value: bundleId),
          ],
        ),
        if (widget.module.extras.isNotEmpty)
          DebugSection(
            title: 'Build Info',
            children: widget.module.extras.entries
                .map((e) => DebugInfoRow(label: e.key, value: e.value))
                .toList(),
          ),
      ],
    );
  }
}
