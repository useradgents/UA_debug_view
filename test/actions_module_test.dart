import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ua_debug_view/ua_debug_view.dart';

void main() {
  testWidgets('toggle tiles render without ListTile/Material assertion',
      (tester) async {
    final module = ActionsModule(
      toggles: [
        DebugToggleAction(
          label: 'Verbose logging',
          icon: Icons.subject,
          initialValue: false,
          onToggle: (_) async {},
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(builder: (context) => module.buildPage(context)),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(SwitchListTile), findsOneWidget);
  });
}
