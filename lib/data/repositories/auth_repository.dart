import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../../core/network/auth_token_store.dart';
import '../models/auth_dto.dart';
import '../models/usuario_dto.dart';

class AuthRepository {
  const AuthRepository({required this.apiClient, required this.tokenStore});

  final ApiClient apiClient;
  final AuthTokenStore tokenStore;

  Future<LoginResponseDto> login({
    required String email,
    required String senha,
  }) async {
    final response = await apiClient.dio.post<Map<String, dynamic>>(
      'auth/login',
      data: LoginRequestDto(email: email, senha: senha).toJson(),
    );
    final data = response.data;
    if (data == null) {
      throw const FormatException(
        'A API retornou uma resposta vazia no login.',
      );
    }
    return LoginResponseDto.fromJson(data);
  }

  Future<UsuarioDto> getCurrentUser() async {
    final response = await apiClient.dio.get<Map<String, dynamic>>(
      'usuarios/me',
    );
    final data = response.data;
    if (data == null) {
      throw const FormatException(
        'A API retornou uma resposta vazia para o usuário atual.',
      );
    }
    return UsuarioDto.fromJson(data);
  }

  void saveAccessToken(String token) => tokenStore.save(token);

  void clearAccessToken() => tokenStore.clear();

  static String userMessageFor(Object error) {
    if (error is FormatException) {
      return 'A resposta do servidor está fora do formato esperado.';
    }
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 400 || statusCode == 401) {
        return 'Credenciais inválidas ou usuário inativo.';
      }
      if (statusCode == 403) {
        return 'Seu perfil não tem permissão para acessar este recurso.';
      }
      if (statusCode == 422) {
        return 'Confira os dados informados e tente novamente.';
      }
      if (statusCode != null && statusCode >= 500) {
        return 'O serviço está indisponível no momento. Tente novamente mais tarde.';
      }
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return 'Não foi possível conectar à API. Verifique o endereço e tente novamente.';
      }
    }
    return 'Não foi possível entrar. Tente novamente.';
  }
}
