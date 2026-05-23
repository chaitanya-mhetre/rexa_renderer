/// SDUI Renderer — Flutter SDK for Server-Driven UI
///
/// Fetches published layout JSON from the SDUI backend and renders native
/// Flutter widget trees at runtime — no app release required.
///
/// Quick start:
/// ```dart
/// import 'package:sdui_renderer/sdui_renderer.dart';
///
/// // Initialize once at app start
/// await Sdui.initialize(apiKey: 'sdui_your_project_api_key');
/// Sdui.setContext({'user': {'name': 'Jane'}});
///
/// // Full screen or embedded section — same widget
/// SduiScreen(routeName: 'home')
/// SduiScreen(routeName: 'home_banner', cacheStrategy: SduiCacheStrategy.optimistic)
/// ```
library sdui_renderer;

// Public facade
export 'src/sdui.dart' show Sdui;

// Widget + companions
export 'src/sdui_screen.dart';
export 'src/sdui_controller.dart';
export 'src/sdui_error.dart';

// Cache
export 'src/cache/sdui_cache_strategy.dart';
export 'src/cache/sdui_cached_screen.dart';
export 'src/cache/sdui_cache_service.dart';

// Actions
export 'src/actions/sdui_action.dart';
export 'src/actions/sdui_action_registry.dart' show SduiActionHandler, SduiActionObserverCallback;

// Context
export 'src/context/sdui_context_store.dart' show SduiContextStore;

// Existing internals still public
export 'src/models/sdui_layout.dart';
export 'src/parser/sdui_parser.dart';
export 'src/registry/widget_registry.dart';
export 'src/theme/sdui_theme.dart';
export 'src/network/sdui_network_service.dart' show SduiNetworkService;
