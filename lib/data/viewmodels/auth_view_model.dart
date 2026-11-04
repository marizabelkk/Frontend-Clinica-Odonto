import 'package:flutter/foundation.dart';

import '../../data/models/usuario_dto.dart';
import '../repositories/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  AuthViewModel({required this.repository});

  final AuthRepository repository;

  UsuarioDto? _usuario;
  String? _accessToken;
  String? _errorMessage;
  bool _isLoading = false;

  UsuarioDto? get usuario => _usuario;
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
      _errorMessage = AuthRepository.userMessageFor(error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
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
