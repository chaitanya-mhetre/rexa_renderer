import 'package:flutter/widgets.dart';
import '../sdui_action.dart';
import '../sdui_action_registry.dart';
import '../../form/sdui_form_state.dart';

/// Returns an action handler for `validateForm`.
///
/// When dispatched it:
/// 1. Calls [SduiFormState.validateAll] on the nearest [SduiFormScope].
/// 2. Dispatches `isValid` branch on success, `isNotValid` branch on failure.
/// 3. Returns the boolean result of validation.
SduiActionHandler makeValidateFormHandler(SduiActionRegistry registry) {
  return (BuildContext ctx, SduiAction action) async {
    final form = SduiFormScope.of(ctx);
    final ok = form?.validateAll() ?? true;

    final branch = ok ? action.props['isValid'] : action.props['isNotValid'];
    if (branch is Map<String, dynamic>) {
      if (ctx.mounted) {
        await registry.dispatch(ctx, SduiAction.fromJson(branch));
      }
    }

    return ok;
  };
}
