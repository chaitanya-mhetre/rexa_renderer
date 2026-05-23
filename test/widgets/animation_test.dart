import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sdui_renderer/sdui_renderer.dart';

Widget _buildNode(Map<String, dynamic> json) {
  final node = SduiNode.fromJson(json);
  final registry = WidgetRegistry.defaults();
  return MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (ctx) => registry.build(ctx, node),
      ),
    ),
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    SduiCacheService.resetForTest();
    Sdui.resetForTest();
    await Sdui.initialize(apiKey: 'k');
  });

  testWidgets('Node with animation:{type:fade_in} renders SduiAnimatedWrapper',
      (tester) async {
    await tester.pumpWidget(_buildNode({
      'type': 'text',
      'data': 'hello',
      'animation': {'type': 'fade_in', 'duration': 100},
    }));
    await tester.pump();
    expect(find.byType(SduiAnimatedWrapper), findsOneWidget);
    expect(find.text('hello'), findsOneWidget);
  });

  testWidgets('Node without animation does NOT render SduiAnimatedWrapper',
      (tester) async {
    await tester.pumpWidget(_buildNode({
      'type': 'text',
      'data': 'plain',
    }));
    await tester.pump();
    expect(find.byType(SduiAnimatedWrapper), findsNothing);
    expect(find.text('plain'), findsOneWidget);
  });

  testWidgets('fade_slide_up wraps child correctly', (tester) async {
    await tester.pumpWidget(_buildNode({
      'type': 'text',
      'data': 'sliding up',
      'animation': {'type': 'fade_slide_up', 'duration': 200, 'delay': 0},
    }));
    await tester.pump();
    expect(find.byType(SduiAnimatedWrapper), findsOneWidget);
    expect(find.text('sliding up'), findsOneWidget);
  });

  testWidgets('scale_in wraps child correctly', (tester) async {
    await tester.pumpWidget(_buildNode({
      'type': 'text',
      'data': 'scaling in',
      'animation': {'type': 'scale_in', 'duration': 300},
    }));
    await tester.pump();
    expect(find.byType(SduiAnimatedWrapper), findsOneWidget);
  });

  testWidgets('pulse wraps child correctly', (tester) async {
    await tester.pumpWidget(_buildNode({
      'type': 'text',
      'data': 'pulsing',
      'animation': {'type': 'pulse', 'duration': 600, 'repeat': true},
    }));
    await tester.pump();
    expect(find.byType(SduiAnimatedWrapper), findsOneWidget);
  });

  testWidgets('animation on container node wraps container', (tester) async {
    await tester.pumpWidget(_buildNode({
      'type': 'column',
      'animation': {'type': 'fade_in', 'duration': 400},
      'children': [
        {'type': 'text', 'data': 'child'},
      ],
    }));
    await tester.pump();
    expect(find.byType(SduiAnimatedWrapper), findsOneWidget);
    expect(find.text('child'), findsOneWidget);
  });

  testWidgets('animation advances after pump', (tester) async {
    await tester.pumpWidget(_buildNode({
      'type': 'text',
      'data': 'animating',
      'animation': {'type': 'fade_in', 'duration': 200},
    }));
    // After a pump() the controller hasn't been forwarded yet
    // (delay is 0 but Future.delayed still defers by one microtask).
    await tester.pump();
    // Pump the delay + half the animation.
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(SduiAnimatedWrapper), findsOneWidget);
    // Complete the animation.
    await tester.pumpAndSettle();
    expect(find.text('animating'), findsOneWidget);
  });
}
