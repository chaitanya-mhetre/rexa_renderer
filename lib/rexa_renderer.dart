/// REXA Renderer — Flutter SDK for Server-Driven UI
///
/// Fetches published layout JSON from the REXA backend and renders
/// Flutter widget trees dynamically — no app release required.
///
/// Quick start:
/// ```dart
/// import 'package:rexa_renderer/rexa_renderer.dart';
///
/// final fetcher = RexaLayoutFetcher(
///   baseUrl: 'https://your-rexa-instance.com',
///   apiKey: 'rxa_your_project_api_key',
/// );
///
/// // Drop-in widget (fetches + renders automatically)
/// RexaScreen(fetcher: fetcher, screenName: 'home')
///
/// // Or render a pre-parsed node
/// RexaRenderer(node: myNode)
/// ```
library rexa_renderer;

// Public models
export 'src/models/rexa_layout.dart';

// Fetcher
export 'src/fetcher/layout_fetcher.dart';

// Parser
export 'src/parser/rexa_parser.dart';

// Theme
export 'src/theme/rexa_theme.dart';

// Registry
export 'src/registry/widget_registry.dart';

// Top-level widgets
export 'src/rexa_screen.dart';
