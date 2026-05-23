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

  testWidgets('SduiLottieWidget renders "No src" placeholder when src is empty',
      (tester) async {
    // Props are passed at the top level of the JSON (not nested under 'props').
    final node = SduiNode.fromJson({'type': 'lottie'});
    final registry = WidgetRegistry.defaults();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => registry.build(ctx, node),
          ),
        ),
      ),
    );
    expect(find.text('No src'), findsOneWidget);
  });

  testWidgets('SduiLottieWidget is registered under "lottie" and "Lottie"',
      (tester) async {
    final registry = WidgetRegistry.defaults();

    for (final type in ['lottie', 'Lottie']) {
      final node = SduiNode.fromJson({'type': type});
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => registry.build(ctx, node),
            ),
          ),
        ),
      );
      expect(find.text('No src'), findsWidgets,
          reason: 'Expected placeholder for type "$type"');
    }
  });

  testWidgets('SduiLottieWidget respects width and height props', (tester) async {
    // Top-level JSON keys become accessible via node.prop(key).
    final node = SduiNode.fromJson({
      'type': 'lottie',
      'width': 120,
      'height': 80,
    });
    final registry = WidgetRegistry.defaults();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => registry.build(ctx, node),
          ),
        ),
      ),
    );
    // The outermost SizedBox (the one wrapping the whole widget) must have
    // the specified dimensions.
    final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
    final outer = sizedBoxes.firstWhere(
      (s) => s.width == 120 && s.height == 80,
      orElse: () => throw TestFailure(
        'No SizedBox with width=120, height=80 found',
      ),
    );
    expect(outer.width, 120);
    expect(outer.height, 80);
  });
}
