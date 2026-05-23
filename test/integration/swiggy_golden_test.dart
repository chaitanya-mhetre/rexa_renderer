import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sdui_renderer/sdui_renderer.dart';
import 'package:sdui_renderer/src/cache/sdui_cache_service.dart';
import 'package:sdui_renderer/src/sdui.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    SduiCacheService.resetForTest();
    Sdui.resetForTest();
  });

  testWidgets(
    'Swiggy-shaped: native shell + 2 SDUI sections + custom action + context reactivity',
    (tester) async {
      // ── Load fixtures ────────────────────────────────────────────────────
      final banner =
          jsonDecode(File('test/fixtures/swiggy_banner.json').readAsStringSync())
              as Map<String, dynamic>;
      final promo =
          jsonDecode(File('test/fixtures/swiggy_promo.json').readAsStringSync())
              as Map<String, dynamic>;

      // ── Wire static HTTP adapter ─────────────────────────────────────────
      final dio = Dio()
        ..httpClientAdapter = _StaticAdapter({
          '/api/v1/screens/home_banner': banner,
          '/api/v1/screens/home_promo': promo,
        });

      await Sdui.initialize(apiKey: 'k', dio: dio);

      // Set initial context
      Sdui.setContext({'user': {'name': 'Jane'}, 'cart': {'itemCount': 2}});

      // Register custom action
      String? cartAddProductId;
      Sdui.registerAction('addToCart', (ctx, a) async {
        cartAddProductId = a.props['productId'] as String?;
      });

      // ── Pump the widget tree ──────────────────────────────────────────────
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('Swiggy')),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('NATIVE SEARCH BAR'),
              SduiScreen(routeName: 'home_banner'),
              SduiScreen(routeName: 'home_promo'),
              Text('NATIVE FOOTER'),
            ],
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // ── Verify SDUI sections rendered with variable interpolation ─────────
      expect(find.text('Welcome back, Jane!'), findsOneWidget,
          reason: 'Banner should show resolved user.name');
      expect(find.text('Cart (2)'), findsOneWidget,
          reason: 'Promo should show resolved cart.itemCount');

      // ── Verify native widgets coexist with SDUI sections ─────────────────
      expect(find.text('NATIVE SEARCH BAR'), findsOneWidget,
          reason: 'Native header should still be visible');
      expect(find.text('NATIVE FOOTER'), findsOneWidget,
          reason: 'Native footer should still be visible');

      // ── Tap the SDUI Add button → custom action fires ─────────────────────
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      expect(cartAddProductId, equals('p1'),
          reason: 'addToCart action should fire with productId=p1');

      // ── Update context → banner re-renders with new name ─────────────────
      Sdui.updateContext({'user': {'name': 'Bob'}});
      await tester.pumpAndSettle();
      expect(find.text('Welcome back, Bob!'), findsOneWidget,
          reason: 'Banner should re-render after context update');
    },
  );
}

// ── Static HTTP adapter ───────────────────────────────────────────────────────

class _StaticAdapter implements HttpClientAdapter {
  final Map<String, dynamic> routes;
  _StaticAdapter(this.routes);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final body = routes[options.path];
    if (body == null) {
      throw DioException(
        requestOptions: options,
        error: 'Not found: ${options.path}',
        type: DioExceptionType.unknown,
      );
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
