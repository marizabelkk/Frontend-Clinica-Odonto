import 'package:flutter/foundation.dart';

import '../core/network/api_errors.dart';
import '../models/usuario_model.dart';
import '../services/repositories/autenticacao_repository.dart';

class AutenticacaoViewModel extends ChangeNotifier {
  AutenticacaoViewModel({required this.repository});

  final AutenticacaoRepository repository;

  UsuarioModel? _usuario;
  String? _accessToken;
  String? _errorMessage;
  bool _isLoading = false;

  UsuarioModel? get usuario => _usuario;
  String? get accessToken => _accessToken;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _usuario != null && _accessToken != null;
  PerfilUsuario? get perfil => _usuario?.perfil;

  Future<bool> login({required String email, required String senha}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final loginResponse = await repository.login(email: email, senha: senha);
      _accessToken = loginResponse.accessToken;
      repository.saveAccessToken(loginResponse.accessToken);

      // Fetch the authenticated identity from the canonical /usuarios/me route.
      _usuario = await repository.getCurrentUser();
      return true;
    } catch (error) {
      repository.clearAccessToken();
      _usuario = null;
      _accessToken = null;
      _errorMessage = AutenticacaoRepository.userMessageFor(error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Envia o código de recuperação por e-mail. Retorna a mensagem de erro, ou null se deu certo.
  Future<String?> requestPasswordReset(String email) async {
    try {
      await repository.requestPasswordReset(email);
      return null;
    } catch (error) {
      return apiErrorMessage(
        error,
        fallback: 'Não foi possível enviar o código. Tente novamente.',
      );
    }
  }

  /// Redefine a senha com o código recebido. Retorna a mensagem de erro, ou null se deu certo.
  Future<String?> resetPassword({
    required String email,
    required String codigo,
    required String novaSenha,
  }) async {
    try {
      await repository.resetPassword(
        email: email,
        codigo: codigo,
        novaSenha: novaSenha,
      );
      return null;
    } catch (error) {
      return apiErrorMessage(
        error,
        fallback: 'Não foi possível redefinir a senha. Tente novamente.',
      );
    }
  }

  void logout() {
    repository.clearAccessToken();
    _usuario = null;
    _accessToken = null;
    _errorMessage = null;
    notifyListeners();
  }
}
