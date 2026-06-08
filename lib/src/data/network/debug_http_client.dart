import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import '../../domain/entities/debug_network_request.dart';
import 'debug_network_store.dart';

/// A [HttpClient] wrapper that intercepts every request *and its response*
/// (status, headers, bodies, timing, errors) and stores them in
/// [DebugNetworkStore] for display in `NetworkModule`.
///
/// Prefer calling `DebugView.enableNetworkCapture()` — it installs this
/// override (chaining any existing one) with a single, package-owned call.
///
/// Capturing all `dart:io` traffic — which includes Dio (default adapter) and
/// the `http` package on native platforms — comes down to:
///
/// ```dart
/// void main() {
///   HttpOverrides.global = DebugHttpOverrides();
///   runApp(MyApp());
/// }
/// ```
///
/// If the app already sets [HttpOverrides.global] (proxy, certificate
/// pinning…), pass it as [previous] so it keeps working — the inner
/// [HttpClient] is created by the previous override, then wrapped:
///
/// ```dart
/// HttpOverrides.global = DebugHttpOverrides(HttpOverrides.current);
/// ```
///
/// Capture is structured (not console logging): the [NetworkModule] decides how
/// to render it. Not supported on Flutter Web (no `dart:io`).
class DebugHttpOverrides extends HttpOverrides {
  /// An existing override to delegate to before wrapping, so proxy /
  /// certificate-pinning behaviour is preserved when chaining.
  final HttpOverrides? previous;

  DebugHttpOverrides([this.previous]);

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final inner = previous?.createHttpClient(context) ??
        super.createHttpClient(context);
    return _DebugHttpClient(inner);
  }

  @override
  String findProxyFromEnvironment(Uri url, Map<String, String>? environment) {
    return previous?.findProxyFromEnvironment(url, environment) ??
        super.findProxyFromEnvironment(url, environment);
  }
}

// ── Body / header capture helpers ──────────────────────────────────────────

Map<String, String> _collectHeaders(HttpHeaders headers) {
  final map = <String, String>{};
  headers.forEach((name, values) => map[name] = values.join(', '));
  return map;
}

/// Whether a content-type is worth decoding as text (vs. showing a byte count).
bool _isTextual(ContentType? ct) {
  if (ct == null) return true; // unknown — often JSON; try to decode it
  final mime = ct.mimeType.toLowerCase();
  return mime.contains('json') ||
      mime.contains('xml') ||
      mime.contains('javascript') ||
      mime.contains('x-www-form-urlencoded') ||
      mime.startsWith('text/');
}

/// Decode captured bytes to a displayable string, or a placeholder for binary.
String? _decodeBody(List<int> bytes, ContentType? contentType) {
  if (bytes.isEmpty) return null;
  if (_isTextual(contentType)) {
    try {
      return utf8.decode(bytes, allowMalformed: true);
    } catch (_) {
      // fall through to the binary placeholder
    }
  }
  final mime = contentType?.mimeType ?? 'binary';
  return '<${bytes.length} bytes · $mime>';
}

class _DebugHttpClient implements HttpClient {
  final HttpClient _inner;

  _DebugHttpClient(this._inner);

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    final stopwatch = Stopwatch()..start();
    try {
      final request = await _inner.openUrl(method, url);
      return _DebugHttpClientRequest(
        request,
        method: method,
        url: url.toString(),
        stopwatch: stopwatch,
      );
    } catch (error) {
      // Connection-level failures (DNS, refused, …) surface here, before a
      // request object even exists — record them anyway.
      stopwatch.stop();
      DebugNetworkStore.instance.add(
        DebugNetworkRequest(
          timestamp: DateTime.now(),
          method: method.toUpperCase(),
          url: url.toString(),
          error: error,
          duration: stopwatch.elapsed,
          completed: true,
        ),
      );
      rethrow;
    }
  }

  // Delegate all other members to _inner
  @override
  bool get autoUncompress => _inner.autoUncompress;
  @override
  set autoUncompress(bool value) => _inner.autoUncompress = value;
  @override
  Duration? get connectionTimeout => _inner.connectionTimeout;
  @override
  set connectionTimeout(Duration? value) => _inner.connectionTimeout = value;
  @override
  Duration get idleTimeout => _inner.idleTimeout;
  @override
  set idleTimeout(Duration value) => _inner.idleTimeout = value;
  @override
  int? get maxConnectionsPerHost => _inner.maxConnectionsPerHost;
  @override
  set maxConnectionsPerHost(int? value) =>
      _inner.maxConnectionsPerHost = value;
  @override
  String? get userAgent => _inner.userAgent;
  @override
  set userAgent(String? value) => _inner.userAgent = value;
  @override
  void addCredentials(Uri url, String realm, HttpClientCredentials credentials) =>
      _inner.addCredentials(url, realm, credentials);
  @override
  void addProxyCredentials(String host, int port, String realm,
          HttpClientCredentials credentials) =>
      _inner.addProxyCredentials(host, port, realm, credentials);
  @override
  set authenticate(
          Future<bool> Function(Uri url, String scheme, String? realm)? f) =>
      _inner.authenticate = f;
  @override
  set authenticateProxy(
          Future<bool> Function(
                  String host, int port, String scheme, String? realm)?
              f) =>
      _inner.authenticateProxy = f;
  @override
  set badCertificateCallback(
          bool Function(X509Certificate cert, String host, int port)?
              callback) =>
      _inner.badCertificateCallback = callback;
  @override
  set connectionFactory(
          Future<ConnectionTask<Socket>> Function(
                  Uri url, String? proxyHost, int? proxyPort)?
              f) =>
      _inner.connectionFactory = f;
  @override
  set keyLog(Function(String line)? callback) => _inner.keyLog = callback;
  @override
  void close({bool force = false}) => _inner.close(force: force);
  @override
  Future<HttpClientRequest> delete(String host, int port, String path) =>
      openUrl('delete', Uri(scheme: 'http', host: host, port: port, path: path));
  @override
  Future<HttpClientRequest> deleteUrl(Uri url) => openUrl('delete', url);
  @override
  set findProxy(String Function(Uri url)? f) => _inner.findProxy = f;
  @override
  Future<HttpClientRequest> get(String host, int port, String path) =>
      openUrl('get', Uri(scheme: 'http', host: host, port: port, path: path));
  @override
  Future<HttpClientRequest> getUrl(Uri url) => openUrl('get', url);
  @override
  Future<HttpClientRequest> head(String host, int port, String path) =>
      openUrl('head', Uri(scheme: 'http', host: host, port: port, path: path));
  @override
  Future<HttpClientRequest> headUrl(Uri url) => openUrl('head', url);
  @override
  Future<HttpClientRequest> open(
          String method, String host, int port, String path) =>
      openUrl(method, Uri(scheme: 'http', host: host, port: port, path: path));
  @override
  Future<HttpClientRequest> patch(String host, int port, String path) =>
      openUrl('patch', Uri(scheme: 'http', host: host, port: port, path: path));
  @override
  Future<HttpClientRequest> patchUrl(Uri url) => openUrl('patch', url);
  @override
  Future<HttpClientRequest> post(String host, int port, String path) =>
      openUrl('post', Uri(scheme: 'http', host: host, port: port, path: path));
  @override
  Future<HttpClientRequest> postUrl(Uri url) => openUrl('post', url);
  @override
  Future<HttpClientRequest> put(String host, int port, String path) =>
      openUrl('put', Uri(scheme: 'http', host: host, port: port, path: path));
  @override
  Future<HttpClientRequest> putUrl(Uri url) => openUrl('put', url);
}

class _DebugHttpClientRequest implements HttpClientRequest {
  final HttpClientRequest _inner;
  @override
  final String method;
  final String url;
  final Stopwatch stopwatch;

  /// Accumulates the outgoing body as the app writes it.
  final BytesBuilder _bodyBytes = BytesBuilder(copy: false);

  _DebugHttpClientRequest(
    this._inner, {
    required this.method,
    required this.url,
    required this.stopwatch,
  });

  @override
  Future<HttpClientResponse> close() async {
    final entry = DebugNetworkRequest(
      timestamp: DateTime.now(),
      method: method.toUpperCase(),
      url: url,
      requestHeaders: _collectHeaders(_inner.headers),
      requestBody: _decodeBody(_bodyBytes.takeBytes(), _inner.headers.contentType),
    );
    DebugNetworkStore.instance.add(entry);

    try {
      final response = await _inner.close();
      entry
        ..statusCode = response.statusCode
        ..responseHeaders = _collectHeaders(response.headers);
      DebugNetworkStore.instance.touch();
      return _DebugHttpClientResponse(response, entry, stopwatch);
    } catch (error) {
      stopwatch.stop();
      entry
        ..error = error
        ..duration = stopwatch.elapsed
        ..completed = true;
      DebugNetworkStore.instance.touch();
      rethrow;
    }
  }

  // ── Body-writing methods — captured, then delegated ──────────────────────
  @override
  void add(List<int> data) {
    _bodyBytes.add(data);
    _inner.add(data);
  }

  @override
  Future<void> addStream(Stream<List<int>> stream) {
    return _inner.addStream(stream.map((chunk) {
      _bodyBytes.add(chunk);
      return chunk;
    }));
  }

  @override
  void write(Object? object) {
    _bodyBytes.add(encoding.encode(object?.toString() ?? 'null'));
    _inner.write(object);
  }

  @override
  void writeln([Object? object = '']) {
    _bodyBytes.add(encoding.encode('${object ?? ''}\n'));
    _inner.writeln(object);
  }

  @override
  void writeAll(Iterable<dynamic> objects, [String separator = '']) {
    _bodyBytes.add(encoding.encode(objects.join(separator)));
    _inner.writeAll(objects, separator);
  }

  @override
  void writeCharCode(int charCode) {
    _bodyBytes.add(encoding.encode(String.fromCharCode(charCode)));
    _inner.writeCharCode(charCode);
  }

  // Delegate all other members to _inner
  @override
  bool get bufferOutput => _inner.bufferOutput;
  @override
  set bufferOutput(bool value) => _inner.bufferOutput = value;
  @override
  int get contentLength => _inner.contentLength;
  @override
  set contentLength(int value) => _inner.contentLength = value;
  @override
  Encoding get encoding => _inner.encoding;
  @override
  set encoding(Encoding value) => _inner.encoding = value;
  @override
  bool get followRedirects => _inner.followRedirects;
  @override
  set followRedirects(bool value) => _inner.followRedirects = value;
  @override
  int get maxRedirects => _inner.maxRedirects;
  @override
  set maxRedirects(int value) => _inner.maxRedirects = value;
  @override
  bool get persistentConnection => _inner.persistentConnection;
  @override
  set persistentConnection(bool value) => _inner.persistentConnection = value;
  @override
  HttpConnectionInfo? get connectionInfo => _inner.connectionInfo;
  @override
  List<Cookie> get cookies => _inner.cookies;
  @override
  Future<HttpClientResponse> get done => _inner.done;
  @override
  HttpHeaders get headers => _inner.headers;
  @override
  Uri get uri => _inner.uri;
  @override
  void abort([Object? exception, StackTrace? stackTrace]) =>
      _inner.abort(exception, stackTrace);
  @override
  void addError(Object error, [StackTrace? stackTrace]) =>
      _inner.addError(error, stackTrace);
  @override
  Future<void> flush() => _inner.flush();
}

/// Wraps the response so the body is captured as the app reads it, without
/// consuming the stream (the app still gets every byte). Once the stream is
/// done, the matching [DebugNetworkRequest] is updated in place.
class _DebugHttpClientResponse implements HttpClientResponse {
  final HttpClientResponse _inner;
  final DebugNetworkRequest _entry;
  final Stopwatch _stopwatch;
  final BytesBuilder _bodyBytes = BytesBuilder(copy: false);
  late final Stream<List<int>> _captured;

  _DebugHttpClientResponse(this._inner, this._entry, this._stopwatch) {
    _captured = _inner.transform(
      StreamTransformer<List<int>, List<int>>.fromHandlers(
        handleData: (data, sink) {
          _bodyBytes.add(data);
          sink.add(data);
        },
        handleError: (error, stackTrace, sink) {
          _entry.error ??= error;
          sink.addError(error, stackTrace);
        },
        handleDone: (sink) {
          _finalize();
          sink.close();
        },
      ),
    );
  }

  void _finalize() {
    if (_entry.completed) return;
    _stopwatch.stop();
    _entry.responseBody =
        _decodeBody(_bodyBytes.takeBytes(), _inner.headers.contentType);
    _entry.duration = _stopwatch.elapsed;
    _entry.completed = true;
    DebugNetworkStore.instance.touch();
  }

  // ── Stream<List<int>> — everything flows through the captured stream ──────
  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData,
          {Function? onError, void Function()? onDone, bool? cancelOnError}) =>
      _captured.listen(onData,
          onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  @override
  Stream<List<int>> asBroadcastStream(
          {void Function(StreamSubscription<List<int>> subscription)? onListen,
          void Function(StreamSubscription<List<int>> subscription)?
              onCancel}) =>
      _captured.asBroadcastStream(onListen: onListen, onCancel: onCancel);
  @override
  Future<bool> any(bool Function(List<int> element) test) => _captured.any(test);
  @override
  Stream<R> cast<R>() => _captured.cast<R>();
  @override
  Future<bool> contains(Object? needle) => _captured.contains(needle);
  @override
  Stream<List<int>> distinct(
          [bool Function(List<int> previous, List<int> next)? equals]) =>
      _captured.distinct(equals);
  @override
  Future<E> drain<E>([E? futureValue]) => _captured.drain(futureValue);
  @override
  Future<List<int>> elementAt(int index) => _captured.elementAt(index);
  @override
  Future<bool> every(bool Function(List<int> element) test) =>
      _captured.every(test);
  @override
  Stream<S> expand<S>(Iterable<S> Function(List<int> element) convert) =>
      _captured.expand(convert);
  @override
  Future<List<int>> get first => _captured.first;
  @override
  Future<List<int>> firstWhere(bool Function(List<int> element) test,
          {List<int> Function()? orElse}) =>
      _captured.firstWhere(test, orElse: orElse);
  @override
  Future<S> fold<S>(
          S initialValue, S Function(S previous, List<int> element) combine) =>
      _captured.fold(initialValue, combine);
  @override
  Future<void> forEach(void Function(List<int> element) action) =>
      _captured.forEach(action);
  @override
  Stream<List<int>> handleError(Function onError,
          {bool Function(dynamic error)? test}) =>
      _captured.handleError(onError, test: test);
  @override
  bool get isBroadcast => _captured.isBroadcast;
  @override
  Future<bool> get isEmpty => _captured.isEmpty;
  @override
  Future<String> join([String separator = '']) => _captured.join(separator);
  @override
  Future<List<int>> get last => _captured.last;
  @override
  Future<List<int>> lastWhere(bool Function(List<int> element) test,
          {List<int> Function()? orElse}) =>
      _captured.lastWhere(test, orElse: orElse);
  @override
  Future<int> get length => _captured.length;
  @override
  Stream<S> map<S>(S Function(List<int> event) convert) =>
      _captured.map(convert);
  @override
  Future<dynamic> pipe(StreamConsumer<List<int>> streamConsumer) =>
      _captured.pipe(streamConsumer);
  @override
  Future<List<int>> reduce(
          List<int> Function(List<int> previous, List<int> element) combine) =>
      _captured.reduce(combine);
  @override
  Future<List<int>> get single => _captured.single;
  @override
  Future<List<int>> singleWhere(bool Function(List<int> element) test,
          {List<int> Function()? orElse}) =>
      _captured.singleWhere(test, orElse: orElse);
  @override
  Stream<List<int>> skip(int count) => _captured.skip(count);
  @override
  Stream<List<int>> skipWhile(bool Function(List<int> element) test) =>
      _captured.skipWhile(test);
  @override
  Stream<List<int>> take(int count) => _captured.take(count);
  @override
  Stream<List<int>> takeWhile(bool Function(List<int> element) test) =>
      _captured.takeWhile(test);
  @override
  Stream<List<int>> timeout(Duration timeLimit,
          {void Function(EventSink<List<int>> sink)? onTimeout}) =>
      _captured.timeout(timeLimit, onTimeout: onTimeout);
  @override
  Future<List<List<int>>> toList() => _captured.toList();
  @override
  Future<Set<List<int>>> toSet() => _captured.toSet();
  @override
  Stream<S> transform<S>(StreamTransformer<List<int>, S> streamTransformer) =>
      _captured.transform(streamTransformer);
  @override
  Stream<List<int>> where(bool Function(List<int> event) test) =>
      _captured.where(test);
  @override
  Stream<E> asyncExpand<E>(Stream<E>? Function(List<int> event) convert) =>
      _captured.asyncExpand(convert);
  @override
  Stream<E> asyncMap<E>(FutureOr<E> Function(List<int> event) convert) =>
      _captured.asyncMap(convert);

  // ── HttpClientResponse-specific members — delegated to _inner ─────────────
  @override
  X509Certificate? get certificate => _inner.certificate;
  @override
  HttpClientResponseCompressionState get compressionState =>
      _inner.compressionState;
  @override
  HttpConnectionInfo? get connectionInfo => _inner.connectionInfo;
  @override
  int get contentLength => _inner.contentLength;
  @override
  List<Cookie> get cookies => _inner.cookies;
  @override
  Future<Socket> detachSocket() => _inner.detachSocket();
  @override
  HttpHeaders get headers => _inner.headers;
  @override
  bool get isRedirect => _inner.isRedirect;
  @override
  bool get persistentConnection => _inner.persistentConnection;
  @override
  String get reasonPhrase => _inner.reasonPhrase;
  @override
  Future<HttpClientResponse> redirect(
          [String? method, Uri? url, bool? followLoops]) =>
      _inner.redirect(method, url, followLoops);
  @override
  List<RedirectInfo> get redirects => _inner.redirects;
  @override
  int get statusCode => _inner.statusCode;
}
