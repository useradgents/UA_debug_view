/// A captured HTTP request/response pair.
///
/// The request fields ([method], [url], [requestHeaders], [requestBody]) are
/// known up-front. The response fields ([statusCode], [responseHeaders],
/// [responseBody], [duration], [error]) are filled in progressively as the
/// response arrives, and [completed] flips to `true` once the body has been
/// fully read (or the request failed). This lets the UI show a request as
/// "pending" and update it in place.
class DebugNetworkRequest {
  /// Stable identifier used to update this entry once the response completes.
  final String id;
  final DateTime timestamp;
  final String method;
  final String url;
  final Map<String, String> requestHeaders;
  final String? requestBody;

  int? statusCode;
  Map<String, String> responseHeaders;
  String? responseBody;
  Duration? duration;
  Object? error;
  bool completed;

  DebugNetworkRequest({
    required this.timestamp,
    required this.method,
    required this.url,
    String? id,
    this.requestHeaders = const {},
    this.requestBody,
    this.statusCode,
    this.responseHeaders = const {},
    this.responseBody,
    this.duration,
    this.error,
    this.completed = false,
  }) : id = id ?? _generateId();

  bool get isSuccess =>
      statusCode != null && statusCode! >= 200 && statusCode! < 300;
  bool get isError =>
      error != null || (statusCode != null && statusCode! >= 400);

  /// `true` while we're still waiting for the response (or its body).
  bool get isPending => !completed && error == null;

  static int _counter = 0;
  static String _generateId() =>
      '${DateTime.now().microsecondsSinceEpoch}_${_counter++}';
}
