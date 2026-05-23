import 'dart:async';
import 'package:flutter/widgets.dart';
import '../sdui_action.dart';
import '../sdui_action_registry.dart';

SduiActionHandler makeMultiActionHandler(SduiActionRegistry registry) {
  return (BuildContext ctx, SduiAction action) async {
    final sync = action.props['sync'] as bool? ?? false;
    final actions = action.props['actions'];
    if (actions is! List) return null;
    if (sync) {
      for (final a in actions) {
        if (a is Map<String, dynamic>) {
          await registry.dispatch(ctx, SduiAction.fromJson(a));
        }
      }
    } else {
      final futures = <Future>[];
      for (final a in actions) {
        if (a is Map<String, dynamic>) {
          final r = registry.dispatch(ctx, SduiAction.fromJson(a));
          if (r is Future) futures.add(r);
        }
      }
      await Future.wait(futures);
    }
    return null;
  };
}
