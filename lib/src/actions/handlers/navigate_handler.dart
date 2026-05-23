import 'dart:async';
import 'package:flutter/material.dart';
import '../sdui_action.dart';

FutureOr<dynamic> navigateHandler(BuildContext ctx, SduiAction action) {
  final style = action.props['navigationStyle'] as String? ?? 'push';
  final routeName = action.props['routeName'] as String?;
  final args = action.props['arguments'];
  final result = action.props['result'];

  Widget destination() => _PlaceholderRouteWidget(routeName: routeName);

  switch (style) {
    case 'push':
      return Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => destination()));
    case 'pushReplacement':
      return Navigator.of(ctx).pushReplacement(MaterialPageRoute(builder: (_) => destination()));
    case 'pushAndRemoveAll':
      return Navigator.of(ctx).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => destination()),
        (_) => false,
      );
    case 'pop':
      Navigator.of(ctx).pop(result);
      return null;
    case 'popAll':
      Navigator.of(ctx).popUntil(ModalRoute.withName('/'));
      return null;
    case 'pushNamed':
      return Navigator.of(ctx).pushNamed(routeName!, arguments: args);
    case 'pushReplacementNamed':
      return Navigator.of(ctx).pushReplacementNamed(routeName!, arguments: args);
    case 'pushNamedAndRemoveAll':
      return Navigator.of(ctx).pushNamedAndRemoveUntil(routeName!, (_) => false, arguments: args);
    default:
      debugPrint('navigateHandler: unknown navigationStyle "$style"');
      return null;
  }
}

class _PlaceholderRouteWidget extends StatelessWidget {
  final String? routeName;
  const _PlaceholderRouteWidget({this.routeName});
  @override
  Widget build(BuildContext ctx) => Scaffold(
        appBar: AppBar(title: Text(routeName ?? 'SDUI Route')),
        body: const Center(child: Text('Loading…')),
      );
}
