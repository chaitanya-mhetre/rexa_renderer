import 'dart:async';
import 'package:flutter/widgets.dart';
import '../sdui_action.dart';

FutureOr<dynamic> delayHandler(BuildContext ctx, SduiAction action) async {
  final ms = action.props['milliseconds'] as int? ?? 0;
  await Future.delayed(Duration(milliseconds: ms));
  return null;
}
