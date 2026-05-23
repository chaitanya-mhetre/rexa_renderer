import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_renderer/src/sdui_controller.dart';

void main() {
  test('emits lifecycle events when wired', () async {
    final c = SduiController();
    final events = <SduiLifecycleEvent>[];
    final sub = c.events.listen(events.add);
    c.notifyFetchStart();
    c.notifyFetchDone();
    await Future.delayed(Duration.zero);
    expect(events.map((e) => e.runtimeType.toString()), [
      'SduiFetchStartEvent',
      'SduiFetchDoneEvent',
    ]);
    await sub.cancel();
  });

  test('refresh callback is invoked', () async {
    final c = SduiController();
    var refreshed = false;
    c.attach(() async { refreshed = true; }, () async {});
    await c.refresh();
    expect(refreshed, isTrue);
  });

  test('attach twice throws', () {
    final c = SduiController();
    c.attach(() async {}, () async {});
    expect(() => c.attach(() async {}, () async {}), throwsStateError);
  });
}
