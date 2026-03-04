/// Core data model for a REXA layout node tree.
/// Mirrors the Flutter-compatible JSON schema produced by the REXA builder.
library rexa_models;

/// A single node in the REXA widget tree.
/// Closely mirrors Flutter's widget constructor parameters.
class RexaNode {
  /// Widget type, e.g. "scaffold", "text", "column".
  final String type;

  /// Text content — used by [text] widget.
  final String? data;

  /// Inline style overrides.
  final Map<String, dynamic> style;

  /// Direct child nodes (for multi-child widgets like column/row).
  final List<RexaNode> children;

  // ── Named slots (single-child) ──────────────────────────────────────────
  final RexaNode? appBar;
  final RexaNode? body;
  final RexaNode? child;
  final RexaNode? title;
  final RexaNode? leading;
  final RexaNode? floatingActionButton;
  final RexaNode? bottomNavigation;
  final RexaNode? trailing;

  /// Action widgets (icon buttons in AppBar, etc.)
  final List<RexaNode> actions;

  /// Extra properties not modelled above — accessed via [prop].
  final Map<String, dynamic> _extra;

  const RexaNode({
    required this.type,
    this.data,
    this.style = const {},
    this.children = const [],
    this.appBar,
    this.body,
    this.child,
    this.title,
    this.leading,
    this.floatingActionButton,
    this.bottomNavigation,
    this.trailing,
    this.actions = const [],
    Map<String, dynamic> extra = const {},
  }) : _extra = extra;

  /// Access any extra JSON property by key.
  dynamic prop(String key) => _extra[key];

  /// Convenience: read a numeric property from style or root.
  double? numProp(String key) {
    final v = style[key] ?? _extra[key];
    if (v == null) return null;
    return (v as num).toDouble();
  }

  /// Parse a [RexaNode] from a raw JSON map.
  factory RexaNode.fromJson(Map<String, dynamic> json) {
    RexaNode? parseSlot(String key) {
      final v = json[key];
      if (v == null || v is! Map<String, dynamic>) return null;
      return RexaNode.fromJson(v);
    }

    List<RexaNode> parseList(String key) {
      final v = json[key];
      if (v == null || v is! List) return const [];
      return v
          .whereType<Map<String, dynamic>>()
          .map(RexaNode.fromJson)
          .toList(growable: false);
    }

    // Collect known keys so the rest go into _extra
    const knownKeys = {
      'type', 'data', 'style', 'children', 'actions',
      'appBar', 'body', 'child', 'title', 'leading',
      'floatingActionButton', 'bottomNavigation', 'trailing',
    };

    final extra = <String, dynamic>{
      for (final e in json.entries)
        if (!knownKeys.contains(e.key)) e.key: e.value,
    };

    return RexaNode(
      type: (json['type'] as String? ?? '').toLowerCase(),
      data: json['data'] as String?,
      style: (json['style'] as Map<String, dynamic>?) ?? {},
      children: parseList('children'),
      appBar: parseSlot('appBar'),
      body: parseSlot('body'),
      child: parseSlot('child'),
      title: parseSlot('title'),
      leading: parseSlot('leading'),
      floatingActionButton: parseSlot('floatingActionButton'),
      bottomNavigation: parseSlot('bottomNavigation'),
      trailing: parseSlot('trailing'),
      actions: parseList('actions'),
      extra: extra,
    );
  }

  @override
  String toString() => 'RexaNode(type: $type)';
}

/// Top-level API response from GET /api/v1/screens/[screenName].
class RexaLayoutResponse {
  final bool success;
  final String screen;
  final int version;
  final DateTime? publishedAt;
  final RexaNode? layout;
  final String? error;

  const RexaLayoutResponse({
    required this.success,
    this.screen = '',
    this.version = 0,
    this.publishedAt,
    this.layout,
    this.error,
  });

  factory RexaLayoutResponse.fromJson(Map<String, dynamic> json) {
    RexaNode? layout;
    final rawLayout = json['layout'];
    if (rawLayout is Map<String, dynamic>) {
      layout = RexaNode.fromJson(rawLayout);
    }
    return RexaLayoutResponse(
      success: json['success'] == true,
      screen: json['screen'] as String? ?? '',
      version: (json['version'] as num?)?.toInt() ?? 0,
      publishedAt: json['publishedAt'] != null
          ? DateTime.tryParse(json['publishedAt'] as String)
          : null,
      layout: layout,
      error: json['error'] as String?,
    );
  }
}
