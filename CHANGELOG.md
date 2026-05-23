# Changelog

## 0.2.0

### Added — Embedding & runtime
- `SduiScreen` — single widget for full-screen + embedded (Swiggy pattern)
- `Sdui` static facade with `initialize`, `setContext`, `updateContext`, `registerAction`, `onAnyAction`, `dispatch`
- `SduiContextStore` — observable, dot-path-accessible host state for `{{var}}` substitution
- `SduiActionRegistry` with override + observer hooks
- `SduiCacheStrategy` (networkFirst / cacheFirst / optimistic / cacheOnly / networkOnly)
- `SduiCacheService` SharedPreferences-backed
- `SduiNetworkService` Dio wrapper with `X-Sdui-*` header injection
- `SduiController` for pull-to-refresh and lifecycle events
- `SduiError` with node path for diagnostics

### Added — Actions
- `navigate` (8 navigation styles), `dialog`, `snackBar`, `setValue`, `multiAction`, `delay`, `none`
- `networkRequest` with nested-action body resolution
- `getFormValue` + `validateForm` with SduiFormScope coordination
- `showModalBottomSheet`

### Added — Widgets
- Layout: Stack, Positioned, Wrap, SafeArea + all existing
- Indicators: CircularProgressIndicator, LinearProgressIndicator
- Inputs: TextFormField with validators, Checkbox, Switch, Slider, Radio (form-aware)
- Display: Chip, Badge, Tooltip, Divider, Card
- 30+ widgets total

### Changed
- Package renamed from `rexa_renderer` to `sdui_renderer` (breaking)
- `SduiScreen` API replaced legacy `fetcher` / `screenName` constructor; use `routeName` + global `Sdui.initialize`

## 0.1.0

- Initial release as `rexa_renderer`
- Basic JSON-to-Flutter rendering
- Layout fetcher
- Caching via SharedPreferences
