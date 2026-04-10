import 'package:flutter_test/flutter_test.dart';
import 'package:ua_debug_view_example/main.dart';

void main() {
  testWidgets('Example app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ExampleApp());
    expect(find.text('ua_debug_view example'), findsOneWidget);
  });
}
