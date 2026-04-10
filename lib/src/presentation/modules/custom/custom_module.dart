import 'package:flutter/material.dart';
import '../../../core/widgets/debug_bottom_sheet_scaffold.dart';
import '../../../domain/module/debug_module.dart';

/// A fully custom module — supply your own title, icon, and widget.
class CustomModule extends DebugModule {
  final String _title;
  final IconData _icon;
  final Widget Function(BuildContext context) builder;

  const CustomModule({
    required String title,
    required IconData icon,
    required this.builder,
  })  : _title = title,
        _icon = icon;

  @override
  String get title => _title;

  @override
  IconData get icon => _icon;

  @override
  Widget buildPage(BuildContext context) {
    return DebugBottomSheetScaffold(
      title: _title,
      body: builder(context),
    );
  }
}
