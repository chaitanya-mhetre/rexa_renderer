import '../context/sdui_context_store.dart';

final _varPattern = RegExp(r'\{\{([^{}]+)\}\}');

String resolveVariables(String input, SduiContextStore ctx) {
  return input.replaceAllMapped(_varPattern, (m) {
    final path = m.group(1)!.trim();
    final value = ctx.getValue(path);
    return value?.toString() ?? m.group(0)!;
  });
}

dynamic resolveVariablesInJson(dynamic json, SduiContextStore ctx) {
  if (json is String) {
    return resolveVariables(json, ctx);
  } else if (json is Map<String, dynamic>) {
    return json.map((k, v) => MapEntry(k, resolveVariablesInJson(v, ctx)));
  } else if (json is List) {
    return json.map((e) => resolveVariablesInJson(e, ctx)).toList();
  }
  return json;
}
