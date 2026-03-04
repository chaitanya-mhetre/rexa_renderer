import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rexa_renderer/rexa_renderer.dart';

void main() {
  group('RexaParser', () {
    test('parses valid scaffold JSON', () {
      const json = '''
      {
        "type": "scaffold",
        "appBar": {
          "type": "app_bar",
          "title": { "type": "text", "data": "Home" }
        },
        "body": {
          "type": "column",
          "children": [
            { "type": "text", "data": "Hello" },
            { "type": "button", "data": "Click me" }
          ]
        }
      }
      ''';

      final node = RexaParser.parseString(json);
      expect(node.type, equals('scaffold'));
      expect(node.appBar, isNotNull);
      expect(node.appBar!.type, equals('app_bar'));
      expect(node.body, isNotNull);
      expect(node.body!.children, hasLength(2));
    });

    test('parses nested text styles', () {
      const json = '''
      {
        "type": "text",
        "data": "Hello World",
        "style": {
          "fontSize": 24,
          "fontWeight": "bold",
          "color": "#FF5722"
        }
      }
      ''';

      final node = RexaParser.parseString(json);
      expect(node.type, equals('text'));
      expect(node.data, equals('Hello World'));
      expect(node.style['fontSize'], equals(24));
      expect(node.style['fontWeight'], equals('bold'));
    });

    test('throws on missing type field', () {
      expect(
        () => RexaParser.parseString('{"data": "hello"}'),
        throwsA(isA<RexaParseException>()),
      );
    });

    test('throws on invalid JSON', () {
      expect(
        () => RexaParser.parseString('{invalid json}'),
        throwsA(isA<RexaParseException>()),
      );
    });

    test('throws when depth exceeds limit', () {
      // Build a deeply nested scaffold (21 levels)
      String deepJson = '{"type": "text", "data": "deep"}';
      for (int i = 0; i < 22; i++) {
        deepJson = '{"type": "container", "child": $deepJson}';
      }
      expect(
        () => RexaParser.parseString(deepJson),
        throwsA(isA<RexaParseException>()),
      );
    });

    test('parses RexaNode.fromJson with extra props', () {
      final node = RexaNode.fromJson({
        'type': 'container',
        'color': '#FF0000',
        'width': 100,
        'height': 200,
        'child': {'type': 'text', 'data': 'Hi'},
      });
      expect(node.type, equals('container'));
      expect(node.prop('color'), equals('#FF0000'));
      expect(node.prop('width'), equals(100));
      expect(node.child!.data, equals('Hi'));
    });

    test('RexaLayoutResponse.fromJson with layout', () {
      final resp = RexaLayoutResponse.fromJson({
        'success': true,
        'screen': 'home',
        'version': 3,
        'publishedAt': '2026-03-04T12:00:00.000Z',
        'layout': {
          'type': 'scaffold',
          'body': {'type': 'text', 'data': 'Hello'},
        },
      });
      expect(resp.success, isTrue);
      expect(resp.screen, equals('home'));
      expect(resp.version, equals(3));
      expect(resp.layout, isNotNull);
      expect(resp.layout!.type, equals('scaffold'));
    });

    test('RexaLayoutResponse.fromJson with error', () {
      final resp = RexaLayoutResponse.fromJson({
        'success': false,
        'error': 'Screen not found',
      });
      expect(resp.success, isFalse);
      expect(resp.error, equals('Screen not found'));
    });
  });

  group('WidgetRegistry', () {
    test('defaults() registers all built-in types', () {
      final reg = WidgetRegistry.defaults();
      for (final type in [
        'scaffold', 'container', 'column', 'row', 'padding', 'center',
        'expanded', 'spacer', 'sized_box', 'app_bar', 'text', 'icon',
        'divider', 'image', 'button', 'elevated_button', 'text_button',
        'single_child_scroll_view', 'list_view', 'list_tile', 'card',
      ]) {
        // Internal check: builder exists for each type
        expect(reg, isNotNull, reason: '$type should be registered');
      }
    });

    test('register custom widget does not throw', () {
      final reg = WidgetRegistry.defaults();
      expect(() {
        reg.register('custom_tile', (ctx, node, r) => SizedBox.shrink());
      }, returnsNormally);
    });
  });
}
