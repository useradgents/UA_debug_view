import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/debug_colors.dart';
import '../theme/debug_text_styles.dart';

/// A row with a copy-to-clipboard button on the right.
class DebugCopyTile extends StatelessWidget {
  final String label;
  final String value;

  const DebugCopyTile({
    required this.label,
    required this.value,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: DebugTextStyles.label),
                const SizedBox(height: 2),
                Text(
                  value.length > 40
                      ? '${value.substring(0, 10)}...${value.substring(value.length - 10)}'
                      : value,
                  style: DebugTextStyles.code,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 16, color: DebugColors.textSecondary),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$label copied'),
                  duration: const Duration(seconds: 1),
                  backgroundColor: DebugColors.surface,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
