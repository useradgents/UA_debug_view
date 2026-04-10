import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/debug_colors.dart';
import '../theme/debug_text_styles.dart';

/// A label/value row used throughout the debug panel.
/// Long-pressing the value copies it to the clipboard.
class DebugInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool copyable;

  const DebugInfoRow({
    required this.label,
    required this.value,
    super.key,
    this.copyable = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: copyable
          ? () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$label copied'),
                  duration: const Duration(seconds: 1),
                  backgroundColor: DebugColors.surface,
                ),
              );
            }
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Text(label, style: DebugTextStyles.label),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: Text(
                value,
                style: DebugTextStyles.value,
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
