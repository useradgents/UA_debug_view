import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/debug_colors.dart';
import '../../../core/widgets/debug_bottom_sheet_scaffold.dart';
import '../../../core/widgets/debug_section.dart';
import '../../../core/widgets/debug_info_row.dart';
import '../../../domain/entities/debug_storage_provider.dart';
import '../../../domain/module/debug_module.dart';

/// Browse and delete SharedPreferences keys (and optional custom storages).
class StorageModule extends DebugModule {
  final List<DebugStorageProvider> additionalStorages;
  final List<String> sensitiveKeys;

  const StorageModule({
    this.additionalStorages = const [],
    this.sensitiveKeys = const [],
  });

  @override
  String get title => 'Storage';

  @override
  IconData get icon => Icons.storage_outlined;

  @override
  Widget buildPage(BuildContext context) => _StoragePage(module: this);
}

class _StoragePage extends StatefulWidget {
  final StorageModule module;

  const _StoragePage({required this.module});

  @override
  State<_StoragePage> createState() => _StoragePageState();
}

class _StoragePageState extends State<_StoragePage> {
  Map<String, String>? _prefs;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final map = <String, String>{};
    for (final key in keys) {
      final value = prefs.get(key);
      map[key] = value?.toString() ?? '—';
    }
    if (mounted) {
      setState(() {
        _prefs = map;
        _isLoading = false;
      });
    }
  }

  bool _isSensitive(String key) {
    return widget.module.sensitiveKeys.any(
      (s) => key.toLowerCase().contains(s.toLowerCase()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DebugBottomSheetScaffold(
      title: 'Storage',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: DebugColors.textSecondary),
          onPressed: _load,
        ),
      ],
      children: [
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else ...[
          DebugSection(
            title: 'SharedPreferences (${_prefs?.length ?? 0} keys)',
            children: _prefs?.isEmpty == true
                ? [const DebugInfoRow(label: 'Empty', value: '', copyable: false)]
                : (_prefs?.entries.map((e) {
                    final isSensitive = _isSensitive(e.key);
                    return DebugInfoRow(
                      label: e.key,
                      value: isSensitive ? '••••••' : e.value,
                      copyable: !isSensitive,
                    );
                  }).toList() ?? []),
          ),
          ...widget.module.additionalStorages.map(
            (provider) => _CustomStorageSection(
              provider: provider,
              sensitiveKeys: widget.module.sensitiveKeys,
            ),
          ),
        ],
      ],
    );
  }
}

class _CustomStorageSection extends StatefulWidget {
  final DebugStorageProvider provider;
  final List<String> sensitiveKeys;

  const _CustomStorageSection({
    required this.provider,
    required this.sensitiveKeys,
  });

  @override
  State<_CustomStorageSection> createState() => _CustomStorageSectionState();
}

class _CustomStorageSectionState extends State<_CustomStorageSection> {
  Map<String, String>? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final data = await widget.provider.read();
    if (mounted) {
      setState(() {
        _data = data;
        _isLoading = false;
      });
    }
  }

  bool _isSensitive(String key) {
    return widget.sensitiveKeys.any(
      (s) => key.toLowerCase().contains(s.toLowerCase()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return DebugSection(
        title: widget.provider.name,
        children: const [Center(child: CircularProgressIndicator())],
      );
    }

    return DebugSection(
      title: '${widget.provider.name} (${_data?.length ?? 0} keys)',
      children: _data?.isEmpty == true
          ? [const DebugInfoRow(label: 'Empty', value: '', copyable: false)]
          : (_data?.entries.map((e) {
              final isSensitive = _isSensitive(e.key);
              return DebugInfoRow(
                label: e.key,
                value: isSensitive ? '••••••' : e.value,
                copyable: !isSensitive,
              );
            }).toList() ?? []),
    );
  }
}
