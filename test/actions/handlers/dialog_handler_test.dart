import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_renderer/src/actions/sdui_action.dart';
import 'package:sdui_renderer/src/actions/handlers/dialog_handler.dart';

void main() {
  testWidgets('dialog shows widget content', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(builder: (ctx) {
          return ElevatedButton(
            onPressed: () => dialogHandler(ctx, SduiAction(
              actionType: 'dialog',
              props: {'message': 'Confirm?'},
            )),
            child: const Text('open'),
          );
        }),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Confirm?'), findsOneWidget);
  });
}
