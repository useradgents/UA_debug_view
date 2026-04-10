import 'package:flutter/material.dart';
import '../../core/theme/debug_colors.dart';
import '../../core/theme/debug_text_styles.dart';
import '../../domain/module/debug_module.dart';

/// The main debug panel bottom sheet with internal navigation.
class DebugBottomSheet extends StatefulWidget {
  final ValueNotifier<List<DebugModule>> modulesNotifier;
  final Color accentColor;

  const DebugBottomSheet({
    required this.modulesNotifier,
    required this.accentColor,
    super.key,
  });

  static Future<void> show(
    BuildContext context, {
    required ValueNotifier<List<DebugModule>> modulesNotifier,
    required Color accentColor,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DebugBottomSheet(
        modulesNotifier: modulesNotifier,
        accentColor: accentColor,
      ),
    );
  }

  @override
  State<DebugBottomSheet> createState() => _DebugBottomSheetState();
}

class _DebugBottomSheetState extends State<DebugBottomSheet> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Container(
      height: screenHeight * 0.88,
      decoration: const BoxDecoration(
        color: DebugColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Handle indicator
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: DebugColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Expanded(
            child: Navigator(
              key: _navigatorKey,
              onGenerateRoute: (settings) => _buildRoute(settings),
            ),
          ),
        ],
      ),
    );
  }

  Route<dynamic> _buildRoute(RouteSettings settings) {
    Widget page;

    if (settings.name == '/') {
      page = ValueListenableBuilder<List<DebugModule>>(
        valueListenable: widget.modulesNotifier,
        builder: (_, modules, __) => _DebugMenuRoot(
          modules: modules,
          accentColor: widget.accentColor,
          modulesNotifier: widget.modulesNotifier,
        ),
      );
    } else {
      final moduleTitle = (settings.arguments as DebugModule).title;
      final fallback = settings.arguments as DebugModule;
      page = ValueListenableBuilder<List<DebugModule>>(
        valueListenable: widget.modulesNotifier,
        builder: (ctx, modules, __) {
          final fresh = modules.firstWhere(
            (m) => m.title == moduleTitle,
            orElse: () => fallback,
          );
          return fresh.buildPage(ctx);
        },
      );
    }

    return PageRouteBuilder<void>(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        );
      },
    );
  }
}

class _DebugMenuRoot extends StatelessWidget {
  final List<DebugModule> modules;
  final Color accentColor;
  final ValueNotifier<List<DebugModule>> modulesNotifier;

  const _DebugMenuRoot({
    required this.modules,
    required this.accentColor,
    required this.modulesNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DebugColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Text('Debug Panel', style: DebugTextStyles.title),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: modules.length,
              itemBuilder: (context, index) {
                final module = modules[index];
                final preview = module.buildPreview(context);
                return _ModuleTile(
                  module: module,
                  preview: preview,
                  accentColor: accentColor,
                  onTap: () {
                    final moduleTitle = module.title;
                    Navigator.of(context).push(
                      PageRouteBuilder<void>(
                        settings: RouteSettings(
                          name: '/$moduleTitle',
                          arguments: module,
                        ),
                        pageBuilder: (_, __, ___) =>
                            ValueListenableBuilder<List<DebugModule>>(
                          valueListenable: modulesNotifier,
                          builder: (ctx, freshModules, __) {
                            final fresh = freshModules.firstWhere(
                              (m) => m.title == moduleTitle,
                              orElse: () => module,
                            );
                            return fresh.buildPage(ctx);
                          },
                        ),
                        transitionsBuilder: (_, animation, __, child) {
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(1, 0),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            )),
                            child: child,
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleTile extends StatelessWidget {
  final DebugModule module;
  final Widget? preview;
  final Color accentColor;
  final VoidCallback onTap;

  const _ModuleTile({
    required this.module,
    required this.accentColor,
    required this.onTap,
    this.preview,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: DebugColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DebugColors.border, width: 0.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(module.icon, color: accentColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(module.title, style: DebugTextStyles.label),
                    if (preview != null) ...[
                      const SizedBox(height: 4),
                      preview!,
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: DebugColors.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
