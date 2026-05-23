import 'dart:async';
import 'package:flutter/widgets.dart';
import '../sdui_action.dart';
import '../sdui_action_registry.dart';
import '../../context/sdui_context_store.dart';

SduiActionHandler makeSetValueHandler(SduiContextStore ctxStore, SduiActionRegistry registry) {
  return (BuildContext ctx, SduiAction action) async {
    final values = action.props['values'];
    if (values is Map<String, dynamic>) {
      ctxStore.update(values);
    } else if (values is List) {
      final patch = <String, dynamic>{};
      for (final item in values) {
        if (item is Map && item['key'] is String) {
          patch[item['key'] as String] = item['value'];
        }
      }
      ctxStore.update(patch);
    }
    final next = action.props['action'];
    if (next is Map<String, dynamic>) {
      return registry.dispatch(ctx, SduiAction.fromJson(next));
    }
    return null;
  };
}
