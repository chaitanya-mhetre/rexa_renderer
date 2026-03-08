# sdui_renderer

Flutter SDK for **REXA** — the Server-Driven UI platform.

Render REXA layouts dynamically in your Flutter app without releasing a new app version.
The SDK fetches published layout JSON from the REXA backend, parses it, and builds a real Flutter widget tree.

---

## Features

- **Zero-config drop-in**: replace any screen with `SduiScreen(screenName: 'home')`
- **ETag-aware caching** — uses `If-None-Match` for conditional GETs; falls back to stale cache on network failure
- **30+ built-in widgets** — scaffold, app_bar, column, row, text, image, button, card, list_view, list_tile, divider, and more
- **Extensible registry** — register your own custom widgets in 1 line
- **Theme tokens** — light/dark design tokens with auto text-style resolution
- **Validated parser** — enforces max depth (20) and max nodes (500) with `SduiParseException`

---

## Installation

```yaml
# pubspec.yaml
dependencies:
  sdui_renderer:
    git:
      url: https://github.com/your-org/sdui
      path: flutter_sdk/sdui_renderer
```

Or once published to pub.dev:

```yaml
dependencies:
  sdui_renderer: ^0.1.0
```

---

## Quick Start

```dart
import 'package:sdui_renderer/sdui_renderer.dart';

// 1. Create a fetcher (do this once, e.g. in a provider/service)
final fetcher = SduiLayoutFetcher(
  baseUrl: 'https://your-sdui-instance.com',
  apiKey: 'rxa_your_project_api_key',  // from REXA Project Settings
);

// 2. Replace any screen with SduiScreen
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SduiScreen(
      fetcher: fetcher,
      screenName: 'home',   // matches the screen slug in the REXA builder
    );
  }
}
```

---

## API Reference

### `SduiLayoutFetcher`

```dart
SduiLayoutFetcher({
  required String baseUrl,  // your REXA backend URL
  required String apiKey,   // project API key
  Duration cacheTTL = const Duration(minutes: 5),
  bool staleWhileRevalidate = true,
})
```

| Method | Description |
|--------|-------------|
| `fetchScreen(screenName)` | Fetch + cache a screen layout |
| `clearCache(screenName)` | Remove cached layout for one screen |
| `clearAllCaches()` | Remove all cached layouts |
| `dispose()` | Close the HTTP client |

---

### `SduiScreen`

Drop-in screen widget that fetches and renders automatically.

```dart
SduiScreen(
  fetcher: fetcher,
  screenName: 'cart',
  tokens: SduiTokens.defaultDark(),       // optional: theme tokens
  registry: myCustomRegistry,              // optional: custom widget registry
  loadingWidget: MyLoadingSpinner(),       // optional
  errorBuilder: (err) => ErrorPage(err),  // optional
)
```

---

### `SduiRenderer`

Render a pre-parsed `SduiNode` directly (no network fetch).

```dart
final node = SduiParser.parseString(jsonString);
SduiRenderer(node: node)
```

---

### Custom Widgets

```dart
final registry = WidgetRegistry.defaults();

// Register your own widget builder
registry.register('promo_banner', (context, node, registry) {
  return PromoBanner(
    title: node.prop('title') as String?,
    imageUrl: node.prop('imageUrl') as String?,
  );
});

SduiScreen(fetcher: fetcher, screenName: 'home', registry: registry)
```

---

### Theme Tokens

```dart
// Light theme (default)
final tokens = SduiTokens.defaultLight();

// Dark theme
final tokens = SduiTokens.defaultDark();

// Custom tokens
final tokens = SduiTokens(
  primaryColor: Color(0xFF6366F1),
  onPrimary: Colors.white,
  scaffoldBackground: Colors.white,
  // ... other tokens
);

SduiScreen(fetcher: fetcher, screenName: 'home', tokens: tokens)
```

---

## Supported Widget Types

| Category | Types |
|----------|-------|
| **Layout** | `scaffold`, `container`, `column`, `row`, `padding`, `center`, `expanded`, `spacer`, `sized_box` |
| **Navigation** | `app_bar` |
| **Display** | `text`, `icon`, `image` / `image_network`, `divider` |
| **Input** | `button`, `elevated_button`, `text_button`, `outlined_button`, `icon_button`, `floating_action_button` |
| **Scroll/Lists** | `single_child_scroll_view`, `list_view`, `list_tile` |
| **Composite** | `card` |

Unknown types render as `⚠ Unknown widget: type_name` — easy to spot in development.

---

## Layout JSON Schema

The REXA JSON closely mirrors Flutter's widget tree. A typical screen looks like:

```json
{
  "type": "scaffold",
  "backgroundColor": "#FFFFFF",
  "appBar": {
    "type": "app_bar",
    "title": { "type": "text", "data": "My App" },
    "backgroundColor": "#6366F1",
    "foregroundColor": "#FFFFFF"
  },
  "body": {
    "type": "single_child_scroll_view",
    "child": {
      "type": "column",
      "children": [
        {
          "type": "image_network",
          "src": "https://example.com/banner.jpg",
          "height": 200,
          "fit": "cover"
        },
        {
          "type": "padding",
          "padding": 16,
          "child": {
            "type": "text",
            "data": "Welcome back!",
            "style": { "fontSize": 24, "fontWeight": "bold" }
          }
        },
        {
          "type": "button",
          "data": "Shop Now",
          "style": {
            "backgroundColor": "#6366F1",
            "borderRadius": 8
          }
        }
      ]
    }
  }
}
```

Publish this from the REXA dashboard and your app picks it up instantly — no release needed.

---

## Caching Strategy

1. On first fetch: download → cache in `SharedPreferences` with timestamp + ETag
2. On subsequent fetches within TTL: return cache immediately
3. After TTL expires: send `If-None-Match` header → `304 Not Modified` refreshes timestamp, or new content updates cache
4. On network error: return stale cache (if `staleWhileRevalidate: true`)

---

## Testing

```bash
flutter test
```

---

## Architecture

```
sdui_renderer/
├── lib/
│   ├── sdui_renderer.dart        # Public exports
│   └── src/
│       ├── models/               # SduiNode, SduiLayoutResponse
│       ├── fetcher/              # SduiLayoutFetcher (HTTP + cache)
│       ├── parser/               # SduiParser (validation + parsing)
│       ├── registry/             # WidgetRegistry (type → builder map)
│       ├── widgets/              # All built-in widget implementations
│       ├── theme/                # SduiTheme, SduiTokens
│       └── sdui_screen.dart      # SduiScreen, SduiRenderer
└── test/
    └── sdui_parser_test.dart
```
