import 'package:axiom/core/widgets/keyboard_dismiss_on_tap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('keeps focus inside the field and dismisses it outside', (
    tester,
  ) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: KeyboardDismissOnTap(
          child: Scaffold(
            body: Column(
              children: [
                TextField(focusNode: focusNode),
                const Expanded(
                  child: ColoredBox(key: Key('outside'), color: Colors.black),
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

    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);

    await tester.tapAt(tester.getCenter(find.byKey(const Key('outside'))));
    await tester.pump();
    expect(focusNode.hasFocus, isFalse);
  });

  testWidgets('moves focus normally when another field is tapped', (
    tester,
  ) async {
    final first = FocusNode();
    final second = FocusNode();
    addTearDown(first.dispose);
    addTearDown(second.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: KeyboardDismissOnTap(
          child: Scaffold(
            body: Column(
              children: [
                TextField(focusNode: first),
                TextField(focusNode: second),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextField).first);
    await tester.pump();
    await tester.tap(find.byType(TextField).last);
    await tester.pump();

    expect(first.hasFocus, isFalse);
    expect(second.hasFocus, isTrue);
  });
}
