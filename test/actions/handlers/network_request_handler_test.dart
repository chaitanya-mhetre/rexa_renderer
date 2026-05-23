import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sdui_renderer/sdui_renderer.dart';
import 'package:sdui_renderer/src/cache/sdui_cache_service.dart';
import 'package:sdui_renderer/src/sdui.dart';

class _MockAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions) handler;
  final List<RequestOptions> calls = [];

  _MockAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? r,
    Future<void>? cancel,
  ) {
    calls.add(o);
    return handler(o);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(String body, int status) => ResponseBody.fromString(
      body,
      status,
      headers: {
        'content-type': ['application/json'],
      },
    );

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    SduiCacheService.resetForTest();
    Sdui.resetForTest();
  });

  testWidgets('networkRequest GET dispatches a 200 follow-up action',
      (tester) async {
    final adapter = _MockAdapter((o) async => _json('{"ok":true}', 200));
    final dio = Dio()..httpClientAdapter = adapter;
    await Sdui.initialize(apiKey: 'k', dio: dio);
    String? followup;
    Sdui.registerAction('navigate', (ctx, a) async {
      followup = a.props['routeName'] as String?;
    }, override: true);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Builder(builder: (ctx) {
      return ElevatedButton(
        onPressed: () => Sdui.dispatch(
            ctx,
            SduiAction(
              actionType: 'networkRequest',
              props: {
                'url': 'https://api.example.com/data',
                'method': 'get',
                'results': [
                  {
                    'statusCode': 200,
                    'action': {'actionType': 'navigate', 'routeName': '/home'},
                  },
                ],
              },
            )),
        child: const Text('go'),
      );
    }))));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(adapter.calls, hasLength(1));
    expect(adapter.calls.first.path, 'https://api.example.com/data');
    expect(adapter.calls.first.method, 'GET');
    expect(followup, '/home');
  });

  testWidgets('networkRequest POST sends resolved body with {{vars}}',
      (tester) async {
    final adapter = _MockAdapter((o) async => _json('{"ok":true}', 200));
    final dio = Dio()..httpClientAdapter = adapter;
    await Sdui.initialize(apiKey: 'k', dio: dio);
    Sdui.setContext({'user': {'name': 'Jane'}});
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Builder(builder: (ctx) {
      return ElevatedButton(
        onPressed: () => Sdui.dispatch(
            ctx,
            SduiAction(
              actionType: 'networkRequest',
              props: {
                'url': 'https://api.example.com/profile',
                'method': 'post',
                'body': {'name': '{{user.name}}'},
              },
            )),
        child: const Text('go'),
      );
    }))));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(adapter.calls, hasLength(1));
    expect(adapter.calls.first.method, 'POST');
    expect((adapter.calls.first.data as Map)['name'], 'Jane');
  });

  testWidgets('networkRequest POST resolves nested action inside body',
      (tester) async {
    final adapter = _MockAdapter((o) async => _json('{"ok":true}', 200));
    final dio = Dio()..httpClientAdapter = adapter;
    await Sdui.initialize(apiKey: 'k', dio: dio);
    // Register a stand-in for getFormValue that returns a known value
    Sdui.registerAction('getFormValue', (ctx, a) async {
      return a.props['id'] == 'email' ? 'a@b.com' : null;
    }, override: true);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Builder(builder: (ctx) {
      return ElevatedButton(
        onPressed: () => Sdui.dispatch(
            ctx,
            SduiAction(
              actionType: 'networkRequest',
              props: {
                'url': 'https://api.example.com/login',
                'method': 'post',
                'body': {
                  'email': {'actionType': 'getFormValue', 'id': 'email'},
                },
              },
            )),
        child: const Text('go'),
      );
    }))));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(adapter.calls.first.method, 'POST');
    final body = adapter.calls.first.data as Map;
    expect(body['email'], 'a@b.com');
  });

  testWidgets('networkRequest matches 401 follow-up action', (tester) async {
    final adapter = _MockAdapter((o) async => _json('{"error":"unauth"}', 401));
    final dio = Dio()..httpClientAdapter = adapter;
    await Sdui.initialize(apiKey: 'k', dio: dio);
    String? snack;
    Sdui.registerAction('snackBar', (ctx, a) async {
      snack = a.props['label'] as String?;
    }, override: true);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Builder(builder: (ctx) {
      return ElevatedButton(
        onPressed: () => Sdui.dispatch(
            ctx,
            SduiAction(
              actionType: 'networkRequest',
              props: {
                'url': 'https://api.example.com/x',
                'method': 'get',
                'results': [
                  {
                    'statusCode': 200,
                    'action': {'actionType': 'snackBar', 'label': 'good'},
                  },
                  {
                    'statusCode': 401,
                    'action': {'actionType': 'snackBar', 'label': 'auth fail'},
                  },
                ],
              },
            )),
        child: const Text('go'),
      );
    }))));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(snack, 'auth fail');
  });
}
