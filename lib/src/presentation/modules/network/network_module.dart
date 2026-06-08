import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/debug_colors.dart';
import '../../../core/theme/debug_text_styles.dart';
import '../../../core/widgets/debug_bottom_sheet_scaffold.dart';
import '../../../data/network/debug_network_store.dart';
import '../../../domain/entities/debug_network_request.dart';
import '../../../domain/module/debug_module.dart';

/// Displays captured HTTP requests in a Charles Proxy-style interface.
///
/// Wire up by setting `HttpOverrides.global = DebugHttpOverrides()` in your
/// main.dart, which captures every `dart:io` request, its response, bodies,
/// headers, timing and errors.
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
    DebugNetworkStore.instance
      ..maxRequests = maxRequests
      ..ignoredPaths = ignoredPaths;
    return _NetworkPage(module: this);
  }
}

// ── Body formatting ─────────────────────────────────────────────────────────

/// Pretty-print a body as indented JSON when it looks like JSON; otherwise
/// return it untouched (already a placeholder for binary payloads).
String _prettyBody(String body) {
  final trimmed = body.trimLeft();
  if (!trimmed.startsWith('{') && !trimmed.startsWith('[')) return body;
  try {
    return const JsonEncoder.withIndent('  ').convert(jsonDecode(body));
  } catch (_) {
    return body;
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
            // Ignored paths are already dropped at the store level, so the
            // emitted list contains only the traffic we want to show.
            final requests = snapshot.data ?? [];

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
    if (request.isPending) return DebugColors.textSecondary;
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
            if (request.duration != null)
              Text(
                '${request.duration!.inMilliseconds}ms',
                style: DebugTextStyles.caption,
              ),
            const SizedBox(width: 8),
            _TrailingStatus(request: request, color: _statusColor),
          ],
        ),
      ),
    );
  }
}

class _TrailingStatus extends StatelessWidget {
  final DebugNetworkRequest request;
  final Color color;

  const _TrailingStatus({required this.request, required this.color});

  @override
  Widget build(BuildContext context) {
    if (request.isPending) {
      return const SizedBox(
        width: 12,
        height: 12,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          color: DebugColors.textSecondary,
        ),
      );
    }
    if (request.error != null) {
      return Icon(Icons.error_outline, size: 16, color: color);
    }
    if (request.statusCode != null) {
      return Text(
        '${request.statusCode}',
        style: DebugTextStyles.caption.copyWith(color: color),
      );
    }
    return const SizedBox.shrink();
  }
}

class _RequestDetailPage extends StatelessWidget {
  final DebugNetworkRequest request;

  const _RequestDetailPage({required this.request});

  @override
  Widget build(BuildContext context) {
    final hasReqBody = request.requestBody != null && request.requestBody!.isNotEmpty;
    final hasRespBody = request.responseBody != null && request.responseBody!.isNotEmpty;

    return Scaffold(
      backgroundColor: DebugColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(request.method, style: DebugTextStyles.title),
        iconTheme: const IconThemeData(color: DebugColors.textPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SelectableText(request.url, style: DebugTextStyles.code),
          const SizedBox(height: 16),

          // ── Summary chips: status + timing ──────────────────────────────
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (request.statusCode != null)
                _Chip(
                  label: 'Status ${request.statusCode}',
                  color: request.isError
                      ? DebugColors.error
                      : request.isSuccess
                          ? DebugColors.success
                          : DebugColors.warning,
                ),
              if (request.duration != null)
                _Chip(label: '${request.duration!.inMilliseconds} ms'),
              if (request.isPending) const _Chip(label: 'Pending…'),
            ],
          ),

          if (request.error != null) ...[
            const SizedBox(height: 16),
            const _SectionTitle('Error'),
            const SizedBox(height: 8),
            Text(
              request.error.toString(),
              style: DebugTextStyles.code.copyWith(color: DebugColors.error),
            ),
          ],

          _HeadersSection(title: 'Request Headers', headers: request.requestHeaders),
          if (hasReqBody)
            _BodySection(title: 'Request Body', body: request.requestBody!),

          _HeadersSection(title: 'Response Headers', headers: request.responseHeaders),
          if (hasRespBody)
            _BodySection(title: 'Response Body', body: request.responseBody!),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color? color;
  const _Chip({required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c == null ? DebugColors.surface : c.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: c == null ? DebugColors.border : c.withValues(alpha: 0.4),
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: c == null
            ? DebugTextStyles.caption
            : DebugTextStyles.caption.copyWith(color: c),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) =>
      Text(title.toUpperCase(), style: DebugTextStyles.sectionTitle);
}

class _HeadersSection extends StatelessWidget {
  final String title;
  final Map<String, String> headers;

  const _HeadersSection({required this.title, required this.headers});

  @override
  Widget build(BuildContext context) {
    if (headers.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _SectionTitle(title),
        const SizedBox(height: 8),
        ...headers.entries.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: SelectableText.rich(
              TextSpan(
                style: DebugTextStyles.code,
                children: [
                  TextSpan(
                    text: '${e.key}: ',
                    style: DebugTextStyles.code
                        .copyWith(color: DebugColors.textPrimary),
                  ),
                  TextSpan(text: e.value),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BodySection extends StatefulWidget {
  final String title;
  final String body;

  const _BodySection({required this.title, required this.body});

  @override
  State<_BodySection> createState() => _BodySectionState();
}

class _BodySectionState extends State<_BodySection> {
  bool _copied = false;

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final formatted = _prettyBody(widget.body);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _SectionTitle(widget.title)),
            GestureDetector(
              onTap: () => _copy(formatted),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: _copied
                    ? const Icon(Icons.check,
                        key: ValueKey('copied'),
                        size: 14,
                        color: DebugColors.success)
                    : const Icon(Icons.copy,
                        key: ValueKey('copy'),
                        size: 14,
                        color: DebugColors.textSecondary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: DebugColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: DebugColors.border, width: 0.5),
          ),
          child: SelectableText(formatted, style: DebugTextStyles.code),
        ),
      ],
    );
  }
}
