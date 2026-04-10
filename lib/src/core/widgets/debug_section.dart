import 'package:flutter/material.dart';
import '../theme/debug_colors.dart';
import '../theme/debug_text_styles.dart';

/// A titled section container used to group related info in the debug panel.
class DebugSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const DebugSection({
    required this.title,
    required this.children,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: DebugTextStyles.sectionTitle,
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: DebugColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: DebugColors.border, width: 0.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(children: children),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
