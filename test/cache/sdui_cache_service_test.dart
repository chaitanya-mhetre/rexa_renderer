import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sdui_renderer/src/cache/sdui_cache_service.dart';
import 'package:sdui_renderer/src/cache/sdui_cached_screen.dart';

void main() {
  setUp(() async {
    SduiCacheService.resetForTest();
    SharedPreferences.setMockInitialValues({});
    await SduiCacheService.initialize();
  });

  test('put then get roundtrips', () async {
    await SduiCacheService.put('home', '{"type":"x"}', 1);
    final c = await SduiCacheService.get('home');
    expect(c, isNotNull);
    expect(c!.routeName, 'home');
    expect(c.version, 1);
  });

  test('get returns null for unknown route', () async {
    expect(await SduiCacheService.get('nope'), isNull);
  });

  test('remove clears a single entry', () async {
    await SduiCacheService.put('home', '{}', 1);
    await SduiCacheService.remove('home');
    expect(await SduiCacheService.get('home'), isNull);
  });

  test('clear wipes everything', () async {
    await SduiCacheService.put('home', '{}', 1);
    await SduiCacheService.put('cart', '{}', 1);
    await SduiCacheService.clear();
    expect(await SduiCacheService.get('home'), isNull);
    expect(await SduiCacheService.get('cart'), isNull);
  });

  test('put overwrites on same route', () async {
    await SduiCacheService.put('home', '{"v":1}', 1);
    await SduiCacheService.put('home', '{"v":2}', 2);
    final c = await SduiCacheService.get('home');
    expect(c!.version, 2);
  });
}
