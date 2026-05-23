import 'dart:async';
import 'package:flutter/material.dart';
import '../sdui_action.dart';

FutureOr<dynamic> dialogHandler(BuildContext ctx, SduiAction action) {
  final message = action.props['message'] as String? ?? '';
  final title = action.props['title'] as String?;
  final barrierDismissible = action.props['barrierDismissible'] as bool? ?? true;
  return showDialog<dynamic>(
    context: ctx,
    barrierDismissible: barrierDismissible,
    builder: (_) => AlertDialog(
      title: title == null ? null : Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
      ],
    ),
  );
}
