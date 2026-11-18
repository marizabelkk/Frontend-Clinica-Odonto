import 'package:dio/dio.dart';

/// Texto `detail` devolvido pela API (`{"detail": "..."}`), se houver.
String? serverDetail(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['detail'] is String) {
      return data['detail'] as String;
    }
  }
  return null;
}

/// Mensagem amigável para qualquer falha de chamada à API.
/// Mostra o `detail` do servidor em erros 4xx e no 503 (que traz a orientação
/// de como resolver, ex.: banco não inicializado).
String apiErrorMessage(Object error, {required String fallback}) {
  if (error is FormatException) {
    return 'A resposta do servidor está fora do formato esperado.';
  }
  if (error is DioException) {
    final status = error.response?.statusCode;
    final detail = serverDetail(error);
    if (status == 403) {
      return detail ?? 'Seu perfil não tem permissão para esta ação.';
    }
    if (status == 503) {
      return detail ?? 'O serviço está indisponível no momento.';
    }
    if (status != null && status >= 500) {
      return 'O serviço está indisponível no momento. Tente novamente mais tarde.';
    }
    if (status != null && detail != null) return detail;
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'Não foi possível conectar à API. Verifique se o backend está rodando e o endereço está correto.';
    }
  }
  return fallback;
}
