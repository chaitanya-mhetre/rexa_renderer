// test/actions/handlers/misc_handlers_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_renderer/src/actions/sdui_action.dart';
import 'package:sdui_renderer/src/actions/sdui_action_registry.dart';
import 'package:sdui_renderer/src/actions/handlers/set_value_handler.dart';
import 'package:sdui_renderer/src/actions/handlers/multi_action_handler.dart';
import 'package:sdui_renderer/src/actions/handlers/delay_handler.dart';
import 'package:sdui_renderer/src/actions/handlers/none_handler.dart';
import 'package:sdui_renderer/src/context/sdui_context_store.dart';

void main() {
  testWidgets('setValue writes to context store and chains action', (tester) async {
    final ctxStore = SduiContextStore();
    final reg = SduiActionRegistry();
    reg.register('setValue', makeSetValueHandler(ctxStore, reg));
    String? chained;
    reg.register('test', (_, a) async { chained = a.props['v']; });

    await tester.pumpWidget(MaterialApp(home: Builder(builder: (bctx) {
      return ElevatedButton(
        onPressed: () => reg.dispatch(bctx, SduiAction(
          actionType: 'setValue',
          props: {
            'values': {'a': 1},
            'action': {'actionType': 'test', 'v': 'chained'},
          },
        )),
        child: const Text('go'),
      );
    })));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(ctxStore.snapshot['a'], 1);
    expect(chained, 'chained');
  });

  testWidgets('multiAction sync executes in order', (tester) async {
    final reg = SduiActionRegistry();
    final order = <int>[];
    reg.register('a', (_, __) async { await Future.delayed(const Duration(milliseconds: 10)); order.add(1); });
    reg.register('b', (_, __) async { order.add(2); });
    reg.register('multiAction', makeMultiActionHandler(reg));

    await tester.pumpWidget(MaterialApp(home: Builder(builder: (bctx) {
      return ElevatedButton(
        onPressed: () => reg.dispatch(bctx, SduiAction(
          actionType: 'multiAction',
          props: {
            'sync': true,
            'actions': [
              {'actionType': 'a'},
              {'actionType': 'b'},
            ],
          },
        )),
        child: const Text('go'),
      );
    })));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(order, [1, 2]);
  });

  testWidgets('delay waits the configured ms', (tester) async {
    final reg = SduiActionRegistry();
    reg.register('delay', delayHandler);
    late BuildContext capturedCtx;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (bctx) {
      capturedCtx = bctx;
      return const SizedBox();
    })));
    final sw = Stopwatch()..start();
    await tester.runAsync(() async {
      await reg.dispatch(capturedCtx, SduiAction(actionType: 'delay', props: {'milliseconds': 50}));
    });
    sw.stop();
    expect(sw.elapsed.inMilliseconds, greaterThanOrEqualTo(50));
  });

  test('noneHandler returns null without side effects', () async {
    final r = await noneHandler(_NullContext(), SduiAction(actionType: 'none', props: {}));
    expect(r, isNull);
  });
}

class _NullContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation i) => null;
}
