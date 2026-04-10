import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../../domain/entities/debug_network_request.dart';
import 'debug_network_store.dart';

/// A [HttpClient] wrapper that intercepts all requests and stores them
/// in [DebugNetworkStore] for display in [NetworkModule].
///
/// Usage:
/// ```dart
/// HttpOverrides.global = DebugHttpOverrides();
/// ```
class DebugHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _DebugHttpClient(super.createHttpClient(context));
  }
}

class _DebugHttpClient implements HttpClient {
  final HttpClient _inner;

  _DebugHttpClient(this._inner);

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    final stopwatch = Stopwatch()..start();

    final request = await _inner.openUrl(method, url);
    return _DebugHttpClientRequest(
      request,
      method: method,
      url: url.toString(),
      stopwatch: stopwatch,
    );
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
      _inner.delete(host, port, path);
  @override
  Future<HttpClientRequest> deleteUrl(Uri url) => _inner.deleteUrl(url);
  @override
  set findProxy(String Function(Uri url)? f) => _inner.findProxy = f;
  @override
  Future<HttpClientRequest> get(String host, int port, String path) =>
      _inner.get(host, port, path);
  @override
  Future<HttpClientRequest> getUrl(Uri url) => _inner.getUrl(url);
  @override
  Future<HttpClientRequest> head(String host, int port, String path) =>
      _inner.head(host, port, path);
  @override
  Future<HttpClientRequest> headUrl(Uri url) => _inner.headUrl(url);
  @override
  Future<HttpClientRequest> open(
          String method, String host, int port, String path) =>
      _inner.open(method, host, port, path);
  @override
  Future<HttpClientRequest> patch(String host, int port, String path) =>
      _inner.patch(host, port, path);
  @override
  Future<HttpClientRequest> patchUrl(Uri url) => _inner.patchUrl(url);
  @override
  Future<HttpClientRequest> post(String host, int port, String path) =>
      _inner.post(host, port, path);
  @override
  Future<HttpClientRequest> postUrl(Uri url) => _inner.postUrl(url);
  @override
  Future<HttpClientRequest> put(String host, int port, String path) =>
      _inner.put(host, port, path);
  @override
  Future<HttpClientRequest> putUrl(Uri url) => _inner.putUrl(url);
}

class _DebugHttpClientRequest implements HttpClientRequest {
  final HttpClientRequest _inner;
  @override
  final String method;
  final String url;
  final Stopwatch stopwatch;

  _DebugHttpClientRequest(
    this._inner, {
    required this.method,
    required this.url,
    required this.stopwatch,
  });

  @override
  Future<HttpClientResponse> close() async {
    final response = await _inner.close();
    stopwatch.stop();

    DebugNetworkStore.instance.add(
      DebugNetworkRequest(
        timestamp: DateTime.now(),
        method: method,
        url: url,
        requestHeaders: _inner.headers.value('content-type') != null
            ? {'content-type': _inner.headers.value('content-type')!}
            : {},
        statusCode: response.statusCode,
        duration: stopwatch.elapsed,
      ),
    );

    return response;
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
  void add(List<int> data) => _inner.add(data);
  @override
  void addError(Object error, [StackTrace? stackTrace]) =>
      _inner.addError(error, stackTrace);
  @override
  Future<void> addStream(Stream<List<int>> stream) =>
      _inner.addStream(stream);
  @override
  Future<void> flush() => _inner.flush();
  @override
  void write(Object? object) => _inner.write(object);
  @override
  void writeAll(Iterable<dynamic> objects, [String separator = '']) =>
      _inner.writeAll(objects, separator);
  @override
  void writeCharCode(int charCode) => _inner.writeCharCode(charCode);
  @override
  void writeln([Object? object = '']) => _inner.writeln(object);
}
