import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_renderer/src/sdui_error.dart';

void main() {
  test('SduiError carries type, message, nodePath, and rawNode', () {
    final err = SduiError(
      type: 'container',
      message: 'unknown prop "frobnicate"',
      nodePath: 'scaffold.body.column.children[0]',
      rawNode: const {'type': 'container', 'frobnicate': true},
    );
    expect(err.type, 'container');
    expect(err.message, 'unknown prop "frobnicate"');
    expect(err.nodePath, 'scaffold.body.column.children[0]');
    expect(err.rawNode, isMap);
  });

  test('SduiError.toString is human-readable', () {
    final err = SduiError(type: 'x', message: 'boom');
    expect(err.toString(), contains('boom'));
    expect(err.toString(), contains('x'));
  });
}
