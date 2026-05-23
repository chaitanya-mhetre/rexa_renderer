import 'dart:convert';

class SduiCachedScreen {
  final String routeName;
  final String json;
  final int version;
  final DateTime cachedAt;

  const SduiCachedScreen({
    required this.routeName,
    required this.json,
    required this.version,
    required this.cachedAt,
  });

  bool isFreshWithin(Duration? maxAge) {
    if (maxAge == null) return true;
    return DateTime.now().difference(cachedAt) <= maxAge;
  }

  Map<String, dynamic> toJson() => {
        'routeName': routeName,
        'json': json,
        'version': version,
        'cachedAt': cachedAt.toIso8601String(),
      };

  String toJsonString() => jsonEncode(toJson());

  factory SduiCachedScreen.fromJson(Map<String, dynamic> m) => SduiCachedScreen(
        routeName: m['routeName'] as String,
        json: m['json'] as String,
        version: m['version'] as int,
        cachedAt: DateTime.parse(m['cachedAt'] as String),
      );

  factory SduiCachedScreen.fromJsonString(String s) =>
      SduiCachedScreen.fromJson(jsonDecode(s) as Map<String, dynamic>);
}
