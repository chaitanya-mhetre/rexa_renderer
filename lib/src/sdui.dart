import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'actions/sdui_action.dart';
import 'actions/sdui_action_registry.dart';
import 'actions/handlers/navigate_handler.dart';
import 'actions/handlers/snackbar_handler.dart';
import 'actions/handlers/dialog_handler.dart';
import 'actions/handlers/modal_bottom_sheet_handler.dart';
import 'actions/handlers/set_value_handler.dart';
import 'actions/handlers/multi_action_handler.dart';
import 'actions/handlers/delay_handler.dart';
import 'actions/handlers/none_handler.dart';
import 'actions/handlers/network_request_handler.dart';
import 'actions/handlers/get_form_value_handler.dart';
import 'actions/handlers/validate_form_handler.dart';
import 'cache/sdui_cache_service.dart';
import 'cache/sdui_cache_strategy.dart';
import 'context/sdui_context_store.dart';
import 'network/sdui_network_service.dart';

class Sdui {
  static bool _initialized = false;
  static late SduiContextStore _contextStore;
  static late SduiActionRegistry _registry;
  static SduiCacheStrategy _defaultStrategy = SduiCacheStrategy.networkFirst;
  static Duration? _defaultMaxAge;

  static SduiContextStore get contextStore => _contextStore;
  static SduiActionRegistry get registry => _registry;
  static SduiCacheStrategy get defaultCacheStrategy => _defaultStrategy;
  static Duration? get defaultMaxAge => _defaultMaxAge;

  static Future<void> initialize({
    required String apiKey,
    String? baseUrl,
    Dio? dio,
    SduiCacheStrategy defaultCacheStrategy = SduiCacheStrategy.networkFirst,
    Duration? defaultMaxAge,
    SduiActionObserverCallback? onAnyAction,
  }) async {
    if (_initialized) return;
    _contextStore = SduiContextStore();
    _registry = SduiActionRegistry();
    _defaultStrategy = defaultCacheStrategy;
    _defaultMaxAge = defaultMaxAge;

    SduiNetworkService.initialize(apiKey: apiKey, baseUrl: baseUrl, dio: dio);
    await SduiCacheService.initialize();

    _registry.register('navigate', navigateHandler);
    _registry.register('snackBar', snackBarHandler);
    _registry.register('dialog', dialogHandler);
    _registry.register('showModalBottomSheet', modalBottomSheetHandler);
    _registry.register('setValue', makeSetValueHandler(_contextStore, _registry));
    _registry.register('multiAction', makeMultiActionHandler(_registry));
    _registry.register('delay', delayHandler);
    _registry.register('none', noneHandler);
    _registry.register('networkRequest', makeNetworkRequestHandler(_registry));
    _registry.register('getFormValue', getFormValueHandler);
    _registry.register('validateForm', makeValidateFormHandler(_registry));

    if (onAnyAction != null) _registry.onAnyAction(onAnyAction);
    _initialized = true;
  }

  static void updateApiKey(String apiKey) => SduiNetworkService.updateApiKey(apiKey);

  static void setContext(Map<String, dynamic> ctx) => _contextStore.set(ctx);
  static void updateContext(Map<String, dynamic> patch) => _contextStore.update(patch);
  static dynamic getContextValue(String dotPath) => _contextStore.getValue(dotPath);

  static void registerAction(String actionType, SduiActionHandler handler, {bool override = false}) =>
      _registry.register(actionType, handler, override: override);
  static void unregisterAction(String actionType) => _registry.unregister(actionType);
  static void onAnyAction(SduiActionObserverCallback cb) => _registry.onAnyAction(cb);
  static FutureOr<dynamic> dispatch(BuildContext ctx, SduiAction action) =>
      _registry.dispatch(ctx, action);

  static Future<void> clearCache({String? routeName}) async {
    if (routeName == null) {
      await SduiCacheService.clear();
    } else {
      await SduiCacheService.remove(routeName);
    }
  }

  @visibleForTesting
  static void resetForTest() {
    _initialized = false;
  }
}
