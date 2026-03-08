import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/sdui_layout.dart';
import '../theme/sdui_theme.dart';
import '../registry/widget_registry.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  Helper
// ═══════════════════════════════════════════════════════════════════════════

Color? _parseColor(dynamic raw) {
  if (raw == null) return null;
  final s = raw.toString().replaceFirst('#', '');
  try {
    return Color(int.parse(s.length == 6 ? 'FF$s' : s, radix: 16));
  } catch (_) {
    return null;
  }
}

EdgeInsets _parsePadding(dynamic raw) {
  if (raw == null) return EdgeInsets.zero;
  if (raw is num) return EdgeInsets.all(raw.toDouble());
  if (raw is Map<String, dynamic>) {
    return EdgeInsets.only(
      top: (raw['top'] ?? raw['vertical'] ?? raw['all'] ?? 0).toDouble(),
      bottom: (raw['bottom'] ?? raw['vertical'] ?? raw['all'] ?? 0).toDouble(),
      left: (raw['left'] ?? raw['horizontal'] ?? raw['all'] ?? 0).toDouble(),
      right: (raw['right'] ?? raw['horizontal'] ?? raw['all'] ?? 0).toDouble(),
    );
  }
  return EdgeInsets.zero;
}

MainAxisAlignment _parseMainAxisAlignment(String? v) => switch (v) {
      'end' => MainAxisAlignment.end,
      'center' => MainAxisAlignment.center,
      'spaceBetween' => MainAxisAlignment.spaceBetween,
      'spaceAround' => MainAxisAlignment.spaceAround,
      'spaceEvenly' => MainAxisAlignment.spaceEvenly,
      _ => MainAxisAlignment.start,
    };

CrossAxisAlignment _parseCrossAxisAlignment(String? v) => switch (v) {
      'end' => CrossAxisAlignment.end,
      'center' => CrossAxisAlignment.center,
      'stretch' => CrossAxisAlignment.stretch,
      _ => CrossAxisAlignment.start,
    };

/// Safely parse a numeric value from a prop (handles both String and num)
double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) {
    final parsed = double.tryParse(value);
    return parsed;
  }
  return null;
}

/// Safely parse an integer value from a prop (handles both String and num)
int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  if (value is String) {
    final parsed = int.tryParse(value);
    return parsed;
  }
  return null;
}

/// Insert a gap widget between each child widget in a list
List<Widget> _insertGaps(List<Widget> children, Widget gap) {
  if (children.isEmpty) return children;
  final result = <Widget>[];
  for (int i = 0; i < children.length; i++) {
    result.add(children[i]);
    if (i < children.length - 1) {
      result.add(gap);
    }
  }
  return result;
}

// ═══════════════════════════════════════════════════════════════════════════
//  scaffold
// ═══════════════════════════════════════════════════════════════════════════

class SduiScaffoldWidget extends StatelessWidget {
  final SduiNode node;
  final WidgetRegistry registry;
  const SduiScaffoldWidget({super.key, required this.node, required this.registry});

  @override
  Widget build(BuildContext context) {
    final tokens = SduiTheme.of(context);
    final bg = _parseColor(node.prop('backgroundColor')) ?? tokens.scaffoldBackground;

    PreferredSizeWidget? appBar;
    if (node.appBar != null) {
      final bar = registry.build(context, node.appBar!);
      appBar = PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: bar,
      );
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: appBar,
      body: node.body != null ? registry.build(context, node.body!) : null,
      floatingActionButton: node.floatingActionButton != null
          ? registry.build(context, node.floatingActionButton!)
          : null,
      bottomNavigationBar: node.bottomNavigation != null
          ? registry.build(context, node.bottomNavigation!)
          : null,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  app_bar
// ═══════════════════════════════════════════════════════════════════════════

class SduiAppBarWidget extends StatelessWidget {
  final SduiNode node;
  final WidgetRegistry registry;
  const SduiAppBarWidget({super.key, required this.node, required this.registry});

  @override
  Widget build(BuildContext context) {
    final tokens = SduiTheme.of(context);
    final bg = _parseColor(node.prop('backgroundColor')) ?? tokens.appBarBackground;
    final fg = _parseColor(node.prop('foregroundColor')) ?? const Color(0xFF111827);
    final centerTitle = node.prop('centerTitle') as bool? ?? true;

    Widget? titleWidget;
    final titleNode = node.title;
    if (titleNode != null) {
      titleWidget = registry.build(context, titleNode);
    } else if (node.data != null) {
      titleWidget = Text(node.data!, style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 18));
    }

    return AppBar(
      backgroundColor: bg,
      foregroundColor: fg,
      centerTitle: centerTitle,
      elevation: (node.prop('elevation') as num?)?.toDouble() ?? 0,
      title: titleWidget,
      leading: node.leading != null ? registry.build(context, node.leading!) : null,
      actions: node.actions.map((a) => registry.build(context, a)).toList(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  text
// ═══════════════════════════════════════════════════════════════════════════

class SduiTextWidget extends StatelessWidget {
  final SduiNode node;
  const SduiTextWidget({super.key, required this.node});

  @override
  Widget build(BuildContext context) {
    final tokens = SduiTheme.of(context);
    final text = node.data ?? node.prop('value')?.toString() ?? '';
    final style = tokens.resolveTextStyle(node.style);
    final align = switch (node.style['textAlign'] as String?) {
      'center' => TextAlign.center,
      'right' || 'end' => TextAlign.end,
      _ => TextAlign.start,
    };
    final maxLines = (node.prop('maxLines') as num?)?.toInt();
    return Text(
      text,
      style: style,
      textAlign: align,
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  column
// ═══════════════════════════════════════════════════════════════════════════

class SduiColumnWidget extends StatelessWidget {
  final SduiNode node;
  final WidgetRegistry registry;
  const SduiColumnWidget({super.key, required this.node, required this.registry});

  @override
  Widget build(BuildContext context) {
    // Default to min — columns inside SingleChildScrollView must NOT use max
    // (unbounded height causes RenderFlex error and blank UI).
    // Use mainAxisSize: "max" explicitly only when you need the column to fill.
    final mainAxisSize = node.prop('mainAxisSize') == 'max'
        ? MainAxisSize.max
        : MainAxisSize.min;
    final gap = _parseDouble(node.prop('gap')) ?? 0;
    final children = node.children.map((c) => registry.build(context, c)).toList();
    return Column(
      mainAxisAlignment: _parseMainAxisAlignment(node.prop('mainAxisAlignment') as String?),
      crossAxisAlignment: _parseCrossAxisAlignment(node.prop('crossAxisAlignment') as String?),
      mainAxisSize: mainAxisSize,
      children: gap > 0
          ? _insertGaps(children, SizedBox(height: gap))
          : children,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  row
// ═══════════════════════════════════════════════════════════════════════════

class SduiRowWidget extends StatelessWidget {
  final SduiNode node;
  final WidgetRegistry registry;
  const SduiRowWidget({super.key, required this.node, required this.registry});

  @override
  Widget build(BuildContext context) {
    final gap = _parseDouble(node.prop('gap')) ?? 0;
    final children = node.children.map((c) => registry.build(context, c)).toList();
    return Row(
      mainAxisAlignment: _parseMainAxisAlignment(node.prop('mainAxisAlignment') as String?),
      crossAxisAlignment: _parseCrossAxisAlignment(node.prop('crossAxisAlignment') as String?),
      mainAxisSize: node.prop('mainAxisSize') == 'max' ? MainAxisSize.max : MainAxisSize.min,
      children: gap > 0
          ? _insertGaps(children, SizedBox(width: gap))
          : children,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  container
// ═══════════════════════════════════════════════════════════════════════════

class SduiContainerWidget extends StatelessWidget {
  final SduiNode node;
  final WidgetRegistry registry;
  const SduiContainerWidget({super.key, required this.node, required this.registry});

  @override
  Widget build(BuildContext context) {
    final decoration = node.prop('decoration') as Map<String, dynamic>?;
    Color? bg = _parseColor(node.prop('color') ?? node.style['color'] ?? decoration?['color']);
    double? borderRadius = _parseDouble(decoration?['borderRadius'] ?? node.style['borderRadius']);
    BoxDecoration? boxDecoration;
    if (bg != null || borderRadius != null) {
      boxDecoration = BoxDecoration(
        color: bg,
        borderRadius: borderRadius != null ? BorderRadius.circular(borderRadius) : null,
      );
    }

    return Container(
      width: (node.prop('width') as num?)?.toDouble(),
      height: (node.prop('height') as num?)?.toDouble(),
      padding: _parsePadding(node.prop('padding')),
      margin: _parsePadding(node.prop('margin')),
      decoration: boxDecoration,
      child: node.child != null ? registry.build(context, node.child!) : null,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  padding
// ═══════════════════════════════════════════════════════════════════════════

class SduiPaddingWidget extends StatelessWidget {
  final SduiNode node;
  final WidgetRegistry registry;
  const SduiPaddingWidget({super.key, required this.node, required this.registry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: _parsePadding(node.prop('padding')),
      child: node.child != null ? registry.build(context, node.child!) : const SizedBox.shrink(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  center
// ═══════════════════════════════════════════════════════════════════════════

class SduiCenterWidget extends StatelessWidget {
  final SduiNode node;
  final WidgetRegistry registry;
  const SduiCenterWidget({super.key, required this.node, required this.registry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: node.child != null ? registry.build(context, node.child!) : null,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  expanded
// ═══════════════════════════════════════════════════════════════════════════

class SduiExpandedWidget extends StatelessWidget {
  final SduiNode node;
  final WidgetRegistry registry;
  const SduiExpandedWidget({super.key, required this.node, required this.registry});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: (node.prop('flex') as num?)?.toInt() ?? 1,
      child: node.child != null ? registry.build(context, node.child!) : const SizedBox.shrink(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  spacer
// ═══════════════════════════════════════════════════════════════════════════

class SduiSpacerWidget extends StatelessWidget {
  final SduiNode node;
  const SduiSpacerWidget({super.key, required this.node});

  @override
  Widget build(BuildContext context) => Spacer(flex: (node.prop('flex') as num?)?.toInt() ?? 1);
}

// ═══════════════════════════════════════════════════════════════════════════
//  sized_box
// ═══════════════════════════════════════════════════════════════════════════

class SduiSizedBoxWidget extends StatelessWidget {
  final SduiNode node;
  final WidgetRegistry registry;
  const SduiSizedBoxWidget({super.key, required this.node, required this.registry});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (node.prop('width') as num?)?.toDouble(),
      height: (node.prop('height') as num?)?.toDouble(),
      child: node.child != null ? registry.build(context, node.child!) : null,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  image_network / image
// ═══════════════════════════════════════════════════════════════════════════

class SduiImageWidget extends StatelessWidget {
  final SduiNode node;
  const SduiImageWidget({super.key, required this.node});

  @override
  Widget build(BuildContext context) {
    final src = (node.prop('src') ?? node.prop('url') ?? node.data ?? '') as String;
    final width = (node.prop('width') as num?)?.toDouble();
    final height = (node.prop('height') as num?)?.toDouble();
    final borderRadius = (node.style['borderRadius'] as num?)?.toDouble() ?? 0;
    final fit = switch (node.prop('fit') as String?) {
      'contain' => BoxFit.contain,
      'fill' => BoxFit.fill,
      'fitWidth' => BoxFit.fitWidth,
      'fitHeight' => BoxFit.fitHeight,
      'none' => BoxFit.none,
      _ => BoxFit.cover,
    };

    Widget image;
    if (src.isEmpty) {
      image = Container(
        width: width,
        height: height ?? 120,
        color: const Color(0xFFE5E7EB),
        child: const Icon(Icons.image_outlined, color: Color(0xFF9CA3AF)),
      );
    } else {
      image = CachedNetworkImage(
        imageUrl: src,
        width: width,
        height: height,
        fit: fit,
        placeholder: (_, __) => Container(
          width: width,
          height: height ?? 120,
          color: const Color(0xFFE5E7EB),
        ),
        errorWidget: (_, __, ___) => Container(
          width: width,
          height: height ?? 120,
          color: const Color(0xFFFEE2E2),
          child: const Icon(Icons.broken_image_outlined, color: Color(0xFFEF4444)),
        ),
      );
    }

    if (borderRadius > 0) {
      image = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: image,
      );
    }
    return image;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  button variants
// ═══════════════════════════════════════════════════════════════════════════

class SduiButtonWidget extends StatelessWidget {
  final SduiNode node;
  final WidgetRegistry registry;
  const SduiButtonWidget({super.key, required this.node, required this.registry});

  void _handleTap() {
    final action = node.prop('action') as String?;
    if (action != null) {
      final params = <String, dynamic>{
        if (node.prop('screen') != null) 'screen': node.prop('screen'),
        if (node.prop('url') != null) 'url': node.prop('url'),
        ...?( node.prop('params') as Map<String, dynamic>?),
      };
      registry.fireAction(action, params);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = SduiTheme.of(context);
    final label = (node.prop('label') ?? node.data ?? 'Button') as String;
    final bg = _parseColor(node.style['backgroundColor'] ?? node.prop('color')) ?? tokens.primaryColor;
    final fg = _parseColor(node.style['color']) ?? tokens.onPrimary;
    final borderRadius = _parseDouble(node.style['borderRadius']) ?? 8;
    final fullWidth = node.prop('fullWidth') == true;
    
    // Parse padding from style
    final paddingHorizontal = _parseDouble(node.style['paddingHorizontal']) ?? 0;
    final paddingVertical = _parseDouble(node.style['paddingVertical']) ?? 0;
    final fontSize = _parseDouble(node.style['fontSize']);
    
    Widget child = node.child != null
        ? registry.build(context, node.child!)
        : Text(
            label,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w600,
              fontSize: fontSize,
            ),
          );
    
    // Apply padding if specified
    if (paddingHorizontal > 0 || paddingVertical > 0) {
      child = Padding(
        padding: EdgeInsets.symmetric(
          horizontal: paddingHorizontal,
          vertical: paddingVertical,
        ),
        child: child,
      );
    }

    final type = node.type;
    if (type == 'outlined_button') {
      return OutlinedButton(
        onPressed: _handleTap,
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
          side: BorderSide(color: bg),
        ),
        child: child,
      );
    }
    if (type == 'text_button') {
      return TextButton(onPressed: _handleTap, child: child);
    }
    if (type == 'floating_action_button') {
      return FloatingActionButton(
        onPressed: _handleTap,
        backgroundColor: bg,
        foregroundColor: fg,
        child: child,
      );
    }
    if (type == 'icon_button') {
      return IconButton(
        onPressed: _handleTap,
        icon: child,
        color: bg,
      );
    }
    // ElevatedButton (default)
    Widget button = ElevatedButton(
      onPressed: _handleTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
      ),
      child: child,
    );
    
    // Apply fullWidth if specified
    if (fullWidth) {
      button = SizedBox(width: double.infinity, child: button);
    }
    
    return button;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  icon
// ═══════════════════════════════════════════════════════════════════════════

class SduiIconWidget extends StatelessWidget {
  final SduiNode node;
  const SduiIconWidget({super.key, required this.node});

  // Minimal icon name → IconData map; extend as needed
  static const _icons = <String, IconData>{
    'location_on': Icons.location_on,
    'search': Icons.search,
    'home': Icons.home,
    'person': Icons.person,
    'settings': Icons.settings,
    'arrow_back': Icons.arrow_back,
    'close': Icons.close,
    'add': Icons.add,
    'remove': Icons.remove,
    'star': Icons.star,
    'favorite': Icons.favorite,
    'share': Icons.share,
    'notifications': Icons.notifications,
    'shopping_cart': Icons.shopping_cart,
    'menu': Icons.menu,
    'more_vert': Icons.more_vert,
    'check': Icons.check,
    'phone': Icons.phone,
    'email': Icons.email,
    'edit': Icons.edit,
    'delete': Icons.delete,
    'chevron_right': Icons.chevron_right,
    'restaurant': Icons.restaurant,
    'local_shipping': Icons.local_shipping,
    'local_offer': Icons.local_offer,
  };

  @override
  Widget build(BuildContext context) {
    final name = (node.prop('name') ?? node.data ?? 'help_outline') as String;
    final iconData = _icons[name] ?? Icons.help_outline;
    final color = _parseColor(node.prop('color') ?? node.style['color']);
    final size = (node.prop('size') as num?)?.toDouble() ?? 24;
    return Icon(iconData, color: color, size: size);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  divider
// ═══════════════════════════════════════════════════════════════════════════

class SduiDividerWidget extends StatelessWidget {
  final SduiNode node;
  const SduiDividerWidget({super.key, required this.node});

  @override
  Widget build(BuildContext context) {
    final tokens = SduiTheme.of(context);
    final color = _parseColor(node.prop('color')) ?? tokens.dividerColor;
    final thickness = (node.prop('thickness') as num?)?.toDouble() ?? 1;
    final indent = (node.prop('indent') as num?)?.toDouble() ?? 0;
    final endIndent = (node.prop('endIndent') as num?)?.toDouble() ?? 0;
    return Divider(color: color, thickness: thickness, indent: indent, endIndent: endIndent);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  card
// ═══════════════════════════════════════════════════════════════════════════

class SduiCardWidget extends StatelessWidget {
  final SduiNode node;
  final WidgetRegistry registry;
  const SduiCardWidget({super.key, required this.node, required this.registry});

  @override
  Widget build(BuildContext context) {
    final tokens = SduiTheme.of(context);
    final elevation = (node.prop('elevation') as num?)?.toDouble() ?? 1;
    final borderRadius = (node.style['borderRadius'] as num?)?.toDouble() ?? 12;
    final bg = _parseColor(node.style['backgroundColor']) ?? tokens.cardBackground;
    final padding = _parsePadding(node.prop('padding') ?? node.style['padding']);

    Widget? child;
    if (node.child != null) {
      child = registry.build(context, node.child!);
    } else if (node.children.isNotEmpty) {
      child = Column(
        mainAxisSize: MainAxisSize.min,
        children: node.children.map((c) => registry.build(context, c)).toList(),
      );
    }

    return Card(
      elevation: elevation,
      color: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
      child: child != null ? Padding(padding: padding, child: child) : null,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  list_view
// ═══════════════════════════════════════════════════════════════════════════

class SduiListViewWidget extends StatelessWidget {
  final SduiNode node;
  final WidgetRegistry registry;
  const SduiListViewWidget({super.key, required this.node, required this.registry});

  @override
  Widget build(BuildContext context) {
    final scrollDir = node.prop('scrollDirection') == 'horizontal'
        ? Axis.horizontal
        : Axis.vertical;
    final shrinkWrap = node.prop('shrinkWrap') == true;
    final physics = shrinkWrap
        ? const NeverScrollableScrollPhysics()
        : const AlwaysScrollableScrollPhysics();

    return ListView.separated(
      scrollDirection: scrollDir,
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: _parsePadding(node.prop('padding')),
      itemCount: node.children.length,
      separatorBuilder: (_, __) {
        final sep = node.prop('separator');
        if (sep is Map<String, dynamic>) {
          return registry.build(context, SduiNode.fromJson(sep));
        }
        return const SizedBox.shrink();
      },
      itemBuilder: (ctx, i) => registry.build(ctx, node.children[i]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  list_tile
// ═══════════════════════════════════════════════════════════════════════════

class SduiListTileWidget extends StatelessWidget {
  final SduiNode node;
  final WidgetRegistry registry;
  const SduiListTileWidget({super.key, required this.node, required this.registry});

  @override
  Widget build(BuildContext context) {
    final tokens = SduiTheme.of(context);
    Widget? titleWidget;
    final t = node.title;
    if (t != null) {
      titleWidget = registry.build(context, t);
    } else if (node.prop('title') is String) {
      titleWidget = Text(node.prop('title') as String,
          style: TextStyle(color: tokens.defaultTextColor, fontSize: 14, fontWeight: FontWeight.w500));
    }

    Widget? subtitleWidget;
    if (node.prop('subtitle') is String) {
      subtitleWidget = Text(node.prop('subtitle') as String,
          style: TextStyle(color: tokens.defaultTextColor.withValues(alpha: 0.6), fontSize: 12));
    }

    void handleTap() {
      final action = node.prop('action') as String?;
      if (action != null) {
        registry.fireAction(action, {
          if (node.prop('screen') != null) 'screen': node.prop('screen'),
          if (node.prop('params') != null) ...Map<String, dynamic>.from(node.prop('params') as Map),
        });
      }
    }

    return ListTile(
      leading: node.leading != null ? registry.build(context, node.leading!) : null,
      title: titleWidget,
      subtitle: subtitleWidget,
      trailing: node.trailing != null ? registry.build(context, node.trailing!) : null,
      contentPadding: _parsePadding(node.prop('contentPadding')),
      onTap: handleTap,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  single_child_scroll_view
// ═══════════════════════════════════════════════════════════════════════════

class SduiScrollViewWidget extends StatelessWidget {
  final SduiNode node;
  final WidgetRegistry registry;
  const SduiScrollViewWidget({super.key, required this.node, required this.registry});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: node.prop('scrollDirection') == 'horizontal' ? Axis.horizontal : Axis.vertical,
      padding: _parsePadding(node.prop('padding')),
      child: node.child != null ? registry.build(context, node.child!) : const SizedBox.shrink(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  safe_area
// ═══════════════════════════════════════════════════════════════════════════

class SduiSafeAreaWidget extends StatelessWidget {
  final SduiNode node;
  final WidgetRegistry registry;
  const SduiSafeAreaWidget({super.key, required this.node, required this.registry});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: node.prop('top') != false,
      bottom: node.prop('bottom') != false,
      left: node.prop('left') != false,
      right: node.prop('right') != false,
      child: node.child != null ? registry.build(context, node.child!) : const SizedBox.shrink(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  stack
// ═══════════════════════════════════════════════════════════════════════════

class SduiStackWidget extends StatelessWidget {
  final SduiNode node;
  final WidgetRegistry registry;
  const SduiStackWidget({super.key, required this.node, required this.registry});

  @override
  Widget build(BuildContext context) {
    final alignment = switch (node.prop('alignment') as String?) {
      'center' => Alignment.center,
      'topLeft' => Alignment.topLeft,
      'topRight' => Alignment.topRight,
      'bottomLeft' => Alignment.bottomLeft,
      'bottomRight' => Alignment.bottomRight,
      'topCenter' => Alignment.topCenter,
      'bottomCenter' => Alignment.bottomCenter,
      _ => Alignment.topLeft,
    };
    return Stack(
      alignment: alignment,
      fit: node.prop('fit') == 'expand' ? StackFit.expand : StackFit.loose,
      children: node.children.map((c) => registry.build(context, c)).toList(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  flexible
// ═══════════════════════════════════════════════════════════════════════════

class SduiFlexibleWidget extends StatelessWidget {
  final SduiNode node;
  final WidgetRegistry registry;
  const SduiFlexibleWidget({super.key, required this.node, required this.registry});

  @override
  Widget build(BuildContext context) {
    return Flexible(
      flex: (node.prop('flex') as num?)?.toInt() ?? 1,
      fit: node.prop('fit') == 'tight' ? FlexFit.tight : FlexFit.loose,
      child: node.child != null ? registry.build(context, node.child!) : const SizedBox.shrink(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  wrap
// ═══════════════════════════════════════════════════════════════════════════

class SduiWrapWidget extends StatelessWidget {
  final SduiNode node;
  final WidgetRegistry registry;
  const SduiWrapWidget({super.key, required this.node, required this.registry});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      direction: node.prop('direction') == 'vertical' ? Axis.vertical : Axis.horizontal,
      alignment: switch (node.prop('alignment') as String?) {
        'center' => WrapAlignment.center,
        'end' => WrapAlignment.end,
        'spaceBetween' => WrapAlignment.spaceBetween,
        'spaceAround' => WrapAlignment.spaceAround,
        _ => WrapAlignment.start,
      },
      spacing: (node.prop('spacing') as num?)?.toDouble() ?? 0,
      runSpacing: (node.prop('runSpacing') as num?)?.toDouble() ?? 0,
      children: node.children.map((c) => registry.build(context, c)).toList(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  gesture_detector
// ═══════════════════════════════════════════════════════════════════════════

class SduiGestureDetectorWidget extends StatelessWidget {
  final SduiNode node;
  final WidgetRegistry registry;
  const SduiGestureDetectorWidget({super.key, required this.node, required this.registry});

  void _handleTap() {
    final action = node.prop('action') as String?;
    if (action != null) {
      registry.fireAction(action, {
        if (node.prop('screen') != null) 'screen': node.prop('screen'),
        if (node.prop('params') != null) ...Map<String, dynamic>.from(node.prop('params') as Map),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: node.child != null ? registry.build(context, node.child!) : const SizedBox.shrink(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Unknown / fallback
// ═══════════════════════════════════════════════════════════════════════════

class SduiUnknownWidget extends StatelessWidget {
  final String type;
  const SduiUnknownWidget({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFF59E0B), width: 0.5),
      ),
      child: Text(
        '⚠ Unknown widget: $type',
        style: const TextStyle(fontSize: 11, color: Color(0xFF92400E)),
      ),
    );
  }
}
