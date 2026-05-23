import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'actions/sdui_action.dart';
import 'cache/sdui_cache_strategy.dart';
import 'cache/sdui_cache_service.dart';
import 'context/sdui_context_store.dart';
import 'models/sdui_layout.dart';
import 'network/sdui_network_service.dart';
import 'parser/sdui_parser.dart';
import 'registry/widget_registry.dart';
import 'sdui_controller.dart';
import 'sdui_error.dart';
import 'sdui.dart';
import 'theme/sdui_theme.dart';
import 'utils/variable_resolver.dart';

/// A StatefulWidget that fetches and renders a server-driven UI screen
/// identified by [routeName].
///
/// Uses the global [Sdui] facade for caching, networking, context, and
/// action dispatch — no per-instance fetcher required.
///
/// Example:
/// ```dart
/// SduiScreen(
///   routeName: 'home',
///   cacheStrategy: SduiCacheStrategy.cacheFirst,
///   loadingBuilder: (_) => const CircularProgressIndicator(),
/// )
/// ```
class SduiScreen extends StatefulWidget {
  /// The route/screen name used to look up the layout on the server and
  /// in the local cache.
  final String routeName;

  /// Override the global [Sdui.defaultCacheStrategy] for this screen.
  final SduiCacheStrategy? cacheStrategy;

  /// Override the global [Sdui.defaultMaxAge] for this screen's cache
  /// freshness check.
  final Duration? maxAge;

  /// Widget shown while the layout is being fetched.
  /// Defaults to [SizedBox.shrink] when omitted.
  final WidgetBuilder? loadingBuilder;

  /// Widget shown when the layout fails to load and no cache is available.
  /// Receives the [SduiError] describing the failure.
  final Widget Function(BuildContext, SduiError)? errorBuilder;

  /// Widget shown when the layout loaded successfully but returned no content.
  final WidgetBuilder? emptyBuilder;

  /// Optional controller for imperative refresh / clear-cache operations and
  /// lifecycle event listening.
  final SduiController? controller;

  /// Called when an interactive widget (button, list tile, etc.) fires an
  /// action that is not handled by the global [Sdui.registry].
  final void Function(dynamic)? onAction;

  /// Extra context values merged on top of [Sdui.contextStore] for variable
  /// resolution in this screen's layout only.
  final Map<String, dynamic>? contextOverrides;

  const SduiScreen({
    super.key,
    required this.routeName,
    this.cacheStrategy,
    this.maxAge,
    this.loadingBuilder,
    this.errorBuilder,
    this.emptyBuilder,
    this.controller,
    this.onAction,
    this.contextOverrides,
  });

  @override
  State<SduiScreen> createState() => _SduiScreenState();
}

class _SduiScreenState extends State<SduiScreen> {
  late SduiCacheStrategy _strategy;
  Duration? _maxAge;

  Map<String, dynamic>? _layoutJson;
  SduiError? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _strategy = widget.cacheStrategy ?? Sdui.defaultCacheStrategy;
    _maxAge = widget.maxAge ?? Sdui.defaultMaxAge;
    widget.controller?.attach(_refresh, _clearAndRefresh);
    Sdui.contextStore.addListener(_onContextChange);
    _fetch();
  }

  @override
  void didUpdateWidget(covariant SduiScreen old) {
    super.didUpdateWidget(old);
    final keyChanged = widget.routeName != old.routeName ||
        widget.cacheStrategy != old.cacheStrategy ||
        widget.maxAge != old.maxAge;
    if (keyChanged) {
      _strategy = widget.cacheStrategy ?? Sdui.defaultCacheStrategy;
      _maxAge = widget.maxAge ?? Sdui.defaultMaxAge;
      _fetch();
    }
  }

  @override
  void dispose() {
    Sdui.contextStore.removeListener(_onContextChange);
    widget.controller?.detach();
    super.dispose();
  }

  void _onContextChange() {
    if (mounted) setState(() {});
  }

  Future<void> _refresh() => _fetch(force: true);

  Future<void> _clearAndRefresh() async {
    await SduiCacheService.remove(widget.routeName);
    await _fetch(force: true);
  }

  Future<void> _fetch({bool force = false}) async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    widget.controller?.notifyFetchStart();
    try {
      final result = await _resolveByCacheStrategy(force: force);
      if (!mounted) return;
      setState(() {
        _layoutJson = result;
        _loading = false;
      });
      widget.controller?.notifyFetchDone();
    } catch (e, s) {
      if (!mounted) return;
      setState(() {
        _error = SduiError(message: e.toString(), stackTrace: s);
        _loading = false;
      });
      widget.controller?.notifyFetchError(e);
    }
  }

  Future<Map<String, dynamic>?> _resolveByCacheStrategy(
      {required bool force}) async {
    final cached = await SduiCacheService.get(widget.routeName);
    final cacheFresh = cached != null && cached.isFreshWithin(_maxAge);

    switch (_strategy) {
      case SduiCacheStrategy.networkOnly:
        return _fromNetworkAndCache();

      case SduiCacheStrategy.cacheOnly:
        if (cached == null) {
          throw StateError(
              'cacheOnly: no cached layout for "${widget.routeName}"');
        }
        return _decode(cached.json);

      case SduiCacheStrategy.networkFirst:
        try {
          return await _fromNetworkAndCache();
        } catch (e) {
          if (cached != null) return _decode(cached.json);
          rethrow;
        }

      case SduiCacheStrategy.cacheFirst:
        if (cached != null && cacheFresh && !force) {
          return _decode(cached.json);
        }
        try {
          return await _fromNetworkAndCache();
        } catch (e) {
          if (cached != null) return _decode(cached.json);
          rethrow;
        }

      case SduiCacheStrategy.optimistic:
        if (cached != null) {
          _fromNetworkAndCache().then((fresh) {
            if (mounted) setState(() => _layoutJson = fresh);
          }).catchError((_) {});
          return _decode(cached.json);
        }
        return _fromNetworkAndCache();
    }
  }

  Future<Map<String, dynamic>> _fromNetworkAndCache() async {
    final response = await SduiNetworkService.fetchScreen(widget.routeName);
    final Map<String, dynamic> data;
    if (response.data is Map<String, dynamic>) {
      data = response.data as Map<String, dynamic>;
    } else {
      data = jsonDecode(response.data.toString()) as Map<String, dynamic>;
    }
    final layout = (data['layout'] ?? data) as Map<String, dynamic>;
    final version = (data['version'] as num?)?.toInt() ?? 0;
    await SduiCacheService.put(widget.routeName, jsonEncode(layout), version);
    return layout;
  }

  Map<String, dynamic> _decode(String s) =>
      jsonDecode(s) as Map<String, dynamic>;

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return widget.loadingBuilder?.call(context) ?? const SizedBox.shrink();
    }
    if (_error != null) {
      return widget.errorBuilder?.call(context, _error!) ??
          const SizedBox.shrink();
    }
    if (_layoutJson == null) {
      return widget.emptyBuilder?.call(context) ?? const SizedBox.shrink();
    }
    final resolved = resolveVariablesInJson(
      _layoutJson!,
      _contextForResolve(),
    ) as Map<String, dynamic>;
    return _buildFromJson(context, resolved);
  }

  Widget _buildFromJson(BuildContext context, Map<String, dynamic> json) {
    try {
      final node = SduiParser.parseMap(json);
      // Wire registry action callbacks to Sdui.dispatch so custom-registered
      // action handlers (e.g. addToCart) are invoked when buttons fire.
      final registry = WidgetRegistry.defaults(
        onAction: (actionType, params) {
          Sdui.dispatch(
            context,
            SduiAction(actionType: actionType, props: params),
          );
        },
      );
      return registry.build(context, node);
    } catch (e, s) {
      return widget.errorBuilder?.call(
            context,
            SduiError(
              message: e.toString(),
              stackTrace: s,
              rawNode: json,
            ),
          ) ??
          const SizedBox.shrink();
    }
  }

  SduiContextStore _contextForResolve() {
    if (widget.contextOverrides == null) return Sdui.contextStore;
    final tmp = SduiContextStore()
      ..set({...Sdui.contextStore.snapshot, ...widget.contextOverrides!});
    return tmp;
  }
}

/// Stateless renderer — build a widget tree directly from a [SduiNode].
/// Use this if you've already fetched and parsed the layout.
class SduiRenderer extends StatelessWidget {
  final SduiNode node;
  final WidgetRegistry? registry;
  final SduiTokens? tokens;
  final SduiActionCallback? onAction;

  const SduiRenderer({
    super.key,
    required this.node,
    this.registry,
    this.tokens,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final reg = registry ?? WidgetRegistry.defaults(onAction: onAction);
    if (onAction != null && reg.onAction == null) reg.onAction = onAction;
    final tok = tokens ?? SduiTokens.defaultLight();
    return SduiTheme(tokens: tok, child: reg.build(context, node));
  }
}
