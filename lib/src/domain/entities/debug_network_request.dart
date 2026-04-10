/// A captured HTTP request/response pair.
class DebugNetworkRequest {
  final DateTime timestamp;
  final String method;
  final String url;
  final Map<String, String> requestHeaders;
  final String? requestBody;
  final int? statusCode;
  final Map<String, String> responseHeaders;
  final String? responseBody;
  final Duration? duration;
  final Object? error;

  const DebugNetworkRequest({
    required this.timestamp,
    required this.method,
    required this.url,
    this.requestHeaders = const {},
    this.requestBody,
    this.statusCode,
    this.responseHeaders = const {},
    this.responseBody,
    this.duration,
    this.error,
  });

  bool get isSuccess => statusCode != null && statusCode! >= 200 && statusCode! < 300;
  bool get isError => error != null || (statusCode != null && statusCode! >= 400);
}
