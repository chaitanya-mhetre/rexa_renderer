import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sdui_renderer/sdui_renderer.dart';
import 'package:sdui_renderer/src/cache/sdui_cache_strategy.dart';
import 'package:sdui_renderer/src/cache/sdui_cache_service.dart';
import 'package:sdui_renderer/src/sdui.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    SduiCacheService.resetForTest();
    Sdui.resetForTest();
  });

  testWidgets('renders loading then content', (tester) async {
    final dio = Dio()
      ..httpClientAdapter = _delayedJson(
        '{"layout":{"type":"text","data":"hi"},"version":1}',
        100,
      );
    await Sdui.initialize(apiKey: 'k', dio: dio);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SduiScreen(
          routeName: 'home',
          loadingBuilder: (_) => const Text('loading…'),
        ),
      ),
    ));
    expect(find.text('loading…'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('hi'), findsOneWidget);
  });

  testWidgets('cacheFirst returns cache without network', (tester) async {
    final dio = Dio()..httpClientAdapter = _throwingAdapter();
    await Sdui.initialize(apiKey: 'k', dio: dio);
    await SduiCacheService.put(
      'home',
      '{"type":"text","data":"cached"}',
      1,
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SduiScreen(
          routeName: 'home',
          cacheStrategy: SduiCacheStrategy.cacheFirst,
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('cached'), findsOneWidget);
  });

  testWidgets('errorBuilder shows when network fails and no cache',
      (tester) async {
    final dio = Dio()..httpClientAdapter = _throwingAdapter();
    await Sdui.initialize(apiKey: 'k', dio: dio);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SduiScreen(
          routeName: 'home',
          cacheStrategy: SduiCacheStrategy.networkOnly,
          errorBuilder: (_, e) => const Text('failed'),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('failed'), findsOneWidget);
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

HttpClientAdapter _throwingAdapter() => _MockAdapter((_) async {
      throw DioException(
        requestOptions: RequestOptions(),
        error: 'boom',
      );
    });

class _MockAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions) handler;

  _MockAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) =>
      handler(options);

  @override
  void close({bool force = false}) {}
}
