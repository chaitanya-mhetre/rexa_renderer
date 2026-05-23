import 'dart:async';
import 'package:flutter/material.dart';
import '../sdui_action.dart';

FutureOr<dynamic> snackBarHandler(BuildContext ctx, SduiAction action) {
  final label = action.props['label'] as String? ?? '';
  final duration = action.props['durationMs'] as int? ?? 3000;
  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
    content: Text(label),
    duration: Duration(milliseconds: duration),
  ));
  return null;
}
