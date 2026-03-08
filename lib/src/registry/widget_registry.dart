import 'package:flutter/material.dart';
import '../models/sdui_layout.dart';
import '../widgets/sdui_widgets.dart';

/// Function signature for a custom widget builder.
typedef SduiWidgetBuilder = Widget Function(
  BuildContext context,
  SduiNode node,
  WidgetRegistry registry,
);

/// Callback invoked when a REXA widget fires an action (button tap, list tile tap, etc.).
/// [action] is the action type string (e.g. "navigate", "custom").
/// [params] are optional key/value params from the node JSON.
typedef SduiActionCallback = void Function(
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
  final Map<String, SduiWidgetBuilder> _builders = {};

  /// Optional global action handler for interactive widgets (buttons, tiles, etc.).
  SduiActionCallback? onAction;

  WidgetRegistry({this.onAction});

  /// Fire an action — calls [onAction] if set.
  void fireAction(String action, Map<String, dynamic> params) {
    onAction?.call(action, params);
  }

  /// Create a registry pre-populated with all built-in REXA widgets.
  factory WidgetRegistry.defaults({SduiActionCallback? onAction}) {
    final r = WidgetRegistry(onAction: onAction);
    r._registerBuiltIns();
    return r;
  }

  void _registerBuiltIns() {
    // ── Layout ──────────────────────────────────────────────────────────
    register('scaffold', (c, n, r) => SduiScaffoldWidget(node: n, registry: r));
    register('container', (c, n, r) => SduiContainerWidget(node: n, registry: r));
    register('column', (c, n, r) => SduiColumnWidget(node: n, registry: r));
    register('row', (c, n, r) => SduiRowWidget(node: n, registry: r));
    register('padding', (c, n, r) => SduiPaddingWidget(node: n, registry: r));
    register('center', (c, n, r) => SduiCenterWidget(node: n, registry: r));
    register('expanded', (c, n, r) => SduiExpandedWidget(node: n, registry: r));
    register('spacer', (_, n, __) => SduiSpacerWidget(node: n));
    register('sized_box', (c, n, r) => SduiSizedBoxWidget(node: n, registry: r));
    register('sizedbox', (c, n, r) => SduiSizedBoxWidget(node: n, registry: r));

    // ── Navigation ──────────────────────────────────────────────────────
    register('app_bar', (c, n, r) => SduiAppBarWidget(node: n, registry: r));
    register('appbar', (c, n, r) => SduiAppBarWidget(node: n, registry: r));

    // ── Display ─────────────────────────────────────────────────────────
    register('text', (_, n, __) => SduiTextWidget(node: n));
    register('icon', (_, n, __) => SduiIconWidget(node: n));
    register('divider', (_, n, __) => SduiDividerWidget(node: n));
    register('image', (_, n, __) => SduiImageWidget(node: n));
    register('image_network', (_, n, __) => SduiImageWidget(node: n));
    register('image_asset', (_, n, __) => SduiImageWidget(node: n));
    register('network_image', (_, n, __) => SduiImageWidget(node: n));

    // ── Input ───────────────────────────────────────────────────────────
    register('button', (c, n, r) => SduiButtonWidget(node: n, registry: r));
    register('elevated_button', (c, n, r) => SduiButtonWidget(node: n, registry: r));
    register('text_button', (c, n, r) => SduiButtonWidget(node: n, registry: r));
    register('outlined_button', (c, n, r) => SduiButtonWidget(node: n, registry: r));
    register('icon_button', (c, n, r) => SduiButtonWidget(node: n, registry: r));
    register('floating_action_button', (c, n, r) => SduiButtonWidget(node: n, registry: r));

    // ── Scroll / Lists ───────────────────────────────────────────────────
    register('single_child_scroll_view', (c, n, r) => SduiScrollViewWidget(node: n, registry: r));
    register('list_view', (c, n, r) => SduiListViewWidget(node: n, registry: r));
    register('listview', (c, n, r) => SduiListViewWidget(node: n, registry: r));
    register('list_tile', (c, n, r) => SduiListTileWidget(node: n, registry: r));
    register('listtile', (c, n, r) => SduiListTileWidget(node: n, registry: r));

    // ── Composite ────────────────────────────────────────────────────────
    register('card', (c, n, r) => SduiCardWidget(node: n, registry: r));

    // ── Safety / Layout extras ───────────────────────────────────────────
    register('safe_area', (c, n, r) => SduiSafeAreaWidget(node: n, registry: r));
    register('safearea', (c, n, r) => SduiSafeAreaWidget(node: n, registry: r));
    register('stack', (c, n, r) => SduiStackWidget(node: n, registry: r));
    register('flexible', (c, n, r) => SduiFlexibleWidget(node: n, registry: r));
    register('wrap', (c, n, r) => SduiWrapWidget(node: n, registry: r));
    register('gesture_detector', (c, n, r) => SduiGestureDetectorWidget(node: n, registry: r));
    register('gesturedetector', (c, n, r) => SduiGestureDetectorWidget(node: n, registry: r));
  }

  /// Register (or override) a widget builder for [type].
  void register(String type, SduiWidgetBuilder builder) {
    _builders[type.toLowerCase()] = builder;
  }

  /// Build a Flutter [Widget] from a [SduiNode].
  /// Falls back to [SduiUnknownWidget] for unregistered types.
  Widget build(BuildContext context, SduiNode node) {
    final builder = _builders[node.type];
    if (builder == null) {
      return SduiUnknownWidget(type: node.type);
    }
    return builder(context, node, this);
  }
}
