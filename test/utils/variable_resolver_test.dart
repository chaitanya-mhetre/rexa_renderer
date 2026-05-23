import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_renderer/src/context/sdui_context_store.dart';
import 'package:sdui_renderer/src/utils/variable_resolver.dart';

void main() {
  group('resolveVariables', () {
    test('substitutes a simple string', () {
      final ctx = SduiContextStore()..set({'name': 'Jane'});
      expect(resolveVariables('Hello, {{name}}!', ctx), 'Hello, Jane!');
    });

    test('substitutes dot paths', () {
      final ctx = SduiContextStore()..set({'user': {'name': 'Jane'}});
      expect(resolveVariables('Hi, {{user.name}}', ctx), 'Hi, Jane');
    });

    test('leaves untouched when variable missing', () {
      final ctx = SduiContextStore();
      expect(resolveVariables('Hi, {{user.name}}', ctx), 'Hi, {{user.name}}');
    });

    test('recursively walks maps and lists', () {
      final ctx = SduiContextStore()..set({'n': 'Jane', 'age': 30});
      final input = {
        'type': 'text',
        'data': 'Hi, {{n}}',
        'children': [
          {'data': '{{age}} yrs'},
        ],
      };
      final out = resolveVariablesInJson(input, ctx) as Map;
      expect(out['data'], 'Hi, Jane');
      expect(out['children'][0]['data'], '30 yrs');
    });

    test('preserves non-string, non-map, non-list primitives', () {
      final ctx = SduiContextStore();
      expect(resolveVariablesInJson(42, ctx), 42);
      expect(resolveVariablesInJson(true, ctx), true);
      expect(resolveVariablesInJson(null, ctx), isNull);
    });

    test('handles multiple substitutions per string', () {
      final ctx = SduiContextStore()..set({'a': '1', 'b': '2'});
      expect(resolveVariables('{{a}}-{{b}}', ctx), '1-2');
    });
  });
}
