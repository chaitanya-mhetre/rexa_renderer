import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_renderer/src/actions/sdui_action.dart';
import 'package:sdui_renderer/src/actions/handlers/snackbar_handler.dart';

void main() {
  testWidgets('snackbar shows label', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(builder: (ctx) {
          return ElevatedButton(
            onPressed: () => snackBarHandler(ctx, SduiAction(
              actionType: 'snackBar',
              props: {'label': 'saved'},
            )),
            child: const Text('go'),
          );
        }),
      ),
    ));
    await tester.tap(find.text('go'));
    await tester.pump();
    expect(find.text('saved'), findsOneWidget);
  });
}
