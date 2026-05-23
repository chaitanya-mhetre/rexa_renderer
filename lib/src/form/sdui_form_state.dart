import 'package:flutter/material.dart';

/// A validator function: given the current field value, returns an error
/// string or null (no error).
typedef SduiValidator = String? Function(dynamic value);

// ═══════════════════════════════════════════════════════════════════════════
//  Validator builder
// ═══════════════════════════════════════════════════════════════════════════

/// Convert a list of JSON rule objects into a list of [SduiValidator]s.
///
/// Supported rule types: required, minLength, maxLength, pattern, email.
/// Each rule may carry an optional `errorMessage` to override the default.
List<SduiValidator> buildValidators(List<dynamic>? rules) {
  if (rules == null) return [];
  final out = <SduiValidator>[];
  for (final r in rules) {
    if (r is! Map) continue;
    final type = r['type'] as String?;
    final msg = r['errorMessage'] as String?;
    switch (type) {
      case 'required':
        out.add((v) {
          if (v == null) return msg ?? 'Required';
          if (v is String && v.isEmpty) return msg ?? 'Required';
          return null;
        });
        break;
      case 'minLength':
        final n = (r['value'] as num?)?.toInt() ?? 0;
        out.add((v) {
          if (v is String && v.length < n) return msg ?? 'Min $n characters';
          return null;
        });
        break;
      case 'maxLength':
        final n = (r['value'] as num?)?.toInt() ?? 0;
        out.add((v) {
          if (v is String && v.length > n) return msg ?? 'Max $n characters';
          return null;
        });
        break;
      case 'pattern':
        final p = r['pattern'] as String?;
        if (p == null) break;
        final regex = RegExp(p);
        out.add((v) {
          if (v is String && !regex.hasMatch(v)) return msg ?? 'Invalid format';
          return null;
        });
        break;
      case 'email':
        final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
        out.add((v) {
          if (v is String && v.isNotEmpty && !emailRegex.hasMatch(v)) {
            return msg ?? 'Invalid email';
          }
          return null;
        });
        break;
      default:
        break;
    }
  }
  return out;
}

// ═══════════════════════════════════════════════════════════════════════════
//  SduiFormState
// ═══════════════════════════════════════════════════════════════════════════

/// Holds per-form state: field values, validators, and current errors.
///
/// Exposed to descendant widgets via [SduiFormScope].
class SduiFormState {
  /// Field id → current value (set by [setValue]).
  final Map<String, dynamic> values = {};

  /// Field id → validator chain (registered by [registerField]).
  final Map<String, List<SduiValidator>> validators = {};

  /// Field id → most recent validation error (null = no error).
  final Map<String, String?> errors = {};

  final List<VoidCallback> _listeners = [];

  void addListener(VoidCallback cb) => _listeners.add(cb);
  void removeListener(VoidCallback cb) => _listeners.remove(cb);
  void _notify() {
    for (final l in List.of(_listeners)) {
      l();
    }
  }

  /// Register [id] with its validator chain.  Re-registering replaces the chain.
  void registerField(String id, List<SduiValidator> v) {
    validators[id] = v;
  }

  /// Remove a field completely (called on widget dispose).
  void unregisterField(String id) {
    validators.remove(id);
    values.remove(id);
    errors.remove(id);
  }

  /// Update the current value for [id].  Clears any displayed error so the
  /// user gets instant feedback that the field is now being edited.
  void setValue(String id, dynamic value) {
    values[id] = value;
    if (errors[id] != null) {
      errors[id] = null;
      _notify();
    }
  }

  /// Return the current value for [id], or null if not yet set.
  dynamic getValue(String id) => values[id];

  /// Run every registered validator chain; populate [errors] and notify
  /// listeners.  Returns `true` only when every field is valid.
  bool validateAll() {
    var ok = true;
    errors.clear();
    for (final entry in validators.entries) {
      final id = entry.key;
      final chain = entry.value;
      final value = values[id];
      for (final v in chain) {
        final err = v(value);
        if (err != null) {
          errors[id] = err;
          ok = false;
          break;
        }
      }
    }
    _notify();
    return ok;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  SduiFormScope — InheritedWidget
// ═══════════════════════════════════════════════════════════════════════════

/// Makes a [SduiFormState] available to all descendants.
class SduiFormScope extends InheritedWidget {
  final SduiFormState state;

  const SduiFormScope({
    super.key,
    required this.state,
    required super.child,
  });

  /// Depend on the nearest [SduiFormScope].  Returns null if none found.
  static SduiFormState? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<SduiFormScope>()
        ?.state;
  }

  /// Look up without creating a dependency.
  static SduiFormState? maybeOf(BuildContext context) {
    final el =
        context.getElementForInheritedWidgetOfExactType<SduiFormScope>();
    if (el == null) return null;
    return (el.widget as SduiFormScope).state;
  }

  @override
  bool updateShouldNotify(SduiFormScope old) => state != old.state;
}

// ═══════════════════════════════════════════════════════════════════════════
//  SduiFormWidget — StatefulWidget that owns the state
// ═══════════════════════════════════════════════════════════════════════════

/// Wraps any subtree that needs form state.  Manages [SduiFormState] lifetime
/// and re-renders whenever the state notifies (i.e. after validation).
class SduiFormWidget extends StatefulWidget {
  final Widget child;

  const SduiFormWidget({super.key, required this.child});

  @override
  State<SduiFormWidget> createState() => _SduiFormWidgetState();
}

class _SduiFormWidgetState extends State<SduiFormWidget> {
  late final SduiFormState _state;

  @override
  void initState() {
    super.initState();
    _state = SduiFormState();
    _state.addListener(_rerender);
  }

  void _rerender() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _state.removeListener(_rerender);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SduiFormScope(state: _state, child: widget.child);
  }
}
