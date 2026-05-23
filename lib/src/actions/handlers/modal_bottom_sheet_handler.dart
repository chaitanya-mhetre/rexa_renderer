import 'dart:async';
import 'package:flutter/material.dart';
import '../sdui_action.dart';
import '../../sdui_screen.dart';

FutureOr<dynamic> modalBottomSheetHandler(BuildContext ctx, SduiAction action) {
  final routeName = action.props['routeName'] as String?;
  final widgetJson = action.props['widget'] as Map<String, dynamic>?;
  final title = action.props['title'] as String?;
  final message = action.props['message'] as String?;
  final isDismissible = (action.props['isDismissible'] as bool?) ?? true;
  final isScrollControlled = (action.props['isScrollControlled'] as bool?) ?? false;
  final showDragHandle = (action.props['showDragHandle'] as bool?) ?? false;
  final useSafeArea = (action.props['useSafeArea'] as bool?) ?? true;

  return showModalBottomSheet<dynamic>(
    context: ctx,
    isDismissible: isDismissible,
    isScrollControlled: isScrollControlled,
    showDragHandle: showDragHandle,
    useSafeArea: useSafeArea,
    builder: (_) {
      // Priority: routeName > widget json > title/message
      if (routeName != null) {
        return SduiScreen(routeName: routeName);
      }
      if (widgetJson != null) {
        // No direct Sdui.fromJson — for v1, render the simple form via
        // Padding + Column with title/message. Full widget-tree from JSON
        // would need parser access here; deferred.
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null) ...[
                Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
              ],
              Text(message ?? '(widget JSON not yet supported in modal sheet)'),
            ],
          ),
        );
      }
      // Simple title + message form
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
            ],
            if (message != null) Text(message),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
