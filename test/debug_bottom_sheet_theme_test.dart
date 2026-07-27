import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ua_debug_view/src/presentation/bottom_sheet/debug_bottom_sheet.dart';
import 'package:ua_debug_view/ua_debug_view.dart';

void main() {
  testWidgets('user-built module content inherits the panel dark theme',
      (tester) async {
    Brightness? seenBrightness;

    final module = CustomModule(
      title: 'Flags',
      icon: Icons.flag_outlined,
      builder: (context) {
        seenBrightness = Theme.of(context).brightness;
        return const SizedBox();
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        // Ambient light theme — the sheet must not inherit it.
        theme: ThemeData.light(),
        home: DebugBottomSheet(
          modulesNotifier: ValueNotifier<List<DebugModule>>([module]),
          accentColor: Colors.blue,
        ),
      ),
    );

    await tester.tap(find.text('Flags'));
    await tester.pumpAndSettle();

    expect(seenBrightness, Brightness.dark);
  });
}
