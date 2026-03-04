import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/rexa_layout.dart';

/// Fetches REXA screen layouts from the backend and caches them locally.
///
/// Usage:
/// ```dart
/// final fetcher = RexaLayoutFetcher(
///   baseUrl: 'https://your-rexa-instance.com',
///   apiKey: 'rxa_your_project_key',
/// );
/// final result = await fetcher.fetchScreen('home');
/// ```
class RexaLayoutFetcher {
  final String baseUrl;
  final String apiKey;

  /// Maximum age of cached layout before a fresh fetch is attempted (soft TTL).
  final Duration cacheTTL;

  /// Whether to show stale cache while re-fetching in the background.
  final bool staleWhileRevalidate;

  final http.Client _client;

  RexaLayoutFetcher({
    required this.baseUrl,
    required this.apiKey,
    this.cacheTTL = const Duration(minutes: 5),
    this.staleWhileRevalidate = true,
    http.Client? client,
  }) : _client = client ?? http.Client();

  String _cacheKey(String screenName) => 'rexa_layout_$screenName';
  String _etagKey(String screenName) => 'rexa_etag_$screenName';
  String _timestampKey(String screenName) => 'rexa_ts_$screenName';

  /// Fetch the layout for [screenName].
  ///
  /// Strategy:
  /// 1. Load cached version from SharedPreferences.
  /// 2. If cache is fresh (within TTL) and [forceRefresh] is false, return it immediately.
  /// 3. Otherwise do a conditional GET (ETag). If 304, refresh timestamp and return cache.
  /// 4. If new content, update cache and return fresh result.
  /// 5. On network error, return stale cache if available.
  ///
  /// [forceRefresh] - If true, bypasses cache and always fetches from server.
  Future<RexaLayoutResponse> fetchScreen(String screenName, {bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedJson = prefs.getString(_cacheKey(screenName));
    final cachedEtag = prefs.getString(_etagKey(screenName));
    final cachedTs = prefs.getInt(_timestampKey(screenName)) ?? 0;

    final now = DateTime.now().millisecondsSinceEpoch;
    final age = now - cachedTs;
    final isFresh = age < cacheTTL.inMilliseconds;

    // Return fresh cache immediately (only if not forcing refresh)
    if (!forceRefresh && isFresh && cachedJson != null) {
      return _parseCache(cachedJson);
    }

    // Attempt network fetch
    try {
      final uri = Uri.parse(
        '$baseUrl/api/v1/screens/$screenName?apiKey=$apiKey',
      );

      final headers = <String, String>{
        'Accept': 'application/json',
        if (cachedEtag != null) 'If-None-Match': cachedEtag,
      };

      final response = await _client.get(uri, headers: headers).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 304 && cachedJson != null) {
        // Not modified — refresh timestamp and return cache
        await prefs.setInt(_timestampKey(screenName), now);
        return _parseCache(cachedJson);
      }

      if (response.statusCode == 200) {
        final body = response.body;
        final etag = response.headers['etag'];

        // Persist to cache
        await prefs.setString(_cacheKey(screenName), body);
        await prefs.setInt(_timestampKey(screenName), now);
        if (etag != null) {
          await prefs.setString(_etagKey(screenName), etag);
        }

        final json = jsonDecode(body) as Map<String, dynamic>;
        return RexaLayoutResponse.fromJson(json);
      }

      // Non-200/304 — parse error response
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return RexaLayoutResponse(
        success: false,
        error: json['error'] as String? ?? 'HTTP ${response.statusCode}',
      );
    } catch (e) {
      // Network error — fall back to stale cache if available
      if (staleWhileRevalidate && cachedJson != null) {
        return _parseCache(cachedJson);
      }
      return RexaLayoutResponse(
        success: false,
        error: 'Network error: ${e.toString()}',
      );
    }
  }

  /// Clear the local cache for a specific screen.
  Future<void> clearCache(String screenName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey(screenName));
    await prefs.remove(_etagKey(screenName));
    await prefs.remove(_timestampKey(screenName));
  }

  /// Clear all cached screens.
  Future<void> clearAllCaches() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('rexa_')).toList();
    for (final k in keys) {
      await prefs.remove(k);
    }
  }

  RexaLayoutResponse _parseCache(String raw) {
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return RexaLayoutResponse.fromJson(json);
    } catch (_) {
      return const RexaLayoutResponse(
        success: false,
        error: 'Failed to parse cached layout',
      );
    }
  }

  void dispose() => _client.close();
}
