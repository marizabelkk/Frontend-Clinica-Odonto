import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondonto_uninassau/core/constants/api_constants.dart';
import 'package:ondonto_uninassau/core/network/api_client.dart';

void main() {
  group('ApiClient', () {
    test('configures the versioned API base URL', () {
      expect(ApiConstants.baseUrl, endsWith('/api/v1/'));
    });

    test(
      'joins the API base URL and relative endpoint without losing v1',
      () async {
        final adapter = _CaptureAdapter();
        final dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl))
          ..httpClientAdapter = adapter;
        final client = ApiClient(dio: dio);

        await client.dio.post<void>(
          'auth/login',
          data: {'email': 'test@example.com'},
        );

        expect(adapter.requestOptions?.uri.path, '/api/v1/auth/login');
      },
    );

    test('adds the JWT Bearer token to requests', () async {
      final adapter = _CaptureAdapter();
      final dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl))
        ..httpClientAdapter = adapter;
      final client = ApiClient(
        dio: dio,
        tokenProvider: () async => 'jwt-token',
      );

      await client.dio.get<void>('pacientes');

      expect(
        adapter.requestOptions?.headers['Authorization'],
        'Bearer jwt-token',
      );
    });

    test('does not add authorization when there is no token', () async {
      final adapter = _CaptureAdapter();
      final dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl))
        ..httpClientAdapter = adapter;
      final client = ApiClient(dio: dio, tokenProvider: () async => null);

      await client.dio.get<void>('pacientes');

      expect(
        adapter.requestOptions?.headers.containsKey('Authorization'),
        isFalse,
      );
    });
  });
}

class _CaptureAdapter implements HttpClientAdapter {
  RequestOptions? requestOptions;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestOptions = options;
    return ResponseBody.fromString(
      '{}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
