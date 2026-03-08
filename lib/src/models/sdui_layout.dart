/// Core data model for a REXA layout node tree.
/// Mirrors the Flutter-compatible JSON schema produced by the REXA builder.
library sdui_models;

/// A single node in the REXA widget tree.
/// Closely mirrors Flutter's widget constructor parameters.
class SduiNode {
  /// Widget type, e.g. "scaffold", "text", "column".
  final String type;

  /// Text content — used by [text] widget.
  final String? data;

  /// Inline style overrides.
  final Map<String, dynamic> style;

  /// Direct child nodes (for multi-child widgets like column/row).
  final List<SduiNode> children;

  // ── Named slots (single-child) ──────────────────────────────────────────
  final SduiNode? appBar;
  final SduiNode? body;
  final SduiNode? child;
  final SduiNode? title;
  final SduiNode? leading;
  final SduiNode? floatingActionButton;
  final SduiNode? bottomNavigation;
  final SduiNode? trailing;

  /// Action widgets (icon buttons in AppBar, etc.)
  final List<SduiNode> actions;

  /// Extra properties not modelled above — accessed via [prop].
  final Map<String, dynamic> _extra;

  const SduiNode({
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

  /// Parse a [SduiNode] from a raw JSON map.
  factory SduiNode.fromJson(Map<String, dynamic> json) {
    SduiNode? parseSlot(String key) {
      final v = json[key];
      if (v == null || v is! Map<String, dynamic>) return null;
      return SduiNode.fromJson(v);
    }

    List<SduiNode> parseList(String key) {
      final v = json[key];
      if (v == null || v is! List) return const [];
      return v
          .whereType<Map<String, dynamic>>()
          .map(SduiNode.fromJson)
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

    return SduiNode(
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
  String toString() => 'SduiNode(type: $type)';
}

/// Top-level API response from GET /api/v1/screens/[screenName].
class SduiLayoutResponse {
  final bool success;
  final String screen;
  final int version;
  final DateTime? publishedAt;
  final SduiNode? layout;
  final String? error;

  const SduiLayoutResponse({
    required this.success,
    this.screen = '',
    this.version = 0,
    this.publishedAt,
    this.layout,
    this.error,
  });

  factory SduiLayoutResponse.fromJson(Map<String, dynamic> json) {
    SduiNode? layout;
    final rawLayout = json['layout'];
    if (rawLayout is Map<String, dynamic>) {
      layout = SduiNode.fromJson(rawLayout);
    }
    return SduiLayoutResponse(
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
