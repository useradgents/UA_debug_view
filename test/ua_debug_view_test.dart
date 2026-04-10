import 'package:flutter_test/flutter_test.dart';

import 'package:ua_debug_view/ua_debug_view.dart';

void main() {
  test('DebugLog can be instantiated', () {
    final log = DebugLog(
      timestamp: DateTime.now(),
      level: LogLevel.info,
      message: 'test',
    );
    expect(log.message, 'test');
    expect(log.level, LogLevel.info);
  });
}
