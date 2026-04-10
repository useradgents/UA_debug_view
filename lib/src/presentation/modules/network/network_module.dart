import 'package:flutter/material.dart';
import '../../../core/theme/debug_colors.dart';
import '../../../core/theme/debug_text_styles.dart';
import '../../../core/widgets/debug_bottom_sheet_scaffold.dart';
import '../../../data/network/debug_network_store.dart';
import '../../../domain/entities/debug_network_request.dart';
import '../../../domain/module/debug_module.dart';

/// Displays captured HTTP requests in a Charles Proxy-style interface.
///
/// Wire up by setting `HttpOverrides.global = DebugHttpOverrides()` in your
/// main.dart, or by using [DebugHttpClientAdapter] with Dio.
class NetworkModule extends DebugModule {
  final int maxRequests;
  final List<String> ignoredPaths;

  const NetworkModule({
    this.maxRequests = 100,
    this.ignoredPaths = const [],
  });

  @override
  String get title => 'Network';

  @override
  IconData get icon => Icons.wifi;

  @override
  Widget buildPage(BuildContext context) {
    DebugNetworkStore.instance.maxRequests = maxRequests;
    return _NetworkPage(module: this);
  }
}

class _NetworkPage extends StatefulWidget {
  final NetworkModule module;

  const _NetworkPage({required this.module});

  @override
  State<_NetworkPage> createState() => _NetworkPageState();
}

class _NetworkPageState extends State<_NetworkPage> {
  final _store = DebugNetworkStore.instance;

  @override
  Widget build(BuildContext context) {
    return DebugBottomSheetScaffold(
      title: 'Network',
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_outline, color: DebugColors.textSecondary),
          onPressed: () => setState(() => _store.clear()),
        ),
      ],
      children: [
        StreamBuilder<List<DebugNetworkRequest>>(
          stream: _store.stream,
          initialData: _store.requests,
          builder: (context, snapshot) {
            final requests = (snapshot.data ?? []).where((r) {
              return !widget.module.ignoredPaths
                  .any((path) => r.url.contains(path));
            }).toList();

            if (requests.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    'No requests captured yet',
                    style: DebugTextStyles.value,
                  ),
                ),
              );
            }

            return Column(
              children: requests
                  .map((r) => _RequestTile(request: r))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _RequestTile extends StatelessWidget {
  final DebugNetworkRequest request;

  const _RequestTile({required this.request});

  Color get _statusColor {
    if (request.isError) return DebugColors.error;
    if (request.isSuccess) return DebugColors.success;
    return DebugColors.warning;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        PageRouteBuilder<void>(
          pageBuilder: (_, __, ___) => _RequestDetailPage(request: request),
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
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: DebugColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: DebugColors.border, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                request.method,
                style: DebugTextStyles.caption.copyWith(color: _statusColor),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                Uri.parse(request.url).path,
                style: DebugTextStyles.value,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            if (request.statusCode != null)
              Text(
                '${request.statusCode}',
                style: DebugTextStyles.caption.copyWith(color: _statusColor),
              ),
          ],
        ),
      ),
    );
  }
}

class _RequestDetailPage extends StatelessWidget {
  final DebugNetworkRequest request;

  const _RequestDetailPage({required this.request});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DebugColors.background,
      appBar: AppBar(
        backgroundColor: DebugColors.surface,
        title: Text(request.method, style: DebugTextStyles.title),
        iconTheme: const IconThemeData(color: DebugColors.textPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(request.url, style: DebugTextStyles.code),
          const SizedBox(height: 16),
          if (request.statusCode != null)
            Text('Status: ${request.statusCode}', style: DebugTextStyles.label),
          if (request.duration != null)
            Text('Duration: ${request.duration!.inMilliseconds}ms', style: DebugTextStyles.value),
          if (request.requestBody != null) ...[
            const SizedBox(height: 16),
            const Text('Request Body', style: DebugTextStyles.sectionTitle),
            const SizedBox(height: 8),
            Text(request.requestBody!, style: DebugTextStyles.code),
          ],
          if (request.responseBody != null) ...[
            const SizedBox(height: 16),
            const Text('Response Body', style: DebugTextStyles.sectionTitle),
            const SizedBox(height: 8),
            Text(request.responseBody!, style: DebugTextStyles.code),
          ],
        ],
      ),
    );
  }
}
