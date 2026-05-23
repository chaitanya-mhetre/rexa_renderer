import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_renderer/src/actions/sdui_action.dart';
import 'package:sdui_renderer/src/actions/handlers/modal_bottom_sheet_handler.dart';

void main() {
  testWidgets('showModalBottomSheet with title + message renders content',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (ctx) {
            return ElevatedButton(
              onPressed: () => modalBottomSheetHandler(
                ctx,
                SduiAction(
                  actionType: 'showModalBottomSheet',
                  props: {'title': 'Pick one', 'message': 'Some content'},
                ),
              ),
              child: const Text('open'),
            );
          },
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Pick one'), findsOneWidget);
    expect(find.text('Some content'), findsOneWidget);
  });

  testWidgets('showModalBottomSheet with only title', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (ctx) {
            return ElevatedButton(
              onPressed: () => modalBottomSheetHandler(
                ctx,
                SduiAction(
                  actionType: 'showModalBottomSheet',
                  props: {'title': 'Only title'},
                ),
              ),
              child: const Text('open'),
            );
          },
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Only title'), findsOneWidget);
  });

  testWidgets('showModalBottomSheet with only message', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (ctx) {
            return ElevatedButton(
              onPressed: () => modalBottomSheetHandler(
                ctx,
                SduiAction(
                  actionType: 'showModalBottomSheet',
                  props: {'message': 'Just a message'},
                ),
              ),
              child: const Text('open'),
            );
          },
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Just a message'), findsOneWidget);
  });

  testWidgets('showModalBottomSheet with isDismissible=false', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (ctx) {
            return ElevatedButton(
              onPressed: () => modalBottomSheetHandler(
                ctx,
                SduiAction(
                  actionType: 'showModalBottomSheet',
                  props: {
                    'title': 'Not dismissible',
                    'isDismissible': false,
                  },
                ),
              ),
              child: const Text('open'),
            );
          },
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Not dismissible'), findsOneWidget);
    // Tap outside the modal (on the barrier)
    await tester.tapAt(const Offset(100, 100));
    await tester.pumpAndSettle();
    // Should still be visible since isDismissible is false
    expect(find.text('Not dismissible'), findsOneWidget);
  });
}
