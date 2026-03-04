import 'package:flutter/material.dart';
import '../models/rexa_layout.dart';
import '../widgets/rexa_widgets.dart';

/// Function signature for a custom widget builder.
typedef RexaWidgetBuilder = Widget Function(
  BuildContext context,
  RexaNode node,
  WidgetRegistry registry,
);

/// Callback invoked when a REXA widget fires an action (button tap, list tile tap, etc.).
/// [action] is the action type string (e.g. "navigate", "custom").
/// [params] are optional key/value params from the node JSON.
typedef RexaActionCallback = void Function(
  String action,
  Map<String, dynamic> params,
);

/// Registry that maps widget type strings to builder functions.
///
/// Register custom widgets with [register]. Built-in widgets are pre-registered.
///
/// Usage:
/// ```dart
/// final registry = WidgetRegistry.defaults();
/// registry.register('my_widget', (ctx, node, reg) => MyWidget(node: node));
///
/// final widget = registry.build(context, node);
/// ```
class WidgetRegistry {
  final Map<String, RexaWidgetBuilder> _builders = {};

  /// Optional global action handler for interactive widgets (buttons, tiles, etc.).
  RexaActionCallback? onAction;

  WidgetRegistry({this.onAction});

  /// Fire an action — calls [onAction] if set.
  void fireAction(String action, Map<String, dynamic> params) {
    onAction?.call(action, params);
  }

  /// Create a registry pre-populated with all built-in REXA widgets.
  factory WidgetRegistry.defaults({RexaActionCallback? onAction}) {
    final r = WidgetRegistry(onAction: onAction);
    r._registerBuiltIns();
    return r;
  }

  void _registerBuiltIns() {
    // ── Layout ──────────────────────────────────────────────────────────
    register('scaffold', (c, n, r) => RexaScaffoldWidget(node: n, registry: r));
    register('container', (c, n, r) => RexaContainerWidget(node: n, registry: r));
    register('column', (c, n, r) => RexaColumnWidget(node: n, registry: r));
    register('row', (c, n, r) => RexaRowWidget(node: n, registry: r));
    register('padding', (c, n, r) => RexaPaddingWidget(node: n, registry: r));
    register('center', (c, n, r) => RexaCenterWidget(node: n, registry: r));
    register('expanded', (c, n, r) => RexaExpandedWidget(node: n, registry: r));
    register('spacer', (_, n, __) => RexaSpacerWidget(node: n));
    register('sized_box', (c, n, r) => RexaSizedBoxWidget(node: n, registry: r));
    register('sizedbox', (c, n, r) => RexaSizedBoxWidget(node: n, registry: r));

    // ── Navigation ──────────────────────────────────────────────────────
    register('app_bar', (c, n, r) => RexaAppBarWidget(node: n, registry: r));
    register('appbar', (c, n, r) => RexaAppBarWidget(node: n, registry: r));

    // ── Display ─────────────────────────────────────────────────────────
    register('text', (_, n, __) => RexaTextWidget(node: n));
    register('icon', (_, n, __) => RexaIconWidget(node: n));
    register('divider', (_, n, __) => RexaDividerWidget(node: n));
    register('image', (_, n, __) => RexaImageWidget(node: n));
    register('image_network', (_, n, __) => RexaImageWidget(node: n));
    register('image_asset', (_, n, __) => RexaImageWidget(node: n));
    register('network_image', (_, n, __) => RexaImageWidget(node: n));

    // ── Input ───────────────────────────────────────────────────────────
    register('button', (c, n, r) => RexaButtonWidget(node: n, registry: r));
    register('elevated_button', (c, n, r) => RexaButtonWidget(node: n, registry: r));
    register('text_button', (c, n, r) => RexaButtonWidget(node: n, registry: r));
    register('outlined_button', (c, n, r) => RexaButtonWidget(node: n, registry: r));
    register('icon_button', (c, n, r) => RexaButtonWidget(node: n, registry: r));
    register('floating_action_button', (c, n, r) => RexaButtonWidget(node: n, registry: r));

    // ── Scroll / Lists ───────────────────────────────────────────────────
    register('single_child_scroll_view', (c, n, r) => RexaScrollViewWidget(node: n, registry: r));
    register('list_view', (c, n, r) => RexaListViewWidget(node: n, registry: r));
    register('listview', (c, n, r) => RexaListViewWidget(node: n, registry: r));
    register('list_tile', (c, n, r) => RexaListTileWidget(node: n, registry: r));
    register('listtile', (c, n, r) => RexaListTileWidget(node: n, registry: r));

    // ── Composite ────────────────────────────────────────────────────────
    register('card', (c, n, r) => RexaCardWidget(node: n, registry: r));

    // ── Safety / Layout extras ───────────────────────────────────────────
    register('safe_area', (c, n, r) => RexaSafeAreaWidget(node: n, registry: r));
    register('safearea', (c, n, r) => RexaSafeAreaWidget(node: n, registry: r));
    register('stack', (c, n, r) => RexaStackWidget(node: n, registry: r));
    register('flexible', (c, n, r) => RexaFlexibleWidget(node: n, registry: r));
    register('wrap', (c, n, r) => RexaWrapWidget(node: n, registry: r));
    register('gesture_detector', (c, n, r) => RexaGestureDetectorWidget(node: n, registry: r));
    register('gesturedetector', (c, n, r) => RexaGestureDetectorWidget(node: n, registry: r));
  }

  /// Register (or override) a widget builder for [type].
  void register(String type, RexaWidgetBuilder builder) {
    _builders[type.toLowerCase()] = builder;
  }

  /// Build a Flutter [Widget] from a [RexaNode].
  /// Falls back to [RexaUnknownWidget] for unregistered types.
  Widget build(BuildContext context, RexaNode node) {
    final builder = _builders[node.type];
    if (builder == null) {
      return RexaUnknownWidget(type: node.type);
    }
    return builder(context, node, this);
  }
}
