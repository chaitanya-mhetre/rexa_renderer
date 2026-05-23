import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_renderer/src/context/sdui_context_store.dart';

void main() {
  group('SduiContextStore', () {
    test('set replaces entire snapshot', () {
      final s = SduiContextStore();
      s.set({'a': 1});
      s.set({'b': 2});
      expect(s.snapshot, {'b': 2});
    });

    test('update merges shallowly', () {
      final s = SduiContextStore();
      s.set({'a': 1, 'b': 2});
      s.update({'b': 99, 'c': 3});
      expect(s.snapshot, {'a': 1, 'b': 99, 'c': 3});
    });

    test('getValue resolves dot paths', () {
      final s = SduiContextStore();
      s.set({'user': {'name': 'Jane', 'addr': {'city': 'BLR'}}});
      expect(s.getValue('user.name'), 'Jane');
      expect(s.getValue('user.addr.city'), 'BLR');
      expect(s.getValue('user.missing'), isNull);
      expect(s.getValue('nope'), isNull);
    });

    test('notifies listeners on set and update', () {
      final s = SduiContextStore();
      var count = 0;
      s.addListener(() => count++);
      s.set({'a': 1});
      s.update({'b': 2});
      expect(count, 2);
    });
  });
}
