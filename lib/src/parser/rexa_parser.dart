import 'dart:convert';
import '../models/rexa_layout.dart';

/// Validates and parses raw JSON strings or maps into [RexaNode] trees.
class RexaParser {
  static const int _maxDepth = 20;
  static const int _maxNodes = 500;

  /// Parse a raw JSON [String] into a [RexaNode].
  ///
  /// Throws [RexaParseException] on validation failure.
  static RexaNode parseString(String jsonString) {
    final dynamic raw;
    try {
      raw = jsonDecode(jsonString);
    } catch (e) {
      throw RexaParseException('Invalid JSON: $e');
    }
    return parseMap(raw as Map<String, dynamic>);
  }

  /// Parse a raw [Map] into a [RexaNode].
  static RexaNode parseMap(Map<String, dynamic> json) {
    _validate(json, depth: 0, counter: _NodeCounter());
    return RexaNode.fromJson(json);
  }

  static void _validate(
    dynamic node, {
    required int depth,
    required _NodeCounter counter,
  }) {
    if (depth > _maxDepth) {
      throw RexaParseException('Node tree exceeds max depth of $_maxDepth');
    }
    if (counter.increment() > _maxNodes) {
      throw RexaParseException('Node tree exceeds max node count of $_maxNodes');
    }
    if (node == null || node is! Map<String, dynamic>) {
      throw RexaParseException('Node at depth $depth must be an object');
    }
    if (node['type'] is! String || (node['type'] as String).isEmpty) {
      throw RexaParseException('Node at depth $depth is missing "type" field');
    }

    // Recurse into single-child slots
    for (final slot in [
      'appBar', 'body', 'child', 'title', 'leading',
      'floatingActionButton', 'bottomNavigation', 'trailing',
    ]) {
      final v = node[slot];
      if (v != null) _validate(v, depth: depth + 1, counter: counter);
    }

    // Recurse into array slots
    for (final slot in ['children', 'actions']) {
      final v = node[slot];
      if (v == null) continue;
      if (v is! List) {
        throw RexaParseException('"$slot" at depth $depth must be an array');
      }
      for (final child in v) {
        _validate(child, depth: depth + 1, counter: counter);
      }
    }
  }
}

class _NodeCounter {
  int _count = 0;
  int increment() => ++_count;
}

/// Thrown when REXA JSON fails validation.
class RexaParseException implements Exception {
  final String message;
  const RexaParseException(this.message);

  @override
  String toString() => 'RexaParseException: $message';
}
