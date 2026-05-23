import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_renderer/src/network/sdui_network_service.dart';

void main() {
  test('initialize sets baseUrl and apiKey', () {
    final dio = Dio();
    SduiNetworkService.initialize(
      apiKey: 'sdui_test',
      baseUrl: 'https://api.example.com',
      dio: dio,
    );
    expect(SduiNetworkService.baseUrl, 'https://api.example.com');
    expect(SduiNetworkService.headers['X-Sdui-ApiKey'], 'sdui_test');
    expect(SduiNetworkService.headers['X-Sdui-Sdk-Version'], isNotNull);
    expect(SduiNetworkService.headers['X-Sdui-Protocol-Version'], isNotNull);
  });

  test('initialize defaults baseUrl when omitted', () {
    SduiNetworkService.initialize(apiKey: 'k');
    expect(SduiNetworkService.baseUrl, contains('://'));
  });

  test('fetchScreen builds correct URL', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    dio.httpClientAdapter = _MockAdapter((opts) async {
      return ResponseBody.fromString(
        '{"layout":{"type":"container"},"version":3}',
        200,
        headers: {
          'content-type': ['application/json'],
        },
      );
    });
    SduiNetworkService.initialize(
      apiKey: 'k',
      baseUrl: 'https://api.example.com',
      dio: dio,
    );
    final resp = await SduiNetworkService.fetchScreen('home');
    expect(resp.statusCode, 200);
    expect(resp.data['version'], 3);
  });
}

class _MockAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions) handler;

  _MockAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) =>
      handler(options);

  @override
  void close({bool force = false}) {}
}
