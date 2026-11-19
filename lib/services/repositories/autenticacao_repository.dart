import '../../core/network/api_client.dart';
import '../../core/network/api_errors.dart';
import '../../core/network/auth_token_store.dart';
import '../../models/auth_model.dart';
import '../../models/usuario_model.dart';

class AutenticacaoRepository {
  const AutenticacaoRepository({
    required this.apiClient,
    required this.tokenStore,
  });

  final ApiClient apiClient;
  final AuthTokenStore tokenStore;

  Future<LoginResponseModel> login({
    required String email,
    required String senha,
  }) async {
    final response = await apiClient.dio.post<Map<String, dynamic>>(
      'auth/login',
      data: LoginRequestModel(email: email, senha: senha).toJson(),
    );
    final data = response.data;
    if (data == null) {
      throw const FormatException(
        'A API retornou uma resposta vazia no login.',
      );
    }
    return LoginResponseModel.fromJson(data);
  }

  Future<UsuarioModel> getCurrentUser() async {
    final response = await apiClient.dio.get<Map<String, dynamic>>(
      'usuarios/me',
    );
    final data = response.data;
    if (data == null) {
      throw const FormatException(
        'A API retornou uma resposta vazia para o usuário atual.',
      );
    }
    return UsuarioModel.fromJson(data);
  }

  Future<List<UsuarioModel>> listUsuarios() async {
    final response = await apiClient.dio.get<List<dynamic>>('usuarios');
    final data = response.data;
    if (data == null) {
      throw const FormatException(
        'A API retornou uma resposta vazia para a lista de usuários.',
      );
    }
    return data
        .map((item) => UsuarioModel.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<UsuarioModel> updateUsuarioStatus(
    int id, {
    required bool ativo,
  }) async {
    final response = await apiClient.dio.patch<Map<String, dynamic>>(
      'usuarios/$id/status',
      data: {'ativo': ativo},
    );
    final data = response.data;
    if (data == null) {
      throw const FormatException(
        'A API retornou uma resposta vazia ao atualizar o status do usuário.',
      );
    }
    return UsuarioModel.fromJson(data);
  }

  Future<UsuarioModel> createUsuario({
    required String nome,
    required String email,
    required String senha,
    required PerfilUsuario perfil,
    String? matricula,
  }) async {
    final response = await apiClient.dio.post<Map<String, dynamic>>(
      'usuarios',
      data: {
        'nome': nome,
        'email': email,
        'senha': senha,
        'matricula': matricula,
        'perfil': perfil.apiValue,
      },
    );
    final data = response.data;
    if (data == null) {
      throw const FormatException(
        'A API retornou uma resposta vazia ao cadastrar o usuário.',
      );
    }
    return UsuarioModel.fromJson(data);
  }

  Future<UsuarioModel> updateUsuario(
    int id, {
    required String nome,
    required String email,
    required PerfilUsuario perfil,
    String? matricula,
    String? senha,
  }) async {
    final response = await apiClient.dio.put<Map<String, dynamic>>(
      'usuarios/$id',
      data: {
        'nome': nome,
        'email': email,
        'perfil': perfil.apiValue,
        'matricula': matricula,
        if (senha != null && senha.isNotEmpty) 'senha': senha,
      },
    );
    final data = response.data;
    if (data == null) {
      throw const FormatException(
        'A API retornou uma resposta vazia ao atualizar o usuário.',
      );
    }
    return UsuarioModel.fromJson(data);
  }

  Future<void> deleteUsuario(int id) async {
    await apiClient.dio.delete<void>('usuarios/$id');
  }

  /// Pede o código de recuperação por e-mail. A API responde igual
  /// para e-mails cadastrados ou não (não revela quais existem).
  Future<void> requestPasswordReset(String email) async {
    await apiClient.dio.post<Map<String, dynamic>>(
      'auth/recuperar-senha',
      data: {'email': email},
    );
  }

  Future<void> resetPassword({
    required String email,
    required String codigo,
    required String novaSenha,
  }) async {
    await apiClient.dio.post<Map<String, dynamic>>(
      'auth/redefinir-senha',
      data: {'email': email, 'codigo': codigo, 'nova_senha': novaSenha},
    );
  }

  void saveAccessToken(String token) => tokenStore.save(token);

  void clearAccessToken() => tokenStore.clear();

  static String userMessageFor(Object error) {
    return apiErrorMessage(
      error,
      fallback: 'Não foi possível concluir a operação. Tente novamente.',
    );
  }
}
