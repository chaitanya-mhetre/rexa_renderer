import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sdui_renderer/sdui_renderer.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    SduiCacheService.resetForTest();
    Sdui.resetForTest();
    await Sdui.initialize(apiKey: 'k');
  });

  testWidgets('Carousel renders children with dots', (tester) async {
    final node = SduiNode.fromJson({
      'type': 'carousel',
      'children': [
        {'type': 'container', 'props': {'color': '#FF0000'}},
        {'type': 'container', 'props': {'color': '#00FF00'}},
        {'type': 'container', 'props': {'color': '#0000FF'}},
      ],
    });
    final registry = WidgetRegistry.defaults();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (ctx) => registry.build(ctx, node),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(PageView), findsOneWidget);
  });

  testWidgets('Carousel (TitleCase) renders', (tester) async {
    final node = SduiNode.fromJson({
      'type': 'Carousel',
      'variant': 'snap',
      'height': 180,
      'showDots': true,
      'children': [
        {'type': 'container', 'props': {'color': '#AABBCC'}},
        {'type': 'container', 'props': {'color': '#CCBBAA'}},
      ],
    });
    final registry = WidgetRegistry.defaults();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (ctx) => registry.build(ctx, node),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(PageView), findsOneWidget);
  });

  testWidgets('Carousel with no children renders empty box', (tester) async {
    final node = SduiNode.fromJson({
      'type': 'carousel',
      'children': [],
    });
    final registry = WidgetRegistry.defaults();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (ctx) => registry.build(ctx, node),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    // No PageView when children is empty — just a SizedBox
    expect(find.byType(PageView), findsNothing);
    expect(find.byType(SizedBox), findsWidgets);
  });
}
