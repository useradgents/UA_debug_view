import 'dart:async';
import '../../domain/entities/debug_network_request.dart';

/// In-memory store for captured network requests.
/// Consumed by [NetworkModule].
class DebugNetworkStore {
  static final DebugNetworkStore instance = DebugNetworkStore._internal();

  DebugNetworkStore._internal();

  final List<DebugNetworkRequest> _requests = [];
  final _controller = StreamController<List<DebugNetworkRequest>>.broadcast();

  int maxRequests = 100;

  /// URL fragments whose requests are dropped *before* being stored, so they
  /// never occupy a slot in the [maxRequests] buffer (and thus can't evict
  /// real traffic). Kept in sync with `NetworkModule.ignoredPaths`.
  List<String> ignoredPaths = const [];

  List<DebugNetworkRequest> get requests => List.unmodifiable(_requests);

  Stream<List<DebugNetworkRequest>> get stream => _controller.stream;

  void add(DebugNetworkRequest request) {
    if (ignoredPaths.any((path) => request.url.contains(path))) return;
    _requests.insert(0, request);
    if (_requests.length > maxRequests) {
      _requests.removeRange(maxRequests, _requests.length);
    }
    _controller.add(requests);
  }

  /// Re-emit the current list. Call this after mutating an existing request
  /// in place (e.g. once its response body has been captured) so listeners
  /// rebuild.
  void touch() => _controller.add(requests);

  void clear() {
    _requests.clear();
    _controller.add(requests);
  }
}
