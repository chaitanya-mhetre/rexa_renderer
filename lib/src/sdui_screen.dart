import 'package:flutter/material.dart';
import 'fetcher/layout_fetcher.dart';
import 'models/sdui_layout.dart';
import 'registry/widget_registry.dart';
import 'theme/sdui_theme.dart';

/// Drop-in widget that fetches + renders a REXA server-driven screen.
///
/// Usage:
/// ```dart
/// SduiScreen(
///   fetcher: myFetcher,
///   screenName: 'home',
/// )
/// ```
class SduiScreen extends StatefulWidget {
  final SduiLayoutFetcher fetcher;
  final String screenName;
  final WidgetRegistry? registry;
  final SduiTokens? tokens;

  /// Global action handler for interactive widgets (buttons, tiles, etc.).
  /// Called when a widget fires an action via [WidgetRegistry.fireAction].
  final SduiActionCallback? onAction;

  /// Widget shown while the layout is loading.
  final Widget? loadingWidget;

  /// Widget shown when the layout fails to load and no cache is available.
  final Widget Function(String error)? errorBuilder;

  /// If true, bypasses cache and fetches fresh data from server on init.
  final bool forceRefreshOnInit;

  const SduiScreen({
    super.key,
    required this.fetcher,
    required this.screenName,
    this.registry,
    this.tokens,
    this.onAction,
    this.loadingWidget,
    this.errorBuilder,
    this.forceRefreshOnInit = false,
  });

  @override
  State<SduiScreen> createState() => _SduiScreenState();
}

class _SduiScreenState extends State<SduiScreen> {
  late final WidgetRegistry _registry;
  SduiLayoutResponse? _response;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _registry = widget.registry ?? WidgetRegistry.defaults(onAction: widget.onAction);
    // If caller passed a registry, wire the action handler if not already set.
    if (widget.onAction != null && _registry.onAction == null) {
      _registry.onAction = widget.onAction;
    }
    _load(forceRefresh: widget.forceRefreshOnInit);
  }

  @override
  void didUpdateWidget(SduiScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.screenName != widget.screenName) {
      setState(() => _loading = true);
      _load();
    }
  }

  Future<void> _load({bool forceRefresh = false}) async {
    final response = await widget.fetcher.fetchScreen(widget.screenName, forceRefresh: forceRefresh);
    if (mounted) {
      setState(() {
        _response = response;
        _loading = false;
      });
    }
  }

  /// Public method to refresh the screen (bypasses cache)
  Future<void> refresh() async {
    if (mounted) {
      setState(() => _loading = true);
      await _load(forceRefresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens ?? SduiTokens.defaultLight();

    if (_loading) {
      return widget.loadingWidget ??
          Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: tokens.primaryColor,
              ),
            ),
          );
    }

    final res = _response;
    if (res == null || !res.success || res.layout == null) {
      final err = res?.error ?? 'Unknown error';
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(err);
      }
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_outlined, size: 48, color: Color(0xFF6B7280)),
                const SizedBox(height: 16),
                Text(
                  'Failed to load screen',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: tokens.defaultTextColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  err,
                  style: TextStyle(fontSize: 13, color: tokens.defaultTextColor.withValues(alpha: 0.6)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() => _loading = true);
                    _load();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tokens.primaryColor,
                    foregroundColor: tokens.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SduiTheme(
      tokens: tokens,
      child: _registry.build(context, res.layout!),
    );
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
