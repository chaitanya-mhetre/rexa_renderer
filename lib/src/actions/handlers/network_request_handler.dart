import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import '../sdui_action.dart';
import '../sdui_action_registry.dart';
import '../../network/sdui_network_service.dart';
import '../../utils/variable_resolver.dart';
import '../../sdui.dart';

SduiActionHandler makeNetworkRequestHandler(SduiActionRegistry registry) {
  return (BuildContext ctx, SduiAction action) async {
    final url = action.props['url'] as String?;
    if (url == null || url.isEmpty) {
      debugPrint('networkRequest: missing url');
      return null;
    }

    final method = (action.props['method'] as String? ?? 'get').toLowerCase();
    final headers = _coerceStringMap(action.props['headers']);
    final queryParams = _coerceMap(action.props['queryParameters']);

    // Resolve body: walk + execute nested actions, then resolve {{vars}}
    final rawBody = action.props['body'];
    dynamic body;
    if (rawBody != null) {
      body = await _resolveBody(ctx, registry, rawBody);
      body = resolveVariablesInJson(body, Sdui.contextStore);
    }

    final dio = SduiNetworkService.dio;
    Response response;
    try {
      switch (method) {
        case 'post':
          response = await dio.post(
            url,
            data: body,
            queryParameters: queryParams,
            options: Options(headers: headers),
          );
          break;
        case 'put':
          response = await dio.put(
            url,
            data: body,
            queryParameters: queryParams,
            options: Options(headers: headers),
          );
          break;
        case 'delete':
          response = await dio.delete(
            url,
            data: body,
            queryParameters: queryParams,
            options: Options(headers: headers),
          );
          break;
        case 'get':
        default:
          response = await dio.get(
            url,
            queryParameters: queryParams,
            options: Options(headers: headers),
          );
      }
    } on DioException catch (e) {
      response = e.response ??
          Response(
            requestOptions: RequestOptions(path: url),
            statusCode: -1,
            data: e.message,
          );
    }

    // Match response status to a follow-up action
    final results = action.props['results'];
    if (results is List) {
      for (final r in results) {
        if (r is Map && r['statusCode'] == response.statusCode && r['action'] is Map) {
          if (ctx.mounted) {
            await registry.dispatch(
              ctx,
              SduiAction.fromJson(Map<String, dynamic>.from(r['action'] as Map)),
            );
          }
          break;
        }
      }
    }

    return response;
  };
}

/// Recursive: if a value is itself an action map (has `actionType`), execute
/// it and substitute the return value. Otherwise leave alone (will be
/// variable-resolved in the next pass).
Future<dynamic> _resolveBody(
  BuildContext ctx,
  SduiActionRegistry registry,
  dynamic body,
) async {
  if (body is Map<String, dynamic>) {
    if (body['actionType'] is String) {
      // It's an action — execute and use the return value.
      try {
        return await registry.dispatch(ctx, SduiAction.fromJson(body));
      } catch (e) {
        debugPrint('networkRequest body action failed: $e');
        return null;
      }
    }
    final out = <String, dynamic>{};
    for (final entry in body.entries) {
      out[entry.key] = await _resolveBody(ctx, registry, entry.value);
    }
    return out;
  }
  if (body is List) {
    final out = <dynamic>[];
    for (final v in body) {
      out.add(await _resolveBody(ctx, registry, v));
    }
    return out;
  }
  return body;
}

Map<String, dynamic>? _coerceStringMap(dynamic v) {
  if (v is Map) {
    return v.map((k, val) => MapEntry(k.toString(), val));
  }
  return null;
}

Map<String, dynamic>? _coerceMap(dynamic v) {
  if (v is Map) {
    return v.map((k, val) => MapEntry(k.toString(), val));
  }
  return null;
}
