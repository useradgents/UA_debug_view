import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ua_debug_view/ua_debug_view.dart';

void main() {
  late HttpServer server;
  late String baseUrl;

  setUp(() async {
    DebugNetworkStore.instance.clear();
    DebugView.enableNetworkCapture();

    // A tiny echo server: replies with JSON, reflecting any request body.
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    baseUrl = 'http://${server.address.address}:${server.port}';
    server.listen((request) async {
      final body = await utf8.decoder.bind(request).join();
      request.response
        ..statusCode = request.uri.path == '/notfound' ? 404 : 200
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'path': request.uri.path, 'received': body}));
      await request.response.close();
    });
  });

  tearDown(() async {
    HttpOverrides.global = null;
    DebugNetworkStore.instance.ignoredPaths = const [];
    DebugNetworkStore.instance.maxRequests = 100;
    await server.close(force: true);
  });

  Future<String> drain(HttpClientResponse resp) =>
      resp.transform(utf8.decoder).join();

  test('captures a GET with status, response body, headers and duration',
      () async {
    final client = HttpClient();
    final req = await client.getUrl(Uri.parse('$baseUrl/users/1'));
    final resp = await req.close();
    final body = await drain(resp);
    client.close();

    final captured = DebugNetworkStore.instance.requests;
    expect(captured, hasLength(1));

    final entry = captured.first;
    expect(entry.method, 'GET');
    expect(entry.url, '$baseUrl/users/1');
    expect(entry.statusCode, 200);
    expect(entry.completed, isTrue);
    expect(entry.error, isNull);
    // The body the app read matches what we captured.
    expect(body, contains('/users/1'));
    expect(entry.responseBody, body);
    expect(entry.responseHeaders['content-type'], contains('application/json'));
    expect(entry.duration, isNotNull);
  });

  test('captures the outgoing request body on a POST', () async {
    final client = HttpClient();
    final req = await client.postUrl(Uri.parse('$baseUrl/posts'));
    req.headers.contentType = ContentType.json;
    req.write(jsonEncode({'title': 'foo'}));
    final resp = await req.close();
    await drain(resp);
    client.close();

    final entry = DebugNetworkStore.instance.requests.first;
    expect(entry.method, 'POST');
    expect(entry.requestBody, jsonEncode({'title': 'foo'}));
    expect(entry.responseBody, contains('foo')); // echoed back
  });

  test('captures a 4xx as an error status', () async {
    final client = HttpClient();
    final req = await client.getUrl(Uri.parse('$baseUrl/notfound'));
    final resp = await req.close();
    await drain(resp);
    client.close();

    final entry = DebugNetworkStore.instance.requests.first;
    expect(entry.statusCode, 404);
    expect(entry.isError, isTrue);
  });

  test('captures connection failures in the error field', () async {
    // Bind then immediately close to get a port nothing listens on.
    final dead = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final deadPort = dead.port;
    await dead.close(force: true);

    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 2);
    Object? thrown;
    try {
      final req = await client
          .getUrl(Uri.parse('http://127.0.0.1:$deadPort/x'));
      await req.close();
    } catch (e) {
      thrown = e;
    }
    client.close();

    expect(thrown, isNotNull); // the app still sees the error
    final entry = DebugNetworkStore.instance.requests.first;
    expect(entry.error, isNotNull);
    expect(entry.completed, isTrue);
    expect(entry.isError, isTrue);
  });

  test('ignored paths are dropped before storage, so they never evict real '
      'traffic', () async {
    final store = DebugNetworkStore.instance;
    store
      ..ignoredPaths = ['/healthcheck']
      ..maxRequests = 2;

    final client = HttpClient();

    // One real request we care about keeping.
    await drain(await (await client.getUrl(Uri.parse('$baseUrl/keep'))).close());

    // A flood of ignored requests that would otherwise fill the 2-slot buffer
    // and evict /keep.
    for (var i = 0; i < 5; i++) {
      await drain(
        await (await client.getUrl(Uri.parse('$baseUrl/healthcheck'))).close(),
      );
    }
    client.close();

    final urls = store.requests.map((r) => r.url).toList();
    // None of the ignored requests were stored…
    expect(urls.any((u) => u.contains('/healthcheck')), isFalse);
    // …so /keep is still there.
    expect(urls, contains('$baseUrl/keep'));
  });

  test('enableNetworkCapture chains an existing override and is idempotent',
      () async {
    // Start from a custom override already in place (e.g. proxy / pinning).
    final custom = _CountingHttpOverrides();
    HttpOverrides.global = custom;

    DebugView.enableNetworkCapture();
    final installed = HttpOverrides.current;
    expect(installed, isA<DebugHttpOverrides>());
    expect((installed as DebugHttpOverrides).previous, same(custom));

    // Calling again must not re-wrap (no DebugHttpOverrides inside another).
    DebugView.enableNetworkCapture();
    expect((HttpOverrides.current as DebugHttpOverrides).previous, same(custom));

    // Traffic is still captured, and the chained override saw the client.
    final client = HttpClient();
    final req = await client.getUrl(Uri.parse('$baseUrl/chained'));
    await drain(await req.close());
    client.close();

    expect(custom.created, greaterThan(0));
    expect(DebugNetworkStore.instance.requests, hasLength(1));
    expect(DebugNetworkStore.instance.requests.first.url, '$baseUrl/chained');
  });
}

/// A minimal override that records how many clients it was asked to create,
/// standing in for a real proxy / certificate-pinning override.
class _CountingHttpOverrides extends HttpOverrides {
  int created = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    created++;
    return super.createHttpClient(context);
  }
}
