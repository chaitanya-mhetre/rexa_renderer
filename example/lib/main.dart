/// sdui_renderer example app
///
/// Demonstrates the full SDK surface in a single runnable file:
///   1. Initialization with a fixture-backed Dio adapter (works 100% offline).
///   2. Embedded SduiScreen inside a native Scaffold (Swiggy-style section).
///   3. Custom action registration (addToCart with SnackBar feedback).
///   4. Live context — the cart slider re-renders the banner in place.
///   5. Full-screen SDUI route with a declarative sign-in form.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:sdui_renderer/sdui_renderer.dart';

// ── 1. App entry-point ────────────────────────────────────────────────────────

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Wire a Dio adapter that intercepts every request and serves a bundled JSON
  // fixture instead of hitting the network.  The fixture file is chosen by the
  // last path segment of the request URL, e.g.
  //   GET /api/v1/screens/home_banner  →  assets/screens/home_banner.json
  final dio = Dio()..httpClientAdapter = _FixtureAdapter();

  // ── 2. Initialize the SDK once at app start ────────────────────────────────
  await Sdui.initialize(
    apiKey: 'demo_api_key',
    baseUrl: 'https://demo.local',
    dio: dio,
  );

  // ── 3. Seed context variables used for template interpolation ─────────────
  //       {{user.name}} and {{cart.itemCount}} are resolved at render time.
  Sdui.setContext({
    'user': {'name': 'Jane'},
    'cart': {'itemCount': 3},
  });

  // ── 4. Register a custom action handler ───────────────────────────────────
  //       The JSON button fires  {"actionType": "addToCart", "productId": "p42"}
  //       and this handler is invoked automatically by SduiScreen.
  Sdui.registerAction('addToCart', (ctx, action) {
    final productId = action.props['productId'] as String? ?? 'unknown';
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text('Added $productId to cart'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return null;
  });

  runApp(const DemoApp());
}

// ── Fixture Dio adapter ───────────────────────────────────────────────────────
//
// Implements [HttpClientAdapter] so it slots into Dio without any real HTTP.
// The route name is extracted from the last path segment of the request URL.

class _FixtureAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    // e.g. "https://demo.local/api/v1/screens/home_banner" → "home_banner"
    final name = options.path.split('/').last;
    final asset = 'assets/screens/$name.json';
    try {
      final json = await rootBundle.loadString(asset);
      return ResponseBody.fromString(
        json,
        200,
        headers: {
          'content-type': ['application/json'],
        },
      );
    } catch (_) {
      return ResponseBody.fromString(
        '{"error":"fixture not found: $name"}',
        404,
        headers: {
          'content-type': ['application/json'],
        },
      );
    }
  }

  @override
  void close({bool force = false}) {}
}

// ── Root app ──────────────────────────────────────────────────────────────────

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'sdui_renderer demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

// ── Home page ─────────────────────────────────────────────────────────────────
//
// StatefulWidget so the Slider can update Sdui.context and the banner
// re-renders immediately when cart.itemCount changes.

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double _cartCount = 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('sdui_renderer demo')),
      body: ListView(
        children: [
          // ── Section label ─────────────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Embedded SDUI section',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),

          // ── 5. Embedded SduiScreen (Swiggy pattern) ───────────────────────
          //       Rendered inside a Scaffold card alongside native widgets.
          //       Reacts to Sdui.updateContext changes in real time.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SduiScreen(
              routeName: 'home_banner',
              cacheStrategy: SduiCacheStrategy.cacheFirst,
              loadingBuilder: (_) => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              errorBuilder: (_, err) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Error: ${err.message}',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          ),

          // ── Live context slider ───────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Text(
              'Update cart.itemCount — banner re-renders without a network call:',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Text(
                  '${_cartCount.round()} items',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Expanded(
                  child: Slider(
                    value: _cartCount,
                    min: 0,
                    max: 10,
                    divisions: 10,
                    label: _cartCount.round().toString(),
                    onChanged: (v) {
                      setState(() => _cartCount = v);
                      // updateContext merges the patch and notifies all
                      // SduiScreen listeners so the banner re-renders in place.
                      Sdui.updateContext({
                        'cart': {'itemCount': v.round()},
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 32),

          // ── Section label ─────────────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Custom action — addToCart',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),

          // ── 6. Promo card with custom action button ───────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: SduiScreen(
                  routeName: 'promo_card',
                  loadingBuilder: (_) => const SizedBox(
                    height: 48,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── 7. Full-screen SDUI login route ──────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FilledButton.icon(
              icon: const Icon(Icons.login),
              label: const Text('Open SDUI-driven sign-in form'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const _LoginPage(),
                ),
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Text(
              'The sign-in form is fully server-driven: fields, validation '
              'rules, and the submit action are all declared in '
              'assets/screens/login.json.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Login page (full-screen SDUI) ─────────────────────────────────────────────
//
// The layout — including form fields, validation, and the submit button —
// is declared entirely in login.json.  The validateForm action handler
// is built into the SDK and dispatches isValid / isNotValid sub-actions.

class _LoginPage extends StatelessWidget {
  const _LoginPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in (full SDUI)')),
      body: SduiScreen(
        routeName: 'login',
        cacheStrategy: SduiCacheStrategy.cacheFirst,
        loadingBuilder: (_) => const Center(child: CircularProgressIndicator()),
        errorBuilder: (_, err) => Center(
          child: Text(
            'Could not load login screen: ${err.message}',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
