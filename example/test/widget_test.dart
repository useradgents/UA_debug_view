import 'package:flutter_test/flutter_test.dart';
import 'package:ua_debug_view/ua_debug_view.dart';
import 'package:ua_debug_view_example/main.dart';

void main() {
  testWidgets('Example app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ExampleApp());

    // The app starts on the login screen, with its form and the debug
    // account picker (visible because tests run in debug mode).
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.byType(DebugAccountPicker), findsOneWidget);
  });
}
