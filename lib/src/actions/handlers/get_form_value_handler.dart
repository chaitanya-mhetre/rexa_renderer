import 'dart:async';
import 'package:flutter/widgets.dart';
import '../sdui_action.dart';
import '../../form/sdui_form_state.dart';

/// Action handler for `getFormValue`.
///
/// Reads the current value for `action.props['id']` from the nearest
/// [SduiFormScope] ancestor.  Returns `null` when:
/// - the `id` prop is missing, or
/// - there is no [SduiFormScope] in the tree.
FutureOr<dynamic> getFormValueHandler(BuildContext ctx, SduiAction action) {
  final id = action.props['id'] as String?;
  if (id == null) return null;
  final form = SduiFormScope.of(ctx);
  return form?.getValue(id);
}
