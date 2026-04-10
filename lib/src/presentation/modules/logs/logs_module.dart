import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/debug_colors.dart';
import '../../../core/theme/debug_text_styles.dart';
import '../../../core/widgets/debug_bottom_sheet_scaffold.dart';
import '../../../data/logger/debug_logger.dart';
import '../../../domain/entities/debug_log.dart';
import '../../../domain/module/debug_module.dart';

/// Displays a filterable, scrollable log console.
class LogsModule extends DebugModule {
  /// Optional external log stream. If null, uses [DebugLogger.stream].
  final Stream<DebugLog>? logStream;
  final int maxLogs;
  final List<LogLevel> levels;

  const LogsModule({
    this.logStream,
    this.maxLogs = 500,
    this.levels = LogLevel.values,
  });

  @override
  String get title => 'Logs';

  @override
  IconData get icon => Icons.terminal;

  @override
  Widget buildPage(BuildContext context) => _LogsPage(module: this);
}

class _LogsPage extends StatefulWidget {
  final LogsModule module;

  const _LogsPage({required this.module});

  @override
  State<_LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<_LogsPage> {
  final List<DebugLog> _logs = [];
  StreamSubscription<DebugLog>? _subscription;
  LogLevel? _filterLevel;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Restore logs from buffer so history survives bottom sheet close/reopen.
    // Only applies when using the built-in DebugLogger (not a custom stream).
    if (widget.module.logStream == null) {
      _logs.addAll(DebugLogger.logs.take(widget.module.maxLogs));
    }
    _subscription = (widget.module.logStream ?? DebugLogger.stream).listen((log) {
      if (_logs.length >= widget.module.maxLogs) _logs.removeLast();
      if (mounted) setState(() => _logs.insert(0, log));
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  List<DebugLog> get _filteredLogs {
    if (_filterLevel == null) return _logs;
    return _logs.where((l) => l.level == _filterLevel).toList();
  }

  Color _levelColor(LogLevel level) {
    return switch (level) {
      LogLevel.verbose => DebugColors.logVerbose,
      LogLevel.debug => DebugColors.logDebug,
      LogLevel.info => DebugColors.logInfo,
      LogLevel.warning => DebugColors.logWarning,
      LogLevel.error => DebugColors.logError,
    };
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredLogs;

    return DebugBottomSheetScaffold(
      title: 'Logs',
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_outline, color: DebugColors.textSecondary),
          onPressed: () {
            DebugLogger.clear();
            setState(() => _logs.clear());
          },
        ),
      ],
      children: [
        // Level filter chips
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _LevelChip(
                label: 'All',
                isSelected: _filterLevel == null,
                color: DebugColors.textSecondary,
                onTap: () => setState(() => _filterLevel = null),
              ),
              ...LogLevel.values.map((level) => _LevelChip(
                    label: level.name.toUpperCase(),
                    isSelected: _filterLevel == level,
                    color: _levelColor(level),
                    onTap: () => setState(() => _filterLevel = level),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text('No logs yet', style: DebugTextStyles.value),
            ),
          )
        else
          ...filtered.map((log) => _LogTile(log: log, levelColor: _levelColor(log.level))),
      ],
    );
  }
}

class _LevelChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _LevelChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : DebugColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : DebugColors.border,
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: DebugTextStyles.caption.copyWith(
            color: isSelected ? color : DebugColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _LogTile extends StatefulWidget {
  final DebugLog log;
  final Color levelColor;

  const _LogTile({required this.log, required this.levelColor});

  @override
  State<_LogTile> createState() => _LogTileState();
}

class _LogTileState extends State<_LogTile> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      reverseDuration: const Duration(milliseconds: 600),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onLongPress() async {
    await Clipboard.setData(ClipboardData(text: widget.log.message));
    setState(() => _copied = true);
    await _controller.forward();
    await Future<void>.delayed(const Duration(milliseconds: 800));
    await _controller.reverse();
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: _onLongPress,
      child: Stack(
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: DebugColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border(left: BorderSide(color: widget.levelColor, width: 3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (widget.log.tag != null) ...[
                      Text(widget.log.tag!, style: DebugTextStyles.caption.copyWith(color: widget.levelColor)),
                      const Text(' · ', style: DebugTextStyles.caption),
                    ],
                    Text(
                      '${widget.log.timestamp.hour.toString().padLeft(2, '0')}:'
                      '${widget.log.timestamp.minute.toString().padLeft(2, '0')}:'
                      '${widget.log.timestamp.second.toString().padLeft(2, '0')}',
                      style: DebugTextStyles.caption,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(widget.log.message, style: DebugTextStyles.code),
              ],
            ),
          ),
          if (_copied)
            Positioned.fill(
              child: FadeTransition(
                opacity: _fade,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: DebugColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: DebugColors.success, width: 0.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Copied',
                    style: DebugTextStyles.caption.copyWith(
                      color: DebugColors.success,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
