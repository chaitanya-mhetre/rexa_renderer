# sdui_renderer

[![pub package](https://img.shields.io/pub/v/sdui_renderer.svg)](https://pub.dev/packages/sdui_renderer)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Server-driven UI for Flutter. Fetch production-grade widget JSON from your backend, render native widgets — no app store release for UI changes.

## Features

- One widget — full screen or embedded section, same primitive
- Built-in HTTP networking with auth header injection
- Five cache strategies (networkFirst / cacheFirst / optimistic / cacheOnly / networkOnly)
- Live observable host context — `{{user.name}}` substitutions update in place
- Action registry with override + observer hooks — extend with custom actions
- Forms with declarative validation (required, minLength, pattern, email, ...)
- `networkRequest` action with nested action resolution — submit forms with zero client code
- 30+ built-in widgets covering layout, forms, indicators, navigation chrome
- Server-side schema validation + graceful render-error fallback

## Installation

```yaml
dependencies:
  sdui_renderer: ^0.2.0
```

## Quick start

```dart
import 'package:flutter/material.dart';
import 'package:sdui_renderer/sdui_renderer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Sdui.initialize(apiKey: 'sdui_your_api_key');
  Sdui.setContext({'user': {'name': 'Jane'}});
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        home: const SduiScreen(routeName: 'home'),
      );
}
```

## Embed inside native screens

```dart
Scaffold(
  appBar: AppBar(title: const Text('Home')),
  body: Column(children: [
    const NativeSearchBar(),
    const SduiScreen(
      routeName: 'home_banner',
      cacheStrategy: SduiCacheStrategy.optimistic,
    ),
    Expanded(child: NativeRestaurantList()),
  ]),
)
```

## Variables and observable context

```dart
Sdui.setContext({'user': {'name': 'Jane'}, 'cart': {'itemCount': 2}});
```

In JSON:

```json
{ "type": "text", "data": "Hi {{user.name}}, you have {{cart.itemCount}} items." }
```

When you update context, every SduiScreen referencing the changed keys re-renders.

## Custom actions

```dart
Sdui.registerAction('addToCart', (ctx, action) async {
  await context.read<CartBloc>().add(action.props['productId']);
});
```

JSON:

```json
{ "type": "elevatedButton",
  "child": {"type": "text", "data": "Add"},
  "onPressed": {"actionType": "addToCart", "productId": "p42"} }
```

## Forms with declarative validation

```json
{ "type": "form",
  "child": { "type": "column", "children": [
    { "type": "textFormField", "id": "email",
      "validatorRules": [
        {"type": "required"},
        {"type": "email"}
      ] },
    { "type": "elevatedButton",
      "child": {"type": "text", "data": "Submit"},
      "onPressed": {
        "actionType": "validateForm",
        "isValid": {
          "actionType": "networkRequest",
          "url": "https://api.example.com/login",
          "method": "post",
          "body": {
            "email": {"actionType": "getFormValue", "id": "email"}
          },
          "results": [
            {"statusCode": 200, "action": {"actionType": "navigate", "routeName": "/home"}}
          ]
        },
        "isNotValid": {"actionType": "snackBar", "label": "Fix errors"}
      } } ] } }
```

End-to-end form submission in pure JSON.

## Cache strategies

| Strategy | Behaviour |
|---|---|
| `networkFirst` (default) | Hit network. On failure, fall back to cache. |
| `cacheFirst` | Use cache if fresh; otherwise fetch + cache. |
| `optimistic` | Show cache immediately, refresh in background. |
| `cacheOnly` | Never fetch. |
| `networkOnly` | Never use cache. |

```dart
const SduiScreen(
  routeName: 'banner',
  cacheStrategy: SduiCacheStrategy.optimistic,
  maxAge: Duration(minutes: 5),
)
```

## Pull-to-refresh

```dart
final controller = SduiController();
RefreshIndicator(
  onRefresh: () => controller.refresh(),
  child: SduiScreen(routeName: 'home', controller: controller),
)
```

## Built-in widget catalog

Layout: `Container`, `Column`, `Row`, `Stack`, `Positioned`, `Wrap`, `Padding`, `Center`, `Align`, `Expanded`, `Flexible`, `SafeArea`, `SizedBox`, `Spacer`, `SingleChildScrollView`, `ListView`, `GridView`

Material chrome: `Scaffold`, `AppBar`, `Card`, `ListTile`, `Drawer`, `Divider`

Inputs: `TextField`, `TextFormField`, `Checkbox`, `Switch`, `Slider`, `Radio`

Buttons: `ElevatedButton`, `FilledButton`, `OutlinedButton`, `TextButton`, `IconButton`, `FloatingActionButton`

Display: `Text`, `Icon`, `Image`, `Chip`, `Badge`, `Tooltip`

Indicators: `CircularProgressIndicator`, `LinearProgressIndicator`

## Built-in actions

`navigate`, `dialog`, `snackBar`, `showModalBottomSheet`, `setValue`, `multiAction`, `delay`, `networkRequest`, `getFormValue`, `validateForm`, `none`

## Documentation

See [docs.sdui.app](https://docs.sdui.app) for full schema reference and architectural overview.

## License

MIT
