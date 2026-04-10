import 'package:flutter/material.dart';
import '../../../core/theme/debug_colors.dart';
import '../../../core/theme/debug_text_styles.dart';
import '../../../core/widgets/debug_bottom_sheet_scaffold.dart';
import '../../../domain/module/debug_module.dart';

/// A section entry for [DesignSystemModule].
class DesignSystemSection {
  final String title;
  final Widget Function(BuildContext context) builder;

  const DesignSystemSection({
    required this.title,
    required this.builder,
  });
}

/// Hosts custom design system preview pages (colors, typography, components).
class DesignSystemModule extends DebugModule {
  final List<DesignSystemSection> sections;

  const DesignSystemModule({required this.sections});

  @override
  String get title => 'Design System';

  @override
  IconData get icon => Icons.palette_outlined;

  @override
  Widget buildPage(BuildContext context) => _DesignSystemPage(module: this);
}

class _DesignSystemPage extends StatelessWidget {
  final DesignSystemModule module;

  const _DesignSystemPage({required this.module});

  @override
  Widget build(BuildContext context) {
    return DebugBottomSheetScaffold(
      title: 'Design System',
      children: module.sections
          .map(
            (section) => _SectionTile(
              section: section,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => Scaffold(
                    backgroundColor: DebugColors.background,
                    appBar: AppBar(
                      backgroundColor: DebugColors.surface,
                      title: Text(section.title, style: DebugTextStyles.title),
                      iconTheme: const IconThemeData(color: DebugColors.textPrimary),
                    ),
                    body: section.builder(context),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _SectionTile extends StatelessWidget {
  final DesignSystemSection section;
  final VoidCallback onTap;

  const _SectionTile({required this.section, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(section.title, style: DebugTextStyles.label),
            ),
            const Icon(
              Icons.chevron_right,
              color: DebugColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
