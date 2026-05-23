import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sdui_renderer/src/sdui.dart';
import 'package:sdui_renderer/src/actions/sdui_action.dart';
import 'package:sdui_renderer/src/cache/sdui_cache_service.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    SduiCacheService.resetForTest();
    Sdui.resetForTest();
    await Sdui.initialize(apiKey: 'sdui_test');
  });

  test('initialize is idempotent', () async {
    await Sdui.initialize(apiKey: 'sdui_test');
    expect(true, isTrue);
  });

  test('setContext + getContextValue roundtrip', () {
    Sdui.setContext({'user': {'name': 'Jane'}});
    expect(Sdui.getContextValue('user.name'), 'Jane');
  });

  test('updateContext merges', () {
    Sdui.setContext({'a': 1});
    Sdui.updateContext({'b': 2});
    expect(Sdui.getContextValue('a'), 1);
    expect(Sdui.getContextValue('b'), 2);
  });

  testWidgets('dispatch built-in setValue mutates context', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Builder(builder: (ctx) {
      return ElevatedButton(
        onPressed: () => Sdui.dispatch(ctx, SduiAction(
          actionType: 'setValue',
          props: {'values': {'tapped': true}},
        )),
        child: const Text('go'),
      );
    }))));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(Sdui.getContextValue('tapped'), isTrue);
  });

  testWidgets('onAnyAction observer fires', (tester) async {
    final seen = <String>[];
    Sdui.onAnyAction((a) => seen.add(a.actionType));
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Builder(builder: (ctx) {
      return ElevatedButton(
        onPressed: () => Sdui.dispatch(ctx, SduiAction(actionType: 'none', props: {})),
        child: const Text('go'),
      );
    }))));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(seen, contains('none'));
  });
}
