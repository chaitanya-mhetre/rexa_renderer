import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_renderer/src/cache/sdui_cached_screen.dart';

void main() {
  test('toJson/fromJson roundtrip', () {
    final c = SduiCachedScreen(
      routeName: 'home',
      json: '{"type":"container"}',
      version: 3,
      cachedAt: DateTime.utc(2026, 5, 23, 10),
    );
    expect(SduiCachedScreen.fromJsonString(c.toJsonString()).version, 3);
    expect(SduiCachedScreen.fromJsonString(c.toJsonString()).routeName, 'home');
  });

  test('isFresh respects maxAge', () {
    final now = DateTime.now();
    final fresh = SduiCachedScreen(
      routeName: 'home', json: '', version: 1,
      cachedAt: now.subtract(const Duration(seconds: 30)),
    );
    final stale = SduiCachedScreen(
      routeName: 'home', json: '', version: 1,
      cachedAt: now.subtract(const Duration(minutes: 10)),
    );
    expect(fresh.isFreshWithin(const Duration(minutes: 1)), isTrue);
    expect(stale.isFreshWithin(const Duration(minutes: 1)), isFalse);
    expect(stale.isFreshWithin(null), isTrue);
  });
}
