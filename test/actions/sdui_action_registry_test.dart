import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_renderer/src/actions/sdui_action.dart';
import 'package:sdui_renderer/src/actions/sdui_action_registry.dart';

void main() {
  group('SduiActionRegistry', () {
    test('register stores handler under actionType', () async {
      final reg = SduiActionRegistry();
      String? captured;
      reg.register('test', (ctx, a) async {
        captured = a.props['v'] as String?;
      });
      await reg.dispatch(_dummyCtx(), SduiAction(actionType: 'test', props: {'v': 'hi'}));
      expect(captured, 'hi');
    });

    test('register without override on existing key returns false', () {
      final reg = SduiActionRegistry();
      reg.register('test', (_, __) {});
      final ok = reg.register('test', (_, __) {});
      expect(ok, isFalse);
    });

    test('register with override:true replaces existing', () async {
      final reg = SduiActionRegistry();
      int callCount = 0;
      reg.register('test', (_, __) { callCount = 1; });
      reg.register('test', (_, __) { callCount = 2; }, override: true);
      await reg.dispatch(_dummyCtx(), SduiAction(actionType: 'test', props: {}));
      expect(callCount, 2);
    });

    test('dispatch fires observers before the handler', () async {
      final reg = SduiActionRegistry();
      final order = <String>[];
      reg.onAnyAction((a) => order.add('obs:${a.actionType}'));
      reg.register('test', (_, __) async { order.add('handler'); });
      await reg.dispatch(_dummyCtx(), SduiAction(actionType: 'test', props: {}));
      expect(order, ['obs:test', 'handler']);
    });

    test('dispatch of unknown action fires observer and returns null', () async {
      final reg = SduiActionRegistry();
      String? seen;
      reg.onAnyAction((a) => seen = a.actionType);
      final result = await reg.dispatch(_dummyCtx(), SduiAction(actionType: 'unknown', props: {}));
      expect(result, isNull);
      expect(seen, 'unknown');
    });
  });
}

BuildContext _dummyCtx() => _NullContext();

class _NullContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation i) => null;
}
