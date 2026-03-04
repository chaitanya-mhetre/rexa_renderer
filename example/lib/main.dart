import 'package:flutter/material.dart';
import 'package:rexa_renderer/rexa_renderer.dart';

void main() {
  runApp(const RexaExampleApp());
}

class RexaExampleApp extends StatelessWidget {
  const RexaExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'REXA Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6366F1)),
        useMaterial3: true,
      ),
      home: const AppRoot(),
    );
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  late final RexaLayoutFetcher _fetcher;

  /// Create a custom registry and add your own widgets alongside built-ins
  late final WidgetRegistry _registry;

  @override
  void initState() {
    super.initState();

    _fetcher = RexaLayoutFetcher(
      // Replace with your REXA backend URL
      baseUrl: 'https://your-rexa-instance.com',
      // Replace with your project's API key (found in Project Settings)
      apiKey: 'rxa_your_project_api_key',
      cacheTTL: const Duration(minutes: 5),
      staleWhileRevalidate: true,
    );

    _registry = WidgetRegistry.defaults()
      // Register your own custom widgets:
      // ..register('promo_banner', (ctx, node, reg) => PromoBanner(node: node))
      ;
  }

  @override
  void dispose() {
    _fetcher.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /// [RexaScreen] is a drop-in replacement for a normal Screen widget.
    /// It fetches the server-driven layout and renders it — no rebuilds needed.
    return RexaScreen(
      fetcher: _fetcher,
      screenName: 'home', // matches screen slug in the REXA builder

      // Optional: supply light/dark tokens
      tokens: MediaQuery.platformBrightnessOf(context) == Brightness.dark
          ? RexaTokens.defaultDark()
          : RexaTokens.defaultLight(),

      registry: _registry,

      // Optional: custom loading UI
      loadingWidget: const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),

      // Optional: custom error UI
      errorBuilder: (error) => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(error, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Demo: render a hardcoded RexaNode without network ─────────────────────

class RexaLocalDemo extends StatelessWidget {
  const RexaLocalDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final node = RexaNode.fromJson({
      "type": "scaffold",
      "appBar": {
        "type": "app_bar",
        "title": {"type": "text", "data": "REXA Demo"},
        "backgroundColor": "#6366F1",
        "foregroundColor": "#FFFFFF",
      },
      "body": {
        "type": "single_child_scroll_view",
        "child": {
          "type": "column",
          "children": [
            {
              "type": "padding",
              "padding": 16,
              "child": {
                "type": "card",
                "elevation": 2,
                "style": {"borderRadius": 12},
                "child": {
                  "type": "list_tile",
                  "title": "Server-Driven UI",
                  "subtitle": "Powered by REXA",
                  "leading": {
                    "type": "icon",
                    "name": "settings",
                    "color": "#6366F1"
                  },
                  "trailing": {
                    "type": "icon",
                    "name": "arrow_back",
                    "color": "#9CA3AF"
                  }
                }
              }
            },
            {
              "type": "padding",
              "padding": 16,
              "child": {
                "type": "button",
                "data": "Tap Me",
                "style": {"backgroundColor": "#6366F1", "borderRadius": 8}
              }
            },
            {"type": "divider"},
            {
              "type": "image_network",
              "src": "https://picsum.photos/seed/rexa/400/200",
              "height": 200,
              "style": {"borderRadius": 12},
              "fit": "cover"
            }
          ]
        }
      }
    });

    return RexaRenderer(node: node);
  }
}
