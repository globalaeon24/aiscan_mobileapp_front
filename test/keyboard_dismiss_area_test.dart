import 'package:ai_scan_text/features/main_shell/pages/pair_checks_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_scan_text/widgets/keyboard_dismiss_area.dart';

void main() {
  testWidgets('dismisses focus when tapping outside the active field',
      (tester) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: KeyboardDismissArea(
          child: Scaffold(
            body: Column(
              children: [
                TextField(focusNode: focusNode),
                Expanded(
                  child: Container(
                    key: const Key('outside'),
                    color: Colors.transparent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);

    await tester.tap(find.byKey(const Key('outside')));
    await tester.pump();
    expect(focusNode.hasFocus, isFalse);
  });

  testWidgets('dismisses focus before a button action', (tester) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    var pressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: KeyboardDismissArea(
          child: Scaffold(
            body: Column(
              children: [
                TextField(focusNode: focusNode),
                ElevatedButton(
                  onPressed: () => pressed = true,
                  child: const Text('Сохранить'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.tap(find.text('Сохранить'));
    await tester.pump();

    expect(pressed, isTrue);
    expect(focusNode.hasFocus, isFalse);
  });

  testWidgets('pair check form dismisses focus on an empty area tap',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PairCheckCreatePage()),
    );

    await tester.tap(find.byType(TextFormField).first);
    await tester.pump();
    final editable =
        tester.widget<EditableText>(find.byType(EditableText).first);
    expect(editable.focusNode.hasFocus, isTrue);

    await tester.tap(find.text('Сравните два документа'));
    await tester.pump();

    expect(editable.focusNode.hasFocus, isFalse);
  });
}
