import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_renderer/src/actions/sdui_action.dart';
import 'package:sdui_renderer/src/actions/handlers/navigate_handler.dart';

void main() {
  testWidgets('navigate push: opens new route', (tester) async {
    final navKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
      navigatorKey: navKey,
      home: Builder(builder: (ctx) {
        return ElevatedButton(
          onPressed: () => navigateHandler(ctx, SduiAction(
            actionType: 'navigate',
            props: {'navigationStyle': 'push', 'routeName': '/x'},
          )),
          child: const Text('go'),
        );
      }),
    ));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(navKey.currentState!.canPop(), isTrue);
  });

  testWidgets('navigate pop: returns to previous route', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (root) {
        return ElevatedButton(
          onPressed: () => Navigator.push(root, MaterialPageRoute(
            builder: (inner) => ElevatedButton(
              key: const Key('popper'),
              onPressed: () => navigateHandler(inner, SduiAction(
                actionType: 'navigate',
                props: {'navigationStyle': 'pop'},
              )),
              child: const Text('pop'),
            ),
          )),
          child: const Text('push'),
        );
      }),
    ));
    await tester.tap(find.text('push'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('popper')));
    await tester.pumpAndSettle();
    expect(find.text('push'), findsOneWidget);
  });
}
