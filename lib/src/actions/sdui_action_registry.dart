import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'sdui_action.dart';

typedef SduiActionHandler = FutureOr<dynamic> Function(BuildContext, SduiAction);
typedef SduiActionObserverCallback = void Function(SduiAction);

class SduiActionRegistry {
  final Map<String, SduiActionHandler> _handlers = {};
  final Set<SduiActionObserverCallback> _observers = {};

  bool register(String actionType, SduiActionHandler handler, {bool override = false}) {
    if (_handlers.containsKey(actionType) && !override) {
      debugPrint('SduiActionRegistry: handler for "$actionType" already registered. Pass override:true to replace.');
      return false;
    }
    _handlers[actionType] = handler;
    return true;
  }

  void unregister(String actionType) => _handlers.remove(actionType);

  SduiActionHandler? get(String actionType) => _handlers[actionType];

  void onAnyAction(SduiActionObserverCallback cb) => _observers.add(cb);
  void offAnyAction(SduiActionObserverCallback cb) => _observers.remove(cb);

  FutureOr<dynamic> dispatch(BuildContext ctx, SduiAction action) {
    for (final obs in _observers) {
      try {
        obs(action);
      } catch (e, s) {
        debugPrint('SduiActionRegistry observer threw: $e\n$s');
      }
    }
    final handler = _handlers[action.actionType];
    if (handler == null) {
      debugPrint('SduiActionRegistry: no handler for "${action.actionType}". Did you forget to register it?');
      return null;
    }
    return handler(ctx, action);
  }
}
