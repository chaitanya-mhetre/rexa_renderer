import 'package:flutter/material.dart';

/// Design tokens used by the REXA renderer.
/// Override via [RexaTheme.of(context)] if you wrap your app with [RexaThemeProvider].
@immutable
class RexaTheme extends InheritedWidget {
  final RexaTokens tokens;

  const RexaTheme({
    super.key,
    required this.tokens,
    required super.child,
  });

  static RexaTokens of(BuildContext context) {
    final t = context.dependOnInheritedWidgetOfExactType<RexaTheme>();
    return t?.tokens ?? RexaTokens.defaultLight();
  }

  @override
  bool updateShouldNotify(RexaTheme oldWidget) => tokens != oldWidget.tokens;
}

@immutable
class RexaTokens {
  // Text
  final Color defaultTextColor;
  final double defaultFontSize;
  final FontWeight defaultFontWeight;
  final double defaultLineHeight;

  // Surfaces
  final Color scaffoldBackground;
  final Color appBarBackground;
  final Color cardBackground;
  final Color dividerColor;

  // Accent
  final Color primaryColor;
  final Color onPrimary;

  const RexaTokens({
    required this.defaultTextColor,
    required this.defaultFontSize,
    required this.defaultFontWeight,
    required this.defaultLineHeight,
    required this.scaffoldBackground,
    required this.appBarBackground,
    required this.cardBackground,
    required this.dividerColor,
    required this.primaryColor,
    required this.onPrimary,
  });

  factory RexaTokens.defaultLight() => const RexaTokens(
        defaultTextColor: Color(0xFF111827),
        defaultFontSize: 14,
        defaultFontWeight: FontWeight.w400,
        defaultLineHeight: 1.5,
        scaffoldBackground: Color(0xFFFFFFFF),
        appBarBackground: Color(0xFFFFFFFF),
        cardBackground: Color(0xFFFFFFFF),
        dividerColor: Color(0xFFE5E7EB),
        primaryColor: Color(0xFF6366F1),
        onPrimary: Color(0xFFFFFFFF),
      );

  factory RexaTokens.defaultDark() => const RexaTokens(
        defaultTextColor: Color(0xFFF9FAFB),
        defaultFontSize: 14,
        defaultFontWeight: FontWeight.w400,
        defaultLineHeight: 1.5,
        scaffoldBackground: Color(0xFF0F172A),
        appBarBackground: Color(0xFF1E293B),
        cardBackground: Color(0xFF1E293B),
        dividerColor: Color(0xFF334155),
        primaryColor: Color(0xFF818CF8),
        onPrimary: Color(0xFF1E1B4B),
      );

  /// Build a [TextStyle] from a style map (JSON-sourced).
  TextStyle resolveTextStyle(Map<String, dynamic> style) {
    Color parseColor(String? hex) {
      if (hex == null) return defaultTextColor;
      try {
        final s = hex.replaceFirst('#', '');
        return Color(int.parse(s.length == 6 ? 'FF$s' : s, radix: 16));
      } catch (_) {
        return defaultTextColor;
      }
    }

    FontWeight parseFontWeight(dynamic w) {
      if (w == null) return defaultFontWeight;
      if (w is String) {
        return switch (w) {
          'bold' || '700' => FontWeight.w700,
          'semibold' || '600' => FontWeight.w600,
          'medium' || '500' => FontWeight.w500,
          'light' || '300' => FontWeight.w300,
          _ => defaultFontWeight,
        };
      }
      if (w is num) return FontWeight.values[(w ~/ 100).clamp(1, 9) - 1];
      return defaultFontWeight;
    }

    return TextStyle(
      fontSize: (style['fontSize'] as num?)?.toDouble() ?? defaultFontSize,
      color: parseColor(style['color'] as String?),
      fontWeight: parseFontWeight(style['fontWeight']),
      height: (style['lineHeight'] as num?)?.toDouble() ?? defaultLineHeight,
      letterSpacing: (style['letterSpacing'] as num?)?.toDouble(),
      decoration: style['decoration'] == 'underline'
          ? TextDecoration.underline
          : TextDecoration.none,
    );
  }
}
