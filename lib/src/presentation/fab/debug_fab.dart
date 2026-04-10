import 'package:flutter/material.dart';
import '../../core/theme/debug_colors.dart';
import '../../core/theme/debug_text_styles.dart';

/// A draggable floating action button that opens the debug panel.
/// Shows an environment badge when [environmentTag] is provided.
class DebugFab extends StatefulWidget {
  final VoidCallback onTap;
  final String? environmentTag;
  final Color? environmentColor;
  final Color accentColor;

  const DebugFab({
    required this.onTap,
    required this.accentColor,
    super.key,
    this.environmentTag,
    this.environmentColor,
  });

  @override
  State<DebugFab> createState() => _DebugFabState();
}

class _DebugFabState extends State<DebugFab> {
  double _top = 0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = MediaQuery.sizeOf(context);
      setState(() => _top = size.height * 0.4);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final safeTop = MediaQuery.paddingOf(context).top;
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return Positioned(
      right: 12,
      top: _top,
      child: GestureDetector(
        onVerticalDragUpdate: (details) {
          setState(() {
            _isDragging = true;
            _top = (_top + details.delta.dy).clamp(
              safeTop + 8,
              screenHeight - safeBottom - 60,
            );
          });
        },
        onVerticalDragEnd: (_) => setState(() => _isDragging = false),
        onTap: _isDragging ? null : widget.onTap,
        child: AnimatedOpacity(
          opacity: _isDragging ? 0.6 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: _FabWidget(
            accentColor: widget.accentColor,
            environmentTag: widget.environmentTag,
            environmentColor: widget.environmentColor,
          ),
        ),
      ),
    );
  }
}

class _FabWidget extends StatelessWidget {
  final Color accentColor;
  final String? environmentTag;
  final Color? environmentColor;

  const _FabWidget({
    required this.accentColor,
    this.environmentTag,
    this.environmentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: DebugColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: accentColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(Icons.bug_report_outlined, color: accentColor, size: 22),
        ),
        if (environmentTag != null)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: environmentColor ?? accentColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                environmentTag!,
                style: DebugTextStyles.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 9,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
