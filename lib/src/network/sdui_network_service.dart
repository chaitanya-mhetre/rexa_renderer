import 'package:dio/dio.dart';

/// A singleton-style static service that manages a shared [Dio] instance for
/// all SDUI network requests.
///
/// Call [initialize] once at app startup (typically alongside
/// `SduiRenderer.initialize`) to configure the base URL, API key, and optional
/// custom [Dio] instance.
///
/// Example:
/// ```dart
/// SduiNetworkService.initialize(
///   apiKey: 'sdui_live_xxxx',
///   baseUrl: 'https://api.example.com',
/// );
/// final response = await SduiNetworkService.fetchScreen('home');
/// ```
class SduiNetworkService {
  static const String _defaultBaseUrl = 'https://api.sdui.app';
  static const String sdkVersion = '0.2.0';
  static const String protocolVersion = '1';

  static late Dio _dio;
  static late String _baseUrl;
  static late Map<String, String> _headers;

  /// The base URL configured via [initialize].
  static String get baseUrl => _baseUrl;

  /// An unmodifiable view of the current request headers.
  static Map<String, String> get headers => Map.unmodifiable(_headers);

  /// The underlying [Dio] instance. Exposed for advanced use-cases and testing.
  static Dio get dio => _dio;

  /// Configure the service.
  ///
  /// Must be called before any [fetchScreen] invocations.
  ///
  /// - [apiKey]  — project API key sent as `X-Sdui-ApiKey`.
  /// - [baseUrl] — override the default base URL (`https://api.sdui.app`).
  /// - [dio]     — inject a custom [Dio] instance (useful in tests).
  static void initialize({
    required String apiKey,
    String? baseUrl,
    Dio? dio,
  }) {
    _baseUrl = baseUrl ?? _defaultBaseUrl;
    _headers = {
      'X-Sdui-ApiKey': apiKey,
      'X-Sdui-Sdk-Version': sdkVersion,
      'X-Sdui-Protocol-Version': protocolVersion,
    };
    _dio = dio ?? Dio(BaseOptions(baseUrl: _baseUrl));
    _dio.options.baseUrl = _baseUrl;
    _headers.forEach((k, v) => _dio.options.headers[k] = v);
  }

  /// Replace the API key at runtime without re-initializing.
  static void updateApiKey(String apiKey) {
    _headers['X-Sdui-ApiKey'] = apiKey;
    _dio.options.headers['X-Sdui-ApiKey'] = apiKey;
  }

  /// Fetch the layout for [routeName] from `/api/v1/screens/<routeName>`.
  static Future<Response> fetchScreen(String routeName) {
    return _dio.get('/api/v1/screens/$routeName');
  }
}
