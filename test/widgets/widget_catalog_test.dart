import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sdui_renderer/sdui_renderer.dart';

// Wrapper that builds a node inside a MaterialApp with a real context.
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

  // ── Stack ──────────────────────────────────────────────────────────────────
  testWidgets('Stack renders', (tester) async {
    await tester.pumpWidget(_buildNode({
      'type': 'Stack',
      'alignment': 'center',
      'children': [
        {'type': 'text', 'data': 'layer1'},
        {'type': 'text', 'data': 'layer2'},
      ],
    }));
    expect(find.byType(Stack), findsWidgets);
    expect(find.text('layer1'), findsOneWidget);
  });

  testWidgets('stack (snake_case) renders', (tester) async {
    await tester.pumpWidget(_buildNode({
      'type': 'stack',
      'children': [
        {'type': 'text', 'data': 'hello'},
      ],
    }));
    expect(find.byType(Stack), findsWidgets);
  });

  // ── Positioned ─────────────────────────────────────────────────────────────
  testWidgets('Positioned inside Stack renders', (tester) async {
    await tester.pumpWidget(_buildNode({
      'type': 'Stack',
      'children': [
        {
          'type': 'Positioned',
          'top': 10.0,
          'left': 10.0,
          'child': {'type': 'text', 'data': 'positioned text'},
        }
      ],
    }));
    expect(find.byType(Positioned), findsOneWidget);
    expect(find.text('positioned text'), findsOneWidget);
  });

  testWidgets('positioned (snake_case) renders', (tester) async {
    await tester.pumpWidget(_buildNode({
      'type': 'Stack',
      'children': [
        {
          'type': 'positioned',
          'top': 0.0,
          'right': 0.0,
          'child': {'type': 'text', 'data': 'pos'},
        }
      ],
    }));
    expect(find.byType(Positioned), findsOneWidget);
  });

  // ── Wrap ───────────────────────────────────────────────────────────────────
  testWidgets('Wrap renders with children', (tester) async {
    await tester.pumpWidget(_buildNode({
      'type': 'Wrap',
      'spacing': 8.0,
      'runSpacing': 4.0,
      'children': [
        {'type': 'text', 'data': 'a'},
        {'type': 'text', 'data': 'b'},
        {'type': 'text', 'data': 'c'},
      ],
    }));
    expect(find.byType(Wrap), findsOneWidget);
    expect(find.text('a'), findsOneWidget);
    expect(find.text('b'), findsOneWidget);
  });

  testWidgets('wrap (snake_case) renders', (tester) async {
    await tester.pumpWidget(_buildNode({
      'type': 'wrap',
      'children': [
        {'type': 'text', 'data': 'x'},
      ],
    }));
    expect(find.byType(Wrap), findsOneWidget);
  });

  // ── SafeArea ───────────────────────────────────────────────────────────────
  testWidgets('SafeArea renders with child', (tester) async {
    await tester.pumpWidget(_buildNode({
      'type': 'SafeArea',
      'top': true,
      'bottom': false,
      'child': {'type': 'text', 'data': 'safe'},
    }));
    expect(find.byType(SafeArea), findsOneWidget);
    expect(find.text('safe'), findsOneWidget);
  });

  testWidgets('safe_area (snake_case) renders', (tester) async {
    await tester.pumpWidget(_buildNode({
      'type': 'safe_area',
      'child': {'type': 'text', 'data': 'safe2'},
    }));
    expect(find.byType(SafeArea), findsOneWidget);
  });

  // ── CircularProgressIndicator ──────────────────────────────────────────────
  testWidgets('CircularProgressIndicator renders', (tester) async {
    await tester.pumpWidget(_buildNode({
      'type': 'CircularProgressIndicator',
      'value': 0.5,
      'strokeWidth': 3.0,
    }));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('circular_progress_indicator (snake_case) renders', (tester) async {
    await tester.pumpWidget(_buildNode({
      'type': 'circular_progress_indicator',
      'value': 0.3,
    }));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('CircularProgressIndicator renders indeterminate (no value)', (tester) async {
    await tester.pumpWidget(_buildNode({
      'type': 'CircularProgressIndicator',
    }));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  // ── LinearProgressIndicator ───────────────────────────────────────────────
  testWidgets('LinearProgressIndicator renders', (tester) async {
    await tester.pumpWidget(_buildNode({
      'type': 'LinearProgressIndicator',
      'value': 0.75,
    }));
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('linear_progress_indicator (snake_case) renders', (tester) async {
    await tester.pumpWidget(_buildNode({
      'type': 'linear_progress_indicator',
    }));
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  // ── Checkbox ───────────────────────────────────────────────────────────────
  testWidgets('Checkbox renders unchecked by default', (tester) async {
    await tester.pumpWidget(_buildNode({
      'type': 'Checkbox',
      'value': false,
    }));
    expect(find.byType(Checkbox), findsOneWidget);
  });

  testWidgets('Checkbox renders checked when value is true', (tester) async {
    await tester.pumpWidget(_buildNode({
      'type': 'checkbox',
      'value': true,
    }));
    final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
    expect(checkbox.value, isTrue);
  });

  testWidgets('Checkbox can be toggled', (tester) async {
    await tester.pumpWidget(_buildNode({
      'type': 'Checkbox',
      'value': false,
    }));
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
    expect(checkbox.value, isTrue);
  });

  // ── Switch ─────────────────────────────────────────────────────────────────
  testWidgets('Switch renders off by default', (tester) async {
    await tester.pumpWidget(_buildNode({
      'type': 'Switch',
      'value': false,
    }));
    expect(find.byType(Switch), findsOneWidget);
    final sw = tester.widget<Switch>(find.byType(Switch));
    expect(sw.value, isFalse);
  });

  testWidgets('switch (snake_case) renders on', (tester) async {
    await tester.pumpWidget(_buildNode({
      'type': 'switch',
      'value': true,
    }));
    final sw = tester.widget<Switch>(find.byType(Switch));
    expect(sw.value, isTrue);
  });

  testWidgets('Switch can be toggled', (tester) async {
    await tester.pumpWidget(_buildNode({
      'type': 'Switch',
      'value': false,
    }));
    await tester.tap(find.byType(Switch));
    await tester.pump();
    final sw = tester.widget<Switch>(find.byType(Switch));
    expect(sw.value, isTrue);
  });

  // ── Slider ─────────────────────────────────────────────────────────────────
  testWidgets('Slider renders with default props', (tester) async {
    await tester.pumpWidget(_buildNode({
      'type': 'Slider',
      'value': 0.5,
      'min': 0.0,
      'max': 1.0,
    }));
    expect(find.byType(Slider), findsOneWidget);
    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.value, closeTo(0.5, 0.001));
  });

  testWidgets('slider (snake_case) renders', (tester) async {
    await tester.pumpWidget(_buildNode({
      'type': 'slider',
      'value': 30.0,
      'min': 0.0,
      'max': 100.0,
    }));
    expect(find.byType(Slider), findsOneWidget);
  });

  testWidgets('Slider with divisions renders', (tester) async {
    await tester.pumpWidget(_buildNode({
      'type': 'Slider',
      'value': 50.0,
      'min': 0.0,
      'max': 100.0,
      'divisions': 10,
    }));
    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.divisions, equals(10));
  });

  // ── Radio ──────────────────────────────────────────────────────────────────
  testWidgets('Radio renders with value and groupValue', (tester) async {
    await tester.pumpWidget(_buildNode({
      'type': 'Radio',
      'value': 'a',
      'groupValue': 'b',
    }));
    // Radio is wrapped in a RadioGroup — both types appear in the tree.
    expect(find.byType(Radio<String>), findsOneWidget);
    expect(find.byType(RadioGroup<String>), findsOneWidget);
    final radio = tester.widget<Radio<String>>(find.byType(Radio<String>));
    expect(radio.value, equals('a'));
  });

  testWidgets('radio (snake_case) renders with matching groupValue', (tester) async {
    await tester.pumpWidget(_buildNode({
      'type': 'radio',
      'value': 'x',
      'groupValue': 'x',
    }));
    expect(find.byType(Radio<String>), findsOneWidget);
  });

  // ── Chip ───────────────────────────────────────────────────────────────────
  testWidgets('Chip renders with label', (tester) async {
    await tester.pumpWidget(_buildNode({
      'type': 'Chip',
      'label': 'Flutter',
    }));
    expect(find.byType(Chip), findsOneWidget);
    expect(find.text('Flutter'), findsOneWidget);
  });

  testWidgets('chip (snake_case) renders', (tester) async {
    await tester.pumpWidget(_buildNode({
      'type': 'chip',
      'label': 'Dart',
    }));
    expect(find.byType(Chip), findsOneWidget);
    expect(find.text('Dart'), findsOneWidget);
  });

  // ── Badge ──────────────────────────────────────────────────────────────────
  testWidgets('Badge renders with label and child', (tester) async {
    await tester.pumpWidget(_buildNode({
      'type': 'Badge',
      'label': '3',
      'child': {'type': 'icon', 'name': 'notifications'},
    }));
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('badge (snake_case) renders label only', (tester) async {
    await tester.pumpWidget(_buildNode({
      'type': 'badge',
      'label': '99',
    }));
    expect(find.text('99'), findsOneWidget);
  });

  // ── TextField ──────────────────────────────────────────────────────────────
  testWidgets('TextField renders with hint', (tester) async {
    await tester.pumpWidget(_buildNode({
      'type': 'TextField',
      'hintText': 'Enter name',
      'label': 'Name',
    }));
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('text_field (snake_case) renders', (tester) async {
    await tester.pumpWidget(_buildNode({
      'type': 'text_field',
      'hintText': 'Search...',
    }));
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('text_input alias resolves to TextField', (tester) async {
    await tester.pumpWidget(_buildNode({
      'type': 'text_input',
      'hintText': 'Input here',
    }));
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('TextField renders with initialValue', (tester) async {
    await tester.pumpWidget(_buildNode({
      'type': 'TextField',
      'initialValue': 'hello',
    }));
    await tester.pump(); // allow controller to settle
    expect(find.byType(TextField), findsOneWidget);
    // The text controller pre-populates the EditableText
    expect(find.text('hello'), findsOneWidget);
  });

  // ── Tooltip ────────────────────────────────────────────────────────────────
  testWidgets('Tooltip renders wrapping child', (tester) async {
    await tester.pumpWidget(_buildNode({
      'type': 'Tooltip',
      'message': 'Helpful tip',
      'child': {'type': 'text', 'data': 'hover me'},
    }));
    expect(find.byType(Tooltip), findsOneWidget);
    expect(find.text('hover me'), findsOneWidget);
  });

  testWidgets('tooltip (snake_case) renders', (tester) async {
    await tester.pumpWidget(_buildNode({
      'type': 'tooltip',
      'message': 'tip',
      'child': {'type': 'text', 'data': 'child'},
    }));
    expect(find.byType(Tooltip), findsOneWidget);
  });

  // ── PascalCase aliases ─────────────────────────────────────────────────────
  testWidgets('PascalCase Stack alias works', (tester) async {
    await tester.pumpWidget(_buildNode({
      'type': 'Stack',
      'children': [{'type': 'text', 'data': 'hi'}],
    }));
    expect(find.byType(Stack), findsWidgets);
  });

  testWidgets('PascalCase Wrap alias works', (tester) async {
    await tester.pumpWidget(_buildNode({
      'type': 'Wrap',
      'children': [{'type': 'text', 'data': 'w'}],
    }));
    expect(find.byType(Wrap), findsOneWidget);
  });

  testWidgets('PascalCase SafeArea alias works', (tester) async {
    await tester.pumpWidget(_buildNode({
      'type': 'SafeArea',
      'child': {'type': 'text', 'data': 's'},
    }));
    expect(find.byType(SafeArea), findsOneWidget);
  });
}
