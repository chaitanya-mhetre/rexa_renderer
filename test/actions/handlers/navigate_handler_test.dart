import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sdui_renderer/src/actions/sdui_action.dart';
import 'package:sdui_renderer/src/actions/handlers/navigate_handler.dart';
import 'package:sdui_renderer/src/cache/sdui_cache_service.dart';
import 'package:sdui_renderer/src/sdui.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    SduiCacheService.resetForTest();
    Sdui.resetForTest();
    final dio = Dio()
      ..httpClientAdapter = _delayedJson(
        '{"layout":{"type":"text","data":"destination"},"version":1}',
        50,
      );
    await Sdui.initialize(apiKey: 'test_key', dio: dio);
  });

  testWidgets('navigate push: opens new route', (tester) async {
    final navKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
      navigatorKey: navKey,
      home: Builder(builder: (ctx) {
        return ElevatedButton(
          onPressed: () => navigateHandler(ctx, SduiAction(
            actionType: 'navigate',
            props: {'navigationStyle': 'push', 'routeName': '/x'},
          )),
          child: const Text('go'),
        );
      }),
    ));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(navKey.currentState!.canPop(), isTrue);
  });

  testWidgets('navigate pop: returns to previous route', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (root) {
        return ElevatedButton(
          onPressed: () => Navigator.push(root, MaterialPageRoute(
            builder: (inner) => ElevatedButton(
              key: const Key('popper'),
              onPressed: () => navigateHandler(inner, SduiAction(
                actionType: 'navigate',
                props: {'navigationStyle': 'pop'},
              )),
              child: const Text('pop'),
            ),
          )),
          child: const Text('push'),
        );
      }),
    ));
    await tester.tap(find.text('push'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('popper')));
    await tester.pumpAndSettle();
    expect(find.text('push'), findsOneWidget);
  });
}

HttpClientAdapter _delayedJson(String body, int delayMs) =>
    _MockAdapter((opts) async {
      await Future.delayed(Duration(milliseconds: delayMs));
      return ResponseBody.fromString(
        body,
        200,
        headers: {
          'content-type': ['application/json'],
        },
      );
    });

class _MockAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions) handler;

  _MockAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future? cancelFuture) async {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}
