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

  List<DebugNetworkRequest> get requests => List.unmodifiable(_requests);

  Stream<List<DebugNetworkRequest>> get stream => _controller.stream;

  void add(DebugNetworkRequest request) {
    _requests.insert(0, request);
    if (_requests.length > maxRequests) {
      _requests.removeRange(maxRequests, _requests.length);
    }
    _controller.add(requests);
  }

  void clear() {
    _requests.clear();
    _controller.add(requests);
  }
}
