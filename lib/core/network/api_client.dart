import 'package:dio/dio.dart';

import '../constants/api_constants.dart';

/// Supplies the raw JWT access token, or null when the request is public.
typedef TokenProvider = Future<String?> Function();

const _authorizationHeader = 'Authorization';

/// Central Dio client for requests to the backend REST API.
class ApiClient {
  ApiClient({Dio? dio, TokenProvider? tokenProvider})
    : dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: ApiConstants.baseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
              sendTimeout: const Duration(seconds: 15),
              contentType: Headers.jsonContentType,
              responseType: ResponseType.json,
            ),
          ) {
    this.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final token = await tokenProvider?.call();
            if (token == null || token.isEmpty) {
              options.headers.remove(_authorizationHeader);
            } else {
              final authorization = token.startsWith('Bearer ')
                  ? token
                  : 'Bearer $token';
              options.headers[_authorizationHeader] = authorization;
            }
            handler.next(options);
          } catch (error, stackTrace) {
            handler.reject(
              DioException(
                requestOptions: options,
                error: error,
                stackTrace: stackTrace,
                type: DioExceptionType.unknown,
                message: 'Não foi possível obter o token de autenticação.',
              ),
            );
          }
        },
      ),
    );
  }

  final Dio dio;
}
