import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_renderer/src/actions/sdui_action.dart';

void main() {
  test('SduiAction.fromJson extracts actionType and props', () {
    final a = SduiAction.fromJson({
      'actionType': 'navigate',
      'routeName': '/details',
      'arguments': {'id': 42},
    });
    expect(a.actionType, 'navigate');
    expect(a.props['routeName'], '/details');
    expect(a.props['arguments'], {'id': 42});
  });

  test('SduiAction.fromJson throws on missing actionType', () {
    expect(() => SduiAction.fromJson({'foo': 'bar'}), throwsArgumentError);
  });

  test('SduiAction.toJson roundtrips', () {
    final src = {'actionType': 'snackBar', 'label': 'Hi'};
    expect(SduiAction.fromJson(src).toJson(), src);
  });
}
